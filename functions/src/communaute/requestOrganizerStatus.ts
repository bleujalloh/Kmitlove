import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore, FieldValue } from "firebase-admin/firestore";

import { REGION, ORGANIZER_MAX_NAME_LENGTH, ORGANIZER_MAX_DESCRIPTION_LENGTH } from "../config";
import { ENFORCE_APP_CHECK } from "../shared/appCheck";

interface RequestData {
  organizerName: string;
  organizerDescription: string;
}

/**
 * Demande du statut organisateur (spec Communauté du 11/11/2026, section
 * 3) — simplifiée sur demande explicite du propriétaire : pas
 * d'abonnement, un contrôle humain (validation admin) reste obligatoire
 * avant toute première publication d'événement, quel que soit le profil
 * du membre. Même principe que l'identité (user_status.identityVerificationStatus) :
 * un seul champ de statut, pas de collection séparée.
 */
export const requestOrganizerStatus = onCall({ region: REGION, enforceAppCheck: ENFORCE_APP_CHECK }, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Connexion requise.");
  }
  const uid = request.auth.uid;
  const { organizerName, organizerDescription } = request.data as RequestData;

  if (
    typeof organizerName !== "string" ||
    organizerName.trim().length === 0 ||
    organizerName.length > ORGANIZER_MAX_NAME_LENGTH
  ) {
    throw new HttpsError("invalid-argument", "Nom d'organisateur invalide.");
  }
  if (
    typeof organizerDescription !== "string" ||
    organizerDescription.trim().length === 0 ||
    organizerDescription.length > ORGANIZER_MAX_DESCRIPTION_LENGTH
  ) {
    throw new HttpsError("invalid-argument", "Description invalide.");
  }

  const db = getFirestore();
  const statusRef = db.collection("user_status").doc(uid);
  const statusSnap = await statusRef.get();
  const current = statusSnap.data()?.organizerStatus;
  if (current === "pending" || current === "approved") {
    throw new HttpsError(
      "failed-precondition",
      current === "pending" ? "Une demande est déjà en cours." : "Déjà organisateur.",
    );
  }

  await statusRef.set(
    {
      organizerStatus: "pending",
      organizerName: organizerName.trim(),
      organizerDescription: organizerDescription.trim(),
      organizerRequestedAt: FieldValue.serverTimestamp(),
    },
    { merge: true },
  );

  return { ok: true };
});
