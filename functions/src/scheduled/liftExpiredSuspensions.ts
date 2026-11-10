import { onSchedule } from "firebase-functions/v2/scheduler";
import { getFirestore, Timestamp } from "firebase-admin/firestore";

import { REGION } from "../config";

/**
 * Lève automatiquement les suspensions TEMPORAIRES arrivées à échéance
 * (docs/regles-messagerie-securite.md section 3 : avertissement →
 * suspension temporaire → suspension définitive). Ne touche jamais un
 * compte banni définitivement (sanctionLevel="banned", exclu par le
 * premier filtre ci-dessous) ni un compte suspendu manuellement via
 * adminSetSuspension (sanctionLevel="suspended" comme une suspension de
 * l'échelle, mais suspendedUntil=null — indéfini —, qu'un filtre
 * Firestore "<= now" exclut toujours).
 *
 * Chaque document restaure SON PROPRE preSuspensionStatus (pas la même
 * valeur pour tous), donc une seule donnée ne peut pas être appliquée à
 * tous d'un coup comme le ferait updateRefsInChunks (shared/batchWrite.ts)
 * — mais un seul WriteBatch regroupe quand même les écritures (jusqu'à
 * 500, la limite d'un lot Firestore comme de ce `.limit()`) en une seule
 * requête réseau plutôt qu'une par document.
 */
export const liftExpiredSuspensions = onSchedule(
  { schedule: "every 24 hours", region: REGION },
  async () => {
    const db = getFirestore();
    const now = Timestamp.now();

    const snap = await db
      .collection("user_status")
      .where("sanctionLevel", "==", "suspended")
      .where("suspendedUntil", "<=", now)
      .limit(500)
      .get();

    if (snap.empty) return;

    const batch = db.batch();
    for (const doc of snap.docs) {
      const data = doc.data();
      batch.set(
        doc.ref,
        {
          filtrageStatus: data.preSuspensionStatus ?? "active",
          sanctionLevel: "none",
          suspendedUntil: null,
          preSuspensionStatus: null,
          // Efface aussi un éventuel recours resté sans réponse — sinon
          // appealPending resterait bloqué à true indéfiniment (plus
          // personne ne le remettra jamais à false, la suspension qu'il
          // visait n'existe plus) et empêcherait tout futur recours sur
          // une sanction ultérieure (account/requestSanctionAppeal.ts).
          appealPending: false,
          appealNextRetryAt: null,
        },
        { merge: true },
      );
    }
    await batch.commit();
  },
);
