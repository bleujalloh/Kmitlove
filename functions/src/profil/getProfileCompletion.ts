import { HttpsError } from "firebase-functions/v2/https";
import { onCall } from "../shared/callable";
import { getFirestore } from "firebase-admin/firestore";

import { REGION } from "../config";
import { ENFORCE_APP_CHECK } from "../shared/appCheck";
import { computeProfileCompletionPercent } from "../shared/profileCompletion";

/**
 * Pourcentage de complétion du profil (onglet Profil) — calculé ici, pas
 * en Dart : la liste des champs qui comptent et le nombre minimal de
 * photos sont une règle produit, pas un simple détail d'affichage, donc
 * jamais seulement côté client (même logique que getDiscoverCandidates.ts,
 * via shared/profileCompletion.ts, pour que les deux ne divergent jamais).
 */
export const getProfileCompletion = onCall({ region: REGION, enforceAppCheck: ENFORCE_APP_CHECK }, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Connexion requise.");
  }
  const uid = request.auth.uid;
  const db = getFirestore();

  const [profilSnap, statusSnap, photosCountSnap, compatSnap] = await Promise.all([
    db.collection("users").doc(uid).get(),
    db.collection("user_status").doc(uid).get(),
    db
      .collection("users")
      .doc(uid)
      .collection("photos")
      .where("status", "==", "approved")
      .count()
      .get(),
    db.collection("compat_answers").doc(uid).get(),
  ]);

  const profil = profilSnap.data() ?? {};
  const isVerified = statusSnap.data()?.isVerified === true;
  const approvedPhotoCount = photosCountSnap.data().count;

  const compatAnswerCount = Object.keys((compatSnap.data()?.answers as Record<string, unknown> | undefined) ?? {}).length;
  const percent = computeProfileCompletionPercent(profil, approvedPhotoCount, isVerified, compatAnswerCount);
  return { percent };
});
