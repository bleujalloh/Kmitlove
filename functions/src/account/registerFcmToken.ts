import { HttpsError } from "firebase-functions/v2/https";
import { onCallNoConsent as onCall } from "../shared/callable";
import { getFirestore, FieldValue } from "firebase-admin/firestore";

import { REGION } from "../config";
import { ENFORCE_APP_CHECK } from "../shared/appCheck";

const MAX_TOKEN_LENGTH = 4096;

/**
 * Enregistre le jeton FCM de l'appareil courant (notifications push :
 * nouveau match, nouveau message, nouveau like — docs/suivi-
 * developpement.md section du 11/11/2026). Stocké sur `user_status`,
 * jamais ailleurs : ce document n'est déjà lisible que par son
 * propriétaire et jamais modifiable depuis le client (firestore.rules).
 * Un même compte peut avoir plusieurs appareils, donc un tableau plutôt
 * qu'un champ unique.
 */
export const registerFcmToken = onCall({ region: REGION, enforceAppCheck: ENFORCE_APP_CHECK }, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Connexion requise.");
  }
  const { token } = request.data as { token?: string };
  if (typeof token !== "string" || token.length === 0 || token.length > MAX_TOKEN_LENGTH) {
    throw new HttpsError("invalid-argument", "Jeton invalide.");
  }

  await getFirestore()
    .collection("user_status")
    .doc(request.auth.uid)
    .set({ fcmTokens: FieldValue.arrayUnion(token) }, { merge: true });

  return { ok: true };
});

/**
 * Retire le jeton de l'appareil courant — appelé à la déconnexion pour
 * ne plus notifier un appareil où personne n'est plus connecté avec ce
 * compte.
 */
export const unregisterFcmToken = onCall({ region: REGION, enforceAppCheck: ENFORCE_APP_CHECK }, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Connexion requise.");
  }
  const { token } = request.data as { token?: string };
  if (typeof token !== "string" || token.length === 0) {
    throw new HttpsError("invalid-argument", "Jeton invalide.");
  }

  await getFirestore()
    .collection("user_status")
    .doc(request.auth.uid)
    .set({ fcmTokens: FieldValue.arrayRemove(token) }, { merge: true });

  return { ok: true };
});
