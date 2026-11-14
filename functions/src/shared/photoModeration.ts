import { isProfilePhotoPath } from "./storagePaths";
import { getStorage } from "firebase-admin/storage";
import { ImageAnnotatorClient } from "@google-cloud/vision";

import { SAFE_SEARCH_CATEGORIES_TO_CHECK, SAFE_SEARCH_REJECT_LIKELIHOOD, FACE_DETECTION_MIN_CONFIDENCE } from "../config";

const visionClient = new ImageAnnotatorClient();

const LIKELIHOOD_ORDER = ["UNKNOWN", "VERY_UNLIKELY", "UNLIKELY", "POSSIBLE", "LIKELY", "VERY_LIKELY"];

// Le client Vision type ce champ comme une union chaîne/enum numérique
// selon le mode de sérialisation, mais renvoie en pratique toujours le
// nom de la chaîne (vérifié directement contre l'API réelle, ex.
// "VERY_UNLIKELY") — `String(...)` absorbe l'écart de type sans jamais
// changer le comportement réel.
function meetsOrExceeds(value: unknown, threshold: string): boolean {
  const stringValue = value == null ? "UNKNOWN" : String(value);
  const valueIndex = LIKELIHOOD_ORDER.indexOf(stringValue);
  if (valueIndex === -1) {
    // Valeur jamais vue (changement de représentation de l'API...) :
    // échec FERMÉ, pas ouvert — mieux vaut une photo renvoyée en revue
    // humaine à tort qu'un contenu inapproprié qui passerait
    // silencieusement parce qu'une valeur inconnue a été ignorée.
    // eslint-disable-next-line no-console
    console.error(`photoModeration: valeur SafeSearch inconnue reçue : "${stringValue}"`);
    return true;
  }
  return valueIndex >= LIKELIHOOD_ORDER.indexOf(threshold);
}

export interface PhotoModerationResult {
  hasFace: boolean;
  safeSearch: { adult: string | null; racy: string | null; violence: string | null };
  flaggedCategory: string | null;
}

/**
 * Analyse Vision d'une photo de profil (SafeSearch + détection de
 * visage, demande explicite du propriétaire, 11/11/2026) — un seul
 * appel Vision par photo, réutilisé à la fois par le déclencheur
 * automatique à l'upload (moderatePhotoContent.ts), par le rattrapage
 * planifié (autoApprovePhotos.ts, pour toute photo jamais vraiment
 * analysée) et par la revue manuelle admin (adminReviewPhoto.ts, même
 * raison) — AUCUN chemin vers le statut "approved" ne doit jamais
 * contourner ce contrôle.
 */
export async function analyzePhotoContent(storagePath: string): Promise<PhotoModerationResult> {
  // Le chemin vient d'un document écrit par le client : jamais lu tel quel
  // (shared/storagePaths.ts).
  if (!isProfilePhotoPath(storagePath)) {
    throw new Error("Chemin de photo invalide : analyse refusée.");
  }
  const bucket = getStorage().bucket();
  const [buffer] = await bucket.file(storagePath).download();

  const [result] = await visionClient.annotateImage({
    image: { content: buffer },
    features: [{ type: "SAFE_SEARCH_DETECTION" }, { type: "FACE_DETECTION" }],
  });

  // Erreur propre à CETTE image renvoyée par Vision avec un succès HTTP
  // (ex. "Bad image data") — jamais traitée comme "rien détecté donc
  // sûr" (échec ouvert) : l'appelant doit la traiter comme un échec
  // d'analyse, pas comme une photo propre.
  if (result.error?.message) {
    throw new Error(`Vision n'a pas pu analyser l'image : ${result.error.message}`);
  }

  const safeSearch = result.safeSearchAnnotation;
  if (!safeSearch) {
    // Résultat SafeSearch totalement absent (échec partiel de l'API sans
    // `result.error`) — jamais traité comme "rien à signaler donc sûr"
    // (échec ouvert), même raisonnement que la vérification de
    // `result.error` plus haut.
    throw new Error("Vision n'a renvoyé aucun résultat SafeSearch.");
  }
  const flaggedCategory =
    SAFE_SEARCH_CATEGORIES_TO_CHECK.find((category) =>
      meetsOrExceeds(safeSearch[category], SAFE_SEARCH_REJECT_LIKELIHOOD),
    ) ?? null;

  const hasFace = (result.faceAnnotations ?? []).some(
    (face) => (face.detectionConfidence ?? 0) >= FACE_DETECTION_MIN_CONFIDENCE,
  );

  return {
    hasFace,
    safeSearch: {
      adult: safeSearch.adult ? String(safeSearch.adult) : null,
      racy: safeSearch.racy ? String(safeSearch.racy) : null,
      violence: safeSearch.violence ? String(safeSearch.violence) : null,
    },
    flaggedCategory,
  };
}
