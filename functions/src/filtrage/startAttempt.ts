import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore, FieldValue } from "firebase-admin/firestore";

import { REGION, FILTRAGE_QUESTIONS_PER_ATTEMPT } from "../config";

/**
 * Tire aléatoirement un jeu de questions pour une nouvelle tentative du
 * questionnaire de filtrage (docs/regles-du-projet.md section 1). Les
 * bonnes réponses ne sont jamais envoyées au client.
 */
export const startFiltrageAttempt = onCall({ region: REGION }, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Connexion requise.");
  }
  const uid = request.auth.uid;
  const db = getFirestore();

  const statusSnap = await db.collection("user_status").doc(uid).get();
  const status = statusSnap.data();

  if (status?.filtrageStatus === "active") {
    throw new HttpsError("failed-precondition", "Le compte est déjà activé.");
  }
  if (status?.filtrageStatus === "review_requested") {
    throw new HttpsError("failed-precondition", "Une révision humaine est déjà en cours.");
  }
  const nextRetryAt = status?.filtrageNextRetryAt;
  if (nextRetryAt && nextRetryAt.toMillis() > Date.now()) {
    throw new HttpsError(
      "failed-precondition",
      "Le prochain essai n'est pas encore disponible.",
    );
  }

  const bankSnap = await db
    .collection("filtrage_question_bank")
    .where("active", "==", true)
    .get();

  if (bankSnap.size < FILTRAGE_QUESTIONS_PER_ATTEMPT) {
    throw new HttpsError(
      "internal",
      "La banque de questions n'est pas encore assez remplie.",
    );
  }

  const shuffled = bankSnap.docs
    .map((doc) => doc)
    .sort(() => Math.random() - 0.5)
    .slice(0, FILTRAGE_QUESTIONS_PER_ATTEMPT);

  const attemptRef = db.collection("filtrage_attempts").doc();
  await attemptRef.set({
    uid,
    questionIds: shuffled.map((doc) => doc.id),
    createdAt: FieldValue.serverTimestamp(),
    submittedAt: null,
    score: null,
    passed: null,
  });

  await db.collection("user_status").doc(uid).set(
    { filtrageStatus: "in_progress", filtrageCurrentAttemptId: attemptRef.id },
    { merge: true },
  );

  return {
    attemptId: attemptRef.id,
    questions: shuffled.map((doc) => {
      const data = doc.data();
      return {
        id: doc.id,
        theme: data.theme as string,
        question: data.question as string,
        options: data.options as string[],
      };
    }),
  };
});
