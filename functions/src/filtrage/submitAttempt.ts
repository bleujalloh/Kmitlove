import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore, FieldValue, Timestamp } from "firebase-admin/firestore";

import { REGION, FILTRAGE_PASS_THRESHOLD, FILTRAGE_RETRY_DELAY_DAYS } from "../config";

interface SubmitData {
  attemptId: string;
  answers: Record<string, number>;
}

/**
 * Corrige une tentative côté serveur uniquement (jamais côté client) et
 * met à jour le statut du compte selon le seuil 80-90 % décidé dans
 * docs/regles-du-projet.md section 1.
 */
export const submitFiltrageAttempt = onCall({ region: REGION }, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Connexion requise.");
  }
  const uid = request.auth.uid;
  const { attemptId, answers } = request.data as SubmitData;

  if (!attemptId || typeof answers !== "object") {
    throw new HttpsError("invalid-argument", "Réponses manquantes.");
  }

  const db = getFirestore();
  const attemptRef = db.collection("filtrage_attempts").doc(attemptId);
  const attemptSnap = await attemptRef.get();
  const attempt = attemptSnap.data();

  if (!attempt || attempt.uid !== uid) {
    throw new HttpsError("not-found", "Tentative introuvable.");
  }
  if (attempt.submittedAt) {
    throw new HttpsError("failed-precondition", "Cette tentative a déjà été soumise.");
  }

  const questionIds: string[] = attempt.questionIds;
  const questionDocs = await Promise.all(
    questionIds.map((id) => db.collection("filtrage_question_bank").doc(id).get()),
  );

  let correctCount = 0;
  for (const doc of questionDocs) {
    const data = doc.data();
    if (!data) continue;
    // Une question sans réponse (refusée) compte comme une mauvaise
    // réponse, conformément à docs/regles-du-projet.md section 1.
    const given = answers[doc.id];
    if (given !== undefined && given === data.correctIndex) {
      correctCount += 1;
    }
  }

  const score = correctCount / questionIds.length;
  const passed = score >= FILTRAGE_PASS_THRESHOLD;

  await attemptRef.update({
    submittedAt: FieldValue.serverTimestamp(),
    score,
    passed,
  });

  const statusRef = db.collection("user_status").doc(uid);
  if (passed) {
    await statusRef.set(
      {
        filtrageStatus: "active",
        filtrageActivatedAt: FieldValue.serverTimestamp(),
        filtrageNextRetryAt: null,
        filtrageCurrentAttemptId: null,
      },
      { merge: true },
    );
  } else {
    const nextRetryAt = Timestamp.fromMillis(
      Date.now() + FILTRAGE_RETRY_DELAY_DAYS * 24 * 60 * 60 * 1000,
    );
    await statusRef.set(
      {
        filtrageStatus: "rejected_pending_retry",
        filtrageNextRetryAt: nextRetryAt,
        filtrageLastScore: score,
        filtrageCurrentAttemptId: null,
      },
      { merge: true },
    );
  }

  return { passed, score };
});
