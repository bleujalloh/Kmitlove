import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore, FieldValue } from "firebase-admin/firestore";

import { REGION, EVENT_STATES } from "../config";
import { requireApprovedOrganizer } from "../shared/requireApprovedOrganizer";

// Sous-ensemble de EVENT_STATES que l'organisateur peut déclencher
// lui-même — jamais "complet" (déduit de participantsCount/capacity) ni
// "prevu" (état initial, pas une transition) ; dérivé de la même liste
// que createCommunityPost.ts pour ne jamais diverger (trouvé par revue
// de code : une première version le dupliquait en dur).
const ALLOWED_TRANSITIONS = EVENT_STATES.filter((s) => s === "annule" || s === "termine");

interface UpdateData {
  postId: string;
  eventState: string;
}

/**
 * L'organisateur déclare son événement annulé ou terminé (spec
 * Communauté section 8) — jamais "complet", qui se déduit toujours de
 * participantsCount/capacity (espace organisateur, pas un champ libre).
 */
export const updateEventState = onCall({ region: REGION }, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Connexion requise.");
  }
  const uid = request.auth.uid;
  const { postId, eventState } = request.data as UpdateData;
  if (!postId || !ALLOWED_TRANSITIONS.includes(eventState as never)) {
    throw new HttpsError("invalid-argument", "Statut invalide.");
  }

  const db = getFirestore();
  const postRef = db.collection("community_posts").doc(postId);
  const postSnap = await postRef.get();
  const post = postSnap.data();
  if (!post || post.authorUid !== uid) {
    throw new HttpsError("permission-denied", "Seul l'organisateur peut modifier le statut.");
  }
  await requireApprovedOrganizer(db, uid);
  if (!post.eventState) {
    throw new HttpsError("invalid-argument", "Cette publication n'est pas un événement.");
  }
  if (post.eventState === "annule" || post.eventState === "termine") {
    throw new HttpsError("failed-precondition", "Statut déjà définitif.");
  }

  await postRef.update({ eventState, eventStateUpdatedAt: FieldValue.serverTimestamp() });
  return { ok: true };
});
