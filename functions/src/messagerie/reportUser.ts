import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore, FieldValue } from "firebase-admin/firestore";

import { REGION, REPORT_RATE_LIMITS, MAX_REPORT_DETAILS } from "../config";
import { ENFORCE_APP_CHECK } from "../shared/appCheck";
import { REPORT_REASONS, HIGH_SEVERITY_REASONS } from "../shared/reportReasons";
import { enforceRateLimit } from "../shared/rateLimit";

interface ReportData {
  targetUid: string;
  reason: string;
  details?: string;
  matchId?: string;
  messageId?: string; // signalement d'une photo précise reçue en message
}

/**
 * Signalement d'un membre, ou d'une photo précise reçue en conversation
 * (docs/regles-messagerie-securite.md section 2 : "signaler une photo
 * reçue en un geste"). Motif obligatoire parmi une liste, identité du
 * plaignant jamais communiquée au compte signalé — c'est pour ça que ceci
 * est une Cloud Function et pas une écriture directe dans une collection
 * lisible.
 */
export const reportUser = onCall({ region: REGION, enforceAppCheck: ENFORCE_APP_CHECK }, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Connexion requise.");
  }
  const uid = request.auth.uid;
  const { targetUid, reason, details, matchId, messageId } = request.data as ReportData;

  if (
    typeof targetUid !== "string" ||
    !targetUid ||
    !REPORT_REASONS.includes(reason as (typeof REPORT_REASONS)[number]) ||
    (details !== undefined && details !== null && (typeof details !== "string" || details.length > MAX_REPORT_DETAILS)) ||
    (matchId !== undefined && matchId !== null && typeof matchId !== "string") ||
    (messageId !== undefined && messageId !== null && typeof messageId !== "string")
  ) {
    throw new HttpsError("invalid-argument", "Motif de signalement invalide.");
  }

  const db = getFirestore();

  // Jamais faire confiance au client sur la cohérence matchId/messageId/
  // targetUid : sans ça, n'importe quel appelant pourrait faire supprimer
  // (une fois le signalement confirmé, admin/moderationRequests.ts) la
  // photo d'un message n'appartenant ni à ce match ni à cette personne.
  if (matchId && messageId) {
    const matchSnap = await db.collection("matches").doc(matchId).get();
    const members = (matchSnap.data()?.members as string[] | undefined) ?? [];
    if (!members.includes(uid)) {
      throw new HttpsError("permission-denied", "Tu ne fais pas partie de cette conversation.");
    }
    const messageSnap = await db.collection("matches").doc(matchId).collection("messages").doc(messageId).get();
    if (!messageSnap.exists || messageSnap.data()?.fromUid !== targetUid) {
      throw new HttpsError("invalid-argument", "Ce message ne correspond pas au membre signalé.");
    }
  }

  // La limite de fréquence passe APRÈS les validations : un appel refusé
  // (message qui ne correspond pas, champ invalide) ne consomme aucun quota.
  await enforceRateLimit(uid, REPORT_RATE_LIMITS);

  const targetStatusSnap = await db.collection("user_status").doc(targetUid).get();
  const alreadyPriority = targetStatusSnap.data()?.priorityReview === true;
  const priority = alreadyPriority || HIGH_SEVERITY_REASONS.has(reason);

  await db.collection("moderation_requests").add({
    type: "user_report",
    reporterUid: uid,
    targetUid,
    reason,
    details: details ?? null,
    matchId: matchId ?? null,
    messageId: messageId ?? null,
    priority,
    createdAt: FieldValue.serverTimestamp(),
    resolved: false,
  });

  return { ok: true };
});
