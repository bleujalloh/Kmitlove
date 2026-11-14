import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore, FieldValue, Timestamp } from "firebase-admin/firestore";

import { REGION, FILTRAGE_RETRY_DELAY_DAYS } from "../config";
import { ENFORCE_APP_CHECK } from "../shared/appCheck";
import { requireAdmin } from "../shared/requireAdmin";
import { logAdminAction } from "../shared/adminLog";

interface ResolveData {
  requestId: string;
  approve: boolean;
}

/**
 * Traite une demande de révision humaine après échec du questionnaire
 * de filtrage (docs/regles-du-projet.md section 1 — droit de recours).
 */
export const resolveFiltrageReview = onCall({ region: REGION, enforceAppCheck: ENFORCE_APP_CHECK }, async (request) => {
  const adminUid = requireAdmin(request);
  const { requestId, approve } = request.data as ResolveData;
  if (!requestId) {
    throw new HttpsError("invalid-argument", "requestId manquant.");
  }

  const db = getFirestore();
  const requestRef = db.collection("moderation_requests").doc(requestId);
  const requestSnap = await requestRef.get();
  const data = requestSnap.data();
  if (!data || data.type !== "filtrage_review") {
    throw new HttpsError("not-found", "Demande de révision introuvable.");
  }

  const uid = data.uid as string;
  if (approve) {
    await db.collection("user_status").doc(uid).set(
      {
        filtrageStatus: "active",
        filtrageActivatedAt: FieldValue.serverTimestamp(),
        filtrageNextRetryAt: null,
      },
      { merge: true },
    );
  } else {
    // Même délai qu'un rejet "normal" (submitAttempt.ts) : sans ça, le
    // délai d'origine (fixé au moment de l'échec initial) pourrait déjà
    // être écoulé le temps qu'un admin traite la demande, permettant de
    // retenter immédiatement sans aucun délai anti-contournement.
    const nextRetryAt = Timestamp.fromMillis(
      Date.now() + FILTRAGE_RETRY_DELAY_DAYS * 24 * 60 * 60 * 1000,
    );
    await db.collection("user_status").doc(uid).set(
      { filtrageStatus: "rejected_pending_retry", filtrageNextRetryAt: nextRetryAt },
      { merge: true },
    );
  }

  await requestRef.update({
    resolved: true,
    resolvedAt: FieldValue.serverTimestamp(),
    resolvedBy: adminUid,
    approved: approve,
  });

  await logAdminAction(db, {
    adminUid,
    action: approve ? "filtrage_review_approved" : "filtrage_review_denied",
    targetUid: uid,
  });

  return { ok: true };
});
