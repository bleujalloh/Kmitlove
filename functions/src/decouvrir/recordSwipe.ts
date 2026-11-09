import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore, FieldValue } from "firebase-admin/firestore";

import { REGION, FREE_DAILY_LIKE_LIMIT } from "../config";

interface SwipeData {
  targetUid: string;
  action: "like" | "pass" | "super_like";
}

function todayKey(): string {
  return new Date().toISOString().slice(0, 10); // YYYY-MM-DD, assez pour une limite "par jour"
}

/**
 * Enregistre un like/passe/super-like et crée le match si réciproque
 * (cahier des charges sections 4.4 et 4.6). Limite de likes gratuits et
 * détection de match toujours côté serveur
 * (docs/regles-complementaires-concurrents.md section 3).
 */
export const recordSwipe = onCall({ region: REGION }, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Connexion requise.");
  }
  const uid = request.auth.uid;
  const { targetUid, action } = request.data as SwipeData;

  if (!targetUid || !["like", "pass", "super_like"].includes(action)) {
    throw new HttpsError("invalid-argument", "Paramètres invalides.");
  }
  if (targetUid === uid) {
    throw new HttpsError("invalid-argument", "Impossible de se liker soi-même.");
  }

  const db = getFirestore();
  const swipeRef = db.collection("swipes").doc(`${uid}_${targetUid}`);
  const statusRef = db.collection("user_status").doc(uid);
  const reverseSwipeRef = db.collection("swipes").doc(`${targetUid}_${uid}`);
  const isLikeAction = action === "like" || action === "super_like";

  const matchCreated = await db.runTransaction(async (tx) => {
    // Toutes les lectures d'abord — Firestore refuse une transaction qui
    // lit après avoir déjà écrit.
    const [existingSwipeSnap, statusSnap, reverseSnap] = await Promise.all([
      tx.get(swipeRef),
      tx.get(statusRef),
      tx.get(reverseSwipeRef),
    ]);

    if (existingSwipeSnap.exists) {
      throw new HttpsError("already-exists", "Ce profil a déjà été swipé.");
    }

    if (isLikeAction) {
      const status = statusSnap.data();
      const today = todayKey();
      const countedToday = status?.swipeCountDate === today ? (status?.swipeCount ?? 0) : 0;

      // La limite ne s'applique qu'à la formule gratuite — Premium sera
      // branché ici une fois construit (docs/suivi-developpement.md).
      if (countedToday >= FREE_DAILY_LIKE_LIMIT) {
        throw new HttpsError(
          "resource-exhausted",
          "Limite de likes quotidienne atteinte, reviens demain ou passe en Premium.",
        );
      }

      tx.set(
        statusRef,
        { swipeCountDate: today, swipeCount: countedToday + 1 },
        { merge: true },
      );
    }

    tx.set(swipeRef, {
      fromUid: uid,
      toUid: targetUid,
      action,
      createdAt: FieldValue.serverTimestamp(),
    });

    if (!isLikeAction) return false;

    const reverseAction = reverseSnap.data()?.action;
    const isMutualLike = reverseAction === "like" || reverseAction === "super_like";
    if (!isMutualLike) return false;

    const matchId = [uid, targetUid].sort().join("_");
    const matchRef = db.collection("matches").doc(matchId);
    tx.set(matchRef, {
      uid1: uid,
      uid2: targetUid,
      members: [uid, targetUid],
      createdAt: FieldValue.serverTimestamp(),
      lastMessageAt: null,
    });
    return true;
  });

  return { matchCreated };
});
