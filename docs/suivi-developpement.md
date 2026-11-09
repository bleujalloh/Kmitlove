# Suivi de développement — Kamalove

Checklist de toutes les parties du cahier des charges et des règles, pour qu'aucune ne soit oubliée. Mise à jour à chaque session de travail. `[ ]` à faire, `[~]` en cours, `[x]` fait.

## Fondations

- [x] Projet Flutter créé, structure par fonctionnalité, Riverpod, thème
- [x] Firebase connecté (projet djama-1c7f8), règles Firestore/Storage par défaut déployées
- [x] Squelette Cloud Functions
- [x] **L'APK Android compile avec succès** (`flutter build apk --debug`, 2026-11-09) — minSdk 23 fixé dans android/app/build.gradle.kts (attention : l'outil de migration Gradle de Flutter peut réécrire ce fichier lors d'un futur `flutter build`, à vérifier si ça revient)
- [ ] Plan Firebase Blaze — volontairement repoussé à la fin (décision du 2026-11-09), donc Cloud Functions pas encore déployées/testables en conditions réelles malgré le code prêt et relu
- [ ] Firebase Storage activé (action manuelle requise — console web, région à choisir)
- [x] Navigation de premier niveau (AuthGate : onboarding → auth → vérification e-mail → app). go_router à brancher pour la navigation interne (Découvrir/Likes/Messages/Communauté) à l'étape suivante.
- [ ] Firebase App Check (anti-bot, section 2 regles-du-projet.md)
- [ ] Projets Firebase séparés dev/staging/prod (actuellement un seul projet — à faire avant la mise en production réelle)
- [ ] SHA-1 de signature enregistré dans Firebase (nécessaire pour que Google Sign-In fonctionne réellement sur Android — action à faire au moment des tests sur appareil)

## 4.1 Authentification

- [x] Inscription par e-mail (+ validation 8 caractères, case "18 ans ou plus")
- [x] Connexion par e-mail
- [x] Connexion Google (code en place — nécessite le SHA-1 enregistré pour fonctionner sur appareil réel)
- [x] Connexion Apple (code en place — nécessite un compte Apple Developer pour fonctionner réellement)
- [x] Vérification de l'adresse e-mail (écran d'attente avec rafraîchissement automatique)
- [x] Réinitialisation du mot de passe
- [x] Validation de l'âge minimum (case à cocher) — badge vérifié d'identité à faire plus tard
- [x] Acceptation CGU/charte (écran onboarding réel, fidèle au prototype)
- [x] Suppression du compte (Cloud Function `deleteAccount` : données + compte Auth supprimés ensemble, côté serveur)

## Filtrage à l'inscription (regles-du-projet.md section 1)

