import { getMessaging } from "firebase-admin/messaging";
import { getFirestore, FieldValue } from "firebase-admin/firestore";

/**
 * Envoie une notification push à tous les appareils enregistrés d'un
 * membre (`user_status/{uid}.fcmTokens`, alimenté uniquement par
 * registerFcmToken.ts — jamais écrit directement par le client). Best-
 * effort : une erreur d'envoi ne doit jamais faire échouer l'opération
 * métier qui déclenche la notification (nouveau message, match, like).
 * Les jetons devenus invalides (désinstallation, etc.) sont retirés au
 * passage pour ne pas les retenter indéfiniment.
 */
export async function sendPushToUser(
  uid: string,
  notification: { title: string; body: string },
  data?: Record<string, string>,
): Promise<void> {
  try {
    const db = getFirestore();
    const statusSnap = await db.collection("user_status").doc(uid).get();
    const tokens: string[] = statusSnap.data()?.fcmTokens ?? [];
    if (tokens.length === 0) return;

    const response = await getMessaging().sendEachForMulticast({
      tokens,
      notification,
      data: data ?? {},
    });

    const invalidTokens: string[] = [];
    response.responses.forEach((r, i) => {
      if (
        !r.success &&
        (r.error?.code === "messaging/invalid-registration-token" ||
          r.error?.code === "messaging/registration-token-not-registered")
      ) {
        invalidTokens.push(tokens[i]);
      }
    });
    if (invalidTokens.length > 0) {
      await db
        .collection("user_status")
        .doc(uid)
        .update({ fcmTokens: FieldValue.arrayRemove(...invalidTokens) });
    }
  } catch (err) {
    // eslint-disable-next-line no-console
    console.error("sendPushToUser failed", { uid, err });
  }
}
