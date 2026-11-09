import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore } from "firebase-admin/firestore";
import { getAuth } from "firebase-admin/auth";

import { REGION } from "../config";

/**
 * Supprime les données applicatives ET le compte d'authentification, en
 * une seule opération atomique côté serveur (docs/regles-du-projet.md
 * section 2 — droit à l'oubli RGPD). Le compte Auth est supprimé ici,
 * avec les droits admin, pour ne jamais dépendre d'une "connexion
 * récente" côté client (qui peut échouer et laisser un compte orphelin
 * après que les données ont déjà été effacées). À étendre au fur et à
 * mesure que de nouvelles collections apparaissent (profil, photos,
 * messages...).
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

  await getAuth().deleteUser(uid);

  return { ok: true };
});
