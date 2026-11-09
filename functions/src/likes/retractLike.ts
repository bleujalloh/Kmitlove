import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore } from "firebase-admin/firestore";

import { REGION } from "../config";

interface RetractData {
  targetUid: string;
}

/**
 * Retirer un like (cahier des charges section 4.5). Possible uniquement
 * si ça n'a pas déjà donné lieu à un match — on ne défait jamais un
 * match déjà créé depuis cette fonction.
 */
export const retractLike = onCall({ region: REGION }, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Connexion requise.");
  }
  const uid = request.auth.uid;
  const { targetUid } = request.data as RetractData;
  if (!targetUid) {
    throw new HttpsError("invalid-argument", "targetUid manquant.");
  }

  const db = getFirestore();
  const matchId = [uid, targetUid].sort().join("_");
  const matchSnap = await db.collection("matches").doc(matchId).get();
  if (matchSnap.exists) {
    throw new HttpsError(
      "failed-precondition",
      "Impossible de retirer un like qui a déjà donné lieu à un match.",
    );
  }

  const swipeRef = db.collection("swipes").doc(`${uid}_${targetUid}`);
  const swipeSnap = await swipeRef.get();
  const action = swipeSnap.data()?.action;
  if (swipeSnap.exists && swipeSnap.data()?.fromUid === uid && (action === "like" || action === "super_like")) {
    await swipeRef.delete();
  }

  return { ok: true };
});
