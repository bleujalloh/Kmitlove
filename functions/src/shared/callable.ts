/* eslint-disable @typescript-eslint/no-explicit-any */
import { onCall as baseOnCall, HttpsError } from "firebase-functions/v2/https";
import type { CallableOptions, CallableRequest } from "firebase-functions/v2/https";

/**
 * `onCall` de toute l'application : même chose que celui de Firebase, avec une
 * vérification commune des données reçues AVANT d'appeler la fonction.
 *
 * Constat du 14/11/2026 (test de robustesse `scripts/smoke_all_callables.py`,
 * 57 plantages sur 305 appels) : une demande sans donnée, ou avec un champ de
 * mauvais type (un nombre à la place d'un identifiant), faisait planter la
 * fonction en « erreur interne » au lieu de répondre « paramètres invalides ».
 * Aucun membre n'avait signalé cela — l'appli ne fabrique jamais de telles
 * demandes — mais un client modifié ou un script les envoie, et un plantage
 * cache toujours un champ lu sans être vérifié.
 *
 * Règles appliquées ici, pour toutes les fonctions :
 *  - aucune donnée → objet vide (la fonction répond alors d'elle-même
 *    « manquant ») ; donnée qui n'est pas un objet → refusée ;
 *  - les champs qui désignent un document (`postId`, `uid`, `targetUid`...)
 *    doivent être du texte simple, sans « / » (sinon Firestore plante) ;
 *  - les champs de texte connus (`code`, `text`, `storagePath`...) doivent
 *    être du texte, de longueur raisonnable ;
 *  - les décisions oui/non (`approve`, `accept`, `suspend`...) doivent être de
 *    vrais booléens.
 */
const ID_FIELDS = [
  "postId",
  "uid",
  "targetUid",
  "matchId",
  "messageId",
  "replyId",
  "tipId",
  "requestId",
  "photoId",
  "userId",
  "parentEventId",
];
// Décisions oui/non : « "false" » (du texte) ne doit jamais valoir « oui » —
// avant ce contrôle, un « accept: "false" » accélérait la demande d'un membre
// (respondToParticipation) puisque tout texte non vide est « vrai » en
// JavaScript.
const BOOLEAN_FIELDS = ["approve", "accept", "suspend", "hidden", "granted", "clear"];
const TEXT_FIELDS = ["code", "text", "title", "body", "reason", "details", "storagePath", "query", "category"];
const MAX_ID_LENGTH = 200;
const MAX_TEXT_LENGTH = 50_000;

function invalid(): never {
  throw new HttpsError("invalid-argument", "Données invalides.");
}

function sanitizeRequestData(request: CallableRequest<any>): void {
  const data = request.data as unknown;
  if (data === null || data === undefined) {
    (request as { data: unknown }).data = {};
    return;
  }
  if (typeof data !== "object" || Array.isArray(data)) invalid();

  const fields = data as Record<string, unknown>;
  for (const key of ID_FIELDS) {
    const value = fields[key];
    if (value === undefined || value === null) continue;
    if (typeof value !== "string" || value.length > MAX_ID_LENGTH || value.includes("/")) invalid();
  }
  for (const key of BOOLEAN_FIELDS) {
    const value = fields[key];
    if (value === undefined || value === null) continue;
    if (typeof value !== "boolean") invalid();
  }
  for (const key of TEXT_FIELDS) {
    const value = fields[key];
    if (value === undefined || value === null) continue;
    if (typeof value !== "string" || value.length > MAX_TEXT_LENGTH) invalid();
  }
}

export function onCall<T = any, Return = any>(
  options: CallableOptions<T>,
  handler: (request: CallableRequest<T>) => Return,
) {
  return baseOnCall<T, Return>(options, (request) => {
    sanitizeRequestData(request);
    return handler(request);
  });
}
