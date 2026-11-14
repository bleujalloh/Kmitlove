import { HttpsError } from "firebase-functions/v2/https";
import { onCall } from "../shared/callable";
import { getFirestore, FieldValue } from "firebase-admin/firestore";

import { REGION } from "../config";
import { ENFORCE_APP_CHECK } from "../shared/appCheck";
import { requireAdmin } from "../shared/requireAdmin";
import { logAdminAction } from "../shared/adminLog";
import { analyzePhotoContent } from "../shared/photoModeration";

/** Photos en attente de validation (docs/regles-messagerie-securite.md section 1). */
export const adminListPendingPhotos = onCall({ region: REGION, enforceAppCheck: ENFORCE_APP_CHECK }, async (request) => {
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

export const adminReviewPhoto = onCall({ region: REGION, enforceAppCheck: ENFORCE_APP_CHECK }, async (request) => {
  const adminUid = requireAdmin(request);
  const { userId, photoId, approve } = request.data as ReviewData;
  if (!userId || !photoId) {
    throw new HttpsError("invalid-argument", "Paramètres manquants.");
  }

  const db = getFirestore();
  const photoRef = db.collection("users").doc(userId).collection("photos").doc(photoId);
  const snap = await photoRef.get();
  const photo = snap.data();
  if (!snap.exists || photo?.status !== "pending") {
    throw new HttpsError("not-found", "Photo introuvable ou déjà traitée.");
  }

  // Si l'analyse automatique n'a jamais réussi à tourner sur cette photo
  // (déclencheur en échec, document créé avant ce correctif), on la
  // lance ici plutôt que de laisser `hasFace` indéfini pour toujours —
  // la décision humaine d'approuver ou refuser reste celle de l'admin,
  // seul le signal manquant est complété (trouvé par revue de code).
  let moderationUpdate: Record<string, unknown> = {};
  if (approve && !photo?.moderatedAt && typeof photo?.storagePath === "string") {
    const { hasFace, safeSearch } = await analyzePhotoContent(photo.storagePath);
    moderationUpdate = { hasFace, safeSearch, moderatedAt: FieldValue.serverTimestamp() };
  }

  await photoRef.update({
    ...moderationUpdate,
    status: approve ? "approved" : "rejected",
    reviewedAt: FieldValue.serverTimestamp(),
    reviewedBy: adminUid,
  });

  await logAdminAction(db, {
    adminUid,
    action: approve ? "photo_approved" : "photo_rejected",
    targetUid: userId,
    details: { photoId },
  });

  return { ok: true };
});
