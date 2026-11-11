import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { FieldValue } from "firebase-admin/firestore";

import { REGION } from "../config";
import { analyzePhotoContent } from "../shared/photoModeration";

/**
 * Modération automatique du contenu à l'upload d'une photo (sur demande
 * explicite du propriétaire, 11/11/2026) : avant ce correctif, aucun
 * contrôle automatique de contenu n'existait — seule la revue humaine ou
 * l'approbation automatique après 48h (autoApprovePhotos.ts) décidaient,
 * ce qui laissait passer une photo inappropriée non vue à temps par un
 * admin. Se déclenche à la création du document de suivi (après l'envoi
 * du fichier à Storage côté client, PhotoRepository.uploadPhoto — le
 * fichier existe donc déjà quand ce déclencheur Firestore se lance,
 * contrairement à un déclencheur Storage qui pourrait arriver dans un
 * ordre différent).
 *
 * Pas de `retry: true` ici (volontaire) : un retry Eventarc pourrait
 * recommencer à partir de plusieurs minutes/heures jusqu'à 7 jours,
 * facturé à chaque tentative — si l'appel Vision échoue (quota,
 * réseau...), le document reste simplement "pending" sans `moderatedAt`,
 * et autoApprovePhotos.ts (qui tourne déjà toutes les heures) retente
 * lui-même l'analyse avant d'approuver — un seul mécanisme de rattrapage
 * au lieu de deux qui se superposeraient.
 */
export const moderatePhotoContent = onDocumentCreated(
  { document: "users/{userId}/photos/{photoId}", region: REGION },
  async (event) => {
    const snap = event.data;
    if (!snap) return;
    const photo = snap.data();
    // Garde-fou : ce document n'est censé être créé qu'au statut
    // "pending" (firestore.rules) et toujours avec un storagePath — mais
    // jamais une confiance aveugle à cette forme attendue.
    if (photo.status !== "pending" || typeof photo.storagePath !== "string") return;

    const { hasFace, safeSearch, flaggedCategory } = await analyzePhotoContent(photo.storagePath);

    // Relu juste avant d'écrire : avec `retry: true`, une tentative
    // retardée (après un échec transitoire) pourrait sinon écraser une
    // décision déjà prise entre-temps par un admin (adminReviewPhoto.ts)
    // ou par autoApprovePhotos.ts avec les données périmées de
    // l'événement d'origine (trouvé par revue de code).
    const liveSnap = await snap.ref.get();
    if (liveSnap.data()?.status !== "pending") return;

    await snap.ref.update({
      hasFace,
      safeSearch,
      moderatedAt: FieldValue.serverTimestamp(),
      // Rejet immédiat (spec section 1), sans attendre la revue humaine
      // ni le délai de 48h — distinct de `hasFace`, condition réelle de
      // visibilité dans Découvrir (getCandidates.ts), calculée dans tous
      // les cas, même quand la photo n'est pas rejetée.
      ...(flaggedCategory
        ? { status: "rejected", rejectedBy: "auto_moderation", rejectionReason: flaggedCategory }
        : {}),
    });
  },
);
