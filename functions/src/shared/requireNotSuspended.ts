import { HttpsError } from "firebase-functions/v2/https";

/**
 * Un compte suspendu ne doit jamais pouvoir lever sa propre sanction via
 * le questionnaire de filtrage — seul resolveSanctionAppeal le peut
 * (docs/regles-messagerie-securite.md section 3). Centralisé ici pour que
 * filtrage/startAttempt.ts et filtrage/submitAttempt.ts restent en phase :
 * un oubli dans l'un des deux rouvrirait le contournement.
 */
export function requireNotSuspended(status: Record<string, unknown> | undefined): void {
  if (status?.filtrageStatus === "suspended") {
    throw new HttpsError(
      "failed-precondition",
      "Compte suspendu — fais un recours depuis l'app plutôt que de retenter le questionnaire.",
    );
  }
}
