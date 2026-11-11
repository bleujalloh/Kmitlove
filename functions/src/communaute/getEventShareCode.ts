import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore } from "firebase-admin/firestore";

import { REGION } from "../config";

/**
 * Récupère le code de partage privé d'un événement "sur invitation"
 * (spec Communauté section 2 — partage privé d'une invitation sans
 * rendre l'événement public). Réservé à l'organisateur, jamais exposé
 * sur le document public (règlement permanent section 6).
 */
export const getEventShareCode = onCall({ region: REGION }, async (request) => {
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
  const postSnap = await postRef.get();
  const post = postSnap.data();
  if (!post || post.authorUid !== uid) {
    throw new HttpsError("permission-denied", "Seul l'organisateur peut voir ce code.");
  }
  if (post.accessMode !== "sur_invitation") {
    throw new HttpsError("failed-precondition", "Cet événement n'est pas sur invitation.");
  }

  const invitationsSnap = await postRef.collection("private").doc("invitations").get();
  const shareCode = invitationsSnap.data()?.shareCode;
  if (!shareCode) {
    throw new HttpsError("not-found", "Aucun code de partage pour cet événement.");
  }
  return { shareCode };
});
