import { HttpsError } from "firebase-functions/v2/https";

import { SENSITIVE_CONSENT_VERSION } from "../config";

/**
 * Consentement RGPD art. 9 valide : donné, et pour la VERSION ACTUELLE du
 * texte (account/sensitiveConsent.ts). Tout ce qui traite ou montre les
 * données sensibles d'un membre — découverte, likes, swipes, messages,
 * enregistrement du profil — repose sur ce seul contrôle côté serveur : le
 * garde-fou de l'écran (auth_gate.dart) ne suffit pas, un client modifié le
 * contourne.
 */
export function hasValidConsent(status: Record<string, unknown> | undefined): boolean {
  const consent = status?.sensitiveConsent as { granted?: boolean; version?: number } | undefined;
  return consent?.granted === true && consent.version === SENSITIVE_CONSENT_VERSION;
}

export function requireConsent(status: Record<string, unknown> | undefined): void {
  if (!hasValidConsent(status)) {
    throw new HttpsError("failed-precondition", "consent-required : consentement requis.");
  }
}
