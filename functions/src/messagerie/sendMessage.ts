import { HttpsError } from "firebase-functions/v2/https";
import { onCall } from "../shared/callable";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import { getStorage } from "firebase-admin/storage";

import { REGION, MESSAGE_MAX_LENGTH, MESSAGE_RATE_LIMITS } from "../config";
import { ENFORCE_APP_CHECK } from "../shared/appCheck";
import { enforceRateLimit } from "../shared/rateLimit";
import { requireConsent } from "../shared/consent";

/**
 * Envoi d'un message (texte ou photo de conversation). Jusqu'au 14/11/2026
 * le client écrivait directement dans Firestore, ce qui ne permettait aucune
 * limite de fréquence : un script pouvait inonder une conversation. Tout
 * passe désormais par cette fonction (firestore.rules : `create: false`
 * sur les messages) qui vérifie, dans l'ordre : compte actif, appartenance
 * au match, absence de blocage, forme du message, puis la fréquence.
 *
 * Le déclencheur `onMessageCreated` (aperçu du match + notification) reste
 * inchangé : il réagit à la création du document, d'où qu'elle vienne.
 */
export const sendMessage = onCall({ region: REGION, enforceAppCheck: ENFORCE_APP_CHECK }, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Connexion requise.");
  }
  const uid = request.auth.uid;
  const { matchId, text, imageStoragePath } = request.data as {
    matchId?: unknown;
    text?: unknown;
    imageStoragePath?: unknown;
  };

  if (typeof matchId !== "string" || matchId.length === 0 || matchId.includes("/")) {
    throw new HttpsError("invalid-argument", "Conversation invalide.");
  }
  const hasImage = imageStoragePath !== undefined && imageStoragePath !== null;
  let cleanText = "";
  if (hasImage) {
    // La photo doit être dans le dossier de CETTE conversation, jamais un
    // chemin choisi par le client (sinon on pourrait « envoyer » le fichier
    // d'une autre conversation ou d'un autre membre).
    if (
      typeof imageStoragePath !== "string" ||
      !imageStoragePath.startsWith(`chat_photos/${matchId}/`) ||
      imageStoragePath.slice(`chat_photos/${matchId}/`.length).includes("/")
    ) {
      throw new HttpsError("invalid-argument", "Photo invalide.");
    }
  } else {
    if (typeof text !== "string" || text.trim().length === 0 || text.length > MESSAGE_MAX_LENGTH) {
      throw new HttpsError("invalid-argument", "Message invalide.");
    }
    cleanText = text.trim();
  }

  const db = getFirestore();
  const [statusSnap, matchSnap, blockSnap] = await Promise.all([
    db.collection("user_status").doc(uid).get(),
    db.collection("matches").doc(matchId).get(),
    db.collection("blocks").doc(matchId).get(),
  ]);

  if (statusSnap.data()?.filtrageStatus !== "active") {
    throw new HttpsError("permission-denied", "Ton compte n'est pas actif.");
  }
  requireConsent(statusSnap.data());
  const members = (matchSnap.data()?.members as string[] | undefined) ?? [];
  if (!matchSnap.exists || !members.includes(uid)) {
    throw new HttpsError("permission-denied", "Tu ne fais pas partie de cette conversation.");
  }
  if (blockSnap.exists) {
    throw new HttpsError("permission-denied", "Conversation indisponible.");
  }
  if (hasImage) {
    const file = getStorage().bucket().file(imageStoragePath as string);
    const [exists] = await file.exists();
    if (!exists) {
      throw new HttpsError("failed-precondition", "La photo n'a pas été envoyée.");
    }
    // Seul l'auteur du dépôt (métadonnée posée à l'envoi, imposée par
    // storage.rules) peut publier la photo : jamais celle de l'autre membre.
    const [metadata] = await file.getMetadata();
    if (metadata.metadata?.uploaderUid !== uid) {
      throw new HttpsError("permission-denied", "Cette photo n'est pas la tienne.");
    }
  }

  await enforceRateLimit(uid, MESSAGE_RATE_LIMITS);

  const ref = await matchSnap.ref.collection("messages").add({
    fromUid: uid,
    text: cleanText,
    ...(hasImage ? { imageStoragePath } : {}),
    createdAt: FieldValue.serverTimestamp(),
    readBy: [uid],
  });
  return { ok: true, id: ref.id };
});
