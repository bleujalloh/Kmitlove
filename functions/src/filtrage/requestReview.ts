import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore, FieldValue } from "firebase-admin/firestore";

import { REGION } from "../config";

/**
 * Droit de recours après un échec au filtrage (docs/regles-du-projet.md
 * section 1) : crée une demande visible par un modérateur dans l'espace
 * admin, sans attendre le délai de nouvel essai.
 */
export const requestFiltrageReview = onCall({ region: REGION }, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Connexion requise.");
  }
  const uid = request.auth.uid;
  const db = getFirestore();

  const statusRef = db.collection("user_status").doc(uid);
  const statusSnap = await statusRef.get();
  const status = statusSnap.data();

  if (status?.filtrageStatus !== "rejected_pending_retry") {
    throw new HttpsError(
      "failed-precondition",
      "Une révision ne peut être demandée qu'après un échec au questionnaire.",
    );
  }

  await db.collection("moderation_requests").add({
    type: "filtrage_review",
    uid,
    priority: false, // champ requis par le tri de adminListModerationRequests (orderBy)
    createdAt: FieldValue.serverTimestamp(),
    resolved: false,
    lastScore: status.filtrageLastScore ?? null,
  });

  await statusRef.set({ filtrageStatus: "review_requested" }, { merge: true });

  return { ok: true };
});
