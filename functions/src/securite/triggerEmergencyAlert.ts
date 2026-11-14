import { HttpsError } from "firebase-functions/v2/https";
import { onCallNoConsent as onCall } from "../shared/callable";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import type { DocumentSnapshot } from "firebase-admin/firestore";

import { REGION } from "../config";
import { ENFORCE_APP_CHECK } from "../shared/appCheck";

interface EmergencyData {
  eventPostId?: string;
  matchId?: string;
}

function otherMember(snap: DocumentSnapshot | null | undefined, uid: string): string | null {
  const members = snap?.data()?.members as string[] | undefined;
  return members?.find((m) => m !== uid) ?? null;
}

/**
 * Bouton "Signaler un danger immédiat" (docs/regles-complementaires-
 * concurrents.md section 1). N'appelle jamais les secours automatiquement
 * — alerte la modération en priorité absolue (toujours en tête de la
 * file admin, voir adminListModerationRequests), avec le contexte le
 * plus récent disponible pour qu'elle puisse agir vite sans dépendre
 * uniquement de ce que le membre a eu le temps de taper.
 */
export const triggerEmergencyAlert = onCall({ region: REGION, enforceAppCheck: ENFORCE_APP_CHECK }, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Connexion requise.");
  }
  const uid = request.auth.uid;
  const { eventPostId, matchId } = (request.data ?? {}) as EmergencyData;
  const db = getFirestore();

  const [lastActiveMatchSnap, eventSnap, matchSnap] = await Promise.all([
    db
      .collection("matches")
      .where("members", "array-contains", uid)
      .orderBy("lastMessageAt", "desc")
      .limit(1)
      .get(),
    eventPostId ? db.collection("community_posts").doc(eventPostId).get() : Promise.resolve(null),
    matchId ? db.collection("matches").doc(matchId).get() : Promise.resolve(null),
  ]);

  const lastActiveMatch = lastActiveMatchSnap.docs[0];

  await db.collection("moderation_requests").add({
    type: "emergency_alert",
    reporterUid: uid,
    priority: true,
    createdAt: FieldValue.serverTimestamp(),
    resolved: false,
    context: {
      eventPostId: eventPostId ?? null,
      eventOrganizerUid: eventSnap?.data()?.authorUid ?? null,
      matchId: matchId ?? null,
      matchOtherUid: matchSnap ? otherMember(matchSnap, uid) : null,
      lastActiveMatchId: lastActiveMatch?.id ?? null,
      lastActiveMatchOtherUid: lastActiveMatch ? otherMember(lastActiveMatch, uid) : null,
    },
  });

  return { ok: true };
});
