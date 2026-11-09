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
