import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore, FieldValue } from "firebase-admin/firestore";

import { REGION } from "../config";
import { ENFORCE_APP_CHECK } from "../shared/appCheck";
import { requireAdmin } from "../shared/requireAdmin";
import { logAdminAction } from "../shared/adminLog";

/** Liste les demandes de statut organisateur en attente (spec Communauté section 3). */
export const adminListOrganizerRequests = onCall({ region: REGION, enforceAppCheck: ENFORCE_APP_CHECK }, async (request) => {
  requireAdmin(request);
  const db = getFirestore();
  const snap = await db
    .collection("user_status")
    .where("organizerStatus", "==", "pending")
    .orderBy("organizerRequestedAt", "asc")
    .limit(50)
    .get();
  return {
    requests: snap.docs.map((d) => ({
      uid: d.id,
      organizerName: d.data().organizerName,
      organizerDescription: d.data().organizerDescription,
    })),
  };
});

interface ReviewData {
  uid: string;
  approve: boolean;
}

/**
 * Validation humaine obligatoire avant toute première publication
 * d'événement (spec Communauté section 3) — aucun abonnement ne permet
 * de contourner ce contrôle, il n'y en a d'ailleurs pas pour l'instant.
 */
export const adminReviewOrganizerRequest = onCall({ region: REGION, enforceAppCheck: ENFORCE_APP_CHECK }, async (request) => {
  const adminUid = requireAdmin(request);
  const { uid, approve } = request.data as ReviewData;
  if (!uid) {
    throw new HttpsError("invalid-argument", "uid manquant.");
  }

  const db = getFirestore();
  const statusRef = db.collection("user_status").doc(uid);
  const statusSnap = await statusRef.get();
  if (statusSnap.data()?.organizerStatus !== "pending") {
    throw new HttpsError("failed-precondition", "Aucune demande en attente pour ce membre.");
  }

  await statusRef.set(
    {
      organizerStatus: approve ? "approved" : "rejected",
      organizerReviewedAt: FieldValue.serverTimestamp(),
      organizerReviewedBy: adminUid,
    },
    { merge: true },
  );

  await logAdminAction(db, {
    adminUid,
    action: approve ? "organizer_approved" : "organizer_rejected",
    targetUid: uid,
  });

  return { ok: true };
});

/**
 * Suspend le statut organisateur sans suspendre le compte entier (reste
 * membre, ne peut plus publier/gérer d'événements) — distinct de
 * adminSetSuspension (account/listUsers.ts), qui coupe tout accès.
 */
export const adminSuspendOrganizer = onCall({ region: REGION, enforceAppCheck: ENFORCE_APP_CHECK }, async (request) => {
  const adminUid = requireAdmin(request);
  const { uid } = request.data as { uid: string };
  if (!uid) {
    throw new HttpsError("invalid-argument", "uid manquant.");
  }

  const db = getFirestore();
  await db.collection("user_status").doc(uid).set(
    {
      organizerStatus: "suspended",
      organizerReviewedAt: FieldValue.serverTimestamp(),
      organizerReviewedBy: adminUid,
    },
    { merge: true },
  );

  await logAdminAction(db, { adminUid, action: "organizer_suspended", targetUid: uid });
  return { ok: true };
});
