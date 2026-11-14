import { HttpsError } from "firebase-functions/v2/https";
import { onCall } from "../shared/callable";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import { getStorage } from "firebase-admin/storage";
import * as logger from "firebase-functions/logger";

import { REGION } from "../config";
import { ENFORCE_APP_CHECK } from "../shared/appCheck";
import { requireAdmin } from "../shared/requireAdmin";
import { computeSanctionUpdate } from "../shared/sanctions";
import type { SanctionAction } from "../shared/sanctions";
import { logAdminAction } from "../shared/adminLog";

/**
 * Liste les signalements/demandes non résolus (section 6), triés pour
 * qu'une urgence (bouton "danger immédiat", ou un compte déjà à 3
 * signalements confirmés) remonte toujours en premier — docs/regles-
 * complementaires-concurrents.md section 1 et docs/regles-messagerie-
 * securite.md section 3. `priority` est écrit sur CHAQUE type de demande
 * à la création (y compris filtrage_review) : un orderBy Firestore exclut
 * silencieusement les documents qui n'ont pas le champ trié.
 */
export const adminListModerationRequests = onCall({ region: REGION, enforceAppCheck: ENFORCE_APP_CHECK }, async (request) => {
  requireAdmin(request);
  const db = getFirestore();
  const snap = await db
    .collection("moderation_requests")
    .where("resolved", "==", false)
    .orderBy("priority", "desc")
    .orderBy("createdAt", "asc")
    .limit(50)
    .get();

  const requests = snap.docs.map((d) => ({ id: d.id, ...d.data() }));

  // Enrichit avec le compteur de signalements confirmés déjà sur le
  // compte visé, pour que l'admin voie le contexte sans devoir rouvrir
  // chaque fiche séparément.
  const targetUids = Array.from(
    new Set(
      requests
        .map((r) => (r as Record<string, unknown>).targetUid as string | null | undefined)
        .filter((v): v is string => typeof v === "string"),
    ),
  );
  if (targetUids.length > 0) {
    const statusSnaps = await db.getAll(...targetUids.map((uid) => db.collection("user_status").doc(uid)));
    const byUid = new Map(statusSnaps.map((s) => [s.id, s.data()]));
    for (const r of requests as Record<string, unknown>[]) {
      const targetUid = r.targetUid as string | null | undefined;
      const targetStatus = targetUid ? byUid.get(targetUid) : undefined;
      r.targetConfirmedReportCount = targetStatus?.confirmedReportCount ?? 0;
      r.targetSanctionLevel = targetStatus?.sanctionLevel ?? "none";
    }
  }

  return { requests };
});

type ResolveAction = "dismiss" | "warn" | "suspend" | "ban" | "handled";

interface ResolveData {
  requestId: string;
  action: ResolveAction;
}

interface ResolveOutcome {
  type: string;
  targetUid: string | null;
  reporterUid: string | null;
  isEmergency: boolean;
  sanctionResult: { confirmedReportCount: number; priorityReview: boolean } | null;
  storagePathToDelete: string | null;
}

/**
 * Traite un signalement (docs/regles-messagerie-securite.md section 3 :
 * escalade avertissement → suspension temporaire → suspension définitive,
 * droit de recours séparé via resolveSanctionAppeal) ou une alerte
 * d'urgence (action "handled" uniquement, aucune sanction automatique —
 * la réponse réelle au danger se passe hors de l'app).
 *
 * Tout — relecture de "resolved", calcul de la sanction, retrait de la
 * photo signalée, marquage "traité" — se fait dans UNE seule transaction
 * Firestore : sans ça, un double clic ou un retry réseau pourrait faire
 * avancer confirmedReportCount deux fois pour un seul signalement
 * confirmé. Toutes les lectures (tx.get) sont faites avant la moindre
 * écriture (tx.set/update), même piège déjà corrigé dans
 * decouvrir/recordSwipe.ts — Firestore refuse l'inverse.
 */
