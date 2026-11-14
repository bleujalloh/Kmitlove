import { HttpsError } from "firebase-functions/v2/https";
import { onCall } from "../shared/callable";
import { getFirestore, FieldValue } from "firebase-admin/firestore";

import { REGION } from "../config";
import { ENFORCE_APP_CHECK } from "../shared/appCheck";
import { computeAge } from "../shared/age";
import { GENDERS } from "../shared/genders";
import { VALID_COUNTRY_NAMES } from "../shared/validCountries";

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
// (docs/suivi-developpement.md, section du 11/11/2026). GENDERS vit
// maintenant dans shared/genders.ts (12/11/2026) : getCandidates.ts en a
// aussi besoin pour valider le nouveau filtre rapide "Tous/Hommes/Femmes"
// de Découvrir, jamais une seconde liste tenue à la main en parallèle.
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

// Insensible à la casse, contrairement à `closedValue` : des profils
// réels existent déjà en base avec un pays en minuscules ("france",
// trouvé en vérifiant les données réelles avant ce correctif, 12/11/2026
// — la ville a le même problème, signalé par le propriétaire), écrits
// avant que ce sélecteur fermé n'existe. Sans cette tolérance, modifier
// n'importe quel AUTRE champ de ces profils aurait échoué d'un coup à
// cause d'un champ jamais retouché par ce correctif-ci. Renvoie
// toujours l'orthographe canonique de `allowed`, donc une donnée
// ancienne se normalise au passage, au prochain enregistrement.
function closedValueCaseInsensitive(value: unknown, field: string, allowed: readonly string[]): string {
  if (typeof value !== "string") invalid(field);
  const match = allowed.find((a) => a.toLowerCase() === (value as string).toLowerCase());
  if (!match) invalid(field);
  return match;
}

// `city` reste du texte libre (aucune liste fermée, voir plus bas) :
// impossible de corriger sa casse avec certitude dans le cas général
// (ex. "Aix-en-Provence" a volontairement un "en" en minuscule). On ne
// corrige donc que le cas trouvé en vérifiant les données réelles avant
// ce correctif (12/11/2026) — une ville saisie entièrement en minuscule
// ("paris") — en capitalisant seulement la première lettre, jamais
// chaque mot. Une saisie déjà correctement capitalisée par l'utilisateur
// (ou par une suggestion de core/data/major_cities.dart côté client)
// n'est jamais modifiée.
function capitalizeFirstLetter(value: string): string {
  if (value.length === 0) return value;
  return value[0].toUpperCase() + value.slice(1);
}

/**
 * Enregistre le profil public (`users/{uid}`) — remplace l'écriture
 * directe du client (firestore.rules n'accepte plus `create`/`update` sur
 * cette collection que via cette fonction, voir la règle correspondante)
 * pour que les choix fermés (genre, intention relationnelle, habitudes de
 * vie, qualités) et l'âge minimum soient réellement appliqués côté
 * serveur, pas seulement proposés par les écrans Flutter.
 */
