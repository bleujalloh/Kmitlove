import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore } from "firebase-admin/firestore";

import {
  REGION,
  COMPAT_THEME_WEIGHTS,
  COMPAT_MIN_THEME_COVERAGE,
  COMPAT_SCALE_MIN,
  COMPAT_SCALE_MAX,
} from "../config";

interface ComputeData {
  targetUid: string;
}

/**
 * Calcule le score de compatibilité entre l'appelant et un autre membre
 * (docs/regles-economie-et-compatibilite.md section 2). Les réponses
 * détaillées des deux membres ne sortent jamais de cette fonction — seul
 * le score arrondi est renvoyé.
 */
export const computeCompatibility = onCall({ region: REGION }, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Connexion requise.");
  }
  const { targetUid } = request.data as ComputeData;
  if (!targetUid) {
    throw new HttpsError("invalid-argument", "targetUid manquant.");
  }
  const uid = request.auth.uid;
  const db = getFirestore();

  const [mySnap, theirSnap, bankSnap, targetUserSnap] = await Promise.all([
    db.collection("compat_answers").doc(uid).get(),
    db.collection("compat_answers").doc(targetUid).get(),
    db.collection("compat_question_bank").where("active", "==", true).get(),
    db.collection("users").doc(targetUid).get(),
  ]);

  // Contrôle de visibilité (cahier des charges section 4.3, docs/suivi-
  // developpement.md) : si la cible a explicitement désactivé sa
  // visibilité, aucun score n'est jamais calculé pour elle, pour
  // personne — visible par défaut (absence du champ), comme
  // `showReadReceipts`.
  if (targetUserSnap.data()?.compatAnswersVisible === false) {
    return { score: null };
  }

  // Les réponses sont écrites directement par le client (pas de "bonne
  // réponse" à cacher ici), donc jamais fiables sans validation : une
  // valeur hors de l'échelle 1-5, ou non numérique, fausserait le score
  // de toute personne comparée à ce membre si elle n'était pas filtrée.
  const sanitizeAnswers = (raw: unknown): Record<string, number> => {
    const result: Record<string, number> = {};
    if (typeof raw !== "object" || raw === null) return result;
    for (const [key, value] of Object.entries(raw as Record<string, unknown>)) {
      if (
        typeof value === "number" &&
        Number.isFinite(value) &&
        value >= COMPAT_SCALE_MIN &&
        value <= COMPAT_SCALE_MAX
      ) {
        result[key] = value;
      }
    }
    return result;
  };

  const myAnswers = sanitizeAnswers(mySnap.data()?.answers);
  const theirAnswers = sanitizeAnswers(theirSnap.data()?.answers);

  // Regroupe les questions par thème pour calculer un score par thème,
  // puis exclure ceux qui n'ont pas assez de réponses communes.
  const questionsByTheme = new Map<string, string[]>();
  for (const doc of bankSnap.docs) {
    const theme = doc.data().theme as string;
    if (!questionsByTheme.has(theme)) questionsByTheme.set(theme, []);
    questionsByTheme.get(theme)!.push(doc.id);
  }

  const scaleRange = COMPAT_SCALE_MAX - COMPAT_SCALE_MIN;
  let weightedSum = 0;
  let totalWeightUsed = 0;

  for (const [theme, questionIds] of questionsByTheme) {
    const similarities: number[] = [];
    for (const qId of questionIds) {
      const mine = myAnswers[qId];
      const theirs = theirAnswers[qId];
      if (mine === undefined || theirs === undefined) continue;
      const similarity = 1 - Math.abs(mine - theirs) / scaleRange;
      similarities.push(similarity);
    }

    const coverage = questionIds.length === 0 ? 0 : similarities.length / questionIds.length;
    if (coverage < COMPAT_MIN_THEME_COVERAGE) continue;

    const themeScore = similarities.reduce((a, b) => a + b, 0) / similarities.length;
    const weight = COMPAT_THEME_WEIGHTS[theme] ?? 0;
    weightedSum += themeScore * weight;
    totalWeightUsed += weight;
  }

  const score = totalWeightUsed === 0 ? null : weightedSum / totalWeightUsed;

  return {
    score: score === null ? null : Math.round(score * 100),
  };
});
