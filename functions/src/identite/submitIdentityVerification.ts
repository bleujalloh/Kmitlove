import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore, FieldValue } from "firebase-admin/firestore";

import { REGION } from "../config";

/**
 * Déclare une pièce de vérification d'identité (selfie) déjà déposée
 * dans Storage sous identity_verifications/{uid}/. Ouverte à tout
 * membre qui le souhaite, pas réservée aux organisateurs d'événements
 * (docs/regles-complementaires-concurrents.md section 1).
 */
export const submitIdentityVerification = onCall({ region: REGION }, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Connexion requise.");
  }
  const uid = request.auth.uid;
  const { storagePath } = request.data as { storagePath: string };
  if (!storagePath || !storagePath.startsWith(`identity_verifications/${uid}/`)) {
    throw new HttpsError("invalid-argument", "Chemin de fichier invalide.");
  }

  const db = getFirestore();
  const statusSnap = await db.collection("user_status").doc(uid).get();
  if (statusSnap.data()?.identityVerificationStatus === "pending") {
    throw new HttpsError("failed-precondition", "Une demande est déjà en cours.");
  }

  await db.collection("user_status").doc(uid).set(
    {
      identityVerificationStatus: "pending",
      identityVerificationStoragePath: storagePath,
      identityVerificationSubmittedAt: FieldValue.serverTimestamp(),
    },
    { merge: true },
  );

  return { ok: true };
});
