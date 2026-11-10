import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore, FieldValue } from "firebase-admin/firestore";

import { REGION } from "../config";

/**
 * Enregistre la position approximative du membre pour calculer une
 * distance dans Découvrir — stockée dans `user_status` (lisible par son
 * seul propriétaire), jamais dans le profil public `users/{uid}`, et
 * jamais renvoyée telle quelle à un autre membre (cahier des charges
 * section 4.4, docs/regles-du-projet.md section 2 : position précise
 * jamais exposée publiquement).
 */
export const updateMyLocation = onCall({ region: REGION }, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Connexion requise.");
  }
  const { lat, lng } = request.data as { lat: number; lng: number };
  if (
    typeof lat !== "number" ||
    typeof lng !== "number" ||
    !Number.isFinite(lat) ||
    !Number.isFinite(lng) ||
    lat < -90 ||
    lat > 90 ||
    lng < -180 ||
    lng > 180
  ) {
    throw new HttpsError("invalid-argument", "Coordonnées invalides.");
  }

  await getFirestore().collection("user_status").doc(request.auth.uid).set(
    { locationLat: lat, locationLng: lng, locationUpdatedAt: FieldValue.serverTimestamp() },
    { merge: true },
  );
  return { ok: true };
});
