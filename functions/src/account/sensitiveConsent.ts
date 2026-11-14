import { HttpsError } from "firebase-functions/v2/https";
import { onCallNoConsent as onCall } from "../shared/callable";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import { getAuth } from "firebase-admin/auth";

import { REGION, SENSITIVE_CONSENT_VERSION } from "../config";
import { ENFORCE_APP_CHECK } from "../shared/appCheck";

/**
 * Consentement explicite et séparé au traitement des données sensibles
 * (RGPD art. 9, docs/rgpd-registre-des-traitements.md §3) : le genre et les
 * genres recherchés révèlent une orientation sexuelle, l'appartenance à la
 * communauté peut révéler une origine ou des convictions, les photos servent
 * à la modération. Enregistré côté serveur (jamais par le client) dans
 * `user_status.sensitiveConsent`, avec la version du texte et la date.
 *
 * `granted: false` = retrait du consentement (aussi simple à faire qu'à
 * donner, art. 7.3) : le membre disparaît de la découverte des autres
 * (decouvrir/getCandidates.ts) et l'app lui redemande son consentement ou
 * propose de supprimer le compte ; saveProfil refuse toute écriture du profil
 * sans consentement valide.
 */
export const recordSensitiveConsent = onCall({ region: REGION, enforceAppCheck: ENFORCE_APP_CHECK }, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Connexion requise.");
  }
  const { granted, version } = request.data as { granted?: unknown; version?: unknown };
  if (typeof granted !== "boolean") {
    throw new HttpsError("invalid-argument", "Valeur invalide.");
  }
  // Le client envoie la version du texte qu'il a AFFICHÉ : un consentement
  // donné sur un ancien texte (application pas à jour) ne doit jamais être
  // enregistré comme valable pour le texte actuel.
  if (version !== SENSITIVE_CONSENT_VERSION) {
    throw new HttpsError("failed-precondition", "consent-version-outdated : mets l'application à jour.");
  }
  // Le consentement est demandé AVANT le questionnaire de filtrage (le
  // questionnaire révèle l'appartenance à la communauté) : le document de
  // statut peut donc ne pas exister encore pour un compte neuf. On le crée
  // alors — mais seulement si le compte d'authentification existe réellement :
  // un compte déjà supprimé dont le jeton serait encore valide (jusqu'à 1 h)
  // ne doit jamais recréer un document fantôme.
  try {
    await getAuth().getUser(request.auth.uid);
  } catch (err) {
    if ((err as { code?: string }).code === "auth/user-not-found") {
      throw new HttpsError("not-found", "Compte introuvable.");
    }
    throw err;
  }
  await getFirestore()
    .collection("user_status")
    .doc(request.auth.uid)
    .set(
      {
        sensitiveConsent: {
          granted,
          version: SENSITIVE_CONSENT_VERSION,
          at: FieldValue.serverTimestamp(),
        },
      },
      { merge: true },
    );
  return { ok: true };
});
