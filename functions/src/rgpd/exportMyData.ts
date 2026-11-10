import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore } from "firebase-admin/firestore";

import { REGION } from "../config";

/**
 * Droit à la portabilité des données (RGPD, docs/regles-complementaires-concurrents.md
 * section 2) : compile tout ce qu'un membre a le droit de récupérer sur
 * lui-même — jamais les données d'un autre membre.
 */
export const exportMyData = onCall({ region: REGION }, async (request) => {
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
    sentSwipesSnap,
    myPostsSnap,
    matchesSnap,
  ] = await Promise.all([
    db.collection("users").doc(uid).get(),
    db.collection("user_status").doc(uid).get(),
    db.collection("compat_answers").doc(uid).get(),
    db.collection("users").doc(uid).collection("photos").get(),
    db.collection("swipes").where("fromUid", "==", uid).get(),
    db.collection("community_posts").where("authorUid", "==", uid).get(),
    db.collection("matches").where("members", "array-contains", uid).get(),
  ]);

  // Les droits/statuts internes (filtrageStatus, isPremium, isVerified...)
  // sont inclus, mais jamais les champs de contrôle purement techniques
  // qui n'apportent rien au membre (ex. jetons de paiement déjà traités).
  return {
    exportedAt: new Date().toISOString(),
    profile: profileSnap.data() ?? null,
    status: statusSnap.data() ?? null,
    compatibilityAnswers: compatSnap.data()?.answers ?? null,
    photos: photosSnap.docs.map((d) => ({ id: d.id, status: d.data().status })),
    likesSent: sentSwipesSnap.docs.map((d) => ({
      toUid: d.data().toUid,
      action: d.data().action,
    })),
    communityPosts: myPostsSnap.docs.map((d) => ({
      id: d.id,
      type: d.data().type,
      text: d.data().text,
      status: d.data().status,
    })),
    matches: matchesSnap.docs.map((d) => ({
      id: d.id,
      members: d.data().members,
      createdAt: d.data().createdAt?.toDate?.()?.toISOString() ?? null,
    })),
  };
});
