import { getFirestore, FieldValue } from "firebase-admin/firestore";
import { getAuth } from "firebase-admin/auth";
import { getStorage } from "firebase-admin/storage";

import { deleteRefsInChunks } from "./batchWrite";
import { cancelParticipationAndPromote } from "./participation";

/**
 * Supprime réellement TOUTES les données d'un membre, pas seulement son
 * profil — droit à l'oubli RGPD (docs/regles-du-projet.md section 2).
 * Source unique de la suppression : utilisée par la demande du membre
 * (account/deleteAccount.ts) ET par la purge automatique des comptes
 * inactifs (scheduled/purgeInactiveAccounts.ts) — jamais deux listes
 * d'étapes à tenir à jour en parallèle.
 *
 * Rejouable : aucune erreur n'est avalée (une panne passagère de Storage ne
 * doit jamais mener à supprimer le compte d'authentification tout en
 * laissant des fichiers que plus rien ne permettra de retrouver) ; si
 * l'appel est relancé, chaque étape est sans effet sur ce qui est déjà
 * supprimé, y compris le compte d'authentification déjà absent.
 *
 * Conservés volontairement (docs/rgpd-registre-des-traitements.md §6) :
 * signalements (`moderation_requests`) et journal des actions
 * d'administration.
 */
export async function eraseAccount(uid: string): Promise<void> {
  const db = getFirestore();
  const bucket = getStorage().bucket();

  // 1. Fichiers Storage (photos de profil + vérification d'identité).
  // `deleteFiles` sur un dossier vide ne lève pas d'erreur : toute erreur
  // est donc réelle et doit remonter.
  await Promise.all([
    bucket.deleteFiles({ prefix: `profile_photos/${uid}/` }),
    bucket.deleteFiles({ prefix: `identity_verifications/${uid}/` }),
    // Affiches d'événements déposées par ce membre (storage.rules :
    // event_posters/{uid}/...).
    bucket.deleteFiles({ prefix: `event_posters/${uid}/` }),
  ]);

  // 2. Sous-collections du profil : photos et événements en favori.
  const [photosSnap, favoritesSnap] = await Promise.all([
    db.collection("users").doc(uid).collection("photos").get(),
    db.collection("users").doc(uid).collection("favorites").get(),
  ]);
  await deleteRefsInChunks(db, [...photosSnap.docs, ...favoritesSnap.docs].map((d) => d.ref));

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
    // Photos envoyées dans la conversation (storage.rules : chat_photos/
    // {matchId}/...) : sans cette ligne, les fichiers restaient dans
    // Storage après la suppression des messages qui les référençaient.
    await bucket.deleteFiles({ prefix: `chat_photos/${matchDoc.id}/` });
    await matchDoc.ref.delete();
  }

  // 5. Blocages posés par ce membre ET ceux dont il est la cible (sinon la
  // liste « Mes blocages » de l'autre membre garde un « Membre » fantôme).
  const [blocksMadeSnap, blocksReceivedSnap] = await Promise.all([
    db.collection("blocks").where("blockerUid", "==", uid).get(),
    db.collection("blocks").where("blockedUid", "==", uid).get(),
  ]);
  await deleteRefsInChunks(db, [...blocksMadeSnap.docs, ...blocksReceivedSnap.docs].map((d) => d.ref));

  // 6. Publications du membre, avec TOUT ce qu'elles contiennent (demandes
  // de participation, lieu privé, invitations, mais aussi j'aime, réponses
  // et avis des autres membres : `recursiveDelete` descend dans toutes les
  // sous-collections), et les codes d'invitation partageables qui y mènent.
  const myPostsSnap = await db.collection("community_posts").where("authorUid", "==", uid).get();
  for (const postDoc of myPostsSnap.docs) {
    const codesSnap = await db.collection("event_invite_codes").where("postId", "==", postDoc.id).get();
    await deleteRefsInChunks(db, codesSnap.docs.map((d) => d.ref));
    await db.recursiveDelete(postDoc.ref);
  }

  // 6 bis. Participations que ce membre a faites sur les événements des
  // autres : une place CONFIRMÉE est libérée proprement (compteur remis à
  // jour, liste d'attente promue — shared/participation.ts), sinon
  // l'événement resterait « complet » pour toujours.
  const myParticipationsSnap = await db.collectionGroup("participations").where("uid", "==", uid).get();
  for (const doc of myParticipationsSnap.docs) {
    const postRef = doc.ref.parent.parent;
    if (postRef && doc.data().status === "accepted" && (await postRef.get()).exists) {
      await cancelParticipationAndPromote(db, postRef.id, uid);
    }
    await doc.ref.delete();
  }

  // 6 ter. Réponses, j'aime et avis laissés sur les publications des autres
  // (togglePostLike/replyToPost/submitEventReview) — index COLLECTION_GROUP
  // dans firestore.indexes.json.
  const [myRepliesSnap, myLikesSnap, myReviewsSnap, invitationsSnap] = await Promise.all([
    db.collectionGroup("replies").where("authorUid", "==", uid).get(),
    db.collectionGroup("likes").where("likerUid", "==", uid).get(),
    db.collectionGroup("reviews").where("uid", "==", uid).get(),
    // Listes d'invités des événements sur invitation où ce membre figure.
    db.collectionGroup("private").where("invitedUids", "array-contains", uid).get(),
  ]);
  await deleteRefsInChunks(
    db,
    [...myRepliesSnap.docs, ...myLikesSnap.docs, ...myReviewsSnap.docs].map((d) => d.ref),
  );
  for (const doc of invitationsSnap.docs) {
    await doc.ref.update({ invitedUids: FieldValue.arrayRemove(uid) });
  }

  // 6 quater. Signal anti-abus « comptes par appareil » (registerDeviceSignal) :
  // l'identifiant d'appareil ne doit plus être relié à un compte supprimé.
  const deviceSnap = await db.collection("device_signals").where("uids", "array-contains", uid).get();
  for (const deviceDoc of deviceSnap.docs) {
    const remaining = ((deviceDoc.data().uids as string[] | undefined) ?? []).filter((u) => u !== uid);
    if (remaining.length === 0) {
      await deviceDoc.ref.delete();
    } else {
      await deviceDoc.ref.update({ uids: remaining });
    }
  }

  // 6 quinquies. Compteurs de fréquence (shared/rateLimit.ts) et jetons
  // d'achat consommés (paiements en pause : normalement vide).
  const [rateLimitsSnap, purchaseTokensSnap] = await Promise.all([
    db.collection("rate_limits").where("uid", "==", uid).get(),
    db.collection("used_purchase_tokens").where("uid", "==", uid).get(),
  ]);
  await deleteRefsInChunks(db, [...rateLimitsSnap.docs, ...purchaseTokensSnap.docs].map((d) => d.ref));

  // 7. Réponses au test de compatibilité et tentatives de filtrage.
  const filtrageAttemptsSnap = await db.collection("filtrage_attempts").where("uid", "==", uid).get();
  await deleteRefsInChunks(db, filtrageAttemptsSnap.docs.map((d) => d.ref));

  const batch = db.batch();
  batch.delete(db.collection("user_status").doc(uid));
  batch.delete(db.collection("users").doc(uid));
  batch.delete(db.collection("compat_answers").doc(uid));
  await batch.commit();

  // 8. Compte d'authentification en tout dernier. Déjà absent (appel relancé,
  // ou donnée orpheline) : rien à faire, ce n'est pas une erreur.
  try {
    await getAuth().deleteUser(uid);
  } catch (err) {
    if ((err as { code?: string }).code !== "auth/user-not-found") throw err;
  }
}
