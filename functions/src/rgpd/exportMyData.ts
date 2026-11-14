import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore, Timestamp, DocumentData } from "firebase-admin/firestore";

import { REGION } from "../config";
import { ENFORCE_APP_CHECK } from "../shared/appCheck";
import { isProfilePhotoPath } from "../shared/storagePaths";
import { downloadLinkFor } from "../shared/storageLinks";

/**
 * Droit d'accès et à la portabilité des données (RGPD art. 15 et 20, docs/
 * regles-complementaires-concurrents.md section 2) : compile TOUT ce qu'un
 * membre a le droit de récupérer sur lui-même — jamais l'identité ni les
 * données d'un autre membre (les likes reçus, les signalements faits et les
 * blocages ne sont donc donnés qu'en nombre ou sans désigner la personne).
 *
 * Complété le 14/11/2026 (le registre RGPD §5 listait l'export comme
 * partiel) : messages envoyés, photos en fichier (liens de téléchargement),
 * j'aime et réponses de la Communauté, participations, avis, signalements
 * faits, raison de refus des photos, consentement, préférences.
 */


/** Convertit récursivement les dates Firestore en texte ISO lisible. */
function plain(value: unknown): unknown {
  if (value instanceof Timestamp) return value.toDate().toISOString();
  if (Array.isArray(value)) return value.map(plain);
  if (value && typeof value === "object") {
    return Object.fromEntries(Object.entries(value as Record<string, unknown>).map(([k, v]) => [k, plain(v)]));
  }
  return value;
}

function plainDoc(data: DocumentData | undefined): Record<string, unknown> | null {
  return data ? (plain(data) as Record<string, unknown>) : null;
}

