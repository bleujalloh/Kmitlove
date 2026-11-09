import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore, FieldValue } from "firebase-admin/firestore";

import { REGION, MAX_ACTIVE_ANNONCES_PER_USER, ANNONCE_FLAGGED_KEYWORDS } from "../config";

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

interface CreatePostData {
  type: PostType;
  title?: string;
  text: string;
  eventDate?: string; // ISO, requis pour les événements
  capacity?: number; // requis pour les événements
  preciseLocation?: string; // jamais stocké dans le document public
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

  if (isEvent) {
    if (
      !data.eventDate ||
      typeof data.capacity !== "number" ||
      !Number.isFinite(data.capacity) ||
      data.capacity <= 0
    ) {
      throw new HttpsError("invalid-argument", "Date et capacité (nombre positif) requises pour un événement.");
    }
    const statusSnap = await db.collection("user_status").doc(uid).get();
    if (statusSnap.data()?.isVerified !== true) {
      throw new HttpsError(
        "permission-denied",
        "Seuls les membres vérifiés peuvent organiser un événement physique.",
      );
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
    capacity: data.capacity ?? null,
    participantsCount: 0,
    status,
    createdAt: FieldValue.serverTimestamp(),
  });

  if (needsPreciseLocation) {
    await postRef.collection("private").doc("location").set({
      preciseLocation: data.preciseLocation!.trim(),
    });
  }

  return { postId: postRef.id, status };
});
