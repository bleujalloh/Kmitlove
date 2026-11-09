import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { FieldValue } from "firebase-admin/firestore";

import { REGION } from "../config";

/**
 * Met à jour l'aperçu du match (dernier message, date) à chaque nouveau
 * message — jamais écrit directement par le client, qui n'a pas le
 * droit d'écrire sur le document `matches` (firestore.rules).
 */
export const onMessageCreated = onDocumentCreated(
  { document: "matches/{matchId}/messages/{messageId}", region: REGION },
  async (event) => {
    const data = event.data?.data();
    if (!data) return;

    const preview = typeof data.text === "string" ? data.text.slice(0, 120) : "";

    await event.data!.ref.parent.parent!.update({
      lastMessageAt: FieldValue.serverTimestamp(),
      lastMessagePreview: preview,
      lastMessageFromUid: data.fromUid,
    });
  },
);
