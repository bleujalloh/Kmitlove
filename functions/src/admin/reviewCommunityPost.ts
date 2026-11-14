import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore, FieldValue } from "firebase-admin/firestore";

import { REGION } from "../config";
import { ENFORCE_APP_CHECK } from "../shared/appCheck";
import { requireAdmin } from "../shared/requireAdmin";
import { logAdminAction } from "../shared/adminLog";

/** Liste les annonces/événements en attente de revue (section 4.7/6). */
export const adminListPendingCommunityPosts = onCall({ region: REGION, enforceAppCheck: ENFORCE_APP_CHECK }, async (request) => {
  requireAdmin(request);
  const db = getFirestore();
  const snap = await db
    .collection("community_posts")
    .where("status", "==", "pending_review")
    .orderBy("createdAt", "asc")
    .limit(50)
    .get();
  return { posts: snap.docs.map((d) => ({ id: d.id, ...d.data() })) };
});

interface ReviewData {
  postId: string;
  approve: boolean;
}

/**
 * Valide ou refuse une publication en attente (docs/regles-annonces-evenements.md
 * section 3 : revue humaine obligatoire pour tout événement physique).
 */
export const adminReviewCommunityPost = onCall({ region: REGION, enforceAppCheck: ENFORCE_APP_CHECK }, async (request) => {
  const adminUid = requireAdmin(request);
  const { postId, approve } = request.data as ReviewData;
  if (!postId) {
    throw new HttpsError("invalid-argument", "postId manquant.");
  }

  const db = getFirestore();
  const postRef = db.collection("community_posts").doc(postId);
  const postSnap = await postRef.get();
  if (!postSnap.exists || postSnap.data()?.status !== "pending_review") {
    throw new HttpsError("not-found", "Publication introuvable ou déjà traitée.");
  }

  await postRef.update({
    status: approve ? "published" : "rejected",
    reviewedAt: FieldValue.serverTimestamp(),
    reviewedBy: adminUid,
  });

  await logAdminAction(db, {
    adminUid,
    action: approve ? "post_approved" : "post_rejected",
    targetUid: (postSnap.data()?.authorUid as string | undefined) ?? null,
    details: { postId },
  });

  return { ok: true };
});
