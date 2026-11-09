import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore } from "firebase-admin/firestore";

import { REGION } from "../config";

/**
 * Supprime/anonymise les données applicatives avant que le client ne
 * supprime le compte d'authentification (docs/regles-du-projet.md
 * section 2 — droit à l'oubli RGPD). À étendre au fur et à mesure que
 * de nouvelles collections apparaissent (profil, photos, messages...).
 */
export const deleteAccount = onCall({ region: REGION }, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Connexion requise.");
  }
  const uid = request.auth.uid;
  const db = getFirestore();

  const batch = db.batch();
  batch.delete(db.collection("user_status").doc(uid));
  batch.delete(db.collection("users").doc(uid));
  await batch.commit();

  return { ok: true };
});
