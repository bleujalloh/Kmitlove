import { HttpsError } from "firebase-functions/v2/https";
import { onCallNoConsent as onCall } from "../shared/callable";
import { getFirestore, FieldValue } from "firebase-admin/firestore";

import { REGION, REPORT_RATE_LIMITS, MAX_REPORT_DETAILS } from "../config";
import { ENFORCE_APP_CHECK } from "../shared/appCheck";
import { REPORT_REASONS, HIGH_SEVERITY_REASONS } from "../shared/reportReasons";
import { enforceRateLimit } from "../shared/rateLimit";

/** Signalement d'une publication/annonce/événement (section 4.7 + 4.8). */
export const reportCommunityPost = onCall({ region: REGION, enforceAppCheck: ENFORCE_APP_CHECK }, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Connexion requise.");
  }
  const uid = request.auth.uid;
  const { postId, reason, details, replyId } = request.data as {
    postId: string;
    reason: string;
    details?: string;
    replyId?: string;
  };
  if (
    typeof postId !== "string" ||
    !postId ||
    !REPORT_REASONS.includes(reason as (typeof REPORT_REASONS)[number]) ||
    (details !== undefined && details !== null && (typeof details !== "string" || details.length > MAX_REPORT_DETAILS)) ||
    (replyId !== undefined && replyId !== null && typeof replyId !== "string")
  ) {
    throw new HttpsError("invalid-argument", "Motif de signalement invalide.");
  }

  const db = getFirestore();
  // Résolu dès la création (pas seulement au traitement admin) pour que
  // l'escalade sache tout de suite qui viser, et pour que l'admin voie
  // "Visé : X" sans devoir rouvrir la publication (docs/regles-messagerie-
  // securite.md section 3 : compteur tous domaines confondus).
  const postSnap = await db.collection("community_posts").doc(postId).get();
  let targetUid = postSnap.data()?.authorUid as string | undefined;
  // Signalement d'une réponse : le membre visé est l'auteur de la réponse,
  // pas celui de la publication.
  if (replyId) {
    const replySnap = await postSnap.ref.collection("replies").doc(replyId).get();
    if (!replySnap.exists) {
      throw new HttpsError("not-found", "Réponse introuvable.");
    }
    targetUid = replySnap.data()?.authorUid as string | undefined;
  }

  // La limite de fréquence passe APRÈS les validations : un appel refusé
  // (réponse introuvable, champ invalide) ne consomme aucun quota.
  await enforceRateLimit(uid, REPORT_RATE_LIMITS);

  const targetStatusSnap = targetUid ? await db.collection("user_status").doc(targetUid).get() : null;
  const alreadyPriority = targetStatusSnap?.data()?.priorityReview === true;
  const priority = alreadyPriority || HIGH_SEVERITY_REASONS.has(reason);

  await db.collection("moderation_requests").add({
    type: "post_report",
    reporterUid: uid,
    postId,
    replyId: replyId ?? null,
    targetUid: targetUid ?? null,
    reason,
    details: details ?? null,
    priority,
    createdAt: FieldValue.serverTimestamp(),
    resolved: false,
  });

  return { ok: true };
});
