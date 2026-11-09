import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore, FieldValue } from "firebase-admin/firestore";

import { REGION } from "../config";
import { REPORT_REASONS } from "../shared/reportReasons";

interface ReportData {
  targetUid: string;
  reason: string;
  details?: string;
  matchId?: string;
}

/**
 * Signalement d'un membre (docs/regles-economie-et-compatibilite.md
 * section 3). Motif obligatoire parmi une liste, identité du plaignant
 * jamais communiquée au compte signalé — c'est pour ça que ceci est une
 * Cloud Function et pas une écriture directe dans une collection lisible.
 */
export const reportUser = onCall({ region: REGION }, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Connexion requise.");
  }
  const uid = request.auth.uid;
  const { targetUid, reason, details, matchId } = request.data as ReportData;

  if (!targetUid || !REPORT_REASONS.includes(reason as (typeof REPORT_REASONS)[number])) {
    throw new HttpsError("invalid-argument", "Motif de signalement invalide.");
  }

  const db = getFirestore();
  await db.collection("moderation_requests").add({
    type: "user_report",
    reporterUid: uid,
    targetUid,
    reason,
    details: details ?? null,
    matchId: matchId ?? null,
    createdAt: FieldValue.serverTimestamp(),
    resolved: false,
  });

  return { ok: true };
});
