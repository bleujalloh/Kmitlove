import { HttpsError } from "firebase-functions/v2/https";
import { onCallNoConsent as onCall } from "../shared/callable";

import { REGION } from "../config";
import { ENFORCE_APP_CHECK } from "../shared/appCheck";
import { eraseAccount } from "../shared/eraseAccount";

/**
 * Suppression du compte demandée par le membre (droit à l'oubli) : toutes
 * ses données, puis son compte d'authentification — voir
 * shared/eraseAccount.ts pour la liste complète des étapes.
 */
export const deleteAccount = onCall({ region: REGION, enforceAppCheck: ENFORCE_APP_CHECK, timeoutSeconds: 300 }, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Connexion requise.");
  }
  await eraseAccount(request.auth.uid);
  return { ok: true };
});
