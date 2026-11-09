import { onSchedule } from "firebase-functions/v2/scheduler";
import { getFirestore, Timestamp } from "firebase-admin/firestore";

import { REGION, PHOTO_AUTO_APPROVE_HOURS } from "../config";

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

    // Un lot Firestore est limité à 500 écritures : on découpe plutôt
    // que de risquer un retard indéfini si le retard de modération
    // dépasse cette taille.
    const chunkSize = 500;
    for (let i = 0; i < snap.docs.length; i += chunkSize) {
      const batch = db.batch();
      for (const doc of snap.docs.slice(i, i + chunkSize)) {
        batch.update(doc.ref, { status: "approved", approvedBy: "auto_delay" });
      }
      await batch.commit();
    }
  },
);
