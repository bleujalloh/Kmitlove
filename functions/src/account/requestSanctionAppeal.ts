import { HttpsError } from "firebase-functions/v2/https";
import { onCallNoConsent as onCall } from "../shared/callable";
import { getFirestore, FieldValue, Timestamp } from "firebase-admin/firestore";

import { REGION } from "../config";
import { ENFORCE_APP_CHECK } from "../shared/appCheck";

/**
 * Droit de recours après une sanction — avertissement, suspension
 * temporaire ou définitive, que la sanction vienne de l'escalade
 * automatique ou d'une suspension manuelle via adminSetSuspension
 * (docs/regles-messagerie-securite.md section 3). adminSetSuspension pose
 * aussi sanctionLevel="suspended" (synchronisé avec filtrageStatus, voir
 * shared/sanctions.ts), donc sanctionLevel non "none" couvre déjà les
 * deux origines ; filtrageStatus === "suspended" reste un repli
 * défensif pour une donnée plus ancienne où ça ne serait pas le cas.
 *
 * Lu et écrit dans une même transaction : sans ça, un double-appui ou un
 * retry réseau pourrait lire appealPending=false deux fois de suite et
 * créer deux demandes de recours en double (même raisonnement que
 * shared/sanctions.ts et admin/bootstrapFirstAdmin.ts).
 */
export const requestSanctionAppeal = onCall({ region: REGION, enforceAppCheck: ENFORCE_APP_CHECK }, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Connexion requise.");
  }
  const uid = request.auth.uid;
  const db = getFirestore();
  const statusRef = db.collection("user_status").doc(uid);

  await db.runTransaction(async (tx) => {
    const statusSnap = await tx.get(statusRef);
    const status = statusSnap.data();

    const sanctionLevel = status?.sanctionLevel as string | undefined;
    const hasSanction =
      (sanctionLevel != null && sanctionLevel !== "none") || status?.filtrageStatus === "suspended";
    if (!hasSanction) {
      throw new HttpsError("failed-precondition", "Aucune sanction active à contester.");
    }
    if (status?.appealPending === true) {
      throw new HttpsError("already-exists", "Un recours est déjà en cours de traitement.");
    }
    const nextRetryAt = status?.appealNextRetryAt as Timestamp | undefined;
    if (nextRetryAt && nextRetryAt.toMillis() > Date.now()) {
      throw new HttpsError("failed-precondition", "Un recours a déjà été refusé récemment, réessaie plus tard.");
    }

    const requestRef = db.collection("moderation_requests").doc();
    tx.set(requestRef, {
      type: "sanction_appeal",
      // targetUid (pas "uid") : même convention que user_report/
      // post_report, lue par l'enrichissement de adminListModerationRequests
      // (targetConfirmedReportCount/targetSanctionLevel) dans
      // admin/moderationRequests.ts — sans ça, ces deux champs
      // resteraient silencieusement à 0/"none" pour une demande de recours.
      targetUid: uid,
      sanctionLevel: sanctionLevel ?? null,
      priority: false,
      createdAt: FieldValue.serverTimestamp(),
      resolved: false,
    });
    tx.set(statusRef, { appealPending: true }, { merge: true });
  });

  return { ok: true };
});
