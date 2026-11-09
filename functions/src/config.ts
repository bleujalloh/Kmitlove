// Région choisie pour la latence avec les membres en France/Europe/Afrique
// de l'Ouest (docs/architecture-technique.md).
export const REGION = "europe-west1";

// docs/regles-du-projet.md section 1
export const FILTRAGE_QUESTIONS_PER_ATTEMPT = 15;
export const FILTRAGE_PASS_THRESHOLD = 0.85; // dans la fourchette 80-90 % décidée
export const FILTRAGE_RETRY_DELAY_DAYS = 7;

// docs/regles-economie-et-compatibilite.md section 2
export const COMPAT_THEME_WEIGHTS: Record<string, number> = {
  vision_couple: 0.3,
  valeurs_culture: 0.25,
  famille: 0.2,
  mode_vie: 0.15,
  communication: 0.1,
};
// Seuil de validité d'un thème : en dessous, il est exclu du calcul et son
// poids redistribué sur les autres (docs/regles-economie-et-compatibilite.md).
export const COMPAT_MIN_THEME_COVERAGE = 0.6;
export const COMPAT_SCALE_MIN = 1;
export const COMPAT_SCALE_MAX = 5;

// docs/regles-complementaires-concurrents.md section 3
export const FREE_DAILY_LIKE_LIMIT = 20;
export const DISCOVER_CANDIDATE_POOL_SIZE = 50; // avant filtrage
export const DISCOVER_CANDIDATES_RETURNED = 10; // après filtrage, envoyés au client
export const INACTIVE_ACCOUNT_DAYS = 30;

// docs/regles-annonces-evenements.md
export const MAX_ACTIVE_ANNONCES_PER_USER = 3;
// Filtre automatique très simple en l'absence d'IA de modération — un
// premier garde-fou, pas une détection fiable (docs/regles-annonces-evenements.md
// section 3). À étoffer ou remplacer par un vrai outil plus tard.
export const ANNONCE_FLAGGED_KEYWORDS = [
  "paypal",
  "virement",
  "escort",
  "tarif",
  "€/h",
  "cb uniquement",
  "promo",
  "boutique en ligne",
];

// docs/regles-economie-et-compatibilite.md section 1 et cahier des
// charges section 5. Identifiants à créer dans Google Play Console
// (et App Store Connect une fois le compte développeur Apple ouvert) —
// doivent correspondre exactement à ceux déclarés côté client.
export const ANDROID_PACKAGE_NAME = "com.kamalove.kamalove";
export const PREMIUM_SUBSCRIPTION_PRODUCT_ID = "kamalove_premium_monthly";
export const JETON_PACK_PRODUCTS: Record<string, number> = {
  kamalove_jetons_5: 5,
  kamalove_jetons_15: 15,
};
