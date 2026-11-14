import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore, FieldValue } from "firebase-admin/firestore";

import { REGION } from "../config";
import { ENFORCE_APP_CHECK } from "../shared/appCheck";

/**
 * Transforme un code de partage privé (getEventShareCode.ts) en
 * invitation : ajoute l'uid de l'appelant à la liste d'invités de
 * l'événement visé, sans que l'organisateur ait eu besoin de connaître
 * cet uid à l'avance et sans rendre l'événement davantage public (spec
 * Communauté section 2). Le code lui-même n'est jamais lu directement
 * par le client (firestore.rules) — uniquement via cette fonction.
 */
export const redeemEventInviteCode = onCall({ region: REGION, enforceAppCheck: ENFORCE_APP_CHECK }, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Connexion requise.");
  }
  const uid = request.auth.uid;
  const { code } = request.data as { code: string };
  if (!code?.trim()) {
    throw new HttpsError("invalid-argument", "Code manquant.");
  }

  const db = getFirestore();
  const codeRef = db.collection("event_invite_codes").doc(code.trim().toUpperCase());
  const codeSnap = await codeRef.get();
  const postId = codeSnap.data()?.postId as string | undefined;
  if (!postId) {
    throw new HttpsError("not-found", "Code d'invitation invalide.");
  }

  const postRef = db.collection("community_posts").doc(postId);
  const postSnap = await postRef.get();
  const post = postSnap.data();
  if (!post || post.status !== "published") {
    throw new HttpsError("not-found", "Événement introuvable.");
  }
  if (post.eventState === "annule" || post.eventState === "termine") {
    throw new HttpsError("failed-precondition", "Cet événement n'accepte plus de demandes.");
  }
  if (post.authorUid === uid) {
    throw new HttpsError("invalid-argument", "Tu es l'organisateur de cet événement.");
  }

  await postRef.collection("private").doc("invitations").set(
    { invitedUids: FieldValue.arrayUnion(uid) },
    { merge: true },
  );

  return { ok: true, postId };
});
