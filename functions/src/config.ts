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

// Durée de conservation d'une photo refusée avant suppression automatique
// (photos/purgeRejectedPhotos.ts, docs/rgpd-registre-des-traitements.md §7).
export const REJECTED_PHOTO_RETENTION_DAYS = 30;

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
// nombre de photos APPROUVÉES ET AVEC VISAGE DÉTECTÉ (voir
// photos/moderatePhotoContent.ts — distinct du simple nombre de photos
// approuvées, utilisé lui pour le calcul de complétion de profil), un
// profil est tout simplement exclu de Découvrir (jamais seulement "moins
// bien classé") — sans ça, un compte pouvait apparaître avec une seule
// photo, voire aucune vérification visuelle du tout, voire des photos
// sans aucun visage (paysage, objet...). Au-dessus du minimum, chaque
// photo supplémentaire améliore légèrement le classement (voir
// getDiscoverCandidates.ts).
export const MIN_APPROVED_PHOTOS_TO_BE_DISCOVERABLE = 2;

// Modération automatique du contenu à l'upload (sur demande explicite du
// propriétaire, 11/11/2026 — avant, aucun contrôle automatique
// n'existait, seule la revue humaine ou l'approbation après 48h
// décidaient). Catégories SafeSearch vérifiées et seuil de rejet
// automatique : "LIKELY" ou plus → rejeté immédiatement, sans attendre
// la revue humaine ni le délai de PHOTO_AUTO_APPROVE_HOURS.
export const SAFE_SEARCH_CATEGORIES_TO_CHECK = ["adult", "racy", "violence"] as const;
export const SAFE_SEARCH_REJECT_LIKELIHOOD = "LIKELY";
// Confiance minimale (0-1) pour compter une détection de visage comme
// réelle plutôt qu'une détection ambiguë de faible confiance.
export const FACE_DETECTION_MIN_CONFIDENCE = 0.5;
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

// Badge "En ligne" sur la carte Découvrir (maquette visuelle validée le
// 12/11/2026) : réutilise lastActiveAt déjà écrit par recordActivity.ts
// (jusqu'ici seulement pour le masquage des comptes inactifs 30 jours),
// jamais un nouveau système de présence temps réel — un membre actif
// dans cette fenêtre récente est considéré "en ligne".
export const ONLINE_THRESHOLD_MINUTES = 10;

// Messagerie : longueur maximale (la même que firestore.rules l'imposait à
// l'écriture directe) et fréquence autorisée par membre
// (messagerie/sendMessage.ts, shared/rateLimit.ts) — un usage humain normal
// reste très en dessous, seul un script ou un abus les atteint.
export const MESSAGE_MAX_LENGTH = 2000;
export const MESSAGE_RATE_LIMITS = [
  { key: "msg_min", limit: 20, windowSeconds: 60 },
  { key: "msg_day", limit: 600, windowSeconds: 24 * 60 * 60 },
];

// Signalements (membre ou publication) : un seul quota partagé entre les
// deux fonctions, pour qu'on ne puisse pas saturer la file de modération en
// alternant l'une et l'autre.
// Longueur maximale du texte libre d'un signalement.
export const MAX_REPORT_DETAILS = 1000;
export const REPORT_RATE_LIMITS = [
  { key: "report_hour", limit: 10, windowSeconds: 60 * 60 },
  { key: "report_day", limit: 30, windowSeconds: 24 * 60 * 60 },
];

// Consentement explicite au traitement des données sensibles (RGPD art. 9 :
// orientation déduite de « genre + genres recherchés », appartenance
// culturelle, photos) — account/sensitiveConsent.ts. À incrémenter quand le
// texte du consentement change : les membres doivent alors le redonner.
export const SENSITIVE_CONSENT_VERSION = 1;

// Purge des comptes inactifs (scheduled/purgeInactiveAccounts.ts,
// docs/rgpd-registre-des-traitements.md §7) : avertissement après
// INACTIVE_ACCOUNT_WARNING_MONTHS mois sans activité, suppression
// INACTIVE_ACCOUNT_GRACE_DAYS jours plus tard si le membre n'est pas revenu
// (donc 24 mois d'inactivité au total environ).
export const INACTIVE_ACCOUNT_WARNING_MONTHS = 23;
export const INACTIVE_ACCOUNT_GRACE_DAYS = 30;
export const INACTIVE_PURGE_MAX_PER_RUN = 25;

// Réponses aux publications du fil (communaute/postInteractions.ts) : même
// mécanisme que la messagerie et les signalements (shared/rateLimit.ts).
export const REPLY_RATE_LIMITS = [{ key: "reply_hour", limit: 20, windowSeconds: 60 * 60 }];

// Pourcentage de complétion du profil (shared/profileCompletion.ts) : le test
// de compatibilité compte quand le membre a répondu à au moins une session
// complète de questions (COMPAT_QUESTIONS_PER_SESSION).
export const COMPAT_ANSWERS_FOR_FULL_COMPLETION = COMPAT_QUESTIONS_PER_SESSION;
