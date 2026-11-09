import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore, FieldValue } from "firebase-admin/firestore";

import { REGION } from "../config";
import { requireAdmin } from "../shared/requireAdmin";

/** Liste les signalements/demandes de révision non résolus (section 6). */
export const adminListModerationRequests = onCall({ region: REGION }, async (request) => {
  requireAdmin(request);
  const db = getFirestore();
  const snap = await db
    .collection("moderation_requests")
    .where("resolved", "==", false)
    .orderBy("createdAt", "asc")
    .limit(50)
    .get();
  return { requests: snap.docs.map((d) => ({ id: d.id, ...d.data() })) };
});

interface ResolveData {
  requestId: string;
  action: "dismiss" | "warn" | "suspend";
}

/**
 * Traite un signalement (docs/regles-economie-et-compatibilite.md
 * section 3 : escalade avertissement → suspension → recours). Reste
 * simplifié par rapport à l'escalade à 3 paliers complète (pas de
 * comptage automatique des signalements précédents) — à affiner.
 */
export const adminResolveModerationRequest = onCall({ region: REGION }, async (request) => {
  const adminUid = requireAdmin(request);
  const { requestId, action } = request.data as ResolveData;
  if (!requestId || !["dismiss", "warn", "suspend"].includes(action)) {
    throw new HttpsError("invalid-argument", "Paramètres invalides.");
  }

  const db = getFirestore();
  const requestRef = db.collection("moderation_requests").doc(requestId);
  const requestSnap = await requestRef.get();
  const data = requestSnap.data();
  if (!data) {
    throw new HttpsError("not-found", "Signalement introuvable.");
  }
  if (data.type === "filtrage_review") {
    throw new HttpsError(
      "invalid-argument",
      "Une révision de filtrage se traite avec resolveFiltrageReview, pas ici.",
    );
  }

  const targetUid = data.targetUid as string | undefined;
  if (action === "suspend" && targetUid) {
    await db.collection("user_status").doc(targetUid).set(
      { filtrageStatus: "suspended", suspendedAt: FieldValue.serverTimestamp() },
      { merge: true },
    );
  }

  await requestRef.update({
    resolved: true,
    resolvedAt: FieldValue.serverTimestamp(),
    resolvedBy: adminUid,
    action,
  });

  return { ok: true };
});
