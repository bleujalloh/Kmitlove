import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore, FieldValue } from "firebase-admin/firestore";

import { REGION } from "../config";
import { requireApprovedOrganizer } from "../shared/requireApprovedOrganizer";

interface InviteData {
  postId: string;
  targetUid: string;
}

/**
 * Invite un membre à un événement "sur invitation" (spec Communauté
 * section 2) — seul l'organisateur peut inviter, jamais le membre
 * lui-même (sinon l'accès sur invitation n'aurait aucun sens).
 */
export const inviteToEvent = onCall({ region: REGION }, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Connexion requise.");
  }
  const uid = request.auth.uid;
  const { postId, targetUid } = request.data as InviteData;
  if (!postId || !targetUid) {
    throw new HttpsError("invalid-argument", "Paramètres manquants.");
  }
  if (targetUid === uid) {
    throw new HttpsError("invalid-argument", "Impossible de s'inviter soi-même.");
  }

  const db = getFirestore();
  const postRef = db.collection("community_posts").doc(postId);
  const postSnap = await postRef.get();
  const post = postSnap.data();
  if (!post || post.authorUid !== uid) {
    throw new HttpsError("permission-denied", "Seul l'organisateur peut inviter.");
  }
  await requireApprovedOrganizer(db, uid);
  if (post.accessMode !== "sur_invitation") {
    throw new HttpsError("failed-precondition", "Cet événement n'est pas sur invitation.");
  }

  // Jamais sur le document public (voir createCommunityPost.ts) : la
  // liste des invités resterait sinon lisible par tout membre connecté.
  await postRef
    .collection("private")
    .doc("invitations")
    .set({ invitedUids: FieldValue.arrayUnion(targetUid) }, { merge: true });
  return { ok: true };
});
