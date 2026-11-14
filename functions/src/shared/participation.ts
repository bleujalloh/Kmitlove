import { Firestore, FieldValue } from "firebase-admin/firestore";
import { HttpsError } from "firebase-functions/v2/https";
import * as crypto from "crypto";

import { sendPushToUser } from "./push";

/**
 * Annule la participation d'un membre à un événement et, si elle était
 * confirmée, libère la place : décrémente `participantsCount` et promeut la
 * personne la plus ancienne de la liste d'attente (relue DANS la transaction
 * pour qu'une double annulation simultanée ne promeuve pas deux fois la même
 * personne). Source unique : utilisée par `cancelParticipation` (demande du
 * membre) ET par `eraseAccount` (suppression de compte) — sans cela, effacer
 * un participant laissait l'événement « complet » pour toujours.
 */
export async function cancelParticipationAndPromote(
  db: Firestore,
  postId: string,
  uid: string,
): Promise<{ promotedUid: string | null }> {
  const postRef = db.collection("community_posts").doc(postId);
  const participationRef = postRef.collection("participations").doc(uid);

  const promotedUid = await db.runTransaction(async (tx) => {
    // Firestore exige que TOUTES les lectures d'une transaction précèdent la
    // première écriture : la personne de tête de la liste d'attente est donc
    // lue avant de modifier quoi que ce soit (l'ancienne version, avec la
    // lecture après les écritures, échouait toujours pour une place
    // confirmée — trouvé par le test réel du 14/11/2026).
    const participationSnap = await tx.get(participationRef);
    const participation = participationSnap.data();
    if (!participation) {
      throw new HttpsError("not-found", "Aucune participation à annuler.");
    }
    if (!["pending", "accepted", "waitlisted"].includes(participation.status)) {
      throw new HttpsError("failed-precondition", "Cette participation ne peut plus être annulée.");
    }

    const wasAccepted = participation.status === "accepted";
    let nextInLine: FirebaseFirestore.QueryDocumentSnapshot | null = null;
    if (wasAccepted) {
      const waitlistSnap = await tx.get(
        postRef
          .collection("participations")
          .where("status", "==", "waitlisted")
          .orderBy("requestedAt", "asc")
          .limit(1),
      );
      nextInLine = waitlistSnap.empty ? null : waitlistSnap.docs[0];
    }

    // --- écritures ---
    tx.update(participationRef, {
      status: "cancelled",
      respondedAt: FieldValue.serverTimestamp(),
    });
    if (!wasAccepted) {
      return null;
    }
    if (!nextInLine) {
      tx.update(postRef, { participantsCount: FieldValue.increment(-1) });
      return null;
    }
    // Une place se libère et une personne l'occupe aussitôt : le nombre de
    // participants ne change pas.
    const checkinCode = crypto.randomBytes(4).toString("hex").toUpperCase();
    tx.update(nextInLine.ref, {
      status: "accepted",
      respondedAt: FieldValue.serverTimestamp(),
      checkinCode,
    });
    return nextInLine.id;
  });

  if (promotedUid) {
    const postSnap = await postRef.get();
    await sendPushToUser(
      promotedUid,
      {
        title: "Une place s'est libérée",
        body: `Tu es confirmé·e pour « ${postSnap.data()?.title ?? "l'événement"} » — une place vient de se libérer.`,
      },
      { type: "event_promoted" },
    );
  }
  return { promotedUid };
}
