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
// Un Super Like doit coûter quelque chose en dehors de Premium (signalé
// par le propriétaire le 11/11/2026 : il ne doit JAMAIS être gratuit et
// illimité comme un like normal) — un jeton par Super Like, gratuit et
// illimité uniquement pour les membres Premium.
export const SUPER_LIKE_JETON_COST = 1;
export const DISCOVER_CANDIDATE_POOL_SIZE = 50; // avant filtrage
export const DISCOVER_CANDIDATES_RETURNED = 10; // après filtrage, envoyés au client
export const INACTIVE_ACCOUNT_DAYS = 30;

// Communauté — refonte du 11/11/2026 (spec complète transmise par le
// propriétaire). Catégories et formats fermés : vérifiés côté serveur,
// jamais une liste qui n'existerait que côté client.
export const EVENT_CATEGORIES = [
  "soiree",
  "conference",
  "atelier",
  "exposition",
  "debat",
  "projection",
  "rencontre",
] as const;
export const EVENT_FORMATS = ["presentiel", "en_ligne"] as const;
export const EVENT_ACCESS_MODES = ["public", "sur_demande", "sur_invitation"] as const;
// Statut fixé par l'organisateur (distinct du statut de modération
// published/pending_review/rejected) — "complet" se déduit du nombre de
// participants, jamais fixé directement.
export const EVENT_STATES = ["prevu", "complet", "annule", "termine"] as const;
export const ORGANIZER_MAX_NAME_LENGTH = 80;
export const ORGANIZER_MAX_DESCRIPTION_LENGTH = 500;
// Récurrence d'événement (spec Communauté section 10, complété le
// 11/11/2026) : liste fermée vérifiée côté serveur, jamais une
// périodicité libre saisie par le client. Nombre d'occurrences
// générées à la création plafonné pour ne jamais créer une série non
// bornée ni surcharger la revue de modération humaine (chaque
// occurrence reste un événement "pending_review" comme les autres).
export const EVENT_RECURRENCE_FREQUENCIES = ["hebdomadaire", "mensuel"] as const;
export const EVENT_RECURRENCE_MAX_OCCURRENCES = 6;
// Rappel automatique (spec Communauté section 9) : délai avant le début
// de l'événement en dessous duquel un participant confirmé reçoit une
// notification push — functions/src/scheduled/sendEventReminders.ts.
export const EVENT_REMINDER_HOURS_BEFORE = 24;

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

// Nom du sujet Pub/Sub pour les notifications temps réel Google Play
// (RTDN) — à lier dans Play Console > Monétisation > Notifications en
// temps réel (action manuelle, voir docs/suivi-developpement.md).
export const PLAY_RTDN_TOPIC = "play-billing-rtdn";

// docs/regles-messagerie-securite.md section 1 — délai maximal garanti
// avant approbation automatique d'une photo, faute de modérateur
// disponible en permanence.
export const PHOTO_AUTO_APPROVE_HOURS = 48;

// docs/regles-complementaires-concurrents.md section 3
export const MATCH_EXPIRY_DAYS = 7;

// docs/regles-annonces-evenements.md / Boost (cahier des charges section 5)
export const BOOST_DURATION_MINUTES = 30;
export const BOOST_FREE_WEEKLY_FOR_PREMIUM = 1;

// docs/regles-messagerie-securite.md section 3 — escalade avertissement →
// suspension TEMPORAIRE → suspension définitive. Durée de la suspension
// temporaire avant levée automatique.
export const SANCTION_SUSPENSION_DAYS = 30;
// "Un compte visé par 3 signalements distincts et confirmés, tous
// domaines confondus, passe automatiquement en revue prioritaire."
export const PRIORITY_REVIEW_REPORT_THRESHOLD = 3;
// Même raisonnement que FILTRAGE_RETRY_DELAY_DAYS : empêche de re-soumettre
// un recours en boucle immédiatement après un refus.
export const SANCTION_APPEAL_RETRY_DELAY_DAYS = 7;

// docs/suivi-developpement.md, section du 11/11/2026 : en dessous de ce
// nombre de photos APPROUVÉES, un profil est tout simplement exclu de
// Découvrir (jamais seulement "moins bien classé") — sans ça, un compte
// pouvait apparaître avec une seule photo, voire aucune vérification
// visuelle du tout. Au-dessus du minimum, chaque photo supplémentaire
// améliore légèrement le classement (voir getDiscoverCandidates.ts).
export const MIN_APPROVED_PHOTOS_TO_BE_DISCOVERABLE = 2;
// Nombre de questions du test de compatibilité tirées au hasard à
// chaque ouverture de l'écran — priorité donnée aux questions pas encore
// répondues (functions/src/compatibilite/getCompatQuestions.ts), pour
// que la banque entière finisse par être couverte en quelques sessions
// plutôt que de toujours montrer les 17 mêmes premières questions.
export const COMPAT_QUESTIONS_PER_SESSION = 18;

// "Limite de comptes par appareil" (docs/suivi-developpement.md,
// Fondations) — un identifiant d'appareil n'est qu'un indice (il est
// trivialement réinitialisable à la réinstallation, et peut être partagé
// légitimement par un foyer), donc jamais utilisé pour bloquer une
// inscription : seulement pour mettre en revue prioritaire un compte une
// fois ce seuil atteint depuis le même appareil (shared/deviceSignal.ts).
export const MULTI_ACCOUNT_DEVICE_THRESHOLD = 3;
