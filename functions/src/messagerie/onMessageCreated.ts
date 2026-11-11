import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { FieldValue, getFirestore } from "firebase-admin/firestore";

import { REGION } from "../config";
import { sendPushToUser } from "../shared/push";

/**
 * Met à jour l'aperçu du match (dernier message, date) à chaque nouveau
 * message — jamais écrit directement par le client, qui n'a pas le
 * droit d'écrire sur le document `matches` (firestore.rules) — et
 * notifie le destinataire (docs/suivi-developpement.md section du
 * 11/11/2026).
 */
export const onMessageCreated = onDocumentCreated(
  { document: "matches/{matchId}/messages/{messageId}", region: REGION },
  async (event) => {
    const data = event.data?.data();
    if (!data) return;

    // Une photo (sendImageMessage) a un texte vide — sans repli, la liste
    // des conversations afficherait "Dites bonjour" comme si rien n'avait
    // été envoyé, alors qu'une photo attend d'être vue.
    const hasImage = typeof data.imageStoragePath === "string";
    const preview = typeof data.text === "string" && data.text.length > 0
      ? data.text.slice(0, 120)
      : hasImage
        ? "Photo"
        : "";

    const matchRef = event.data!.ref.parent.parent!;
    await matchRef.update({
      lastMessageAt: FieldValue.serverTimestamp(),
      lastMessagePreview: preview,
      lastMessageFromUid: data.fromUid,
    });

    const matchSnap = await matchRef.get();
    const members: string[] = matchSnap.data()?.members ?? [];
    const recipientUid = members.find((m) => m !== data.fromUid);
    if (!recipientUid) return;

    const senderSnap = await getFirestore().collection("users").doc(data.fromUid).get();
    const senderName = (senderSnap.data()?.displayName as string | undefined) ?? "Quelqu'un";
    await sendPushToUser(
      recipientUid,
      { title: senderName, body: preview || "Nouveau message" },
      { type: "message", matchId: matchRef.id },
    );
  },
);
