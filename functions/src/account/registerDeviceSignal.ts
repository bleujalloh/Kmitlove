import { HttpsError } from "firebase-functions/v2/https";
import { onCallNoConsent as onCall } from "../shared/callable";
import { getFirestore, FieldValue } from "firebase-admin/firestore";

import { REGION, MULTI_ACCOUNT_DEVICE_THRESHOLD } from "../config";
import { ENFORCE_APP_CHECK } from "../shared/appCheck";

interface Data {
  deviceId?: string;
}

/**
 * Signal anti-abus "limite de comptes par appareil" (docs/suivi-
 * developpement.md, Fondations) — appelée une seule fois par le client,
 * juste après une inscription qui vient de créer un nouveau compte
 * (`additionalUserInfo.isNewUser`), jamais à chaque connexion. Ne bloque
 * jamais l'inscription elle-même (voir config.ts) : au-delà du seuil, le
 * compte le plus récent est simplement mis en revue prioritaire, comme un
 * signalement classique (adminResolveModerationRequest le traite déjà via
 * son chemin générique dismiss/warn/suspend/ban).
 */
export const registerDeviceSignal = onCall({ region: REGION, enforceAppCheck: ENFORCE_APP_CHECK }, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Connexion requise.");
  }
  const uid = request.auth.uid;
  const { deviceId } = (request.data ?? {}) as Data;
  if (!deviceId || typeof deviceId !== "string" || deviceId.length > 200) {
    throw new HttpsError("invalid-argument", "deviceId manquant ou invalide.");
  }

  const db = getFirestore();
  const deviceRef = db.collection("device_signals").doc(deviceId);

  await db.runTransaction(async (tx) => {
    const snap = await tx.get(deviceRef);
    const data = snap.data();
    const existingUids = Array.isArray(data?.uids) ? (data!.uids as string[]) : [];
    // Un même compte peut rappeler cette fonction (reprise après coupure
    // réseau, par ex.) sans que ce soit un nouveau compte supplémentaire.
    if (existingUids.includes(uid)) return;

    const uids = [...existingUids, uid];
    tx.set(deviceRef, { uids, lastSeenAt: FieldValue.serverTimestamp() }, { merge: true });

    // Un seul signalement par appareil, au moment où le seuil est franchi
    // — pas un nouveau à chaque compte supplémentaire au-delà, qui
    // noierait la file de modération sans information nouvelle.
    const alreadyFlagged = data?.flagged === true;
    if (!alreadyFlagged && uids.length >= MULTI_ACCOUNT_DEVICE_THRESHOLD) {
      tx.set(deviceRef, { flagged: true }, { merge: true });
      tx.set(db.collection("moderation_requests").doc(), {
        type: "multi_account_signal",
        targetUid: uid,
        reason: `${uids.length} comptes créés depuis le même appareil : ${uids.join(", ")}`,
        priority: true,
        resolved: false,
        createdAt: FieldValue.serverTimestamp(),
      });
    }
  });

  return { ok: true };
});
