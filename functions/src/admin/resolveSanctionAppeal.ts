import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore, FieldValue, Timestamp } from "firebase-admin/firestore";

import { REGION, SANCTION_APPEAL_RETRY_DELAY_DAYS } from "../config";
import { requireAdmin } from "../shared/requireAdmin";
import { logAdminAction } from "../shared/adminLog";

interface ResolveData {
  requestId: string;
  approve: boolean; // true = lever la sanction, false = la maintenir
}

/**
 * Traite un recours contre une sanction (droit de recours, docs/regles-
 * messagerie-securite.md section 3). Tout dans une seule transaction,
 * même raisonnement que admin/moderationRequests.ts : sans ça, un double
 * clic/retry pourrait traiter deux fois le même recours.
 */
export const resolveSanctionAppeal = onCall({ region: REGION }, async (request) => {
  const adminUid = requireAdmin(request);
  const { requestId, approve } = request.data as ResolveData;
  if (!requestId) {
    throw new HttpsError("invalid-argument", "requestId manquant.");
  }

  const db = getFirestore();
  const requestRef = db.collection("moderation_requests").doc(requestId);

  const targetUid = await db.runTransaction<string>(async (tx) => {
    // --- Lectures d'abord ---
    const requestSnap = await tx.get(requestRef);
    const data = requestSnap.data();
    if (!data || data.type !== "sanction_appeal") {
      throw new HttpsError("not-found", "Recours introuvable.");
    }
    if (data.resolved === true) {
      throw new HttpsError("already-exists", "Recours déjà traité.");
    }

    const uid = data.targetUid as string;
    const statusRef = db.collection("user_status").doc(uid);
    const statusSnap = await tx.get(statusRef);
    const status = statusSnap.data();

    // Le recours a été déposé contre un niveau de sanction précis
    // (enregistré à la création, account/requestSanctionAppeal.ts). Si le
    // compte a depuis reçu une sanction DIFFÉRENTE ET toujours active
    // (nouveau signalement confirmé entre-temps), approuver ce vieux
    // recours ne doit jamais lever cette sanction plus récente qu'il ne
    // concernait pas. En revanche, si le compte n'est déjà plus sanctionné
    // du tout (ex. réactivé entre-temps via adminSetSuspension plutôt que
    // ce recours même), on autorise quand même l'approbation : elle ne
    // fait plus que classer la demande, sans quoi elle resterait bloquée
    // pour toujours (storedLevel ne pourra plus jamais redevenir égal à
    // ce qu'il était au moment du recours).
    const storedLevel = (status?.sanctionLevel as string | undefined) ?? "none";
    const appealedLevel = (data.sanctionLevel as string | undefined | null) ?? "none";
    if (approve && storedLevel !== appealedLevel && storedLevel !== "none") {
      throw new HttpsError(
        "failed-precondition",
        "Le compte a reçu une sanction plus récente depuis ce recours — à réexaminer séparément.",
      );
    }

    // --- Écritures ensuite ---
    if (approve) {
      const update: Record<string, unknown> = {
        sanctionLevel: "none",
        appealPending: false,
        appealNextRetryAt: null,
      };
      // Un "warned" ne touche jamais filtrageStatus/preSuspensionStatus
      // (shared/sanctions.ts) — seuls suspend/ban les posent. Les
      // restaurer inconditionnellement ici écraserait un filtrageStatus
      // sans rapport (ex. en attente de retry du filtrage, filtrage/
      // submitAttempt.ts) pour un compte qui n'a jamais été suspendu. On
      // se base sur filtrageStatus (le signal qui fait vraiment autorité,
      // voir shared/sanctions.ts), pas sur preSuspensionStatus seul :
      // "?? active" couvre aussi une donnée ancienne où il manquerait
      // malgré filtrageStatus="suspended" (même repli que
      // admin/listUsers.ts).
      if (status?.filtrageStatus === "suspended") {
        update.filtrageStatus = status?.preSuspensionStatus ?? "active";
        update.suspendedUntil = null;
        update.preSuspensionStatus = null;
        // Même nettoyage que admin/listUsers.ts (réactivation manuelle) :
        // sinon suspendedBy resterait pointer vers l'admin d'origine sur
        // un compte qui n'est plus suspendu.
        update.suspendedBy = null;
      }
      tx.set(statusRef, update, { merge: true });
    } else {
      // Même raisonnement que submitAttempt.ts pour le filtrage : sans
      // délai, un recours refusé pourrait être immédiatement resoumis en
      // boucle.
      const nextRetryAt = Timestamp.fromMillis(
        Date.now() + SANCTION_APPEAL_RETRY_DELAY_DAYS * 24 * 60 * 60 * 1000,
      );
      tx.set(statusRef, { appealPending: false, appealNextRetryAt: nextRetryAt }, { merge: true });
    }

    tx.update(requestRef, {
      resolved: true,
      resolvedAt: FieldValue.serverTimestamp(),
      resolvedBy: adminUid,
      approved: approve,
    });

    return uid;
  });

  await logAdminAction(db, {
    adminUid,
    action: approve ? "sanction_appeal_approved" : "sanction_appeal_denied",
    targetUid,
    details: { requestId },
  });

  return { ok: true };
});
