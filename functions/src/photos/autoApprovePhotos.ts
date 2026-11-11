import { onSchedule } from "firebase-functions/v2/scheduler";
import { getFirestore, FieldValue, Timestamp } from "firebase-admin/firestore";

import { REGION, PHOTO_AUTO_APPROVE_HOURS } from "../config";
import { updateRefsInChunks } from "../shared/batchWrite";
import { analyzePhotoContent } from "../shared/photoModeration";

/**
 * Approuve automatiquement toute photo encore "pending" après le délai
 * maximal garanti (docs/regles-messagerie-securite.md section 1) —
 * tourne toutes les heures, pas de validation 100 % humaine puisque
 * personne n'est disponible en permanence pour modérer.
 *
 * Ne s'applique JAMAIS à une photo jamais réellement analysée par
 * moderatePhotoContent.ts (`moderatedAt` absent — ce déclencheur n'a pas
 * de retry automatique, volontairement, voir ce fichier ; ou document
 * créé avant ce correctif) : plutôt
 * que de l'approuver à l'aveugle (ce qui aurait exactement recréé la
 * faille que la modération automatique devait fermer), cette tâche
 * retente elle-même l'analyse avant toute approbation par délai.
 *
 * `timeoutSeconds` relevé (défaut 60s) : contrairement à avant (une
 * simple mise à jour en lot), un retard peut maintenant déclencher un
 * téléchargement Storage + un appel Vision par photo jamais analysée —
 * un backlog de plusieurs centaines de photos dépasserait largement
 * 60s. Traité par petits groupes concurrents plutôt qu'un par un pour
 * mieux utiliser ce temps.
 */
const ANALYSIS_CONCURRENCY = 10;

export const autoApprovePhotos = onSchedule(
  { schedule: "every 60 minutes", region: REGION, timeoutSeconds: 540 },
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

    const toApprove: FirebaseFirestore.DocumentReference[] = snap.docs
      .filter((doc) => doc.data().moderatedAt)
      .map((doc) => doc.ref);
    const needsAnalysis = snap.docs.filter((doc) => !doc.data().moderatedAt);

    for (let i = 0; i < needsAnalysis.length; i += ANALYSIS_CONCURRENCY) {
      const chunk = needsAnalysis.slice(i, i + ANALYSIS_CONCURRENCY);
      await Promise.all(
        chunk.map(async (doc) => {
          const photo = doc.data();
          if (typeof photo.storagePath !== "string") {
            return; // document mal formé, rien à analyser — laissé en attente
          }
          try {
            const { hasFace, safeSearch, flaggedCategory } = await analyzePhotoContent(photo.storagePath);
            if (flaggedCategory) {
              await doc.ref.update({
                hasFace,
                safeSearch,
                moderatedAt: FieldValue.serverTimestamp(),
                status: "rejected",
                rejectedBy: "auto_moderation",
                rejectionReason: flaggedCategory,
              });
            } else {
              await doc.ref.update({ hasFace, safeSearch, moderatedAt: FieldValue.serverTimestamp() });
              toApprove.push(doc.ref);
            }
          } catch (err) {
            // Échec persistant (quota Vision, image corrompue...) :
            // laissée "pending", retentée à la prochaine exécution
            // plutôt qu'approuvée sans jamais avoir été réellement
            // analysée.
            // eslint-disable-next-line no-console
            console.error("autoApprovePhotos: analyse impossible, photo laissée en attente", {
              photoId: doc.id,
              err,
            });
          }
        }),
      );
    }

    if (toApprove.length > 0) {
      await updateRefsInChunks(db, toApprove, { status: "approved", approvedBy: "auto_delay" });
    }
  },
);
