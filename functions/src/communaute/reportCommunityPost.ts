import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore, FieldValue } from "firebase-admin/firestore";

import { REGION } from "../config";
import { REPORT_REASONS, HIGH_SEVERITY_REASONS } from "../shared/reportReasons";

/** Signalement d'une publication/annonce/événement (section 4.7 + 4.8). */
export const reportCommunityPost = onCall({ region: REGION }, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Connexion requise.");
  }
  const uid = request.auth.uid;
  const { postId, reason, details, replyId } = request.data as {
    postId: string;
    reason: string;
    details?: string;
    replyId?: string;
  };
  if (!postId || !REPORT_REASONS.includes(reason as (typeof REPORT_REASONS)[number])) {
    throw new HttpsError("invalid-argument", "Motif de signalement invalide.");
  }

  const db = getFirestore();
  // Résolu dès la création (pas seulement au traitement admin) pour que
  // l'escalade sache tout de suite qui viser, et pour que l'admin voie
  // "Visé : X" sans devoir rouvrir la publication (docs/regles-messagerie-
  // securite.md section 3 : compteur tous domaines confondus).
  const postSnap = await db.collection("community_posts").doc(postId).get();
  let targetUid = postSnap.data()?.authorUid as string | undefined;
  // Signalement d'une réponse : le membre visé est l'auteur de la réponse,
  // pas celui de la publication.
  if (replyId) {
    const replySnap = await postSnap.ref.collection("replies").doc(replyId).get();
    if (!replySnap.exists) {
      throw new HttpsError("not-found", "Réponse introuvable.");
    }
    targetUid = replySnap.data()?.authorUid as string | undefined;
  }

  const targetStatusSnap = targetUid ? await db.collection("user_status").doc(targetUid).get() : null;
  const alreadyPriority = targetStatusSnap?.data()?.priorityReview === true;
  const priority = alreadyPriority || HIGH_SEVERITY_REASONS.has(reason);

  await db.collection("moderation_requests").add({
    type: "post_report",
    reporterUid: uid,
    postId,
    replyId: replyId ?? null,
    targetUid: targetUid ?? null,
    reason,
    details: details ?? null,
    priority,
    createdAt: FieldValue.serverTimestamp(),
    resolved: false,
  });

  return { ok: true };
});
