import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore } from "firebase-admin/firestore";

import { REGION } from "../config";
import { ENFORCE_APP_CHECK } from "../shared/appCheck";

/**
 * « Retour » de Découvrir (prototype Decouvrir.dc.html, flèche gauche) :
 * annule le TOUT DERNIER passage du membre pour lui représenter le
 * profil. Règles (les plus strictes, aucune règle métier antérieure) :
 * - réservé aux membres Premium, comme le Boost (cahier des charges
 *   section 5) ;
 * - uniquement un passage ("pass"), jamais un like ni un Super Like :
 *   annuler un like contournerait la limite quotidienne, le coût en
 *   jetons et les notifications déjà envoyées ;
 * - uniquement le dernier swipe (recordSwipe mémorise
 *   `lastPassTargetUid`, effacé par tout swipe suivant).
 */
export const undoLastSwipe = onCall({ region: REGION, enforceAppCheck: ENFORCE_APP_CHECK }, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Connexion requise.");
  }
  const uid = request.auth.uid;
  const targetUid = request.data?.targetUid;
  if (typeof targetUid !== "string" || !targetUid) {
    throw new HttpsError("invalid-argument", "Profil manquant.");
  }

  const db = getFirestore();
  const statusRef = db.collection("user_status").doc(uid);
  const swipeRef = db.collection("swipes").doc(`${uid}_${targetUid}`);

  await db.runTransaction(async (tx) => {
    const [statusSnap, swipeSnap] = await Promise.all([tx.get(statusRef), tx.get(swipeRef)]);
    const status = statusSnap.data();
    if (status?.isPremium !== true) {
      throw new HttpsError("permission-denied", "Revenir en arrière est réservé aux membres Premium.");
    }
    if (status?.lastPassTargetUid !== targetUid || swipeSnap.data()?.action !== "pass") {
      throw new HttpsError("failed-precondition", "Seul ton dernier passage peut être annulé.");
    }
    tx.delete(swipeRef);
    tx.set(statusRef, { lastPassTargetUid: null }, { merge: true });
  });

  return { ok: true };
});
