import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore } from "firebase-admin/firestore";

import { REGION } from "../config";
import { computeAge } from "../shared/age";

const MIN_ADULT_AGE = 18;
const MAX_SHORT_TEXT = 60;
const MAX_NAME_LENGTH = 50;
const MAX_BIO_LENGTH = 500;
const MAX_LIST_ITEMS = 15;
const MIN_HEIGHT_CM = 100;
const MAX_HEIGHT_CM = 250;

// Listes fermées des choix possibles — source unique côté serveur. Les
// classes `Gender`/`RelationshipIntent`/`LifestyleHabit`/`ChildrenStatus`/
// `PersonalQuality` dans lib/features/profil/domain/profil.dart ne sont
// qu'un miroir pour l'affichage et la sélection à l'écran : elles ne
// doivent jamais être la seule barrière, sinon un client modifié (ou un
// appel direct à l'API Firestore, comme utilisé pour le seed de test ce
// jour) pourrait enregistrer un troisième genre ou une intention "relation
// libre" contraire au kemetisme — même principe que la confirmation d'âge
// (docs/suivi-developpement.md, section du 11/11/2026).
const GENDERS = ["Femme", "Homme"];
const RELATIONSHIP_INTENTS = [
  "relation_serieuse",
  "relation_durable_famille",
  "decouverte_amoureuse",
  "mariage",
];
const LIFESTYLE_HABITS = ["jamais", "parfois", "souvent"];
const CHILDREN_STATUSES = [
  "a_des_enfants",
  "veut_des_enfants",
  "ne_veut_pas_denfants",
  "ne_sait_pas_encore",
];
const QUALITIES = [
  "Drôle",
  "Ambitieux(se)",
  "Calme",
  "Aventurier(ère)",
  "Romantique",
  "Généreux(se)",
  "Sincère",
  "Spirituel(le)",
  "Attentionné(e)",
  "Déterminé(e)",
  "Créatif(ve)",
  "Loyal(e)",
  "Patient(e)",
  "Optimiste",
];

function invalid(field: string): never {
  throw new HttpsError("invalid-argument", `Champ invalide : ${field}.`);
}

function requiredText(value: unknown, field: string, maxLength: number): string {
  if (typeof value !== "string" || value.trim().length === 0 || value.length > maxLength) {
    invalid(field);
  }
  return (value as string).trim();
}

function optionalText(value: unknown, field: string, maxLength = MAX_SHORT_TEXT): string | null {
  if (value === null || value === undefined) return null;
  if (typeof value !== "string" || value.length > maxLength) invalid(field);
  const trimmed = (value as string).trim();
  return trimmed.length === 0 ? null : trimmed;
}

function freeTextList(value: unknown, field: string): string[] {
  if (value === null || value === undefined) return [];
  if (!Array.isArray(value) || value.length > MAX_LIST_ITEMS) invalid(field);
  const list = value as unknown[];
  if (!list.every((item) => typeof item === "string" && item.trim().length > 0 && item.length <= MAX_SHORT_TEXT)) {
    invalid(field);
  }
  return list.map((item) => (item as string).trim());
}

function closedList(value: unknown, field: string, allowed: string[]): string[] {
  if (value === null || value === undefined) return [];
  if (!Array.isArray(value) || value.length > allowed.length) invalid(field);
  const list = value as unknown[];
  if (!list.every((item) => typeof item === "string" && allowed.includes(item))) {
    invalid(field);
  }
  return list as string[];
}

function closedValue(value: unknown, field: string, allowed: string[]): string {
  if (typeof value !== "string" || !allowed.includes(value)) invalid(field);
  return value as string;
}

function optionalClosedValue(value: unknown, field: string, allowed: string[]): string | null {
  if (value === null || value === undefined) return null;
  return closedValue(value, field, allowed);
}

/**
 * Enregistre le profil public (`users/{uid}`) — remplace l'écriture
 * directe du client (firestore.rules n'accepte plus `create`/`update` sur
 * cette collection que via cette fonction, voir la règle correspondante)
 * pour que les choix fermés (genre, intention relationnelle, habitudes de
 * vie, qualités) et l'âge minimum soient réellement appliqués côté
 * serveur, pas seulement proposés par les écrans Flutter.
 */
