import { HttpsError } from "firebase-functions/v2/https";
import { onCall } from "../shared/callable";
import { getFirestore, FieldValue } from "firebase-admin/firestore";

import { REGION, REPLY_RATE_LIMITS } from "../config";
import { ENFORCE_APP_CHECK } from "../shared/appCheck";
import { sendPushToUser } from "../shared/push";
import { enforceRateLimit } from "../shared/rateLimit";

/**
 * J'aime et réponses sur les publications du fil (prototype
 * Communaute.dc.html : « 24 ♥ » et « 9 réponses » ; cahier des charges
 * section 4.7 : « Commentaires et réactions »). Réservés aux publications
 * du fil (`type == "publication"`) déjà publiées. Tout passe par ces
 * fonctions, jamais par une écriture directe : compte suspendu, blocage
 * entre les deux membres, longueur et fréquence sont vérifiés côté serveur.
 */

const MAX_REPLY_LENGTH = 500;

/**
 * Seuls les membres dont le compte est activé (questionnaire de filtrage
 * réussi) peuvent liker ou répondre : un compte en attente, refusé ou
 * suspendu ne le peut pas (la suspension fait passer `filtrageStatus` à
 * "suspended", shared/sanctions.ts).
 */
function requireActiveMember(status: Record<string, unknown> | undefined): void {
  if (status?.filtrageStatus !== "active") {
    throw new HttpsError("permission-denied", "Ton compte n'est pas actif.");
  }
}

function pairId(a: string, b: string): string {
  return [a, b].sort().join("_");
}

async function loadReplyablePost(postId: unknown) {
  if (typeof postId !== "string" || !postId) {
    throw new HttpsError("invalid-argument", "Publication manquante.");
  }
  const postRef = getFirestore().collection("community_posts").doc(postId);
  const postSnap = await postRef.get();
  const post = postSnap.data();
  if (!post || post.status !== "published" || post.type !== "publication") {
    throw new HttpsError("not-found", "Publication introuvable.");
  }
  return { postRef, post };
}

async function assertNotBlocked(uid: string, authorUid: string): Promise<void> {
  if (uid === authorUid) return;
  const block = await getFirestore().collection("blocks").doc(pairId(uid, authorUid)).get();
  if (block.exists) {
    throw new HttpsError("permission-denied", "Action impossible avec ce membre.");
  }
}

/** Bascule le j'aime du membre sur une publication ; renvoie le nouvel état. */
export const togglePostLike = onCall({ region: REGION, enforceAppCheck: ENFORCE_APP_CHECK }, async (request) => {
  if (!request.auth) throw new HttpsError("unauthenticated", "Connexion requise.");
  const uid = request.auth.uid;
  const db = getFirestore();

  requireActiveMember((await db.collection("user_status").doc(uid).get()).data());
  const { postRef, post } = await loadReplyablePost(request.data?.postId);
  await assertNotBlocked(uid, post.authorUid as string);

  const likeRef = postRef.collection("likes").doc(uid);
  const liked = await db.runTransaction(async (tx) => {
    const snap = await tx.get(likeRef);
    if (snap.exists) {
      tx.delete(likeRef);
      return false;
    }
    // `likerUid` : permet à deleteAccount de retrouver tous les j'aime du membre
    // (droit à l'effacement) sans parcourir toutes les publications.
    tx.set(likeRef, { likerUid: uid, createdAt: FieldValue.serverTimestamp() });
    return true;
  });
  return { liked };
});

/** Ajoute une réponse à une publication et prévient son auteur (push). */
export const replyToPost = onCall({ region: REGION, enforceAppCheck: ENFORCE_APP_CHECK }, async (request) => {
  if (!request.auth) throw new HttpsError("unauthenticated", "Connexion requise.");
  const uid = request.auth.uid;
  const db = getFirestore();

  const text = typeof request.data?.text === "string" ? request.data.text.trim() : "";
  if (text.length === 0 || text.length > MAX_REPLY_LENGTH) {
    throw new HttpsError("invalid-argument", `Une réponse fait entre 1 et ${MAX_REPLY_LENGTH} caractères.`);
  }

  const statusRef = db.collection("user_status").doc(uid);
  requireActiveMember((await statusRef.get()).data());
  const { postRef, post } = await loadReplyablePost(request.data?.postId);
  await assertNotBlocked(uid, post.authorUid as string);

  // Fréquence : REPLY_RATE_LIMITS (mécanisme commun, shared/rateLimit.ts).
  await enforceRateLimit(uid, REPLY_RATE_LIMITS);

  const profile = (await db.collection("users").doc(uid).get()).data();
  const authorName = (profile?.displayName as string | undefined) ?? "Membre";
  const replyRef = await postRef.collection("replies").add({
    authorUid: uid,
    authorName,
    text,
    createdAt: FieldValue.serverTimestamp(),
  });

  if (post.authorUid !== uid) {
    await sendPushToUser(
      post.authorUid as string,
      { title: authorName, body: text.length > 80 ? `${text.slice(0, 77)}...` : text },
      { type: "community_reply", postId: postRef.id },
    );
  }
  return { replyId: replyRef.id };
});
