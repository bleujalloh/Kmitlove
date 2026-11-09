import { HttpsError } from "firebase-functions/v2/https";
import type { CallableRequest } from "firebase-functions/v2/https";

/**
 * Vérifie le rôle admin (custom claim Firebase Auth `admin: true`,
 * cahier des charges section 6 — "rôles et permissions distincts").
 * Ce claim n'est posé par aucune fonction de ce projet : il doit être
 * ajouté manuellement via l'Admin SDK/la console pour le premier compte
 * admin (docs/suivi-developpement.md).
 */
export function requireAdmin(request: CallableRequest): string {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Connexion requise.");
  }
  if (request.auth.token.admin !== true) {
    throw new HttpsError("permission-denied", "Réservé aux administrateurs.");
  }
  return request.auth.uid;
}
