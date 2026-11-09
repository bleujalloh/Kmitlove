import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore, FieldValue } from "firebase-admin/firestore";

import { REGION } from "../config";

/**
 * Consomme un jeton pour faire réapparaître un profil précédemment
 * passé, afin de pouvoir lui envoyer un like (docs/regles-economie-et-compatibilite.md
 * section 1). Ne garantit jamais un match, et un seul rachat possible
 * par profil — jamais plus, même avec d'autres jetons, pour ne pas que
 * ça devienne un outil de harcèlement d'un profil qui a clairement
 * ignoré quelqu'un.
 */
export const useJetonToResurface = onCall({ region: REGION }, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Connexion requise.");
  }
  const uid = request.auth.uid;
  const { targetUid } = request.data as { targetUid: string };
  if (!targetUid) {
    throw new HttpsError("invalid-argument", "targetUid manquant.");
  }

  const db = getFirestore();
  const statusRef = db.collection("user_status").doc(uid);
  const swipeRef = db.collection("swipes").doc(`${uid}_${targetUid}`);

  await db.runTransaction(async (tx) => {
    const [statusSnap, swipeSnap] = await Promise.all([tx.get(statusRef), tx.get(swipeRef)]);
    const status = statusSnap.data();
    const jetons = status?.jetons ?? 0;
    if (jetons < 1) {
      throw new HttpsError("resource-exhausted", "Aucun jeton disponible.");
    }

    const swipe = swipeSnap.data();
    if (!swipe || swipe.action !== "pass") {
      throw new HttpsError(
        "failed-precondition",
        "Un jeton ne peut être utilisé que sur un profil que tu as passé.",
      );
    }

    const resurrected: string[] = status?.resurrectedUids ?? [];
    if (resurrected.includes(targetUid)) {
      throw new HttpsError(
        "failed-precondition",
        "Ce profil a déjà été relancé une fois avec un jeton, impossible de recommencer.",
      );
    }

    // Le "pass" est retiré pour que le flux normal de Découvrir/like
    // (recordSwipe) fonctionne ensuite sans traitement spécial ; on
    // garde une trace du uid pour empêcher un second rachat.
    tx.delete(swipeRef);
    tx.set(
      statusRef,
      {
        jetons: FieldValue.increment(-1),
        resurrectedUids: FieldValue.arrayUnion(targetUid),
      },
      { merge: true },
    );
  });

  return { ok: true };
});