export const exportMyData = onCall({ region: REGION, enforceAppCheck: ENFORCE_APP_CHECK }, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Connexion requise.");
  }
  const uid = request.auth.uid;
  const db = getFirestore();

  const [
    profileSnap,
    statusSnap,
    compatSnap,
    photosSnap,
    swipesSnap,
    receivedSwipesSnap,
    myPostsSnap,
    matchesSnap,
    repliesSnap,
    likesSnap,
    participationsSnap,
    reviewsSnap,
    reportsSnap,
    blocksSnap,
    favoritesSnap,
    attemptsSnap,
    devicesSnap,
  ] = await Promise.all([
    db.collection("users").doc(uid).get(),
    db.collection("user_status").doc(uid).get(),
    db.collection("compat_answers").doc(uid).get(),
    db.collection("users").doc(uid).collection("photos").get(),
    db.collection("swipes").where("fromUid", "==", uid).get(),
    db.collection("swipes").where("toUid", "==", uid).get(),
    db.collection("community_posts").where("authorUid", "==", uid).get(),
    db.collection("matches").where("members", "array-contains", uid).get(),
    db.collectionGroup("replies").where("authorUid", "==", uid).get(),
    db.collectionGroup("likes").where("likerUid", "==", uid).get(),
    db.collectionGroup("participations").where("uid", "==", uid).get(),
    db.collectionGroup("reviews").where("uid", "==", uid).get(),
    db.collection("moderation_requests").where("reporterUid", "==", uid).get(),
    db.collection("blocks").where("blockerUid", "==", uid).get(),
    db.collection("users").doc(uid).collection("favorites").get(),
    db.collection("filtrage_attempts").where("uid", "==", uid).get(),
    db.collection("device_signals").where("uids", "array-contains", uid).get(),
  ]);

  // Messages que j'ai ENVOYÉS (jamais ceux de l'autre membre : ce sont ses
  // données), un match après l'autre.
  const messages: Record<string, unknown>[] = [];
  for (const matchDoc of matchesSnap.docs) {
    const mine = await matchDoc.ref.collection("messages").where("fromUid", "==", uid).get();
    for (const m of mine.docs) {
      const d = m.data();
      messages.push({
        matchId: matchDoc.id,
        text: d.text ?? "",
        sentPhoto: typeof d.imageStoragePath === "string",
        createdAt: plain(d.createdAt),
      });
    }
  }

  // Mes photos en fichier : lien temporaire de téléchargement par photo.
  const photos = await Promise.all(
    photosSnap.docs.map(async (d) => {
      const data = d.data();
      // Le chemin vient d'un document écrit par le client : jamais utilisé tel
      // quel (sinon on pouvait obtenir le fichier d'un autre membre).
      const downloadUrl = isProfilePhotoPath(data.storagePath, uid) ? await downloadLinkFor(data.storagePath) : null;
      return {
        id: d.id,
        status: data.status ?? null,
        uploadedAt: plain(data.uploadedAt),
        rejectedBy: data.rejectedBy ?? null,
        rejectionReason: data.rejectionReason ?? null,
        faceDetected: data.faceDetected ?? null,
        downloadUrl,
      };
    }),
  );

  // Données techniques sans intérêt pour le membre (jetons de notification) :
  // remplacées par le simple nombre d'appareils enregistrés.
  const status = statusSnap.data() ? { ...statusSnap.data() } : null;
  let notificationDevices = 0;
  if (status) {
    notificationDevices = Array.isArray(status.fcmTokens) ? status.fcmTokens.length : 0;
    delete status.fcmTokens;
    // Identifiants d'AUTRES personnes (dernier profil passé, administrateurs
    // ayant décidé) : jamais donnés dans l'export du membre.
    for (const key of Object.keys(status)) {
      if (key === "lastPassTargetUid" || key.endsWith("By")) delete status[key];
    }
  }

  return {
    exportedAt: new Date().toISOString(),
    profile: plainDoc(profileSnap.data()),
    status: status ? plain(status) : null,
    notificationDevices,
    compatibilityAnswers: compatSnap.data()?.answers ?? null,
    photos,
    swipesSent: swipesSnap.docs.map((d) => ({
      toUid: d.data().toUid,
      action: d.data().action,
      createdAt: plain(d.data().createdAt),
    })),
    likesReceivedCount: receivedSwipesSnap.docs.filter((d) => d.data().action !== "pass").length,
    messagesSent: messages,
    matches: matchesSnap.docs.map((d) => ({
      id: d.id,
      members: d.data().members,
      createdAt: plain(d.data().createdAt),
    })),
    communityPosts: myPostsSnap.docs.map((d) => ({
      id: d.id,
      type: d.data().type,
      title: d.data().title ?? null,
      text: d.data().text,
      status: d.data().status,
      createdAt: plain(d.data().createdAt),
    })),
    communityReplies: repliesSnap.docs.map((d) => ({
      postId: d.ref.parent.parent?.id ?? null,
      text: d.data().text,
      createdAt: plain(d.data().createdAt),
    })),
    communityLikes: likesSnap.docs.map((d) => ({
      postId: d.ref.parent.parent?.id ?? null,
      createdAt: plain(d.data().createdAt),
    })),
    eventParticipations: participationsSnap.docs.map((d) => ({
      postId: d.ref.parent.parent?.id ?? null,
      ...(plain({ status: d.data().status, createdAt: d.data().createdAt, message: d.data().message ?? null }) as object),
    })),
    eventReviews: reviewsSnap.docs.map((d) => ({
      postId: d.ref.parent.parent?.id ?? null,
      rating: d.data().rating,
      comment: d.data().comment ?? null,
      createdAt: plain(d.data().createdAt),
    })),
    // Les signalements que j'ai faits, sans désigner la personne visée.
    reportsMade: reportsSnap.docs.map((d) => ({
      type: d.data().type,
      reason: d.data().reason,
      details: d.data().details ?? null,
      createdAt: plain(d.data().createdAt),
      resolved: d.data().resolved === true,
    })),
    blockedMembersCount: blocksSnap.size,
    email: request.auth.token.email ?? null,
    favoriteEvents: favoritesSnap.docs.map((d) => ({ postId: d.id, ...(plain(d.data()) as object) })),
    filtrageAttempts: attemptsSnap.docs.map((d) => plainDoc(d.data())),
    deviceIds: devicesSnap.docs.map((d) => d.id),
  };
});
