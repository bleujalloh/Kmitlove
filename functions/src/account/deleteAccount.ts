import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore } from "firebase-admin/firestore";
import { getAuth } from "firebase-admin/auth";

import { REGION } from "../config";

/**
 * Supprime les données applicatives PUIS le compte d'authentification
 * (docs/regles-du-projet.md section 2 — droit à l'oubli RGPD).
 *
 * Les données sont purgées en premier parce que la priorité légale est
 * que les données personnelles disparaissent, même si la suppression du
 * compte Auth échouait ensuite — ce second cas est rattrapable
 * manuellement sans aucun risque de confidentialité puisque les données
 * sont déjà parties. Chaque étape est idempotente (supprimer un document
 * ou un compte déjà supprimé ne fait rien) : si le client réessaie après
 * une erreur, l'appel peut être refait sans effet de bord.
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

  const attemptsSnap = await db.collection("filtrage_attempts").where("uid", "==", uid).get();
  for (const doc of attemptsSnap.docs) {
    batch.delete(doc.ref);
  }

  await batch.commit();
  await getAuth().deleteUser(uid);

  return { ok: true };
});