- [x] Tirage aléatoire des questions côté serveur (Cloud Function `startFiltrageAttempt`)
- [x] Cloud Function de correction + seuil 85 % (`submitFiltrageAttempt`)
- [x] Écran questionnaire (intro, questions, résultat) relié à de vraies Cloud Functions
- [x] Compte en attente + nouvel essai après délai (7 jours) + recours humain (`requestFiltrageReview`)
- [x] Anti-contournement : reprise de la tentative en cours au lieu d'un nouveau tirage (corrigé après revue indépendante)
- [ ] Banque de questions **chargée dans Firestore** — le contenu est rédigé (docs/banque-questions-filtrage.md), reste à l'importer dans `filtrage_question_bank` avant de pouvoir tester réellement
- [ ] Limite de comptes par appareil/e-mail (nécessite App Check / un dispositif anti-abus, pas encore fait)
- [x] Revue indépendante passée sur cette fonctionnalité (2026-11-09) : 5 problèmes trouvés et corrigés (course d'affichage, double soumission, contournement du délai, suppression de compte, nonce Apple)

## 4.2 Profil

- [x] Création du profil (toutes les informations texte de la section 4.2), validation 18 ans sur la vraie date de naissance
- [ ] **Accès en modification depuis les paramètres** — le formulaire supporte déjà l'édition (`ProfilEditScreen(existing: ...)`) mais rien n'y mène encore ; à faire avec l'écran Paramètres
- [ ] Upload photo + statut "en attente de validation" (délai 48h, regles-messagerie-securite.md) — bloqué par Firebase Storage pas encore activé
- [ ] Badge de vérification d'identité (regles-complementaires-concurrents.md)
- [x] Revue indépendante passée (2026-11-09) : erreur réseau non affichée, corrigée

## 4.3 Test de compatibilité kamite

- [x] Questionnaire (5 thèmes, reformulé en affirmations notées 1-5 — voir docs/banque-questions-compatibilite.md)
- [x] Cloud Function de calcul (formule précise, pondération, seuil de couverture par thème, anti-triche par validation des valeurs)
- [x] Recalcul automatique si modification des réponses (le score est recalculé à chaque appel, jamais mis en cache côté serveur pour l'instant — donc toujours à jour par construction)
- [ ] Banque de questions **chargée dans Firestore** (contenu rédigé, pas encore importé — même situation que le filtrage)
- [ ] Contrôle de visibilité des réponses par l'utilisateur (section 4.3 du cahier des charges le permet, pas encore construit — réponses jamais visibles par les autres de toute façon, donc non bloquant)
- [x] Revue indépendante passée (2026-11-09) : réponses non validées (valeurs hors échelle) et absence de retour d'erreur à la sauvegarde, corrigés

## 4.4 Découvrir

- [x] Génération de candidats à la demande côté serveur (pas encore précalculée par Cloud Scheduler — simplification V1 assumée, à revoir si lent à l'échelle, voir architecture-technique.md section 4)
- [x] Écran swipe connecté aux vraies Cloud Functions (like/pass/super-like, détection de match avec pop-up)
- [x] Filtrage réciproque des préférences de genre, exclusion des profils déjà swipés, exclusion des comptes non activés
- [ ] Filtres manuels (âge ±8 ans par défaut, distance 5-100 km, intention) — pas encore d'UI de filtre, ni de position géographique du tout
- [x] Limite 20 likes/jour gratuit (serveur), illimité Premium pas encore branché (Premium non construit)
- [x] Masquage des comptes inactifs (30 jours) — champ `lastActiveAt` pas encore alimenté par l'app, donc personne n'est exclu pour l'instant ; **à faire** : écrire `lastActiveAt` à la connexion
- [x] Revue indépendante passée (2026-11-09) : bug bloquant (transaction Firestore lecture-après-écriture, empêchait tout like), double-tap, lectures séquentielles, schéma matchs, cast fragile — tous corrigés

## 4.5 Likes

- [x] Écran "m'ont liké" / "mes likes" connecté (getLikes/retractLike côté serveur)
- [x] Teaser Premium pour débloquer "qui m'a liké" (gating déjà en place via `user_status.isPremium`, qu'il reste à faire passer à `true` une fois Premium construit)
- [x] Retirer un like (impossible si déjà match)
- [x] Revue indépendante passée (2026-11-09) : cast fragile, erreur de retrait non affichée, incohérence de modération avec Découvrir, perf — tous corrigés ; `computeAge` extrait en helper partagé (functions/src/shared/age.ts)

## 4.6 Matchs et messagerie

- [x] Création de match (fait dans recordSwipe, Découvrir)
- [ ] Expiration d'un match sans message sous 7 jours (pas de Cloud Scheduler configuré — nécessite le plan Blaze et sa mise en place, pas fait volontairement pour l'instant)
- [x] Messagerie temps réel (Firestore direct, règles renforcées)
- [x] Indicateur de lecture (activé par défaut, désactivable + réciprocité)
- [ ] Photos en message floutées par défaut à la première réception — bloqué par Storage non activé
- [x] Blocage (immédiat, coupe la conversation des deux côtés) / signalement (motif obligatoire, anonyme pour la personne signalée)
- [x] Revue indépendante passée (2026-11-09) : accusé de lecture falsifiable, date de message non garantie serveur, blocage non lié à un vrai match, lectures/écritures non groupées — toutes corrigées

## 4.7 Communauté

- [x] Publications (post-modération, publiées immédiatement)
- [x] Annonces publiques/privées (filtre de mots-clés très simple + revue humaine si doute), max 3 actives
- [x] Événements (toujours en attente de revue humaine), réservés aux membres `isVerified` — **ce flag n'est mis à jour par rien encore** : la vérification d'identité (selfie/vidéo) n'est pas construite, donc personne ne peut créer d'événement pour l'instant. Noté comme blocage.
- [x] Capacité (avec validation de type), liste d'attente si complet
- [x] Code de présence à l'entrée **à la place d'un vrai QR code scanné** (simplification assumée : saisie manuelle d'un code, pas de caméra/scanner — à revoir si besoin d'un vrai QR)
- [ ] Bouton d'urgence sur événement accepté (prévu dans regles-complementaires-concurrents.md, pas encore construit)
- [ ] **Pas d'espace admin pour traiter les `pending_review`** — les publications en attente (annonces douteuses, tous les événements) n'ont actuellement aucune interface pour être validées/refusées ; à faire avec la section 6 (administration)
- [x] Revue indépendante passée (2026-11-09) : capacité non validée (type), demande de participation sur un type qui n'en a pas besoin, listes de motifs dupliquées, requête non bornée, check-in sans écran — toutes corrigées

## 4.8 Sécurité et modération (transverse)

- [ ] Espace admin de traitement des signalements (priorité selon gravité)
- [ ] Escalade (avertissement → suspension 30j → suspension définitive + recours)
- [ ] Journalisation des actions admin

## 5-6. Modèle économique et administration

- [ ] Abonnement Premium (paiement, résiliation en 3 clics, transparence renouvellement)
- [ ] Jetons à l'unité (achat, consommation, anti-abus)
- [ ] Boost (30 min, 1x/semaine Premium)
- [ ] Espace admin complet (section 6 du cahier des charges) : utilisateurs, suspensions, signalements, modération photos/annonces, événements, abonnements, statistiques, journaux

## RGPD / légal (transverse, à ne pas traiter en dernier)

- [ ] Export des données personnelles (portabilité)
- [ ] Suppression/anonymisation réelle à la demande
- [ ] Résiliation Premium en 3 clics
