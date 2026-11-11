import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore } from "firebase-admin/firestore";

import { REGION, COMPAT_QUESTIONS_PER_SESSION } from "../config";

/**
 * Tire un sous-ensemble aléatoire de la banque de compatibilité à chaque
 * ouverture de l'écran (docs/suivi-developpement.md, section du
 * 11/11/2026) — remplace la lecture directe de toute la banque par le
 * client. Priorité aux questions pas encore répondues, pour que la
 * banque entière finisse par être couverte en quelques sessions plutôt
 * que de toujours retomber sur les mêmes questions ; une fois tout
 * répondu, retombe sur un tirage aléatoire classique (permet de revoir/
 * changer d'anciennes réponses).
 */
export const getCompatQuestions = onCall({ region: REGION }, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Connexion requise.");
  }
  const uid = request.auth.uid;
  const db = getFirestore();

  const [bankSnap, myAnswersSnap] = await Promise.all([
    db.collection("compat_question_bank").where("active", "==", true).get(),
    db.collection("compat_answers").doc(uid).get(),
  ]);

  const answered = new Set(Object.keys(myAnswersSnap.data()?.answers ?? {}));
  const unanswered = bankSnap.docs.filter((doc) => !answered.has(doc.id));
  const pool = unanswered.length >= COMPAT_QUESTIONS_PER_SESSION ? unanswered : bankSnap.docs;

  const shuffled = pool
    .map((doc) => doc)
    .sort(() => Math.random() - 0.5)
    .slice(0, COMPAT_QUESTIONS_PER_SESSION);

  return {
    questions: shuffled.map((doc) => {
      const data = doc.data();
      return { id: doc.id, theme: data.theme as string, question: data.question as string };
    }),
  };
});
