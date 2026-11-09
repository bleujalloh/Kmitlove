import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore } from "firebase-admin/firestore";

import { REGION } from "../config";

/**
 * Révèle le lieu précis d'un événement/d'une annonce privée uniquement
 * à l'organisateur ou à un participant accepté (cahier des charges
 * section 4.7, docs/regles-annonces-evenements.md section 2).
 */
export const getEventLocation = onCall({ region: REGION }, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Connexion requise.");
  }
  const uid = request.auth.uid;
  const { postId } = request.data as { postId: string };
  if (!postId) {
    throw new HttpsError("invalid-argument", "postId manquant.");
  }

  const db = getFirestore();
  const postRef = db.collection("community_posts").doc(postId);
  const [postSnap, participationSnap] = await Promise.all([
    postRef.get(),
    postRef.collection("participations").doc(uid).get(),
  ]);
  const post = postSnap.data();
  if (!post) {
    throw new HttpsError("not-found", "Publication introuvable.");
  }

  const isOrganizer = post.authorUid === uid;
  const isAccepted = participationSnap.data()?.status === "accepted";
  if (!isOrganizer && !isAccepted) {
    throw new HttpsError(
      "permission-denied",
      "Le lieu précis n'est visible qu'après acceptation de ta demande.",
    );
  }

  const locationSnap = await postRef.collection("private").doc("location").get();
  return { preciseLocation: locationSnap.data()?.preciseLocation ?? null };
});
