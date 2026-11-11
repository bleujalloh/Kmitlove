import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore, FieldValue } from "firebase-admin/firestore";

import {
  REGION,
  MAX_ACTIVE_ANNONCES_PER_USER,
  ANNONCE_FLAGGED_KEYWORDS,
  EVENT_CATEGORIES,
  EVENT_FORMATS,
  EVENT_ACCESS_MODES,
} from "../config";

type PostType =
  | "publication"
  | "annonce_publique"
  | "annonce_privee"
  | "annonce_libre"
  | "evenement_public"
  | "evenement_prive";

const VALID_TYPES: PostType[] = [
  "publication",
  "annonce_publique",
  "annonce_privee",
  "annonce_libre",
  "evenement_public",
  "evenement_prive",
];

// Annonce libre : un 4e type d'annonce, texte libre sans lieu ni date,
// modérée et comptée comme les autres annonces (docs/regles-annonces-evenements.md).
const ANNONCE_TYPES: PostType[] = ["annonce_publique", "annonce_privee", "annonce_libre"];

const MAX_SHORT_TEXT = 80;
const MAX_CONDITIONS_LENGTH = 400;

interface CreatePostData {
  type: PostType;
  title?: string;
  text: string;
  eventDate?: string; // ISO, requis pour les événements
  eventEndDate?: string; // ISO, optionnel (fiche événement section 6 : horaires début/fin)
  capacity?: number; // requis pour les événements
  preciseLocation?: string; // jamais stocké dans le document public
  // Spec Communauté du 11/11/2026, section 6 (fiche événement) :
  category?: string;
  format?: string;
  city?: string;
  country?: string;
  ageMinimum?: number;
  conditions?: string;
  contactChannel?: string;
  posterStoragePath?: string;
  // Section 2 : trois modes d'accès pour un événement privé.
  accessMode?: string;
  invitedUids?: string[];
  // Section 7 : événements liés à un même rendez-vous (conférence +
  // activités associées) — jamais un événement qui se lie lui-même, et
  // uniquement à un événement DÉJÀ publié par le même organisateur (pas
  // n'importe quel id deviné).
  parentEventId?: string;
}

function containsFlaggedKeyword(text: string): boolean {
  const lower = text.toLowerCase();
  return ANNONCE_FLAGGED_KEYWORDS.some((kw) => lower.includes(kw));
}

/**
 * Point d'entrée unique pour créer tout contenu de l'espace Communauté
 * (cahier des charges section 4.7). Applique la modération mixte, la
 * limite d'annonces actives et la réservation des événements aux
 * membres vérifiés (docs/regles-annonces-evenements.md) — jamais une
 * écriture directe depuis le client (firestore.rules).
 */
