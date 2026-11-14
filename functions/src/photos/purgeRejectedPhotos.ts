import { onSchedule } from "firebase-functions/v2/scheduler";
import { getFirestore, Timestamp } from "firebase-admin/firestore";
import { getStorage } from "firebase-admin/storage";

import { REGION, REJECTED_PHOTO_RETENTION_DAYS } from "../config";
import { isProfilePhotoPath } from "../shared/storagePaths";

/**
 * Minimisation des données (RGPD, docs/rgpd-registre-des-traitements.md
 * §7) : une photo refusée n'a plus aucune utilité (jamais visible des
 * autres membres) — elle est supprimée, fichier Storage puis document,
 * REJECTED_PHOTO_RETENTION_DAYS jours après son refus. Le membre peut la
 * supprimer lui-même à tout moment avant (bouton de la visionneuse du
 * Profil). Décision du propriétaire (13/11/2026) : aucun recours humain
 * pour les photos, donc rien à suspendre pendant ce délai.
 *
 * Date du refus = `reviewedAt` (refus d'un modérateur), sinon
 * `moderatedAt` (refus automatique), sinon `uploadedAt` (anciens
 * documents sans ces dates). La requête s'appuie sur `uploadedAt`
 * (index existant status + uploadedAt) : une photo refusée ne peut pas
 * l'avoir été avant son envoi, donc ce sont des candidats sûrs, affinés
 * ensuite par la vraie date de refus.
 */
const MAX_PER_RUN = 500;

export const purgeRejectedPhotos = onSchedule(
  { schedule: "every 24 hours", region: REGION, timeoutSeconds: 540 },
  async () => {
    const db = getFirestore();
    const bucket = getStorage().bucket();
    const cutoffMs = Date.now() - REJECTED_PHOTO_RETENTION_DAYS * 24 * 60 * 60 * 1000;

    const snap = await db
      .collectionGroup("photos")
      .where("status", "==", "rejected")
      .where("uploadedAt", "<=", Timestamp.fromMillis(cutoffMs))
      .limit(MAX_PER_RUN)
      .get();

    for (const doc of snap.docs) {
      const photo = doc.data();
      const rejectedAt = (photo.reviewedAt ?? photo.moderatedAt ?? photo.uploadedAt) as Timestamp | undefined;
      if (!rejectedAt || rejectedAt.toMillis() > cutoffMs) continue;
      try {
        // Fichier d'abord : si sa suppression échoue (autre chose qu'un
        // fichier déjà absent), le document reste et la photo sera
        // retentée demain, au lieu de laisser un fichier orphelin sans
        // plus aucune référence pour le retrouver.
        // Le chemin vient d'un document écrit par le client : on ne supprime
        // que dans le dossier de photos de CE membre (shared/storagePaths.ts).
        if (isProfilePhotoPath(photo.storagePath, doc.ref.parent.parent?.id)) {
          await bucket.file(photo.storagePath).delete({ ignoreNotFound: true });
        }
        await doc.ref.delete();
      } catch (err) {
        // eslint-disable-next-line no-console
        console.error("purgeRejectedPhotos: suppression impossible, retentée demain", {
          photoPath: doc.ref.path,
          err,
        });
      }
    }
  },
);
