import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore, FieldValue } from "firebase-admin/firestore";

import { REGION } from "../config";
import { requireAdmin } from "../shared/requireAdmin";

/** Photos en attente de validation (docs/regles-messagerie-securite.md section 1). */
export const adminListPendingPhotos = onCall({ region: REGION }, async (request) => {
  requireAdmin(request);
  const db = getFirestore();
  const snap = await db
    .collectionGroup("photos")
    .where("status", "==", "pending")
    .orderBy("uploadedAt", "asc")
    .limit(50)
    .get();
  return {
    photos: snap.docs.map((d) => ({
      id: d.id,
      userId: d.ref.parent.parent!.id,
      ...d.data(),
    })),
  };
});

interface ReviewData {
  userId: string;
  photoId: string;
  approve: boolean;
}

export const adminReviewPhoto = onCall({ region: REGION }, async (request) => {
  const adminUid = requireAdmin(request);
  const { userId, photoId, approve } = request.data as ReviewData;
  if (!userId || !photoId) {
    throw new HttpsError("invalid-argument", "Paramètres manquants.");
  }

  const db = getFirestore();
  const photoRef = db.collection("users").doc(userId).collection("photos").doc(photoId);
  const snap = await photoRef.get();
  if (!snap.exists || snap.data()?.status !== "pending") {
    throw new HttpsError("not-found", "Photo introuvable ou déjà traitée.");
  }

  await photoRef.update({
    status: approve ? "approved" : "rejected",
    reviewedAt: FieldValue.serverTimestamp(),
    reviewedBy: adminUid,
  });

  return { ok: true };
});
