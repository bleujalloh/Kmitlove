import { HttpsError } from "firebase-functions/v2/https";
import { onCallNoConsent as onCall } from "../shared/callable";
import { getFirestore, Timestamp } from "firebase-admin/firestore";

import { REGION } from "../config";
import { ENFORCE_APP_CHECK } from "../shared/appCheck";

/**
 * Réglages de compte de l'écran Paramètres du prototype : préférences de
 * notification par type, visibilité du profil, liste de mes signalements.
 * `user_status` n'est écrit que par les fonctions serveur (firestore.rules) :
 * ces réglages passent donc ici, jamais par une écriture directe.
 */

const NOTIFICATION_KEYS = ["likes", "messages", "matches", "community", "events"] as const;

/** Active ou coupe chaque type de notification (clés absentes : inchangées). */
export const setNotificationPreferences = onCall({ region: REGION, enforceAppCheck: ENFORCE_APP_CHECK }, async (request) => {
  if (!request.auth) throw new HttpsError("unauthenticated", "Connexion requise.");
  const data = (request.data ?? {}) as Record<string, unknown>;
  const update: Record<string, boolean> = {};
  for (const key of NOTIFICATION_KEYS) {
    if (data[key] === undefined) continue;
    if (typeof data[key] !== "boolean") {
      throw new HttpsError("invalid-argument", `Valeur invalide pour ${key}.`);
    }
    update[key] = data[key] as boolean;
  }
  if (Object.keys(update).length === 0) {
    throw new HttpsError("invalid-argument", "Aucune préférence fournie.");
  }
  await getFirestore()
    .collection("user_status")
    .doc(request.auth.uid)
    .set({ notificationPrefs: update }, { merge: true });
  return { ok: true };
});

/** Masque ou réaffiche le profil dans la découverte des autres membres. */
export const setProfileVisibility = onCall({ region: REGION, enforceAppCheck: ENFORCE_APP_CHECK }, async (request) => {
  if (!request.auth) throw new HttpsError("unauthenticated", "Connexion requise.");
  const hidden = request.data?.hidden;
  if (typeof hidden !== "boolean") {
    throw new HttpsError("invalid-argument", "Valeur invalide.");
  }
  await getFirestore()
    .collection("user_status")
    .doc(request.auth.uid)
    .set({ profileHidden: hidden }, { merge: true });
  return { ok: true };
});

/**
 * Mes propres signalements (type, motif, date, traité ou non). Jamais le
 * détail interne de la modération ni la décision prise.
 */
export const listMyReports = onCall({ region: REGION, enforceAppCheck: ENFORCE_APP_CHECK }, async (request) => {
  if (!request.auth) throw new HttpsError("unauthenticated", "Connexion requise.");
  const snap = await getFirestore()
    .collection("moderation_requests")
    .where("reporterUid", "==", request.auth.uid)
    .limit(100)
    .get();
  const reports = snap.docs.map((d) => {
    const data = d.data();
    const created = data.createdAt as Timestamp | undefined;
    return {
      id: d.id,
      type: String(data.type ?? ""),
      reason: String(data.reason ?? ""),
      createdAtMs: created?.toMillis?.() ?? 0,
      resolved: data.resolved === true,
    };
  });
  reports.sort((a, b) => b.createdAtMs - a.createdAtMs);
  return { reports };
});
