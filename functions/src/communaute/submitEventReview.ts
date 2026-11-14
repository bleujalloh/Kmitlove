import { HttpsError } from "firebase-functions/v2/https";
import { onCall } from "../shared/callable";
import { getFirestore, FieldValue } from "firebase-admin/firestore";

import { REGION } from "../config";
import { ENFORCE_APP_CHECK } from "../shared/appCheck";
import { zonedWallTimeToUtcMillis } from "../shared/timezone";

const MAX_COMMENT_LENGTH = 500;

interface ReviewData {
  postId: string;
  rating: number;
  comment?: string;
}

/**
 * Avis après un événement (spec Communauté section 9) — réservé aux
 * membres dont la participation a été acceptée par l'organisateur, pour
 * limiter les faux avis ; jamais une simple vérification côté client.
 */
export const submitEventReview = onCall({ region: REGION, enforceAppCheck: ENFORCE_APP_CHECK }, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Connexion requise.");
  }
  const uid = request.auth.uid;
  const { postId, rating, comment } = request.data as ReviewData;
  if (!postId || typeof rating !== "number" || !Number.isInteger(rating) || rating < 1 || rating > 5) {
    throw new HttpsError("invalid-argument", "Note invalide (1 à 5).");
  }
  if (comment && comment.length > MAX_COMMENT_LENGTH) {
    throw new HttpsError("invalid-argument", "Commentaire trop long.");
  }

  const db = getFirestore();
  const postRef = db.collection("community_posts").doc(postId);
  const [postSnap, participationSnap] = await Promise.all([
    postRef.get(),
    postRef.collection("participations").doc(uid).get(),
  ]);
  const post = postSnap.data();
  if (!post) {
    throw new HttpsError("not-found", "Événement introuvable.");
  }
  // « Avis après un événement » (spec Communauté section 9) : le code ne
  // vérifiait rien, on pouvait noter un événement annoncé pour dans un mois,
  // ou annulé. Le moment est celui de l'heure locale de l'événement.
  if (post.eventState === "annule") {
    throw new HttpsError("failed-precondition", "Cet événement a été annulé.");
  }
  const startMillis =
    typeof post.eventDate === "string" ? zonedWallTimeToUtcMillis(post.eventDate, post.timezone ?? "UTC") : NaN;
  const isOver = post.eventState === "termine" || (Number.isFinite(startMillis) && startMillis <= Date.now());
  if (!isOver) {
    throw new HttpsError("failed-precondition", "Tu pourras laisser un avis une fois l'événement passé.");
  }
  if (participationSnap.data()?.status !== "accepted") {
    throw new HttpsError(
      "permission-denied",
      "Seuls les membres dont la participation a été acceptée peuvent laisser un avis.",
    );
  }

  await postRef.collection("reviews").doc(uid).set({
    uid,
    rating,
    comment: comment?.trim() || null,
    createdAt: FieldValue.serverTimestamp(),
  });

  return { ok: true };
});
