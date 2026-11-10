import { onMessagePublished } from "firebase-functions/v2/pubsub";
import { getFirestore } from "firebase-admin/firestore";

import { REGION, PLAY_RTDN_TOPIC } from "../config";

/**
 * Reçoit les notifications temps réel de Google Play (RTDN) sur les
 * abonnements — c'est le SEUL moyen de savoir qu'un renouvellement
 * automatique a eu lieu (aucun achat côté client ne se déclenche lors
 * d'un renouvellement silencieux) ou qu'un abonnement a été annulé/a
 * expiré/a été remboursé, pour désactiver Premium en conséquence
 * (docs/suivi-developpement.md — "rien ne repasse isPremium à false").
 *
 * Action manuelle restante : lier le sujet Pub/Sub `play-billing-rtdn`
 * dans Play Console > Monétiser > Notifications en temps réel sur les
 * abonnements, avec le compte de service déjà utilisé pour verifyPurchase.
 */
const DEACTIVATING_TYPES = new Set([12, 13]); // REVOKED, EXPIRED
const ACTIVATING_TYPES = new Set([1, 2, 4, 7]); // RECOVERED, RENEWED, PURCHASED, RESTARTED

export const playRtdn = onMessagePublished(
  { topic: PLAY_RTDN_TOPIC, region: REGION },
  async (event) => {
    const dataBase64 = event.data.message.data;
    if (!dataBase64) return;

    let payload: {
      subscriptionNotification?: { notificationType: number; purchaseToken: string };
    };
    try {
      payload = JSON.parse(Buffer.from(dataBase64, "base64").toString("utf8"));
    } catch {
      return; // notification de test ou format inattendu — on ignore proprement
    }

    const notification = payload.subscriptionNotification;
    if (!notification) return; // ex. notification de test Play Console

    const db = getFirestore();
    const tokenSnap = await db
      .collection("used_purchase_tokens")
      .doc(notification.purchaseToken)
      .get();
    const uid = tokenSnap.data()?.uid as string | undefined;
    if (!uid) return; // jeton inconnu — rien à faire côté app

    if (DEACTIVATING_TYPES.has(notification.notificationType)) {
      await db.collection("user_status").doc(uid).set({ isPremium: false }, { merge: true });
    } else if (ACTIVATING_TYPES.has(notification.notificationType)) {
      await db.collection("user_status").doc(uid).set({ isPremium: true }, { merge: true });
    }
    // Les autres types (ON_HOLD, PAUSED, PRICE_CHANGE_CONFIRMED...) sont
    // volontairement ignorés pour l'instant — ni activation ni
    // désactivation, pour rester prudent sur des états ambigus.
  },
);