export const saveProfil = onCall({ region: REGION }, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Connexion requise.");
  }
  const data = request.data as Record<string, unknown>;

  const displayName = requiredText(data.displayName, "displayName", MAX_NAME_LENGTH);

  if (typeof data.birthDate !== "string" || Number.isNaN(Date.parse(data.birthDate))) {
    invalid("birthDate");
  }
  const birthDate = data.birthDate as string;
  if (computeAge(birthDate) < MIN_ADULT_AGE) {
    // Même garde-fou que la confirmation d'âge à l'inscription Google/
    // Apple (cahier des charges section 2) — jamais seulement vérifié
    // côté client.
    throw new HttpsError("permission-denied", "Il faut avoir 18 ans ou plus pour utiliser l'application.");
  }

  const gender = closedValue(data.gender, "gender", GENDERS);
  const seekingGenders = closedList(data.seekingGenders, "seekingGenders", GENDERS);
  if (seekingGenders.length === 0) invalid("seekingGenders");

  const country = requiredText(data.country, "country", MAX_SHORT_TEXT);
  const city = requiredText(data.city, "city", MAX_SHORT_TEXT);
  const bio = requiredText(data.bio, "bio", MAX_BIO_LENGTH);
  const relationshipIntent = closedValue(data.relationshipIntent, "relationshipIntent", RELATIONSHIP_INTENTS);

  const profession = optionalText(data.profession, "profession");
  const languages = freeTextList(data.languages, "languages");
  const interests = freeTextList(data.interests, "interests");
  const culturalOrigins = freeTextList(data.culturalOrigins, "culturalOrigins");
  const values = optionalText(data.values, "values", MAX_BIO_LENGTH);

  let heightCm: number | null = null;
  if (data.heightCm !== null && data.heightCm !== undefined) {
    if (
      typeof data.heightCm !== "number" ||
      !Number.isFinite(data.heightCm) ||
      data.heightCm < MIN_HEIGHT_CM ||
      data.heightCm > MAX_HEIGHT_CM
    ) {
      invalid("heightCm");
    }
    heightCm = data.heightCm;
  }

  const educationLevel = optionalText(data.educationLevel, "educationLevel");
  const smokingHabit = optionalClosedValue(data.smokingHabit, "smokingHabit", LIFESTYLE_HABITS);
  const drinkingHabit = optionalClosedValue(data.drinkingHabit, "drinkingHabit", LIFESTYLE_HABITS);
  const childrenStatus = optionalClosedValue(data.childrenStatus, "childrenStatus", CHILDREN_STATUSES);
  const lookingFor = optionalText(data.lookingFor, "lookingFor", MAX_SHORT_TEXT);
  const qualities = closedList(data.qualities, "qualities", QUALITIES);

  // merge: true — users/{uid} porte aussi showReadReceipts et
  // compatAnswersVisible (écrits séparément par messages_repository.dart/
  // compat_repository.dart, voir l'exception dédiée dans firestore.rules) :
  // un .set() sans merge les effacerait silencieusement à chaque
  // modification de profil.
  await getFirestore()
    .collection("users")
    .doc(request.auth.uid)
    .set(
      {
        displayName,
        birthDate,
        gender,
        seekingGenders,
        country,
        city,
        // Normalisées en minuscules pour le filtre pays/ville de Découvrir
        // (getCandidates.ts) — une comparaison Firestore "==" est
        // sensible à la casse, et country/city restent du texte libre
        // saisi par chacun (pas de liste fermée ici, contrairement au
        // genre ou à l'intention relationnelle).
        countryLower: country.toLowerCase(),
        cityLower: city.toLowerCase(),
        bio,
        relationshipIntent,
        profession,
        languages,
        interests,
        culturalOrigins,
        values,
        heightCm,
        educationLevel,
        smokingHabit,
        drinkingHabit,
        childrenStatus,
        lookingFor,
        qualities,
      },
      { merge: true },
    );

  return { ok: true };
});