export const saveProfil = onCall({ region: REGION, enforceAppCheck: ENFORCE_APP_CHECK }, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Connexion requise.");
  }
  const data = request.data as Record<string, unknown>;
  const db = getFirestore();
  const uid = request.auth.uid;

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

  // Genre et date de naissance sont fixés à l'inscription (audit du
  // 13/11/2026, accepté par le propriétaire) : une fois enregistrés, ils ne
  // changent plus depuis l'appli — sinon un membre pourrait se rajeunir ou
  // changer de genre sans aucun contrôle, ce qui fausse la confiance entre
  // membres, la vérification d'identité et la découverte. Une erreur
  // légitime se corrige via le support (administrateur).
  const [existingProfileSnap, existingStatusSnap] = await Promise.all([
    db.collection("users").doc(uid).get(),
    db.collection("user_status").doc(uid).get(),
  ]);
  const existingGender = existingProfileSnap.data()?.gender as string | undefined;
  if (existingGender && existingGender !== gender) {
    throw new HttpsError("failed-precondition", "gender-locked : le genre ne peut plus être modifié.");
  }
  const existingBirthDate = existingStatusSnap.data()?.birthDate as string | undefined;
  if (existingBirthDate && existingBirthDate.slice(0, 10) !== birthDate.slice(0, 10)) {
    throw new HttpsError("failed-precondition", "birthdate-locked : la date de naissance ne peut plus être modifiée.");
  }
  const seekingGenders = closedList(data.seekingGenders, "seekingGenders", GENDERS);
  if (seekingGenders.length === 0) invalid("seekingGenders");

  // Sélecteur fermé côté client (country_picker, demande explicite du
  // propriétaire le 12/11/2026) : plus aucune saisie libre, donc le
  // serveur doit refuser tout nom qui ne correspond à aucune entrée
  // réellement proposée — même principe que les autres listes fermées
  // de cette fonction, avec tolérance à la casse pour les profils déjà
  // enregistrés avant ce correctif (voir closedValueCaseInsensitive —
  // normalise déjà "france" en "France" toute seule, sans repli).
  //
  // Repli UNIQUEMENT si cette vérification échoue malgré tout (donnée
  // héritée plus divergente qu'une simple casse différente —
  // abréviation, écriture directe de test) ET que la valeur envoyée est
  // EXACTEMENT celle déjà en base (le membre n'a pas touché ce champ,
  // juste modifié autre chose) : conservée telle quelle plutôt que de
  // bloquer tout le reste de l'enregistrement. Un vrai NOUVEAU choix
  // (différent de ce qui existait) passe toujours par la liste fermée
  // en premier, jamais court-circuité par ce repli — et la lecture
  // supplémentaire qu'il demande ne se produit que dans ce cas rare,
  // pas à chaque appel (trouvé par revue de code, deux fois : un repli
  // mal placé AVANT la vérification aurait pu réécrire une casse déjà
  // correcte avec l'ancienne valeur, et une lecture systématique aurait
  // doublé le coût Firestore de cette fonction pour le cas normal).
  let country: string;
  try {
    country = closedValueCaseInsensitive(data.country, "country", VALID_COUNTRY_NAMES);
  } catch (err) {
    const existingSnap = await db.collection("users").doc(uid).get();
    const existingCountry = existingSnap.data()?.country as string | undefined;
    if (typeof data.country === "string" && data.country === existingCountry) {
      country = existingCountry;
    } else {
      throw err;
    }
  }
  const city = capitalizeFirstLetter(requiredText(data.city, "city", MAX_SHORT_TEXT));
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
  // `birthDate` (date de naissance EXACTE) n'est plus jamais écrite sur
  // le document public — demande explicite de l'utilisateur, 12/11/2026
  // (règlement permanent section 17, "la règle la plus stricte gagne") :
  // même si `users/{uid}` était déjà pensé pour être largement lisible,
  // exposer la date de naissance précise à n'importe quel membre
  // connecté allait au-delà de ce qui est réellement nécessaire (l'âge
  // suffit partout). Stockée uniquement dans `user_status/{uid}`
  // (lisible par son seul propriétaire, firestore.rules), jamais
  // ailleurs ; seul `age`, recalculé ici à chaque sauvegarde, est rendu
  // public.
  //
  // Les deux écritures (privée + publique) sont groupées dans un seul
  // WriteBatch — sans ça, un échec entre les deux aurait pu laisser
  // birthDate enregistrée dans user_status sans que users/{uid} soit
  // jamais mis à jour (ou l'inverse), au lieu de réussir ou échouer
  // ensemble (trouvé par revue de code).
  const batch = db.batch();
  batch.set(db.collection("user_status").doc(uid), { birthDate }, { merge: true });
  batch.set(
    db.collection("users").doc(uid),
    {
      displayName,
      age: computeAge(birthDate),
      // Efface explicitement un éventuel `birthDate` hérité de versions
      // précédentes de cette fonction (avant ce correctif, elle était
      // écrite ici en clair) — `merge: true` n'enlève jamais tout seul
      // un champ qu'on ne repasse pas, donc sans ce `delete()` explicite
      // elle serait restée exposée indéfiniment sur ce document public
      // à chaque futur enregistrement.
      birthDate: FieldValue.delete(),
      gender,
      seekingGenders,
      country,
      city,
      // Normalisées en minuscules pour le filtre pays/ville de Découvrir
      // (getCandidates.ts) — une comparaison Firestore "==" est
      // sensible à la casse. `country` passe maintenant par un
      // sélecteur fermé (voir plus haut) ; `city` reste du texte libre
      // saisi par chacun (aucune base de villes exhaustive, voir
      // core/data/major_cities.dart côté client pour le compromis
      // retenu), donc toujours sans liste fermée ici.
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
  await batch.commit();

  return { ok: true };
});
