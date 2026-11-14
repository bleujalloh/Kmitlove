# Architecture technique — app-rencontre

Ce document pose les bases techniques avant le développement : comment l'app est construite, comment elle encaisse la croissance, comment les données des utilisateurs sont protégées.

## Repère culturel (pour que le contenu soit juste)

Le mouvement kémite/kamite se réclame d'une filiation avec l'Égypte ancienne (Kemet) et s'inscrit dans les courants afrocentristes portés notamment par Cheikh Anta Diop et Molefi Kete Asante — l'idée centrale étant que les Africains doivent redevenir sujets de leur propre histoire, et renouer avec les valeurs spirituelles et culturelles africaines précoloniales. C'est cette base (histoire, philosophie, valeurs) qui doit nourrir le questionnaire de filtrage et le test de compatibilité — jamais une question sur l'apparence physique ou l'ascendance biologique.

Sources : [Revue RASP — étude du kémitisme](https://revue-rasp.org/rasp/article/download/809/326/3916), [African Identity between Pan-Africanism and Kemetism](https://qiraatafrican.com/journal/article/african-identity-between-pan-africanism-and-kemetism), [Afrocentricity — Wikipedia](https://wikipedia.com/wiki/Afrocentricity)

## 1. Vue d'ensemble

- **Application mobile** : Flutter (un seul code pour Android et iOS).
- **Backend** : Firebase — pas de serveur à gérer soi-même, Google s'occupe de la partie infrastructure, on garde la maîtrise sur les règles de sécurité et la logique.
- **Trois environnements séparés dès le départ** : développement, test (staging), production. On ne teste jamais une nouveauté directement sur les vraies données des utilisateurs.

## 2. Composants Firebase utilisés

| Composant | Rôle |
|---|---|
| Firebase Auth | Comptes (e-mail, Google, Apple) |
| Firestore | Base de données principale (profils, matchs, messages, communauté) |
| Cloud Functions | Toute la logique sensible côté serveur (notée en détail plus bas) |
| Cloud Storage | Photos de profil et pièces jointes |
| App Check | Vérifie que les requêtes viennent bien de l'app officielle, pas d'un robot |
| Cloud Messaging | Notifications (nouveau message, nouveau match) |

## 3. Ce qui tourne obligatoirement côté serveur (Cloud Functions)

Jamais dans l'app elle-même, pour qu'on ne puisse pas les lire en décompilant l'app ou les contourner :

- Correction du questionnaire de filtrage à l'inscription et calcul du score.
- Calcul du score de compatibilité (test kamite).
- Création d'un match (déclenchée seulement quand les deux likes existent réellement en base).
- Vérification des droits Premium avant de débloquer une fonctionnalité payante.
- Modération automatique des photos à l'upload (détection de contenu explicite avant publication).
- Traitement des signalements et déclenchement des suspensions.

## 4. Montée en charge (scalabilité)

Le point le plus sensible d'une app de rencontre, techniquement, c'est l'écran "Découvrir" (le swipe) : il doit proposer des profils pertinents, proches géographiquement, jamais déjà vus, et compatibles — pour potentiellement des centaines de milliers d'utilisateurs.

- **Phase 1 (lancement, jusqu'à quelques dizaines de milliers d'utilisateurs)** : Firestore suffit, avec un système de "paquets de candidats" précalculés régulièrement par une tâche planifiée (Cloud Scheduler + Cloud Function), plutôt que de chercher en temps réel à chaque swipe — ça évite de surcharger la base.
- **Phase 2 (croissance)** : si la recherche géographique/par filtres devient trop lente ou coûteuse sur Firestore, on branche un moteur de recherche dédié (Algolia ou Typesense) juste pour l'écran Découvrir, Firestore restant la source de vérité pour le reste.
- **Messagerie** : Firestore gère bien la messagerie temps réel nativement, pas de souci particulier à ce niveau avant une très grosse échelle.
- **Photos** : toujours compressées et redimensionnées automatiquement à l'upload (Cloud Function), jamais stocker l'image brute envoyée par le téléphone — ça économise coût de stockage et bande passante dès le premier jour.

## 5. Sécurité des données clients

- **Chiffrement** : les données sont chiffrées au repos par défaut par Google (Firestore, Storage). Les communications app ↔ serveur sont chiffrées (HTTPS/TLS) par défaut avec Firebase.
- **Principe du moindre privilège** : les règles Firestore/Storage interdisent tout par défaut ; chaque autorisation est ajoutée explicitement et testée.
- **Données sensibles jamais publiques** : position GPS précise, adresse, numéro de téléphone — toujours stockés séparément des champs publics du profil, accessibles uniquement par les Cloud Functions qui en ont besoin (ex. calcul de distance approximative), jamais directement lisibles par les autres utilisateurs.
- **Droit à l'oubli (RGPD)** : la suppression de compte doit réellement supprimer ou anonymiser les données en base (profil, messages, photos), pas juste masquer le compte.
- **Minimisation des données** : on ne demande et on ne stocke que ce qui sert réellement à l'app (pas de collecte "au cas où").
- **Journalisation des accès admin** : toute action d'un administrateur (suspension, consultation d'un signalement) est tracée, pour éviter les abus internes.