export const createCommunityPost = onCall({ region: REGION }, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Connexion requise.");
  }
  const uid = request.auth.uid;
  const data = request.data as CreatePostData;

  if (!VALID_TYPES.includes(data.type) || !data.text?.trim()) {
    throw new HttpsError("invalid-argument", "Données de publication invalides.");
  }

  const db = getFirestore();
  const isEvent = data.type === "evenement_public" || data.type === "evenement_prive";
  const isAnnonce = ANNONCE_TYPES.includes(data.type);
  const needsPreciseLocation = isEvent || data.type === "annonce_privee";

  // Rempli seulement pour les événements, utilisé plus bas pour écrire le
  // document final — jamais une liste fermée vérifiée côté client
  // (spec Communauté section 6, règlement permanent section 5).
  let accessMode: string | null = null;
  let invitedUids: string[] = [];
  let category: string | null = null;
  let format: string | null = null;

  if (isEvent) {
    if (
      !data.eventDate ||
      typeof data.capacity !== "number" ||
      !Number.isFinite(data.capacity) ||
      data.capacity <= 0
    ) {
      throw new HttpsError("invalid-argument", "Date et capacité (nombre positif) requises pour un événement.");
    }
    if (data.eventEndDate) {
      const endMillis = Date.parse(data.eventEndDate);
      if (Number.isNaN(endMillis)) {
        throw new HttpsError("invalid-argument", "Date de fin invalide.");
      }
      if (endMillis < Date.parse(data.eventDate)) {
        throw new HttpsError("invalid-argument", "La date de fin doit être après la date de début.");
      }
    }
    if (typeof data.category !== "string" || !EVENT_CATEGORIES.includes(data.category as never)) {
      throw new HttpsError("invalid-argument", "Catégorie invalide.");
    }
    category = data.category;
    if (typeof data.format !== "string" || !EVENT_FORMATS.includes(data.format as never)) {
      throw new HttpsError("invalid-argument", "Format invalide.");
    }
    format = data.format;
    if (!data.city?.trim() || !data.country?.trim()) {
      throw new HttpsError("invalid-argument", "Ville et pays requis (affichés publiquement, jamais l'adresse exacte).");
    }
    if (data.ageMinimum !== undefined && (!Number.isFinite(data.ageMinimum) || data.ageMinimum < 0 || data.ageMinimum > 99)) {
      throw new HttpsError("invalid-argument", "Âge minimum invalide.");
    }
    if (data.conditions && data.conditions.length > MAX_CONDITIONS_LENGTH) {
      throw new HttpsError("invalid-argument", "Conditions trop longues.");
    }
    if (data.contactChannel && data.contactChannel.length > MAX_SHORT_TEXT) {
      throw new HttpsError("invalid-argument", "Contact invalide.");
    }

    // Spec section 2 : un événement public est toujours à accès libre ;
    // un événement privé choisit entre "sur demande" et "sur invitation".
    if (data.type === "evenement_public") {
      accessMode = "public";
    } else {
      if (!data.accessMode || !EVENT_ACCESS_MODES.includes(data.accessMode as never) || data.accessMode === "public") {
        throw new HttpsError("invalid-argument", "Mode d'accès invalide pour un événement privé.");
      }
      accessMode = data.accessMode;
      if (accessMode === "sur_invitation") {
        invitedUids = Array.isArray(data.invitedUids)
          ? data.invitedUids.filter((u): u is string => typeof u === "string").slice(0, 200)
          : [];
      }
    }

    // Spec section 3 : validation admin obligatoire du statut
    // organisateur avant toute première publication d'événement — pas
    // d'abonnement pour l'instant (simplification validée par le
    // propriétaire le 11/11/2026), mais toujours un contrôle humain.
    const statusSnap = await db.collection("user_status").doc(uid).get();
    if (statusSnap.data()?.organizerStatus !== "approved") {
      throw new HttpsError(
        "permission-denied",
        "Seuls les organisateurs validés par un administrateur peuvent créer un événement.",
      );
    }

    if (data.parentEventId) {
      const parentSnap = await db.collection("community_posts").doc(data.parentEventId).get();
      const parent = parentSnap.data();
      if (!parent || parent.authorUid !== uid || !["evenement_public", "evenement_prive"].includes(parent.type)) {
        throw new HttpsError("invalid-argument", "Événement principal invalide.");
      }
    }
  }

  if (isAnnonce) {
    // Deux filtres "in" combinés ne sont pas fiables sur toutes les
    // versions du SDK Firestore : on filtre le statut en mémoire plutôt
    // que par une seconde clause "in" (le volume par utilisateur est de
    // toute façon petit, la limite elle-même l'impose).
    // Limité aux posts les plus récents : la limite de 3 annonces actives
    // garantit qu'elles sont forcément parmi les plus récentes, pas
    // besoin de lire tout l'historique d'un membre qui en aurait créé
    // des centaines au fil du temps.
    const activeSnap = await db
      .collection("community_posts")
      .where("authorUid", "==", uid)
      .where("type", "in", ANNONCE_TYPES)
      .orderBy("createdAt", "desc")
      .limit(20)
      .get();
    const activeCount = activeSnap.docs.filter((doc) =>
      ["published", "pending_review"].includes(doc.data().status),
    ).length;
    if (activeCount >= MAX_ACTIVE_ANNONCES_PER_USER) {
      throw new HttpsError(
        "resource-exhausted",
        `Maximum ${MAX_ACTIVE_ANNONCES_PER_USER} annonces actives à la fois.`,
      );
    }
  }

  if (needsPreciseLocation && !data.preciseLocation?.trim()) {
    throw new HttpsError("invalid-argument", "Lieu précis requis.");
  }

  // Modération mixte (docs/regles-annonces-evenements.md section 3) :
  // - publication (fil) : publiée immédiatement, post-modération.
  // - annonce : filtre automatique léger, revue humaine seulement en cas de doute.
  // - événement : toujours en attente d'une revue humaine, jamais publié seul.
  let status: "published" | "pending_review";
  if (data.type === "publication") {
    status = "published";
  } else if (isEvent) {
    status = "pending_review";
  } else {
    status = containsFlaggedKeyword(data.text) ? "pending_review" : "published";
  }

  const postRef = db.collection("community_posts").doc();
  await postRef.set({
    type: data.type,
    authorUid: uid,
    title: data.title ?? null,
    text: data.text.trim(),
    eventDate: data.eventDate ?? null,
    eventEndDate: data.eventEndDate ?? null,
    capacity: data.capacity ?? null,
    participantsCount: 0,
    status,
    createdAt: FieldValue.serverTimestamp(),
    // Fiche événement (spec Communauté section 6) — null pour les types
    // qui ne sont pas des événements.
    category,
    format,
    city: isEvent ? data.city!.trim() : null,
    country: isEvent ? data.country!.trim() : null,
    ageMinimum: data.ageMinimum ?? null,
    conditions: data.conditions?.trim() || null,
    contactChannel: data.contactChannel?.trim() || null,
    posterStoragePath: data.posterStoragePath ?? null,
    accessMode,
    parentEventId: data.parentEventId ?? null,
    // Statut fixé par l'organisateur, distinct du statut de modération
    // (spec section 6 : confirmé/complet/annulé/terminé) — "complet" se
    // déduit toujours de participantsCount/capacity, jamais stocké ici.
    eventState: isEvent ? "prevu" : null,
  });

  if (needsPreciseLocation) {
    await postRef.collection("private").doc("location").set({
      preciseLocation: data.preciseLocation!.trim(),
    });
  }
  if (accessMode === "sur_invitation") {
    // Jamais sur le document public : la liste des invités révélerait
    // qui est convié à un événement privé à n'importe quel membre
    // connecté qui le lirait (règlement permanent section 6).
    await postRef.collection("private").doc("invitations").set({ invitedUids });
  }

  return { postId: postRef.id, status };
});
