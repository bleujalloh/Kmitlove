import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore, FieldValue, Timestamp } from "firebase-admin/firestore";

import { REGION, FILTRAGE_QUESTIONS_PER_ATTEMPT } from "../config";
import { requireNotSuspended } from "../shared/requireNotSuspended";

/**
 * Les quatre invariants qui doivent tenir à CHAQUE point où cette fonction
 * est sur le point de renvoyer des questions ou de démarrer une tentative
 * — vérifiés trois fois dans cette même fonction (lecture initiale, juste
 * avant de renvoyer une tentative reprise, et sur lecture fraîche dans la
 * transaction finale) parce que chacun peut devenir obsolète pendant les
 * appels asynchrones entre deux (requête sur la banque de questions...).
 * Un compte suspendu (docs/regles-messagerie-securite.md section 3)
 * n'avait ni "active" ni "review_requested" comme filtrageStatus, donc
 * passerait les deux premières gardes sans problème : retenter (et
 * réussir) le questionnaire écraserait filtrageStatus par "active" dans
 * submitFiltrageAttempt.ts, levant la sanction sans passer par
 * resolveSanctionAppeal. Le filtrage ne doit jamais servir à ça. Le délai
 * anti-contournement (filtrageNextRetryAt) a la même fenêtre de
 * contournement : sans le revérifier aussi fraîchement, un second appel
 * en vol au moment où un rejet vient d'être soumis pourrait démarrer une
 * nouvelle tentative sans attendre le délai.
 */
function assertFiltrageStartAllowed(status: Record<string, unknown> | undefined): void {
  if (status?.filtrageStatus === "active") {
    throw new HttpsError("failed-precondition", "Le compte est déjà activé.");
  }
  if (status?.filtrageStatus === "review_requested") {
    throw new HttpsError("failed-precondition", "Une révision humaine est déjà en cours.");
  }
  requireNotSuspended(status);
  const nextRetryAt = status?.filtrageNextRetryAt as Timestamp | undefined;
  if (nextRetryAt && nextRetryAt.toMillis() > Date.now()) {
    throw new HttpsError("failed-precondition", "Le prochain essai n'est pas encore disponible.");
  }
}

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

  // Repli rapide ici (échoue tôt, avant de tirer des questions pour rien)
  // — les garanties réelles sont les deux revérifications sur lecture
  // fraîche plus bas, seules capables de fermer la fenêtre entre cette
  // lecture et un changement de statut survenu entre-temps.
  assertFiltrageStartAllowed(status);

  // Une tentative déjà en cours (ex. app fermée avant la fin) est reprise
  // à l'identique, jamais redémarrée avec un nouveau tirage — sinon on
  // pourrait relancer autant de fois que nécessaire pour tomber sur un
  // jeu de questions plus facile, sans aucun délai (docs/regles-du-projet.md
  // section 1, anti-contournement).
  const currentAttemptId = status?.filtrageCurrentAttemptId as string | undefined;
  if (currentAttemptId) {
    const existingAttemptSnap = await db.collection("filtrage_attempts").doc(currentAttemptId).get();
    const existingAttempt = existingAttemptSnap.data();
    if (existingAttempt && !existingAttempt.submittedAt) {
      const questionDocs = await Promise.all(
        (existingAttempt.questionIds as string[]).map((id) =>
          db.collection("filtrage_question_bank").doc(id).get(),
        ),
      );
      // Si une question tirée a été retirée de la banque depuis (ménage
      // de contenu, question désactivée...), on ne plante pas : on
      // abandonne cette tentative cassée et on repart sur un tirage
      // neuf plutôt que de bloquer l'utilisateur sans recours.
      const allQuestionsStillExist = questionDocs.every((doc) => doc.exists);
      if (allQuestionsStillExist) {
        // Relecture fraîche : le statut lu tout en haut de la fonction a
        // pu changer pendant les lectures ci-dessus (ex. suspension posée
        // entre-temps) — rien n'est écrit dans cette branche, donc une
        // simple relecture suffit, pas besoin d'une transaction.
        const freshSnap = await db.collection("user_status").doc(uid).get();
        assertFiltrageStartAllowed(freshSnap.data());
        return {
          attemptId: currentAttemptId,
          questions: questionDocs.map((doc) => {
            const data = doc.data()!;
            return {
              id: doc.id,
              theme: data.theme as string,
              question: data.question as string,
              options: data.options as string[],
            };
          }),
        };
      }
      await existingAttemptSnap.ref.delete();
      await db.collection("user_status").doc(uid).set(
        { filtrageCurrentAttemptId: null },
        { merge: true },
      );
    }
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

  // Les trois invariants ci-dessus (actif / révision en cours / suspendu)
  // sont revérifiés sur une lecture FRAÎCHE, dans la même transaction que
  // les deux écritures (tentative + statut) : la lecture tout en haut de
  // la fonction pouvait être obsolète de plusieurs centaines de ms (le
  // temps de la requête sur la banque de questions), et un admin a pu
  // entre-temps suspendre ce compte ou approuver sa révision de filtrage.
  // Tout dans une seule transaction évite aussi de laisser une tentative
  // orpheline en base si la revérification échoue après coup.
  //
  // Limite assumée restante, pré-existante et sans rapport avec les
  // sanctions : deux appels concurrents (double-tap, retry réseau) sans
  // filtrageCurrentAttemptId préalable peuvent chacun créer leur propre
  // tentative ; celle qui écrit en dernier gagne filtrageCurrentAttemptId,
  // l'autre reste orpheline mais reste soumettable (submitAttempt.ts la
  // retrouve par son propre id, pas via user_status) — aucune faille de
  // sécurité, juste une tentative en double possible dans de rares cas.
  // Une correction complète demanderait de renvoyer au perdant la
  // tentative du gagnant plutôt que d'en créer une seconde.
  const statusRef = db.collection("user_status").doc(uid);
  await db.runTransaction(async (tx) => {
    const freshStatusSnap = await tx.get(statusRef);
    assertFiltrageStartAllowed(freshStatusSnap.data());

    tx.set(attemptRef, {
      uid,
      questionIds: shuffled.map((doc) => doc.id),
      createdAt: FieldValue.serverTimestamp(),
      submittedAt: null,
      score: null,
      passed: null,
    });
    tx.set(statusRef, { filtrageStatus: "in_progress", filtrageCurrentAttemptId: attemptRef.id }, { merge: true });
  });

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
