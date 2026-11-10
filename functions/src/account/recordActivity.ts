import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore, FieldValue } from "firebase-admin/firestore";

import { REGION } from "../config";

/**
 * Marque le membre comme actif (docs/regles-complementaires-concurrents.md
 * section 3 — masquage des comptes inactifs depuis 30 jours). Appelée
 * une fois par session côté client, pas à chaque interaction.
 */
export const recordActivity = onCall({ region: REGION }, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Connexion requise.");
  }
  await getFirestore()
    .collection("user_status")
    .doc(request.auth.uid)
    .set({ lastActiveAt: FieldValue.serverTimestamp() }, { merge: true });
  return { ok: true };
});
