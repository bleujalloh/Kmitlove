import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import * as crypto from "crypto";

import {
  REGION,
  MAX_ACTIVE_ANNONCES_PER_USER,
  ANNONCE_FLAGGED_KEYWORDS,
  EVENT_CATEGORIES,
  EVENT_FORMATS,
  EVENT_ACCESS_MODES,
  EVENT_RECURRENCE_FREQUENCIES,
  EVENT_RECURRENCE_MAX_OCCURRENCES,
} from "../config";
import { isValidTimeZone } from "../shared/timezone";

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
  // Événements récurrents (spec section 10, complétée le 11/11/2026) :
  // périodicité fermée + nombre d'occurrences SUPPLÉMENTAIRES (en plus
  // de celle créée par cet appel), plafonné côté serveur.
  recurrence?: string;
  recurrenceCount?: number;
  // Fuseau IANA de l'organisateur au moment de la création (ex.
  // "Europe/Paris"), capturé côté client via flutter_timezone — jamais
  // une chaîne arbitraire : vérifiée contre la liste réelle du moteur
  // (shared/timezone.ts). Sert à calculer précisément l'heure de
  // déclenchement des rappels (scheduled/sendEventReminders.ts).
  timezone?: string;
}

const RECURRENCE_INTERVAL_DAYS: Record<string, number> = {
  hebdomadaire: 7,
  mensuel: 30,
};

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
    if (!data.timezone || !isValidTimeZone(data.timezone)) {
      throw new HttpsError("invalid-argument", "Fuseau horaire invalide.");
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

    if (data.recurrence) {
      if (!EVENT_RECURRENCE_FREQUENCIES.includes(data.recurrence as never)) {
        throw new HttpsError("invalid-argument", "Périodicité invalide.");
      }
      if (
        !Number.isInteger(data.recurrenceCount) ||
        data.recurrenceCount! < 1 ||
        data.recurrenceCount! > EVENT_RECURRENCE_MAX_OCCURRENCES
      ) {
        throw new HttpsError(
          "invalid-argument",
          `Nombre d'occurrences invalide (1 à ${EVENT_RECURRENCE_MAX_OCCURRENCES}).`,
        );
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

  const recurrenceFrequency = isEvent && data.recurrence ? data.recurrence : null;
  const intervalDays = recurrenceFrequency ? RECURRENCE_INTERVAL_DAYS[recurrenceFrequency] : 0;

  const postRef = db.collection("community_posts").doc();

  function writeOccurrence(
    tx: FirebaseFirestore.Transaction,
    ref: FirebaseFirestore.DocumentReference,
    occurrenceEventDate: string | null,
    occurrenceEventEndDate: string | null,
  ): void {
    tx.set(ref, {
      type: data.type,
      authorUid: uid,
      title: data.title ?? null,
      text: data.text.trim(),
      eventDate: occurrenceEventDate,
      eventEndDate: occurrenceEventEndDate,
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
      timezone: isEvent ? data.timezone : null,
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
      // Série récurrente (spec section 10) : même recurrenceGroupId pour
      // toutes les occurrences (l'id de la première), null sinon — permet
      // au client de retrouver les autres dates de la même série.
      recurrenceGroupId: recurrenceFrequency ? postRef.id : null,
      recurrenceFrequency,
    });

    if (needsPreciseLocation) {
      tx.set(ref.collection("private").doc("location"), {
        preciseLocation: data.preciseLocation!.trim(),
      });
    }
    if (accessMode === "sur_invitation") {
      // Jamais sur le document public : la liste des invités révélerait
      // qui est convié à un événement privé à n'importe quel membre
      // connecté qui le lirait (règlement permanent section 6). Un code
      // de partage distinct par occurrence (partage privé, spec section
      // 2) permet à l'organisateur de transmettre une invitation sans
      // rendre l'événement public ni connaître l'uid du destinataire à
      // l'avance (redeemEventInviteCode.ts).
      const shareCode = crypto.randomBytes(5).toString("hex").toUpperCase();
      tx.set(ref.collection("private").doc("invitations"), { invitedUids, shareCode });
      tx.set(db.collection("event_invite_codes").doc(shareCode), { postId: ref.id });
    }
  }

  // Toutes les occurrences d'une série récurrente sont écrites dans UNE
  // seule transaction (trouvé par revue de code : des écritures
  // séquentielles indépendantes pouvaient laisser une série à moitié
  // créée, sans retour en arrière, si la fonction échouait au milieu).
  // Largement sous la limite de 500 écritures d'une transaction Firestore
  // (au plus 7 occurrences × 4 écritures chacune).
  await db.runTransaction(async (tx) => {
    writeOccurrence(tx, postRef, data.eventDate ?? null, data.eventEndDate ?? null);

    if (recurrenceFrequency && data.recurrenceCount) {
      const baseStart = Date.parse(data.eventDate!);
      const baseEnd = data.eventEndDate ? Date.parse(data.eventEndDate) : null;
      for (let i = 1; i <= data.recurrenceCount; i += 1) {
        const offsetMs = intervalDays * i * 24 * 60 * 60 * 1000;
        const occurrenceRef = db.collection("community_posts").doc();
        // `.toISOString()` ajoute toujours un "Z" final (heure UTC
        // absolue), alors que `data.eventDate` lui-même n'en a jamais un
        // (heure murale naïve écrite par le client) — un format différent
        // pour les occurrences suivantes aurait été interprété
        // différemment par zonedWallTimeToUtcMillis.ts ET par
        // `DateTime.tryParse` côté client (trouvé par revue de code).
        // L'heure murale (heures:minutes:secondes) reste exacte malgré ce
        // retrait : l'arithmétique ci-dessus ajoute un nombre entier de
        // jours en millisecondes, et toISOString() restitue toujours ces
        // mêmes heure/minute/seconde, jour après jour, sans dérive.
        writeOccurrence(
          tx,
          occurrenceRef,
          new Date(baseStart + offsetMs).toISOString().replace("Z", ""),
          baseEnd !== null ? new Date(baseEnd + offsetMs).toISOString().replace("Z", "") : null,
        );
      }
    }
  });

  return { postId: postRef.id, status };
});
