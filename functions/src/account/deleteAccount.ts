import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore } from "firebase-admin/firestore";
import { getAuth } from "firebase-admin/auth";
import { getStorage } from "firebase-admin/storage";

import { REGION } from "../config";
import { deleteRefsInChunks } from "../shared/batchWrite";

/**
 * Supprime réellement TOUTES les données d'un membre, pas seulement son
 * profil — droit à l'oubli RGPD (docs/regles-du-projet.md section 2).
 * Avant cette version, seuls `users`/`user_status`/`filtrage_attempts`
 * étaient nettoyés : photos, messages, matchs, annonces, swipes et
 * réponses de compatibilité restaient en base indéfiniment, ce qui ne
 * respectait pas le droit à l'oubli.
 *
 * Toujours données d'abord, compte Auth en dernier (idempotent en cas
 * de retry, voir le commentaire plus bas) — même raisonnement que
 * l'ancienne version de cette fonction.
 */
export const deleteAccount = onCall({ region: REGION }, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Connexion requise.");
  }
  const uid = request.auth.uid;
  const db = getFirestore();
  const bucket = getStorage().bucket();

  // 1. Fichiers Storage (photos de profil + vérification d'identité).
  await Promise.all([
    bucket.deleteFiles({ prefix: `profile_photos/${uid}/` }).catch(() => undefined),
    bucket.deleteFiles({ prefix: `identity_verifications/${uid}/` }).catch(() => undefined),
  ]);

  // 2. Sous-collection photos.
  const photosSnap = await db.collection("users").doc(uid).collection("photos").get();
  await deleteRefsInChunks(db, photosSnap.docs.map((d) => d.ref));

  // 3. Swipes envoyés et reçus.
  const [sentSwipes, receivedSwipes] = await Promise.all([
    db.collection("swipes").where("fromUid", "==", uid).get(),
    db.collection("swipes").where("toUid", "==", uid).get(),
  ]);
  await deleteRefsInChunks(db, [...sentSwipes.docs, ...receivedSwipes.docs].map((d) => d.ref));

  // 4. Matchs où le membre apparaît : messages puis le match lui-même.
  const matchesSnap = await db.collection("matches").where("members", "array-contains", uid).get();
  for (const matchDoc of matchesSnap.docs) {
    const messagesSnap = await matchDoc.ref.collection("messages").get();
    await deleteRefsInChunks(db, messagesSnap.docs.map((d) => d.ref));
    await matchDoc.ref.delete();
  }

  // 5. Blocages posés par ce membre.
  const blocksSnap = await db.collection("blocks").where("blockerUid", "==", uid).get();
  await deleteRefsInChunks(db, blocksSnap.docs.map((d) => d.ref));

  // 6. Publications communauté créées par ce membre (+ leurs demandes de
  // participation et leur lieu précis éventuel) et les demandes de
  // participation que ce membre a faites sur les publications des autres.
  const myPostsSnap = await db.collection("community_posts").where("authorUid", "==", uid).get();
  for (const postDoc of myPostsSnap.docs) {
    const [participationsSnap, privateSnap] = await Promise.all([
      postDoc.ref.collection("participations").get(),
      postDoc.ref.collection("private").get(),
    ]);
    await deleteRefsInChunks(db, [...participationsSnap.docs, ...privateSnap.docs].map((d) => d.ref));
    await postDoc.ref.delete();
  }
  const myParticipationsSnap = await db
    .collectionGroup("participations")
    .where("uid", "==", uid)
    .get();
  await deleteRefsInChunks(db, myParticipationsSnap.docs.map((d) => d.ref));

  // 7. Réponses au test de compatibilité et tentatives de filtrage.
  const filtrageAttemptsSnap = await db.collection("filtrage_attempts").where("uid", "==", uid).get();
  await deleteRefsInChunks(db, filtrageAttemptsSnap.docs.map((d) => d.ref));

  const batch = db.batch();
  batch.delete(db.collection("user_status").doc(uid));
  batch.delete(db.collection("users").doc(uid));
  batch.delete(db.collection("compat_answers").doc(uid));
  await batch.commit();

  // 8. Compte d'authentification en tout dernier (voir le commentaire du
  // haut) : chaque étape ci-dessus est individuellement rejouable sans
  // effet de bord si l'appel est relancé après une erreur.
  await getAuth().deleteUser(uid);

  return { ok: true };
});
