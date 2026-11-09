import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore, FieldValue } from "firebase-admin/firestore";

import { REGION } from "../config";
import { REPORT_REASONS } from "../shared/reportReasons";

/** Signalement d'une publication/annonce/événement (section 4.7 + 4.8). */
export const reportCommunityPost = onCall({ region: REGION }, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Connexion requise.");
  }
  const uid = request.auth.uid;
  const { postId, reason, details } = request.data as {
    postId: string;
    reason: string;
    details?: string;
  };
  if (!postId || !REPORT_REASONS.includes(reason as (typeof REPORT_REASONS)[number])) {
    throw new HttpsError("invalid-argument", "Motif de signalement invalide.");
  }

  const db = getFirestore();
  await db.collection("moderation_requests").add({
    type: "post_report",
    reporterUid: uid,
    postId,
    reason,
    details: details ?? null,
    createdAt: FieldValue.serverTimestamp(),
    resolved: false,
  });

  return { ok: true };
});
