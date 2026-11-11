import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import * as crypto from "crypto";

import { REGION } from "../config";
import { sendPushToUser } from "../shared/push";

/**
 * Annulation d'une participation par le membre lui-même (spec Communauté
 * section 9 — "liste d'attente : remplacer une personne qui annule").
 * Si la place libérée était confirmée ("accepted"), la personne la plus
 * ancienne en liste d'attente est promue automatiquement dans la même
 * transaction : jamais une place qui reste vide alors qu'une liste
 * d'attente existe, et jamais deux personnes promues pour une seule
 * place libérée (le tout dans une seule transaction Firestore).
 */
export const cancelParticipation = onCall({ region: REGION }, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Connexion requise.");
  }
  const uid = request.auth.uid;
  const { postId } = request.data as { postId: string };
  if (!postId) {
    throw new HttpsError("invalid-argument", "postId manquant.");
  }

  const db = getFirestore();
  const postRef = db.collection("community_posts").doc(postId);
  const participationRef = postRef.collection("participations").doc(uid);

  const promotedUid = await db.runTransaction(async (tx) => {
    const participationSnap = await tx.get(participationRef);
    const participation = participationSnap.data();
    if (!participation) {
      throw new HttpsError("not-found", "Aucune participation à annuler.");
    }
    if (!["pending", "accepted", "waitlisted"].includes(participation.status)) {
      throw new HttpsError("failed-precondition", "Cette participation ne peut plus être annulée.");
    }

    const wasAccepted = participation.status === "accepted";
    tx.update(participationRef, {
      status: "cancelled",
      respondedAt: FieldValue.serverTimestamp(),
    });

    if (!wasAccepted) {
      return null;
    }
    tx.update(postRef, { participantsCount: FieldValue.increment(-1) });

    // La personne la plus ancienne en liste d'attente, relue DANS la
    // transaction pour éviter qu'une double annulation simultanée ne
    // promeuve deux fois la même personne (même protection TOCTOU que
    // startFiltrageAttempt.ts/participation.ts).
    const waitlistSnap = await tx.get(
      postRef
        .collection("participations")
        .where("status", "==", "waitlisted")
        .orderBy("requestedAt", "asc")
        .limit(1),
    );
    if (waitlistSnap.empty) {
      return null;
    }
    const promotedRef = waitlistSnap.docs[0].ref;
    const checkinCode = crypto.randomBytes(4).toString("hex").toUpperCase();
    tx.update(promotedRef, {
      status: "accepted",
      respondedAt: FieldValue.serverTimestamp(),
      checkinCode,
    });
    tx.update(postRef, { participantsCount: FieldValue.increment(1) });
    return promotedRef.id;
  });

  if (promotedUid) {
    const postSnap = await postRef.get();
    await sendPushToUser(promotedUid, {
      title: "Une place s'est libérée",
      body: `Tu es confirmé·e pour « ${postSnap.data()?.title ?? "l'événement"} » — une place vient de se libérer.`,
    });
  }

  return { ok: true, promotedUid };
});
