import { hasValidConsent, requireConsent } from "../shared/consent";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore, FieldValue } from "firebase-admin/firestore";

import { REGION, FREE_DAILY_LIKE_LIMIT, SUPER_LIKE_JETON_COST } from "../config";
import { ENFORCE_APP_CHECK } from "../shared/appCheck";
import { sendPushToUser } from "../shared/push";

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
export const recordSwipe = onCall({ region: REGION, enforceAppCheck: ENFORCE_APP_CHECK }, async (request) => {
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
  const targetStatusRef = db.collection("user_status").doc(targetUid);
  const reverseSwipeRef = db.collection("swipes").doc(`${targetUid}_${uid}`);
  const blockRef = db.collection("blocks").doc([uid, targetUid].sort().join("_"));
  const isLikeAction = action === "like" || action === "super_like";

  const matchCreated = await db.runTransaction(async (tx) => {
    // Toutes les lectures d'abord — Firestore refuse une transaction qui
    // lit après avoir déjà écrit. Le blocage est relu ICI, fraîchement
    // dans la transaction, pas avant : un blocage posé pile entre une
    // lecture préalable et la validation de cette transaction aurait pu
    // laisser passer un match malgré un blocage tout juste posé
    // (docs/suivi-developpement.md section du 11/11/2026).
    const [existingSwipeSnap, statusSnap, reverseSnap, blockSnap, targetStatusSnap] = await Promise.all([
      tx.get(swipeRef),
      tx.get(statusRef),
      tx.get(reverseSwipeRef),
      tx.get(blockRef),
      tx.get(targetStatusRef),
    ]);

    // Consentement art. 9 (shared/consent.ts) : ni swiper sans l'avoir donné,
    // ni swiper un membre qui l'a retiré (carte restée affichée sur un autre
    // téléphone) — jamais de match avec un profil retiré de la découverte.
    requireConsent(statusSnap.data());
    if (!hasValidConsent(targetStatusSnap.data())) {
      throw new HttpsError("failed-precondition", "Ce profil n'est plus disponible.");
    }

    if (blockSnap.exists) {
      throw new HttpsError("permission-denied", "Impossible d'interagir avec ce profil.");
    }

    if (existingSwipeSnap.exists) {
      throw new HttpsError("already-exists", "Ce profil a déjà été swipé.");
    }

    if (isLikeAction) {
      const status = statusSnap.data();
      const isPremium = status?.isPremium === true;

      if (action === "super_like") {
        // Signalé par le propriétaire le 11/11/2026 : un Super Like ne
        // doit JAMAIS être gratuit/illimité comme un like normal — c'est
        // une économie séparée de la limite quotidienne de likes
        // gratuits (qui ne s'applique qu'aux likes normaux ci-dessous).
        // Premium = gratuit et illimité ; sinon un jeton par envoi.
        if (!isPremium) {
          const jetons = (status?.jetons as number | undefined) ?? 0;
          if (jetons < SUPER_LIKE_JETON_COST) {
            throw new HttpsError(
              "resource-exhausted",
              "super-like-jetons-insuffisants : jeton ou abonnement Premium requis pour un Super Like.",
            );
          }
          tx.set(statusRef, { jetons: FieldValue.increment(-SUPER_LIKE_JETON_COST) }, { merge: true });
        }
      } else if (!isPremium) {
        // La limite ne s'applique qu'à la formule gratuite (cahier des
        // charges section 5 : likes illimités en Premium) — et pour un
        // membre Premium, on ne tient même plus le compteur, qui ne sert
        // à rien dans son cas.
        const today = todayKey();
        const countedToday = status?.swipeCountDate === today ? (status?.swipeCount ?? 0) : 0;
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
    }

    tx.set(swipeRef, {
      fromUid: uid,
      toUid: targetUid,
      action,
      createdAt: FieldValue.serverTimestamp(),
    });
    // Seul le TOUT DERNIER swipe peut être annulé (undoLastSwipe), et
    // seulement s'il s'agit d'un passage : tout autre swipe efface la
    // mémoire du précédent.
    tx.set(statusRef, { lastPassTargetUid: action === "pass" ? targetUid : null }, { merge: true });

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

  // Notifications best-effort, après la transaction (jamais à l'intérieur :
  // une notification n'est pas une opération qui doit pouvoir faire
  // échouer/rejouer la transaction métier) — docs/suivi-developpement.md
  // section du 11/11/2026.
  if (matchCreated) {
    const [mySnap, targetSnap] = await Promise.all([
      db.collection("users").doc(uid).get(),
      db.collection("users").doc(targetUid).get(),
    ]);
    const myName = (mySnap.data()?.displayName as string | undefined) ?? "Quelqu'un";
    const targetName = (targetSnap.data()?.displayName as string | undefined) ?? "Quelqu'un";
    await Promise.all([
      sendPushToUser(uid, { title: "Nouveau match !", body: `Toi et ${targetName}, c'est réciproque.` }, { type: "match" }),
      sendPushToUser(targetUid, { title: "Nouveau match !", body: `Toi et ${myName}, c'est réciproque.` }, { type: "match" }),
    ]);
  } else if (isLikeAction) {
    // Jamais le nom de l'auteur du like ici : "qui m'a liké" en détail
    // reste une fonctionnalité Premium (getLikes.ts) — la notification ne
    // doit pas la révéler gratuitement.
    await sendPushToUser(
      targetUid,
      {
        title: action === "super_like" ? "Un Super Like t'attend !" : "Nouveau like !",
        body: "Quelqu'un aime ton profil sur MERUT.",
      },
      { type: "like" },
    );
  }

  return { matchCreated };
});
