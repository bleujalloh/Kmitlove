import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore } from "firebase-admin/firestore";

import { REGION } from "../config";
import { ENFORCE_APP_CHECK } from "../shared/appCheck";
import { cancelParticipationAndPromote } from "../shared/participation";

/**
 * Annulation d'une participation par le membre lui-même (spec Communauté
 * section 9 — "liste d'attente : remplacer une personne qui annule").
 * Si la place libérée était confirmée ("accepted"), la personne la plus
 * ancienne en liste d'attente est promue automatiquement dans la même
 * transaction : jamais une place qui reste vide alors qu'une liste
 * d'attente existe, et jamais deux personnes promues pour une seule
 * place libérée. La logique vit dans shared/participation.ts (partagée avec
 * la suppression de compte).
 */
export const cancelParticipation = onCall({ region: REGION, enforceAppCheck: ENFORCE_APP_CHECK }, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Connexion requise.");
  }
  const { postId } = request.data as { postId: string };
  if (!postId) {
    throw new HttpsError("invalid-argument", "postId manquant.");
  }
  const { promotedUid } = await cancelParticipationAndPromote(getFirestore(), postId, request.auth.uid);
  return { ok: true, promotedUid };
});