## 6. Prochaine étape après la discussion

Une fois cette architecture validée, étape suivante : structurer le dépôt Flutter (dossiers `lib/features/...`), créer le projet Firebase (environnements dev/staging/prod), et commencer par l'authentification + le questionnaire de filtrage — c'est la fondation sur laquelle tout le reste s'appuie.

## 7. Cartographie des fonctionnalités (règlement permanent, section 21)

Tenue à jour à chaque implantation. Chaque ligne : où vit la fonctionnalité, quelle donnée elle utilise, ce qu'elle réutilise. **Avant de créer quoi que ce soit, chercher ici s'il existe déjà.**

| Fonctionnalité | App (`lib/features/…`) | Serveur (`functions/src/…`) | Données Firestore / Storage | Réutilise / est réutilisé par |
|---|---|---|---|---|
| Authentification, session | `auth`, `onboarding` | `account/*` | Auth, `users`, `user_status` | `authStateProvider` (`core/providers/firebase_providers.dart`) partout |
| Filtrage à l'inscription | `filtrage` | `filtrage/*`, `admin/resolveFiltrageReview` | `filtrage_attempts`, `filtrage_question_bank` | — |
| Profil | `profil` | `profil/saveProfil`, `getProfileCompletion`, `shared/profileCompletion` | `users/{uid}`, `users/{uid}/photos`, Storage `profile_photos` | `candidateFirstPhotoUrlProvider` (photo d'un autre membre) : Découvrir, Likes, Messages, écrans vides (`suggestedProfilePhotosProvider`) |
| Modération photos | `profil` (statuts) | `photos/*`, `shared/photoModeration` | `users/{uid}/photos` (`status`, `hasFace`) | condition de visibilité dans Découvrir (≥ 2 photos visage approuvées) |
| Vérification d'identité | `identite` | `identite/*` | Storage `identity_verifications` (**supprimé dès la décision du modérateur**), `users.isVerified`, `user_status.identityVerification*` | requis pour créer un événement |
| Compatibilité | `compatibilite` | `compatibilite/*` | `compat_answers`, `compat_question_bank` | score affiché dans Découvrir |
| Découvrir (filtres, cartes, swipes, retour, éclair) | `decouvrir` (éclair = `activateProfileBoost` de `core/widgets/boost_action.dart`) | `decouvrir/getCandidates`, `recordSwipe`, `undoLastSwipe` (Premium, dernier passage) | `swipes`, `matches`, `user_status` (position, `lastPassTargetUid`) | filtres 100 % côté serveur ; géocodage inverse local (`detected_place_provider`) |
| Likes | `likes` | `likes/*` | `swipes` | `AppTab`, `candidateFirstPhotoUrlProvider` |
| Matchs et messagerie | `messages` | `messagerie/sendMessage` (**seul chemin d'envoi** : compte actif, membre du match, blocage, longueur, limite de fréquence), `messagerie/onMessageCreated`, `reportUser`, `scheduled/expireMatches` | `matches/{id}`, `matches/{id}/messages` (création refusée aux clients par les règles), Storage `chat_photos`, `rate_limits` | `lastMessageProvider` (non lu), `formatMessageTime`, photo membre ci-dessus, `shared/rateLimit` |
| Blocage | `messages` (`blocks`) | exclu dans `getCandidates`, `getLikes`, `recordSwipe` | `blocks/{uidA_uidB}` | un seul système de blocage pour Découvrir, Likes, Messages |
| Signalement | `core/widgets/report_reasons.dart` | `messagerie/reportUser`, `communaute/reportCommunityPost` (quota commun `REPORT_RATE_LIMITS`), `shared/reportReasons` | `moderation_requests`, `rate_limits` | admin : `admin/moderationRequests` |
| Notifications push | `notifications` (`pushRegistrationProvider`, tap → onglet dans `main_shell.dart`) | `shared/push.ts` (un seul émetteur : `sendPushToUser`), `registerFcmToken` | `user_status.fcmTokens` | déclenché par `recordSwipe`, `onMessageCreated`, `cancelParticipation`, `scheduled/sendEventReminders` |
| Communauté (publications, événements) | `communaute` (j'aime et réponses : `post_interactions.dart`) | `communaute/*` dont `postInteractions` (`togglePostLike`, `replyToPost`), `admin/reviewCommunityPost`, `admin/organizerRequests` | `community_posts` (+ `likes`, `replies`, `participations`, `reviews`), `event_invite_codes`, `community_tips` | organisateur approuvé (`shared/requireApprovedOrganizer`) |
| Premium, jetons, boost | `premium` | `premium/*`, `paiements/*` (en pause) | `user_status.jetons`, `isPremium` | droits vérifiés côté serveur (`recordSwipe`, `activateBoost`) |
| Sécurité du membre | `parametres`, `core/widgets/emergency_sheet.dart` | `securite/triggerEmergencyAlert`, `shared/sanctions` | `users`, `user_status` | — |
| RGPD | `parametres` (export, suppression, retrait du consentement), `auth/.../sensitive_consent_screen.dart` (écran de consentement, branché dans `core/router/auth_gate.dart`) | `rgpd/exportMyData` (export complet), `shared/eraseAccount` (**source unique de suppression**), `account/deleteAccount`, `scheduled/purgeInactiveAccounts` (avertit à 23 mois, supprime 30 jours après), `account/sensitiveConsent` (consentement art. 9 versionné, exigé par `saveProfil`) | toutes les collections ci-dessus, `user_status.sensitiveConsent`, `user_status.inactivityWarnedAt` | registre, durées et écarts : `docs/rgpd-registre-des-traitements.md` |
| Limites de fréquence, App Check, consentement | `settings_controller.dart` (`hasSensitiveConsent`, `kSensitiveConsentVersion`) | `shared/rateLimit` (compteurs à fenêtre fixe, une transaction par appel, quotas déclarés dans `config.ts` : `MESSAGE_RATE_LIMITS`, `REPORT_RATE_LIMITS`, `REPLY_RATE_LIMITS`), `shared/appCheck` (`ENFORCE_APP_CHECK`, **désactivé** tant que les prérequis de la console ne sont pas faits), `shared/consent` (`hasValidConsent`/`requireConsent` : seul contrôle du consentement art. 9 côté serveur), `shared/storagePaths` (`isProfilePhotoPath` : un chemin Storage lu dans un document écrit par le client n'est jamais utilisé tel quel), `shared/participation` (annulation + promotion de la liste d'attente, partagée avec `eraseAccount`) | `rate_limits/{uid}_{règle}` (écriture serveur seule, supprimé avec le compte) | messagerie, signalements, réponses de la Communauté ; une nouvelle limite = une nouvelle constante, jamais un second mécanisme |
| Administration | `admin` | `admin/*`, `shared/requireAdmin`, `shared/adminLog` | `admin_action_logs`, `app_config` | — |

Composants partagés : `core/widgets/` (`app_tab`, `empty_state_cards`, `block_action`, `report_reasons`, `profile_fact_sheet`, `country_field`, `image_viewer` (**`ZoomPager`** : défilement + zoom partagé par la visionneuse générique et par celle de mes photos)…), `core/theme/app_theme.dart` (charte MERUT) et `core/theme/app_background.dart` (arrière-plan en dégradé pastel de toutes les pages ; les cartes sont des surfaces translucides `AppColors.backgroundSoft`, les éléments flottants — menus, notifications — la surface pleine `AppColors.surfaceSolid`), `core/utils/` (`age`, `retry`, `message_time`).
