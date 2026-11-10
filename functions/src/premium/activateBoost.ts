import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore, Timestamp } from "firebase-admin/firestore";

import { REGION, BOOST_DURATION_MINUTES, BOOST_FREE_WEEKLY_FOR_PREMIUM } from "../config";

/**
 * Active le Boost inclus dans Premium — une fois par semaine, 30 minutes
 * (cahier des charges section 5). L'achat de Boosts supplémentaires à
 * l'unité est une fonctionnalité de paiement, volontairement pas
 * construite ici pour l'instant (décision du 2026-11-10).
 */
export const activateBoost = onCall({ region: REGION }, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Connexion requise.");
  }
  const uid = request.auth.uid;
  const db = getFirestore();
  const statusRef = db.collection("user_status").doc(uid);

  await db.runTransaction(async (tx) => {
    const snap = await tx.get(statusRef);
    const status = snap.data();
    if (status?.isPremium !== true) {
      throw new HttpsError("permission-denied", "Le Boost est réservé aux membres Premium.");
    }

    const lastBoostAt = status?.lastBoostAt?.toMillis?.() as number | undefined;
    const cooldownMs = (7 / BOOST_FREE_WEEKLY_FOR_PREMIUM) * 24 * 60 * 60 * 1000;
    if (lastBoostAt && Date.now() - lastBoostAt < cooldownMs) {
      throw new HttpsError(
        "resource-exhausted",
        "Ton Boost gratuit de la semaine a déjà été utilisé.",
      );
    }

    const now = Date.now();
    tx.set(
      statusRef,
      {
        lastBoostAt: Timestamp.fromMillis(now),
        boostedUntil: Timestamp.fromMillis(now + BOOST_DURATION_MINUTES * 60 * 1000),
      },
      { merge: true },
    );
  });

  return { ok: true, durationMinutes: BOOST_DURATION_MINUTES };
});
