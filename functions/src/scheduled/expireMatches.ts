import { onSchedule } from "firebase-functions/v2/scheduler";
import { getFirestore, Timestamp } from "firebase-admin/firestore";

import { REGION, MATCH_EXPIRY_DAYS } from "../config";
import { updateRefsInChunks } from "../shared/batchWrite";

/**
 * Marque "expiré" un match sans aucun message depuis 7 jours
 * (docs/regles-complementaires-concurrents.md section 3). Jamais
 * supprimé — juste déplacé visuellement dans l'app (champ `expired`),
 * récupérable en théorie.
 */
export const expireMatches = onSchedule(
  { schedule: "every 24 hours", region: REGION },
  async () => {
    const db = getFirestore();
    const cutoff = Timestamp.fromMillis(Date.now() - MATCH_EXPIRY_DAYS * 24 * 60 * 60 * 1000);

    const snap = await db
      .collection("matches")
      .where("lastMessageAt", "==", null)
      .where("createdAt", "<=", cutoff)
      .limit(2000)
      .get();

    if (snap.empty) return;

    const refs = snap.docs.filter((d) => d.data().expired !== true).map((d) => d.ref);
    await updateRefsInChunks(db, refs, { expired: true });
  },
);
