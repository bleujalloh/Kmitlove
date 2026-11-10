import { onSchedule } from "firebase-functions/v2/scheduler";
import { getFirestore, Timestamp } from "firebase-admin/firestore";

import { REGION, PHOTO_AUTO_APPROVE_HOURS } from "../config";
import { updateRefsInChunks } from "../shared/batchWrite";

/**
 * Approuve automatiquement toute photo encore "pending" après le délai
 * maximal garanti (docs/regles-messagerie-securite.md section 1) —
 * tourne toutes les heures, pas de validation 100 % humaine puisque
 * personne n'est disponible en permanence pour modérer.
 */
export const autoApprovePhotos = onSchedule(
  { schedule: "every 60 minutes", region: REGION },
  async () => {
    const db = getFirestore();
    const cutoff = Timestamp.fromMillis(Date.now() - PHOTO_AUTO_APPROVE_HOURS * 60 * 60 * 1000);

    const snap = await db
      .collectionGroup("photos")
      .where("status", "==", "pending")
      .where("uploadedAt", "<=", cutoff)
      .limit(2000) // backlog éventuel traité sur plusieurs passages plutôt qu'en un seul lot géant
      .get();

    if (snap.empty) return;

    await updateRefsInChunks(
      db,
      snap.docs.map((d) => d.ref),
      { status: "approved", approvedBy: "auto_delay" },
    );
  },
);
