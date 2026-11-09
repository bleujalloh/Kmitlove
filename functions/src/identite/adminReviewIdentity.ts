import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import { getStorage } from "firebase-admin/storage";

import { REGION } from "../config";
import { requireAdmin } from "../shared/requireAdmin";

/**
 * Liste les demandes de vérification d'identité en attente, avec une
 * URL signée temporaire (10 minutes) vers le selfie — jamais une URL
 * publique, Storage refuse la lecture à qui n'est pas le propriétaire
 * (storage.rules), donc seul l'Admin SDK peut générer ce lien ici.
 */
export const adminListIdentityVerifications = onCall({ region: REGION }, async (request) => {
  requireAdmin(request);
  const db = getFirestore();
  const snap = await db
    .collection("user_status")
    .where("identityVerificationStatus", "==", "pending")
    .limit(50)
    .get();

  const bucket = getStorage().bucket();
  const results = await Promise.all(
    snap.docs.map(async (doc) => {
      const path = doc.data().identityVerificationStoragePath as string | undefined;
      let url: string | null = null;
      if (path) {
        const [signedUrl] = await bucket.file(path).getSignedUrl({
          action: "read",
          expires: Date.now() + 10 * 60 * 1000,
        });
        url = signedUrl;
      }
      return { uid: doc.id, url };
    }),
  );

  return { verifications: results };
});

interface ReviewData {
  uid: string;
  approve: boolean;
}

export const adminReviewIdentityVerification = onCall({ region: REGION }, async (request) => {
  const adminUid = requireAdmin(request);
  const { uid, approve } = request.data as ReviewData;
  if (!uid) {
    throw new HttpsError("invalid-argument", "uid manquant.");
  }

  const db = getFirestore();
  await db.collection("user_status").doc(uid).set(
    {
      identityVerificationStatus: approve ? "verified" : "rejected",
      isVerified: approve,
      identityVerificationReviewedAt: FieldValue.serverTimestamp(),
      identityVerificationReviewedBy: adminUid,
    },
    { merge: true },
  );

  return { ok: true };
});
