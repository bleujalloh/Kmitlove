import { HttpsError } from "firebase-functions/v2/https";
import { onCallNoConsent as onCall } from "../shared/callable";
import { getFirestore, FieldValue } from "firebase-admin/firestore";

import { REGION } from "../config";
import { ENFORCE_APP_CHECK } from "../shared/appCheck";

/**
 * Marque le membre comme actif (docs/regles-complementaires-concurrents.md
 * section 3 — masquage des comptes inactifs depuis 30 jours). Appelée
 * une fois par session côté client, pas à chaque interaction.
 */
export const recordActivity = onCall({ region: REGION, enforceAppCheck: ENFORCE_APP_CHECK }, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Connexion requise.");
  }
  // `update` et non `set` : un compte déjà supprimé dont le jeton de
  // connexion serait encore valide (jusqu'à 1 h) ne doit jamais recréer un
  // document de statut fantôme.
  try {
    await getFirestore()
      .collection("user_status")
      .doc(request.auth.uid)
      .update({
        lastActiveAt: FieldValue.serverTimestamp(),
        // Le membre est revenu : l'avertissement d'inactivité éventuel tombe
        // (scheduled/purgeInactiveAccounts.ts), un futur avertissement sera
        // redonné avant toute suppression.
        inactivityWarnedAt: FieldValue.delete(),
        inactivityWarnUndeliveredAt: FieldValue.delete(),
        inactivityWarnMailId: FieldValue.delete(),
      });
  } catch (err) {
    if ((err as { code?: number }).code === 5) {
      throw new HttpsError("not-found", "Compte introuvable.");
    }
    throw err;
  }
  return { ok: true };
});