export const adminResolveModerationRequest = onCall({ region: REGION, enforceAppCheck: ENFORCE_APP_CHECK }, async (request) => {
  const adminUid = requireAdmin(request);
  const { requestId, action } = request.data as ResolveData;
  const validActions: ResolveAction[] = ["dismiss", "warn", "suspend", "ban", "handled"];
  if (!requestId || !validActions.includes(action)) {
    throw new HttpsError("invalid-argument", "Paramètres invalides.");
  }

  const db = getFirestore();
  const requestRef = db.collection("moderation_requests").doc(requestId);

  const outcome = await db.runTransaction<ResolveOutcome>(async (tx) => {
    // --- Lectures d'abord, dans l'ordre, jamais après une écriture ---
    const requestSnap = await tx.get(requestRef);
    const data = requestSnap.data();
    if (!data) {
      throw new HttpsError("not-found", "Signalement introuvable.");
    }
    if (data.resolved === true) {
      throw new HttpsError("already-exists", "Signalement déjà traité.");
    }
    if (data.type === "filtrage_review") {
      throw new HttpsError(
        "invalid-argument",
        "Une révision de filtrage se traite avec resolveFiltrageReview, pas ici.",
      );
    }
    if (data.type === "sanction_appeal") {
      throw new HttpsError("invalid-argument", "Un recours se traite avec resolveSanctionAppeal, pas ici.");
    }

    if (data.type === "emergency_alert") {
      if (action !== "handled") {
        throw new HttpsError("invalid-argument", "Une alerte d'urgence ne se traite qu'en 'handled'.");
      }
      tx.update(requestRef, { resolved: true, resolvedAt: FieldValue.serverTimestamp(), resolvedBy: adminUid, action });
      return {
        type: data.type,
        targetUid: null,
        reporterUid: (data.reporterUid as string) ?? null,
        isEmergency: true,
        sanctionResult: null,
        storagePathToDelete: null,
      };
    }
    if (action === "handled") {
      throw new HttpsError("invalid-argument", "'handled' réservé aux alertes d'urgence.");
    }

    let targetUid = data.targetUid as string | undefined;
    if (!targetUid && data.type === "post_report" && data.postId) {
      // Repli défensif si le signalement a été créé avant que
      // reportCommunityPost.ts ne résolve targetUid dès la création.
      const postSnap = await tx.get(db.collection("community_posts").doc(data.postId as string));
      targetUid = postSnap.data()?.authorUid as string | undefined;
    }
    // Un admin qui choisit d'avertir/suspendre/bannir doit savoir que ça
    // n'a pas pu s'appliquer — jamais marquer "traité" silencieusement
    // comme si la sanction avait eu lieu alors qu'il n'y a personne à
    // sanctionner (ex. auteur de la publication déjà supprimé) : il
    // choisirait "classer sans suite" en connaissance de cause plutôt que
    // de croire le compte sanctionné à tort.
    if (action !== "dismiss" && !targetUid) {
      throw new HttpsError(
        "failed-precondition",
        "Impossible de retrouver le compte visé (probablement déjà supprimé) — classe sans suite à la place.",
      );
    }

    let statusSnap: FirebaseFirestore.DocumentSnapshot | null = null;
    let messageSnap: FirebaseFirestore.DocumentSnapshot | null = null;
    if (action !== "dismiss" && targetUid) {
      statusSnap = await tx.get(db.collection("user_status").doc(targetUid));
      if (data.type === "user_report" && data.matchId && data.messageId) {
        messageSnap = await tx.get(
          db
            .collection("matches")
            .doc(data.matchId as string)
            .collection("messages")
            .doc(data.messageId as string),
        );
      }
    }

    // --- Écritures ensuite ---
    let sanctionResult: { confirmedReportCount: number; priorityReview: boolean } | null = null;
    let storagePathToDelete: string | null = null;
    if (action !== "dismiss" && targetUid && statusSnap) {
      const computed = computeSanctionUpdate(statusSnap.data() ?? {}, action as SanctionAction);
      tx.set(statusSnap.ref, computed.update, { merge: true });
      sanctionResult = { confirmedReportCount: computed.confirmedReportCount, priorityReview: computed.priorityReview };

      // Signalement confirmé sur une photo de message précise :
      // suppression immédiate, en plus de la sanction sur le compte
      // (docs/regles-messagerie-securite.md section 2) — seulement si le
      // message visé avait bien une photo, jamais pour un message texte.
      if (messageSnap) {
        const storagePath = messageSnap.data()?.imageStoragePath as string | undefined;
        if (storagePath) {
          tx.update(messageSnap.ref, { imageStoragePath: FieldValue.delete(), imageRemoved: true });
          storagePathToDelete = storagePath;
        }
      }
    }

    tx.update(requestRef, { resolved: true, resolvedAt: FieldValue.serverTimestamp(), resolvedBy: adminUid, action });

    return {
      type: data.type as string,
      targetUid: targetUid ?? null,
      reporterUid: null,
      isEmergency: false,
      sanctionResult,
      storagePathToDelete,
    };
  });

  // Le Storage n'est pas transactionnel avec Firestore : fait après coup,
  // au mieux — une photo encore présente côté Storage malgré l'échec ne
  // redevient jamais visible dans l'app puisque imageStoragePath a déjà
  // été retiré du message au-dessus.
  if (outcome.storagePathToDelete) {
    const storagePath = outcome.storagePathToDelete;
    await getStorage()
      .bucket()
      .file(storagePath)
      .delete()
      .catch((err) => logger.error("Échec de suppression Storage pour une photo signalée", { storagePath, err }));
  }

  if (outcome.isEmergency) {
    // reporterUid, pas targetUid : la personne qui a déclenché l'alerte
    // n'est la cible d'aucune action admin, contrairement à tous les
    // autres appels de logAdminAction (voir shared/adminLog.ts).
    await logAdminAction(db, {
      adminUid,
      action: "emergency_alert_handled",
      details: { requestId, reporterUid: outcome.reporterUid },
    });
  } else {
    await logAdminAction(db, {
      adminUid,
      action: `moderation_${action}`,
      targetUid: outcome.targetUid,
      details: {
        requestId,
        type: outcome.type,
        confirmedReportCount: outcome.sanctionResult?.confirmedReportCount ?? null,
      },
    });
  }

  return { ok: true };
});
