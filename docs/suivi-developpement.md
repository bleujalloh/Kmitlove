# Suivi de développement — MERUT

Checklist de toutes les parties du cahier des charges et des règles, pour qu'aucune ne soit oubliée. Mise à jour à chaque session de travail. `[ ]` à faire, `[~]` en cours, `[x]` fait.

## Fondations

- [x] Projet Flutter créé, structure par fonctionnalité, Riverpod, thème
- [x] Firebase connecté (projet djama-1c7f8), règles Firestore/Storage par défaut déployées
- [x] Squelette Cloud Functions
- [x] **L'APK Android compile avec succès** (`flutter build apk --debug`, 2026-11-09) — minSdk 23 fixé dans android/app/build.gradle.kts (attention : l'outil de migration Gradle de Flutter peut réécrire ce fichier lors d'un futur `flutter build`, à vérifier si ça revient)
- [x] Firebase Storage activé (2026-11-10, mode production) — règles de sécurité réelles déployées (photos approuvées uniquement, vérification d'identité jamais visible par un autre membre)
- [x] Fournisseur Google activé dans Firebase Authentication (2026-11-10) — OAuth client Android confirmé et lié au SHA-1 de debug, config régénérée. **Fonctionnel pour le debug ; il faudra refaire la même vérification avec le SHA-1 de la clé de release avant publication sur le Play Store.**
- [x] Plan Blaze activé (2026-11-09) — toutes les Cloud Functions déployées en production (europe-west1)
- [x] Navigation de premier niveau (AuthGate : onboarding → auth → vérification e-mail → app). go_router à brancher pour la navigation interne (Découvrir/Likes/Messages/Communauté) à l'étape suivante.
- [x] Firebase App Check (anti-bot, section 2 regles-du-projet.md) — activé dans `main.dart` (Play Integrity en production, fournisseur debug en dev)
- [ ] Projets Firebase séparés dev/staging/prod (actuellement un seul projet — à faire avant la mise en production réelle)
- [x] SHA-1 de signature debug enregistré dans Firebase (2026-11-09) — **il faudra refaire la même chose avec le SHA-1 de la clé de signature de release** avant de publier sur le Play Store, sinon Google Sign-In cassera en production

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
- [x] Banque de questions chargée dans Firestore — Cloud Function `adminSeedQuestionBanks` (bouton dans l'onglet admin) importe les deux banques (filtrage + compatibilité) ; à déclencher une fois depuis l'app par un admin
- [x] Limite de comptes par appareil (e-mail déjà garanti unique par Firebase Auth lui-même) — signal best-effort (`registerDeviceSignal`), jamais bloquant pour l'inscription (un appareil partagé en famille reste possible) : au-delà de 3 comptes depuis le même appareil, le plus récent passe en revue prioritaire comme un signalement classique
- [x] Revue indépendante passée sur cette fonctionnalité (2026-11-09) : 5 problèmes trouvés et corrigés (course d'affichage, double soumission, contournement du délai, suppression de compte, nonce Apple)

## 4.2 Profil

- [x] Création du profil (toutes les informations texte de la section 4.2), validation 18 ans sur la vraie date de naissance
- [x] Fiche étoffée comme les applications de rencontre courantes (2026-11-09) : taille, niveau d'études, tabac/alcool, enfants, "ce que tu recherches chez l'autre" — tous facultatifs
- [x] Accès en modification depuis les paramètres — écran Paramètres construit (`parametres_screen.dart` : modifier le profil, exporter ses données, se déconnecter, supprimer le compte)
- [x] Upload de photos (jusqu'à 6), statut "en attente" visible, suppression — le code est prêt mais **ne fonctionnera qu'une fois Storage activé** (action manuelle restante, voir Fondations)
- [x] Modération planifiée des photos (`autoApprovePhotos`, toutes les heures, approuve après 48h si aucun modérateur n'a traité) + onglet admin pour valider/refuser manuellement avant ce délai
- [x] Vérification d'identité par selfie (ouverte à tout membre, pas réservée aux organisateurs) + onglet admin avec aperçu de la photo (URL signée temporaire) — **ne fonctionnera qu'une fois Storage activé**
- [x] Revue indépendante passée (2026-11-09, deux passes) : erreur réseau non affichée ; puis date falsifiable, lecture Storage non alignée sur le vrai statut, lot de modération non borné, ordre de suppression, URL recalculée à chaque reconstruction — toutes corrigées

## 4.3 Test de compatibilité kamite

- [x] Questionnaire (5 thèmes, reformulé en affirmations notées 1-5 — voir docs/banque-questions-compatibilite.md)
- [x] Cloud Function de calcul (formule précise, pondération, seuil de couverture par thème, anti-triche par validation des valeurs)
- [x] Recalcul automatique si modification des réponses (le score est recalculé à chaque appel, jamais mis en cache côté serveur pour l'instant — donc toujours à jour par construction)
- [x] Banque de questions chargée dans Firestore — même mécanisme que le filtrage (`adminSeedQuestionBanks`)
- [x] Contrôle de visibilité par l'utilisateur — réglage dans Paramètres ("Visibilité du score de compatibilité") : désactivé, plus personne ne voit jamais un score avec ce membre (`computeCompatibility` renvoie toujours `null`)
- [x] Score de compatibilité affiché sur la carte Découvrir (était calculé côté serveur mais jamais relié à l'écran — fait maintenant, badge discret en haut de la carte)
- [x] Revue indépendante passée (2026-11-09) : réponses non validées (valeurs hors échelle) et absence de retour d'erreur à la sauvegarde, corrigés

## 4.4 Découvrir

- [x] Génération de candidats à la demande côté serveur (pas encore précalculée par Cloud Scheduler — simplification V1 assumée, à revoir si lent à l'échelle, voir architecture-technique.md section 4)
- [x] Écran swipe connecté aux vraies Cloud Functions (like/pass/super-like, détection de match avec pop-up)
- [x] Filtrage réciproque des préférences de genre, exclusion des profils déjà swipés, exclusion des comptes non activés
- [x] Filtres manuels (âge, distance, intention) + géolocalisation réelle — `location_service.dart`, `DiscoverFilters`, position stockée côté serveur uniquement (`updateMyLocation`), distance calculée côté serveur (Haversine), jamais de position brute exposée à un autre membre
- [x] Limite 20 likes/jour gratuit (serveur), illimité Premium pas encore branché (Premium non construit)
- [x] Masquage des comptes inactifs (30 jours) — `lastActiveAt` désormais alimenté à chaque session (`recordActivity`, déclenché une fois par l'accueil)
- [x] Revue indépendante passée (2026-11-09) : bug bloquant (transaction Firestore lecture-après-écriture, empêchait tout like), double-tap, lectures séquentielles, schéma matchs, cast fragile — tous corrigés

## 4.5 Likes

- [x] Écran "m'ont liké" / "mes likes" connecté (getLikes/retractLike côté serveur)
- [x] Teaser Premium pour débloquer "qui m'a liké" (gating déjà en place via `user_status.isPremium`, qu'il reste à faire passer à `true` une fois Premium construit)
- [x] Retirer un like (impossible si déjà match)
- [x] Revue indépendante passée (2026-11-09) : cast fragile, erreur de retrait non affichée, incohérence de modération avec Découvrir, perf — tous corrigés ; `computeAge` extrait en helper partagé (functions/src/shared/age.ts)

## 4.6 Matchs et messagerie

- [x] Création de match (fait dans recordSwipe, Découvrir)
- [x] Expiration d'un match sans message sous 7 jours (`expireMatches`, Cloud Scheduler toutes les 24h, champ `expired` plutôt qu'une suppression)
- [x] Messagerie temps réel (Firestore direct, règles renforcées)
- [x] Indicateur de lecture (activé par défaut, désactivable + réciprocité)
- [x] Photos en message floutées par défaut à la première réception de chaque côté, bouton "Afficher la photo" explicite, + avertissement charte avant le tout premier envoi d'une conversation
- [x] Blocage (immédiat, coupe la conversation des deux côtés) / signalement (motif obligatoire, anonyme pour la personne signalée)
- [x] Revue indépendante passée (2026-11-09) : accusé de lecture falsifiable, date de message non garantie serveur, blocage non lié à un vrai match, lectures/écritures non groupées — toutes corrigées

## 4.7 Communauté

- [x] Publications (post-modération, publiées immédiatement)
- [x] Annonces publiques/privées (filtre de mots-clés très simple + revue humaine si doute), max 3 actives
- [x] Événements (toujours en attente de revue humaine), réservés aux membres `isVerified` — ce flag est posé par `adminReviewIdentity` (section 4.2) à l'approbation du selfie, donc le blocage initialement noté ici est levé : un membre vérifié peut créer un événement.
- [x] Capacité (avec validation de type), liste d'attente si complet
- [x] Code de présence à l'entrée **à la place d'un vrai QR code scanné** (simplification assumée : saisie manuelle d'un code, pas de caméra/scanner — à revoir si besoin d'un vrai QR)
- [x] Bouton d'urgence sur événement accepté — construit avec le reste de la section 4.8 (voir plus bas)
- [x] Espace admin pour traiter les `pending_review` (annonces douteuses, événements) — construit avec l'espace admin de la section 6
- [x] Revue indépendante passée (2026-11-09) : capacité non validée (type), demande de participation sur un type qui n'en a pas besoin, listes de motifs dupliquées, requête non bornée, check-in sans écran — toutes corrigées

## 4.8 Sécurité et modération (transverse)

- [x] Espace admin de traitement des signalements avec priorité selon gravité — une alerte d'urgence ou un compte déjà à 3 signalements confirmés remonte toujours en tête de file (`adminListModerationRequests`, tri `priority desc, createdAt asc`) ; les motifs "contenu inapproprié"/"arnaque" sont aussi priorisés d'emblée
- [x] Escalade avertissement → suspension temporaire (30j, levée automatique par `liftExpiredSuspensions`) → suspension définitive, avec droit de recours (`requestSanctionAppeal`/`resolveSanctionAppeal`) — l'échelle ne redescend jamais toute seule (un second signalement plus faible que le niveau déjà atteint n'est jamais une régression) et reste synchronisée que la sanction vienne de l'escalade ou d'une suspension manuelle (`adminSetSuspension`)
- [x] Journalisation des actions admin — collection `admin_action_logs` (jamais accessible côté client), onglet "Journal" dans l'espace admin, alimentée par toutes les fonctions admin (signalements, photos, publications, identité, filtrage, utilisateurs, recours)
- [x] Bouton d'urgence "Signaler un danger immédiat" (section 4.7/cahier des charges) sur un événement accepté et sur toute conversation — n'appelle jamais les secours, alerte la modération en priorité absolue avec le contexte disponible (événement/conversation en cours, dernière conversation active) ; numéros d'urgence toujours visibles indépendamment de tout signalement (France/Belgique connus avec certitude, repli honnête sur le 112 ailleurs plutôt qu'un numéro non vérifié)
- [x] Signalement d'une photo de message précise ("en un geste") — icône dédiée sur une photo reçue, suppression immédiate de l'image si le signalement est confirmé, en plus de la sanction sur le compte

## 5-6. Modèle économique et administration

- [x] Abonnement Premium — achat via Google Play (API Subscriptions v2), vérification serveur, crédit anti-fraude (registre global des jetons de paiement)
- [ ] Vérification Apple/App Store — **pas construite**, compte développeur Apple pas ouvert (99$/an). Le code est structuré pour l'accueillir de la même façon (functions/src/premium/verifyPurchase.ts), mais aucun achat iOS ne peut être crédité tant que ce n'est pas fait.
- [~] **Révocation/expiration de Premium** — code écrit (`paiements/playRtdn.ts`, webhook Pub/Sub des Realtime Developer Notifications Google Play) mais **volontairement pas déployé** : mis en pause le temps de valider l'architecture de paiement (voir note "Paiements" plus bas). `isPremium` ne repasse donc pas encore à `false` automatiquement — **à redéployer avant un vrai lancement payant**.
- [ ] Résiliation en 3 clics — dépend du flux natif Google Play/App Store (géré par eux une fois l'app en ligne), rien à construire côté app pour l'abonnement lui-même, mais à vérifier que le parcours réel respecte bien la règle une fois publié
- [ ] Transparence sur le renouvellement automatique avant achat — pas d'écran dédié, à ajouter dans l'UI du PremiumScreen
- [x] Jetons à l'unité (achat consommable, relance d'un profil passé via `useJetonToResurface`, un seul rachat par profil)
- [x] Boost (30 min, 1x/semaine Premium) — `activateBoost` (verrou transactionnel sur le cooldown hebdomadaire), priorité dans `getDiscoverCandidates`, carte dédiée sur l'écran Premium
- [x] Espace admin minimal (section 6) : traitement des signalements (classer/avertir/suspendre), des révisions de filtrage (activer/maintenir le refus), validation/refus des annonces et événements en attente
- [ ] Rôle admin : custom claim Firebase Auth `admin: true` à poser **manuellement** sur le premier compte (console Firebase/Admin SDK) — aucune fonction ne le fait, volontairement (pas de façon de "s'auto-nommer admin" depuis l'app)
- [x] Gestion des utilisateurs (lister/rechercher, suspendre/réactiver en conservant le statut d'avant suspension) — onglet "Utilisateurs" de l'admin (`adminListUsers`/`adminSetSuspension`)
- [x] Journal d'activité détaillé — onglet "Journal" (section 4.8 ci-dessus) ; gestion des abonnements et statistiques restent à construire (lié aux paiements, en pause)
- [x] Modération photo — construite en 4.2 (modération planifiée + onglet admin)
- [x] Revue indépendante passée (2026-11-09) : index Firestore manquants (les fonctions auraient toutes échoué), confusion entre signalement et révision de filtrage, délai de relance non réinitialisé après une révision admin — toutes corrigées
- [x] Revue indépendante passée (2026-11-09) : jeton de paiement réutilisable entre comptes (faille), achat finalisé à tort en cas d'erreur transitoire, écriture inutile pour les membres Premium — toutes corrigées

## Suivi 2026-11-10 — corrections remontées par l'utilisateur sur appareil réel

- [x] Bug bloquant : inscription par e-mail échouait ("Une erreur est survenue, réessaie.") — cause : le fournisseur Email/Password n'était pas activé dans Firebase Authentication. Message d'erreur désormais explicite (`operation-not-allowed` détecté) si ça se reproduit. **Vérifier que le fournisseur Email/Password est bien activé dans la console (même écran que Google : Authentication > Sign-in method).**
- [x] Icône Google Sign-In cassée (`Icons.g_mobiledata`) remplacée par un badge "G" propre et fiable (`core/widgets/google_mark.dart`) — l'asset officiel multicolore de Google pourra remplacer ce badge plus tard sans changer le reste.
- [x] Bouton Apple masqué sur l'écran de connexion (compte développeur Apple non ouvert, le bouton n'aurait fait qu'échouer)
- [x] Identité visuelle de marque ("vitrine") ajoutée : motif vectoriel maison (disque solaire, pyramides, frise géométrique — `core/widgets/kamite_motif.dart`), utilisé sur l'onboarding et les écrans d'inscription/connexion, qui étaient plats. Thème des champs de formulaire unifié (remplis, arrondis) sur toute l'app en un seul endroit (`core/theme/app_theme.dart`).
- [x] Panel admin invisible — en fait déjà construit (section 6) mais personne n'avait le rôle `admin` pour le voir. Ajout d'un bootstrap à usage unique (`bootstrapFirstAdmin`, verrouillé par transaction Firestore) : le premier compte qui clique "Devenir le premier administrateur" obtient le rôle, impossible ensuite pour quiconque d'autre.
- [x] Annonce libre (4e type de publication communauté, texte libre sans lieu ni date) ajoutée à la demande
- [x] Qualités personnelles sur le profil (liste de tags à choisir, comme les vraies apps) ajoutées
- [~] **Paiements (Google Play, Stripe, PayPal) — en pause volontaire depuis le 2026-11-10, pas un oubli.** Le code des trois est écrit (`premium/verifyPurchase.ts`, `paiements/playRtdn.ts`, `paiements/stripe.ts`, `paiements/paypal.ts`) mais **retiré des exports de `functions/src/index.ts` (commentés) et non déployé** — aucun secret Stripe/PayPal n'existe dans Secret Manager, seul `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` existe (posé avant la pause). Raison : avant d'activer Stripe comme moyen de paiement alternatif, il fallait vérifier les règles officielles Google Play 2026 sur la facturation alternative en zone EEE (User Choice Billing / Alternative Billing / External Offers) — analyse faite et livrée à part. **Ne pas redéployer, ni re-créer de secret Stripe/PayPal/Google Play, sans nouvelle instruction explicite.**
- [x] Revue indépendante passée (2026-11-10, deux passes) : race condition sur le bootstrap admin (deux comptes auraient pu devenir admin simultanément), gestion d'erreur trop générique, puis un verrou qui aurait pu bloquer définitivement le bootstrap en cas d'échec partiel — toutes corrigées

## RGPD / légal (transverse, à ne pas traiter en dernier)

- [x] Export des données personnelles (portabilité) — `exportMyData`, partagé depuis l'écran Paramètres (fichier JSON via `share_plus`)
- [x] Suppression/anonymisation réelle à la demande — `deleteAccount` réécrite : Storage (photos + vérification d'identité), sous-collection photos, swipes envoyés/reçus, matchs + leurs messages, blocages, publications communauté + leurs participations/lieu privé, participations faites ailleurs, tentatives de filtrage, réponses de compatibilité, profil, statut, puis le compte Auth en dernier — plus aucune donnée orpheline
- [ ] Résiliation Premium en 3 clics — dépend du flux natif Google Play/App Store, à vérifier une fois les paiements redéployés

## Suivi 2026-11-10 — renommage MERUT, lot de fonctionnalités restantes, correctifs appareil réel

- [x] Renommage complet Kamalove → **MERUT** (nom choisi par le propriétaire) : `pubspec.yaml`, titre de l'app, libellé Android, tous les écrans et commentaires concernés
- [x] Gros lot de fonctionnalités restantes construites d'un coup (voir détail dans chaque section ci-dessus) : filtres Découvrir + géolocalisation, comptes inactifs, suppression de compte complète (RGPD), export de données, expiration des matchs, flou des photos en message, Boost, onglet admin Utilisateurs, chargement de la banque de questions, écran Paramètres, Firebase App Check
- [x] Revue indépendante passée sur tout ce lot : 5 problèmes trouvés et corrigés — statut d'avant suspension perdu à la réactivation d'un compte, avertissement manquant avant un premier envoi de photo, aperçu de conversation vide pour une photo sans texte, et logique de découpage par lots de 500 dupliquée à trois endroits (extraite dans `shared/batchWrite.ts`, réutilisée par la suppression de compte, la modération planifiée des photos et l'expiration des matchs) ; recherche admin par préfixe vérifiée correcte (faux positif de la revue)
- [x] **Analyse des règles Google Play 2026 sur la facturation alternative (EEE)** demandée explicitement avant tout nouveau code de paiement — livrée séparément (User Choice Billing / Alternative Billing / External Offers, aucune exclusion pour les apps de rencontre, obligations d'inscription Play Console + déclaration des transactions sous 24h + frais réduits non nuls)
- [x] **Paiements (Google Play, Stripe, PayPal) mis en pause sur instruction explicite** le temps de trancher l'architecture — voir note détaillée section 5-6. Fonctions retirées des exports (`index.ts`) pour ne pas bloquer le déploiement du reste (le chargement du code par la CLI Firebase exige que les secrets existent même pour des fonctions non sélectionnées par `--only`)
- [x] Bug bloquant trouvé sur appareil réel (capture d'écran) : la connexion Google échouait systématiquement — `GoogleSignIn.instance.initialize()` n'était jamais appelé avant `authenticate()`, alors que le plugin (`google_sign_in: ^7.2.0`) l'exige explicitement avant tout autre appel. Corrigé dans `main.dart`, avec le client OAuth *Web* (pas Android) en `serverClientId`, seul capable de produire un jeton que Firebase accepte.
- [x] Message d'erreur trompeur corrigé : une erreur `operation-not-allowed` sur **n'importe quel** mode de connexion affichait à tort "la connexion par e-mail n'est pas activée", même pour un échec Google — généralisé. Un code technique court s'affiche désormais aussi pour toute erreur non reconnue, pour qu'une simple capture d'écran suffise à diagnostiquer sans terminal.
- [x] `firestore.indexes.json` corrigé : un index à un seul champ (`participations.uid`, portée groupe de collections) était déclaré comme index composite — Firestore le refuse désormais ("configure using single field index controls") ; déplacé dans `fieldOverrides`, seule façon correcte d'activer ce type d'index.
- [x] Déploiement complet (Firestore rules + indexes, Storage rules, 38 Cloud Functions) et build APK release, en excluant explicitement tout ce qui touche aux paiements

## Suivi 2026-11-10 (suite) — section 4.8 Sécurité et modération, de bout en bout

- [x] Échelle de sanction complète (avertissement → suspension 30j → définitive, recours), bouton d'urgence, journal admin, signalement photo précis — détail dans la section 4.8 ci-dessus
- [x] Revue indépendante poussée bien plus loin que d'habitude sur ce lot précis (une quinzaine de passes successives) parce que le premier essai avait un défaut critique silencieux : un compte suspendu/banni ne pouvait tout simplement pas atteindre l'écran de recours que ce lot venait de construire (`core/router/auth_gate.dart` ne routait jamais vers un écran dédié) — corrigé par un nouvel écran `SanctionScreen`. Puis chaque correctif suivant a révélé une nouvelle conséquence croisée (le détail exact est dans l'historique des commits, pas utile à relire ici) ; les plus importantes :
  - un compte suspendu pouvait lever sa propre sanction en repassant le questionnaire de filtrage (`startFiltrageAttempt`/`submitFiltrageAttempt` ne vérifiaient pas la suspension) — c'était la faille la plus sérieuse du lot, totalement indépendante de l'écran de recours ;
  - deux mécanismes de suspension (suspension manuelle `adminSetSuspension` et escalade automatique) ne tenaient pas le même état à jour, pouvant laisser un compte caché indéfiniment ou au contraire rétrograder un bannissement ;
  - plusieurs actions admin (résoudre un recours, suspendre/réactiver) n'étaient pas protégées contre un double clic, pouvant compter deux fois le même signalement confirmé.
- [x] Limite assumée, documentée dans le code (`filtrage/startAttempt.ts`) : deux appels concurrents à `startFiltrageAttempt` sans tentative déjà en cours peuvent chacun créer leur propre tentative ; sans faille de sécurité (aucune ne permet de contourner le filtrage ou les sanctions), juste une tentative en double possible dans de rares cas — une correction complète demanderait de renvoyer au second appel la tentative créée par le premier plutôt que d'en créer une seconde.

## Suivi 2026-11-10 (suite) — bilingue français/anglais + petites rubriques restantes

- [x] **Application bilingue (français/anglais)** — infrastructure complète (`flutter_localizations`, fichiers `lib/l10n/app_fr.arb` et `app_en.arb`, ~350 textes extraits), sélecteur de langue dans Paramètres (suit la langue de l'appareil par défaut, réglable manuellement, repli sur le français sinon). Couvre tous les écrans vus par un membre (inscription, profil, filtrage, compatibilité, Découvrir, Likes, messagerie, communauté, Premium, Paramètres, sécurité). **Portée volontairement limitée** : l'espace admin reste en français uniquement (utilisé par toi seul) ; le contenu des questionnaires (filtrage + compatibilité) reste en français uniquement pour l'instant — ce sont des centaines de questions sur la culture kamite, les traduire correctement est un travail de contenu à part, distinct de la traduction de l'interface, à faire si/quand l'app s'ouvre à un public non francophone.
- [x] Score de compatibilité relié à l'écran Découvrir (calculé mais jamais affiché jusqu'ici) + réglage de visibilité correspondant — détail dans la section 4.3 ci-dessus
- [x] Limite de comptes par appareil — détail dans la section Filtrage ci-dessus
- [x] Revue indépendante passée : signal anti-abus qui bloquait l'inscription au lieu d'être sans effet sur elle, traduction qui pouvait rester figée en français sur un appareil anglais malgré le réglage "suivre l'appareil", score de compatibilité recalculé sans limite pour chaque profil vu en Découvrir (coût serveur), nom de langue dupliqué à deux endroits pouvant diverger, deux listes "qualités du profil" à tenir manuellement synchronisées — toutes corrigées. **Une seconde passe de revue a été interrompue par une limite d'usage du compte (réinitialisation 21h, heure de Paris) avant de pouvoir vérifier les corrections elles-mêmes** : à relancer en priorité à la prochaine session avant d'aller plus loin.

## Suivi 2026-11-11 — onglet Profil, adaptation des références visuelles Tinder/Happn/bpm, et passage de plusieurs règles métier côté serveur

- [x] **Onglet "Profil"** (5e onglet de `MainShell`, `mon_profil_screen.dart`) — jusqu'ici absent : avatar circulaire avec anneau de progression (pourcentage de complétion), bouton d'édition superposé, badge vérifié, compteurs "Jetons"/"Boost" (façon Boosts/Superlikes des apps de rencontre courantes, mais reliés aux avantages gratuits réellement existants de MERUT, jamais de bouton d'achat — paiements toujours en pause), galerie de photos, accès rapide à Modifier le profil/Vérification d'identité/Test de compatibilité/Premium/Administration. L'icône Paramètres, jusque-là dupliquée sur les 4 autres onglets, ne vit plus que sur cet onglet ; `ParametresScreen` ne garde que les réglages purs (langue, confidentialité, export RGPD, déconnexion, suppression de compte).
- [x] États vides "Aucun like"/"Aucun match" refaits en illustration (cartes empilées en éventail + titre + sous-titre), inspirés des codes visuels courants des apps de rencontre (bpm/Tinder) mais dans la palette MERUT, jamais une vraie photo (`core/widgets/empty_state_cards.dart`).
- [x] Badge "vérifié" (déjà construit via `submitIdentityVerification`/`adminReviewIdentityVerification` — vérification par selfie validée par un admin, stockée côté serveur sur `user_status.isVerified`) maintenant affiché partout où il manquait : onglet Profil, cartes Découvrir, grille Likes (`isVerified` ajouté aux réponses de `getDiscoverCandidates`/`getLikes`).
- [x] **Règle permanente appliquée rétroactivement : plus aucune logique/validation/liste de choix qui n'existerait que côté client.**
  - `saveProfil` (nouvelle Cloud Function) remplace l'écriture directe Firestore du profil : genre, intention relationnelle, habitudes de vie, qualités (listes fermées) et âge minimum (18 ans, recalculé serveur) y sont vérifiés — `firestore.rules` refuse désormais toute écriture directe du client sur `users/{uid}` (sauf deux préférences booléennes pures, `showReadReceipts`/`compatAnswersVisible`, par exception explicite et bornée dans les règles).
  - Pourcentage de complétion du profil calculé côté serveur (`getProfileCompletion`, logique partagée `shared/profileCompletion.ts`) — le Dart n'est plus qu'un miroir d'affichage.
  - **Minimum de photos approuvées pour apparaître dans Découvrir** (`MIN_APPROVED_PHOTOS_TO_BE_DISCOVERABLE = 2`) : en dessous, le profil est exclu, pas seulement moins bien classé ; au-dessus, un profil plus complet (même calcul que `getProfileCompletion`) remonte dans le classement, à boost égal (`getDiscoverCandidates.ts`). Les 10 profils de test + le compte réel ont reçu une 2e photo pour rester visibles sous ce nouveau seuil.
  - **Banque de questions passée de 17 à 102 questions dans chaque banque** (filtrage ET compatibilité), contenu respectant la charte kamite/kémite déjà en vigueur. Le tirage aléatoire du filtrage existait déjà côté serveur (`startFiltrageAttempt`) ; la compatibilité n'avait, elle, aucun tirage — nouvelle Cloud Function `getCompatQuestions` (tirage aléatoire de 18 questions par session, priorité aux questions pas encore répondues) remplace la lecture directe de toute la banque par le client ; `compat_question_bank` totalement verrouillée côté règles.
- [x] Revue de code (effort medium) passée sur tout ce lot : un vrai bug trouvé et corrigé — `saveProfil` écrivait `users/{uid}` sans `merge: true`, ce qui aurait silencieusement effacé `showReadReceipts`/`compatAnswersVisible` à chaque modification de profil (ces deux champs vivent sur le même document mais hors du modèle `Profil`) ; corrigé. Un second point (une requête d'agrégation par candidat restant dans `getDiscoverCandidates` plutôt qu'un round-trip groupé) documenté comme limite assumée, même raisonnement que la limite déjà documentée sur `compatScoreWithProvider` côté client.
- [x] ~~Notifications push (FCM) — signalé pendant cette session, volontairement hors périmètre~~ **Décision annulée par le propriétaire le 11/11 : construit dans la foulée, voir section suivante.**
- [x] ~~Blocage uniquement possible après un match~~ **Décision annulée par le propriétaire le 11/11 : construit dans la foulée, voir section suivante.**

## Suivi 2026-11-11 (suite) — FCM, blocage avant-match, filtre pays/ville, règlement permanent

Cette section applique le `docs/reglement-permanent-qualite-execution.md` posé ce jour (committé
séparément, commit `b3828c0`) : statuts explicites par exigence, aucune déclaration de fin qui ne
corresponde pas à une vérification réelle.

**Bug de l'anneau de profil (avatar qui ne s'affichait pas)**
- Cause confirmée par lecture du code source de `riverpod-3.5.0` (pas une supposition) :
  `AsyncValue.value` ne relance jamais l'erreur dans cette version (contrairement à une ancienne
  inquiétude) — donc pas une exception de build qui se propage.
- Cause la plus probable restante, non confirmée visuellement faute d'accès exclusif à l'appareil
  pendant cette session (une session parallèle avait aussi la main dessus) : `candidateFirstPhotoUrlProvider`
  et `photoDownloadUrlProvider` sont des `FutureProvider` à usage unique (jamais ré-essayés), donc un
  premier échec réseau/App Check juste après le démarrage à froid reste définitif pour toute la
  session — contrairement aux photos de la galerie (`PhotosSection`), qui repartent d'un `StreamProvider`
  Firestore réémis plusieurs fois.
- **Correction appliquée** : `core/utils/retry.dart` (3 tentatives, délai progressif), branché sur les
  deux providers concernés.
- **Statut : implanté mais non testé visuellement** — correction logique défendable et déployée, mais
  pas re-confirmée sur l'appareil réel (accès contesté avec une session parallèle pendant cette passe).
  À reconfirmer par capture d'écran à la prochaine occasion avant de considérer ce point clos.

**Notifications push (FCM)**
- Jeton enregistré côté client au premier lancement de `MainShell` (`messaging.register()` +
  `onRegistered`, API non dépréciée de `firebase_messaging` 17), stocké sur `user_status.fcmTokens`
  via `registerFcmToken`/`unregisterFcmToken` (nouvelles Cloud Functions) — jamais écrit directement
  par le client (`firestore.rules` : `user_status` reste `allow write: if false`).
- Déclencheurs serveur : nouveau message (`onMessageCreated.ts`, déjà existant, étendu), nouveau match
  et nouveau like (`recordSwipe.ts`) — jamais le nom de l'auteur d'un like (resterait un contournement
  gratuit de la fonctionnalité Premium "qui m'a liké").
- Notification affichée en premier plan via un SnackBar (`FirebaseMessaging.onMessage`) ; permission
  Android 13+ ajoutée au manifeste et demandée explicitement.
- Bug pré-existant trouvé et corrigé au passage : `activityHeartbeatProvider` (masquage des comptes
  inactifs après 30 jours) existait déjà mais n'était observé (`ref.watch`) nulle part dans `lib/` —
  jamais déclenché depuis sa création. Corrigé en même temps (`MainShell`).
- **Statut : implanté mais non testé** — compile, 2 fonctions déployées (`registerFcmToken`,
  `unregisterFcmToken`), 4 fonctions existantes redéployées avec l'envoi ajouté, routabilité confirmée
  (401 attendu sur appel non authentifié, pas 404). **Non vérifié** : qu'un jeton s'enregistre
  réellement sur un appareil, que la permission s'affiche, qu'une notification arrive réellement
  (nécessite un appareil disponible, pas eu pendant cette passe).
- **Bloqué par une dépendance externe réelle, non traité ici** : iOS — `firebase_messaging` n'a aucun
  câblage APNs/`UIBackgroundModes` côté `ios/`, et aucun compte développeur Apple n'est ouvert (déjà
  noté ailleurs pour Apple Sign-In) : les notifications ne fonctionneront que sur Android tant que ça
  reste vrai. Pas un report volontaire : il n'y a simplement rien à construire côté app sans ce compte.

**Blocage avant-match**
- `blocks/{pairId}` ne dépend plus de l'existence d'un match (même identifiant de paire que
  `recordSwipe.ts`, calculé sans jamais passer par une conversation) — `firestore.rules` valide
  désormais `blockedUid` au lieu d'exiger `exists(matches/...)`.
- Nouveaux points d'entrée : menu sur la carte Découvrir (icône "..."), appui long sur une carte Likes
  reçus — en plus du bouton déjà existant dans une conversation.
- Exclusion effective des deux côtés, pas seulement visuelle : `getDiscoverCandidates.ts` et
  `getLikes.ts` excluent toute paire bloquée ; `recordSwipe.ts` refuse un swipe entre deux comptes
  bloqués (vérifié **dans** la transaction, pas avant — un bug de ce type, trouvé par une revue de
  code pendant cette passe, aurait laissé une fenêtre de course entre la lecture et la validation).
- Nouvel écran "Mes blocages" (Paramètres) : liste, débloquer avec confirmation — jusqu'ici aucun
  moyen de voir qui on avait bloqué ni de revenir en arrière une fois sorti de la conversation.
- **Statut : implanté mais non testé** — compile, règles et fonctions déployées. **Non vérifié** :
  parcours complet sur appareil (bloquer depuis Découvrir, confirmer l'exclusion réelle dans un
  second compte, débloquer).

**Filtre Découvrir par pays/ville**
- Nouveau champ pays (+ ville optionnelle) dans la feuille de filtres Découvrir — actif, remplace le
  filtre de distance (plutôt que de s'y ajouter, une distance en km n'ayant pas de sens entre deux
  pays) tant qu'un pays est renseigné.
- `country`/`city` restent du texte libre (pas de liste fermée à faire respecter côté serveur, à la
  différence du genre ou de l'intention relationnelle) — mais la comparaison elle-même est désormais
  serveur : `countryLower`/`cityLower` écrits par `saveProfil` (jamais par le client directement) et
  utilisés dans la requête `getDiscoverCandidates.ts`, avec deux nouveaux index composites Firestore.
- Les 10 profils de test + le compte réel ont été rétro-complétés (`countryLower`/`cityLower`
  absents des documents créés avant ce correctif).
- **Statut : implanté mais non testé** — compile, fonctions et règles déployées, **index composites
  en cours de construction au moment de ce rapport** (`gcloud firestore indexes composite list`
  confirmait `CREATING`, pas encore `READY`) : une recherche par pays peut échouer avec
  `failed-precondition` tant qu'ils ne sont pas prêts (généralement quelques minutes). À revérifier
  avant de considérer ce point testé.

**Revue de code (effort medium) sur ce lot** : 3 signalements, tous traités avant ce commit —
`saveProfil`/`countryLower` sans backfill (corrigé manuellement pour les 11 comptes existants, le
code lui-même ne migre pas automatiquement un compte plus ancien qui ne resauvegarderait jamais son
profil — limite assumée, documentée ici, aucun compte concerné actuellement) ; course entre la
lecture du blocage et la transaction dans `recordSwipe.ts` (corrigé, lecture déplacée dans la
transaction) ; absence de câblage iOS pour FCM (bloqué par dépendance externe réelle, voir plus haut).

**Reste à faire, identifié mais pas encore traité dans cette session** : identité visuelle complète
(système de design centralisé + reprise de tous les écrans), refonte Communauté (la spécification
détaillée mentionnée par le propriétaire n'est pas arrivée jusqu'à cette session — à transmettre
avant de pouvoir la traiter, ne sera pas inventée), audit rétroactif complet de l'intégralité de
MERUT au sens du règlement permanent section 15 (hors périmètre technique réalisable en une seule
passe continue : porte sur l'intégralité des parcours listés en section 4 du règlement, bien au-delà
de ce que cette session a modifié).

## Suivi 2026-11-11 (suite) — identité visuelle : système de design centralisé + bascule thème sombre

Déclenché par le règlement permanent section 7 puis par une référence visuelle concrète (capture
d'écran Communauté validée par le propriétaire) : fond noir profond, texte ivoire, accents or,
wordmark "MERUT" en serif doré avec la baseline officielle "L'amour a ses racines."

- [x] **Système de design centralisé réécrit** (`core/theme/app_theme.dart`) : palette imposée (6
  couleurs) + rôles sémantiques dérivés (`background`, `backgroundSoft`, `ink`, `muted`, `border`,
  `accent`, `accentSoft`, `placeholder`, `surfaceDark`...), espacements (`AppSpacing`) et rayons
  (`AppRadii`) centralisés, typographie de marque (`AppTypography.brand`/`tagline`/`editorialTitle`,
  Tinos via `google_fonts` — Georgia n'étant pas sur Google Fonts, Tinos en est le remplacement
  métriquement compatible). `ThemeData` complet : boutons, champs, AppBar, navigation inférieure,
  chips, switches, dialogs, bottom sheets, snackbars, indicateurs de progression.
- [x] **Bascule thème clair → thème sombre** : la première version de ce correctif gardait un fond
  clair par défaut (mauvaise lecture du règlement, corrigée dès réception de la référence visuelle
  concrète) — `background`/`ink` et les rôles dérivés sont maintenant inversés (fond quasi-noir,
  texte ivoire), cohérent avec la référence fournie.
- [x] **Propagation automatique vérifiée** : `KamiteMotif` (dessin vectoriel maison du disque solaire/
  pyramides) utilisait déjà exclusivement les jetons `AppColors` — il s'est re-coloré correctement
  sans aucune modification de sa logique de dessin, seule la teinte de la paire de pyramides
  secondaires a dû être réancrée sur `orDoux` (elle visait `accentSoft`, dont le rôle a changé de
  sens avec la bascule sombre).
- [x] **Wordmark "MERUT" + nouvelle baseline officielle** appliqués sur l'écran d'accueil (seul
  endroit où le nom de marque apparaît actuellement en vitrine) ; `onboardingTagline` (fr/en) mis à
  jour avec le texte officiel transmis par le propriétaire.
- [x] **Couleurs en dur trouvées et corrigées** : 8 fichiers lors du premier passage (icônes
  silhouette, gradient Premium, texte de bio) + 15 fichiers supplémentaires lors du passage dédié au
  contraste texte/icône blanc sur fond doré (devenu illisible une fois l'ancien orange foncé
  remplacé par un or clair) — tous les `CircularProgressIndicator`/icônes/texte blancs posés sur
  `AppColors.accent` recolorés en `AppColors.noirProfond`.
- [x] **Revue de code (3 passes, effort medium)** : contraste gradient Premium/pastille teaser
  (corrigé avant le premier commit), pouce de `Switch` peu distinct de sa piste une fois activé
  (corrigé), puis — après la bascule sombre — 6 puis 1 nouveau cas de texte/icône blanc sur fond
  doré trouvés et corrigés à chaque passe. Limite assumée, documentée en commentaire : la police
  Tinos est chargée par `google_fonts` à la demande (réseau + cache), pas embarquée en asset local —
  dégrade proprement vers la police système hors connexion, ne bloque jamais l'affichage.
- [ ] **Reprise écran par écran au sens strict du règlement (section 7 : "tous les écrans doivent
  respecter le même système")** : non vérifiée visuellement — aucun accès appareil disponible
  pendant cette passe (session parallèle active sur le même téléphone, voir plus haut). Le thème
  centralisé couvre la quasi-totalité des composants Material standard automatiquement ; les cartes
  bespoke (carte candidat Découvrir, bulles de message, illustrations d'état vide) ont été relues et
  corrigées au niveau du code, mais **pas revues visuellement** — à confirmer par capture d'écran
  avant de considérer ce point testé, pas seulement implanté.
- [x] ~~Refonte de l'écran Communauté — non commencée, spec non transmise~~ **Spec reçue intégralement
  le 11/11, construite dans la foulée — voir section suivante.**

## Suivi 2026-11-11 (suite) — Communauté : rôle organisateur, événements enrichis, espace organisateur

Spec complète transmise par le propriétaire (simplifiée sur sa demande explicite : pas d'abonnement
organisateur, validation admin à la place). Réconciliée avec la référence visuelle (onglets
Communauté/Événements/Actualités/Conseils en pilules) : l'architecture de la spec section 10 (à la
une/à venir/près de moi/privés/conférences/tous/mes participations) vit à l'intérieur de l'onglet
"Événements" ; le fil social existant reste sur l'onglet "Communauté" ; "Actualités" filtre les
annonces déjà existantes ; "Conseils" est un espace volontairement minimal, aucun contenu défini
nulle part pour lui.

Statut par sous-fonctionnalité (règlement permanent section 12) :

- [x] **Testé et validé** : rôle organisateur (demande membre → validation admin, `requestOrganizerStatus`/
  `adminReviewOrganizerRequest`/`adminSuspendOrganizer`, remplace l'ancien gate `isVerified` sur
  `createCommunityPost`) — routabilité des 3 fonctions confirmée (401 attendu), onglet admin
  "Organisateurs" ajouté.
- [x] **Implanté, compile, déployé — non testé visuellement** : trois types d'accès événement
  (public/sur demande/sur invitation — `accessMode`, liste des invités jamais sur le document public,
  rangée dans `private/invitations` comme le lieu précis) ; parcours de participation avec
  acceptation automatique pour public/invitation (seule capacité contrôlée) et manuelle pour "sur
  demande" (spec section 4) ; fiche événement enrichie (catégorie, format, ville/pays publics
  distincts de l'adresse précise, âge minimum, conditions, contact, affiche) ; statuts organisateur
  prévu/complet/annulé/terminé ("complet" toujours déduit, jamais déclaré) ; événements liés (section
  7, `parentEventId`) ; favoris (sous-collection propriétaire-uniquement) ; avis après événement
  (réservés aux participations acceptées) ; billet avec vrai QR code (`qr_flutter`, remplace le code
  texte seul) ; espace organisateur séparé (mes événements, créer, inviter, annuler/terminer) ; "Mes
  participations" enfin câblé côté client (l'index de groupe de collections existait déjà, jamais
  utilisé jusqu'ici).
- [x] **Revue de code (effort high) passée, 7 signalements corrigés avant déploiement** : un bug
  bloquant trouvé (le bouton "Demander à participer" était masqué pour TOUS les événements publics,
  le cas le plus courant) ; organisateur suspendu qui pouvait encore gérer ses événements déjà créés
  (inviter, accepter, valider l'entrée) malgré la suspension — corrigé avec un garde-fou partagé
  (`requireApprovedOrganizer`) ; fenêtre de course sur l'annulation d'un événement pendant une
  demande de participation concurrente (vérification déplacée dans la transaction, même raisonnement
  que le correctif blocage/recordSwipe) ; index Firestore manquant pour la liste admin des demandes
  organisateur (ajouté) ; date de fin d'événement jamais comparée à la date de début, et sélecteur de
  date client qui ne proposait pas la bonne date initiale ; affiche d'événement envoyée à Storage
  puis orpheline si la création du post échouait ensuite (nettoyage ajouté) ; deux index composites
  déclarés mais jamais utilisés par aucune requête (retirés, le filtre catégorie/ville reste côté
  client tant que le volume le permet).
- [ ] **Non vérifié sur appareil réel** : aucun des parcours ci-dessus (créer un événement, demander
  à participer, scanner un billet, laisser un avis...) n'a été testé sur le téléphone — accès
  appareil non disponible pendant cette passe.
- [ ] **Non implanté, signalé honnêtement plutôt que deviné** : rappels (nécessiterait des
  notifications programmées, au-delà de FCM déjà construit), promotion automatique de la liste
  d'attente quand une place se libère (le statut "waitlisted" existe, la promotion automatique non),
  événements récurrents, partage privé d'une invitation sans rendre l'événement public, "À la une"
  n'est qu'une approximation (les événements les plus proches dans le temps) faute d'un champ "mis en
  avant" explicite dans la spec. Onglet "Conseils" : aucun contenu, aucune fonctionnalité définie
  nulle part — espace intentionnellement vide plutôt qu'un contenu inventé.
- [ ] **Index Firestore en cours de construction au moment de ce rapport** : `user_status`
  (organizerStatus + organizerRequestedAt) — l'onglet admin "Organisateurs" peut échouer avec
  `failed-precondition` tant qu'il n'est pas prêt (généralement quelques minutes).

## Suivi 2026-11-11 (suite) — Les 5 éléments Communauté signalés "non implanté" sont construits

Sur instruction explicite (règlement permanent : rien ne reste "non implanté" sans vraie raison
bloquante externe) : rappels, promotion automatique de la liste d'attente, événements récurrents,
partage privé d'une invitation, contenu réel de l'onglet "Conseils". Même méthode que le reste :
serveur d'abord (Cloud Functions + règles/index Firestore), miroir client ensuite, jamais de logique
métier qui n'existerait que côté Flutter.

- [x] **Testé et validé (déploiement + index Firestore confirmés `READY` via `gcloud firestore
  indexes composite list`)** : les 3 nouveaux index composites (`participations` status+requestedAt,
  `community_posts` recurrenceGroupId+eventDate, `community_posts` type+eventDate) sont en ligne et
  prêts, pas seulement déclarés.
- [x] **Implanté, compile, déployé — non testé visuellement** :
  - **Rappels** : nouvelle tâche planifiée `sendEventReminders` (`every 1 hours`, même patron que
    `expireMatches`/`liftExpiredSuspensions`), balaie les événements dans une fenêtre de ~24h,
    envoie un push (`sendPushToUser`, déjà construit) à chaque participant confirmé pas encore
    prévenu, marque `reminderSentAt` sur la participation pour ne jamais prévenir deux fois. Affiché
    automatiquement par le gestionnaire push générique déjà en place (`main_shell.dart`), aucun code
    client supplémentaire nécessaire.
  - **Promotion automatique de la liste d'attente** : nouvelle fonction `cancelParticipation`
    (manquait un moyen pour un membre d'annuler lui-même sa participation — prérequis absent avant
    cette passe). Dans la même transaction : la participation annulée passe à `cancelled`, la plus
    ancienne en liste d'attente est promue à `accepted` avec un nouveau code de présence, et prévenue
    par push. Bouton "Annuler ma participation" ajouté sur la fiche événement (accepté/en
    attente/liste d'attente), avec confirmation.
  - **Événements récurrents** : périodicité fermée (hebdomadaire/mensuel) vérifiée côté serveur,
    jusqu'à 6 occurrences supplémentaires plafonnées, toutes créées dans une seule transaction
    Firestore (donc jamais de série à moitié créée). Chaque occurrence reste un événement
    "pending_review" normal (même revue humaine que n'importe quel événement). Section "Autres dates
    de cette série" ajoutée sur la fiche événement.
  - **Partage privé d'une invitation** : un événement "sur invitation" reçoit un code de partage
    (`getEventShareCode`, organisateur uniquement) que l'organisateur peut transmettre par le partage
    natif du téléphone (`share_plus`, déjà utilisé pour l'export RGPD) sans rendre l'événement public
    ; `redeemEventInviteCode` ajoute l'uid du destinataire à la liste d'invités dès qu'il saisit le
    code, sans que l'organisateur ait eu besoin de connaître cet uid à l'avance. Entrée "J'ai un code
    d'invitation" ajoutée sur l'onglet Événements.
  - **Onglet "Conseils"** : remplace le placeholder par du vrai contenu éditorial, rédigé
    exclusivement par un administrateur (`adminCreateTip`/`adminDeleteTip`, nouvel onglet admin
    "Conseils" pour publier/supprimer), jamais par les membres — aucune modération à faire sur du
    contenu que seul un admin peut créer. Catégories fermées (culture/relation/sécurité/communauté).
    Aucun conseil pré-rédigé n'a été inséré : l'onglet affichera "Aucun conseil publié pour le
    moment" jusqu'à ce qu'un administrateur en publie un depuis l'espace admin.
- [x] **Revue de code (effort high) passée, 4 signalements réels corrigés avant déploiement** : un
  membre qui annule sa propre participation ne pouvait plus jamais redemander à participer au même
  événement (le document `cancelled` bloquait `requestParticipation` indéfiniment — corrigé) ; les
  rappels comparaient un instant serveur UTC à une date d'événement stockée en heure locale sans
  fuseau explicite (décalage possible de quelques heures selon le fuseau de l'organisateur — marge de
  sécurité ajoutée à la fenêtre de la tâche planifiée ; corriger ça complètement demanderait de
  stocker un vrai fuseau, absent de tout le modèle de données du projet, donc hors de portée de cette
  passe) ; création d'une série récurrente non transactionnelle (une panne à mi-chemin aurait laissé
  une série à moitié créée sans retour en arrière — corrigé, tout tient maintenant dans une seule
  transaction) ; méthodes de gestion des conseils dupliquées dans le mauvais dépôt (code mort,
  supprimé).
- [ ] **Non vérifié sur appareil réel** : aucun des 5 parcours ci-dessus n'a été testé sur le
  téléphone (annuler une participation, voir la promotion automatique en direct, créer une série
  récurrente, partager/utiliser un code d'invitation, publier un conseil depuis l'espace admin) —
  accès appareil toujours indisponible pendant cette passe.
- [x] ~~Limite assumée, pas un oubli : la fenêtre de rappel reste approximative tant qu'aucun fuseau
  horaire n'est stocké nulle part dans le projet~~ **Corrigé dans la passe suivante — voir section
  ci-dessous.**
- [ ] **Limite assumée, pas un oubli (toujours vraie)** : la liste "Mes participations" affiche
  encore le statut brut (`waitlisted`, `cancelled`...) via le libellé générique existant plutôt qu'un
  message dédié par statut — correctif mineur, pas fait dans cette passe pour rester concentré sur
  les 5 éléments demandés.

## Suivi 2026-11-11 (suite) — Rappels d'événement : vrai fuseau horaire

Sur décision explicite de l'utilisateur, qui a tranché la seule limite encore documentée après la
passe précédente plutôt que de la laisser comme approximation permanente.

- [x] **Testé et validé (déployé + algorithme vérifié directement contre de vraies données IANA,
  pas seulement en théorie)** : nouveau champ `timezone` (identifiant IANA, ex. "Europe/Paris")
  capturé côté client à la création d'un événement (`flutter_timezone`), vérifié côté serveur contre
  la vraie liste IANA du moteur (`Intl.supportedValuesOf('timeZone')`, jamais une chaîne arbitraire
  acceptée du client) et stocké sur le document. `sendEventReminders.ts` calcule désormais l'instant
  UTC précis de chaque événement à partir de ce fuseau (algorithme à deux passes, uniquement `Intl`,
  sans nouvelle dépendance npm — `functions/src/shared/timezone.ts`), vérifié en conditions réelles :
  Europe/Paris hiver (UTC+1) et été (UTC+2, heure d'été), America/New_York (UTC-5), Africa/Abidjan
  (UTC+0) — les quatre donnent l'instant UTC exact attendu. La marge de sécurité précédente est
  retirée comme mécanisme de décision ; il n'en reste qu'une version résiduelle pour élargir la
  requête Firestore (pré-filtre bon marché, jamais la garantie de justesse — un seul mécanisme de
  correction, pas deux en parallèle comme demandé).
- [x] **Revue de code (effort high) passée, 3 corrections réelles supplémentaires avant déploiement**
  : le format de date différait entre la première occurrence d'une série récurrente (heure naïve) et
  les occurrences suivantes (heure UTC absolue avec "Z") — incohérence corrigée, toutes les
  occurrences utilisent maintenant le même format naïf ; le motif de validation acceptait
  silencieusement une chaîne déjà absolue (avec "Z" ou décalage) au lieu de la rejeter clairement ;
  un événement isolé avec une date/un fuseau corrompu pouvait interrompre toute l'exécution planifiée
  de l'heure et priver tous les autres événements de leur rappel — un `try/catch` par événement
  corrige ça.
- [ ] **Non vérifié sur appareil réel** : la capture du fuseau à la création d'un événement n'a pas
  été testée sur le téléphone — accès appareil toujours indisponible pendant cette passe. La
  vérification de l'algorithme de conversion lui-même (ci-dessus) a été faite directement en Node
  avec de vraies données de fuseaux, ce qui est différent d'un test de bout en bout sur l'app.
- [ ] **Limite assumée et documentée dans le code, pas un oubli** : l'heure "sautée" lors du
  changement d'heure d'été (une heure par an, par fuseau concerné) n'a par nature aucune
  interprétation unique correcte — même les bibliothèques dédiées à ce problème font un choix
  arbitraire dans ce cas précis. Un événement créé pile dans cette heure-là peut avoir son rappel
  décalé d'une heure ; cas extrêmement rare, non traité spécifiquement.

## Suivi 2026-11-11 (suite) — Modération automatique des photos (SafeSearch + visage)

Sur demande explicite de l'utilisateur : avant ce correctif, aucun contrôle automatique de contenu
n'existait sur les photos — seule la revue humaine ou l'approbation automatique après 48h décidaient.

- [x] **Testé et validé (API activée, déployé, exécuté pour de vrai contre 21 photos réelles de la
  base, pas seulement en théorie)** : Google Cloud Vision (SafeSearch + détection de visage, un seul
  appel par photo) déclenché à la création du document de suivi d'une photo
  (`moderatePhotoContent.ts`) — "LIKELY" ou plus sur adulte/suggestif/violence rejette immédiatement,
  sans attendre la revue humaine ni le délai de 48h. Nouveau champ `hasFace` (confiance ≥ 0,5),
  distinct du simple nombre de photos approuvées (toujours utilisé pour la complétion de profil) :
  devient la vraie condition de visibilité dans Découvrir — un profil avec 2 photos approuvées mais
  sans aucun visage détectable n'apparaît plus.
- [x] **Incident réel évité en cours de route par le coordinateur, merci** : un déploiement
  intermédiaire de `getCandidates.ts` exigeant déjà `hasFace` (avant que `moderatePhotoContent` ne
  soit lui-même déployé et avant toute rétro-analyse des photos déjà approuvées) aurait vidé Découvrir
  pour tout le monde. Corrigé en respectant l'ordre nécessaire : 1) déployer `moderatePhotoContent` +
  la robustesse d'`autoApprovePhotos`/`adminReviewPhoto` (aucun risque, n'affecte que les nouvelles
  photos et les futures revues) ; 2) script de migration ponctuel (hors dépôt, exécuté une seule fois
  avec les identifiants admin du projet) faisant passer les 21 photos déjà approuvées dans la même
  analyse Vision ; 3) seulement ensuite déployer `getCandidates.ts` avec l'exigence `hasFace`.
- [x] **Revue de code (effort high, deux passes) passée, corrections réelles avant chaque
  déploiement** : échecs ouverts transformés en échecs fermés (résultat SafeSearch totalement absent,
  valeur de vraisemblance jamais vue) — mieux vaut bloquer une photo à tort que laisser passer un
  contenu inapproprié en silence ; protection contre l'écrasement d'une décision déjà prise par une
  analyse retournée en retard (relecture de l'état réel juste avant d'écrire) ; aucun chemin vers
  "approved" (automatique, rattrapage planifié, revue admin) ne contourne plus ce contrôle ; deux
  requêtes d'agrégation Firestore par candidat fusionnées en une seule lecture dans le chemin déjà
  coûteux de Découvrir.
- [ ] **Non vérifié sur appareil réel** : aucun upload de photo n'a été fait depuis l'app elle-même
  pendant cette passe — accès appareil toujours indisponible. La vérification a porté sur de vraies
  photos déjà en base (via le script de migration) et sur un appel Vision réel isolé (image de test
  publique), pas sur le parcours complet upload → modération → affichage.
- [ ] **À savoir avant de tester Découvrir, pas un bug** : les 21 photos des comptes de test/seed
  existants ressortent toutes `hasFace=false` (ce sont des images de substitution, pas de vrais
  visages) — Découvrir affichera donc 0 profil tant qu'aucun compte n'a 2 vraies photos-visage
  approuvées. Comportement correct du nouveau critère, pas une régression ; à corriger en
  re-générant des photos de test avec de vrais visages si Découvrir doit montrer quelque chose
  pendant les prochains essais.
- [ ] **Limite assumée, pas un oubli** : un faux négatif Vision sur une vraie photo-visage légitime
  (angle inhabituel, lunettes, faible luminosité...) n'a aucun recours admin dans cette passe —
  l'admin peut approuver la photo mais ne peut pas forcer `hasFace` à vrai (volontaire : la spec
  demande un visage "clairement détecté", pas un jugement humain générique) ; seul un nouvel upload
  peut corriger ce cas pour l'instant.

## Suivi 2026-11-12 — Audit de sécurité dédié (règles, IDOR, cohérence client/serveur)

Demande explicite de l'utilisateur, traitée comme un audit à part entière (pas en passant pendant
une autre fonctionnalité) : `firestore.rules` collection par collection, `storage.rules`, chaque
Cloud Function `onCall` (46 fichiers, paiements en pause inclus), cohérence client/serveur, fuites
indirectes de données. Statut honnête : **rien de grave trouvé** — pas une formulation vague, un vrai
résultat après lecture complète de chaque fichier.

- [x] **`firestore.rules` — vérifié collection par collection, rien à corriger** : users (lecture
  publique assumée, écriture serveur uniquement + 2 préférences booléennes whitelistées) ; photos
  (statut pending contrôlé à la création) ; user_status/compat_answers/filtrage_attempts/
  moderation_requests/banques de questions (verrouillés, propriétaire ou serveur uniquement) ;
  matches/messages (appartenance + horodatage serveur obligatoires) ; blocks (impossible d'usurper
  blockerUid ou de bloquer au nom d'un autre) ; community_posts + participations/private/reviews
  (lecture scindée auteur/organisateur, private totalement verrouillé) ; event_invite_codes/
  community_tips (verrouillés comme attendu) ; tout le reste refusé par défaut (`{document=**}`).
- [x] **`storage.rules` — déjà conforme, aucune correction nécessaire** : `profile_photos`
  recroise déjà le statut `approved` réel en base via `firestore.get(...)` avant d'autoriser la
  lecture publique (deviner un chemin ne suffit pas à voir une photo encore en attente/refusée,
  exactement le risque demandé à vérifier) ; `chat_photos` croisé sur l'appartenance au match ;
  `event_posters` public par nature comme la publication elle-même ; `identity_verifications`
  jamais public, seule une URL signée 10 minutes y donne accès (identite/adminReviewIdentity.ts).
- [x] **IDOR — chaque fonction `onCall` vérifiée, aucun cas trouvé où un id envoyé par le client est
  utilisé sans contrôle réel** : filtrage (submitAttempt.ts vérifie `attempt.uid === uid` avant de
  corriger une tentative) ; messagerie (reportUser.ts vérifie déjà explicitement l'appartenance au
  match ET que le message signalé vient bien de la personne visée, commentaire de code déjà présent
  à ce sujet) ; identité (submitIdentityVerification.ts vérifie que le chemin Storage commence par
  son propre uid) ; communauté, likes, jetons, premium : chaque `targetUid` ne sert qu'à lire une
  donnée publique ou à agir sur SA PROPRE participation/swipe/statut, jamais sur celle d'un tiers
  sans vérification (organisateur, appartenance au match, statut déjà accepté...).
- [x] **Fonctions admin — `requireAdmin` appelé sans exception** dans les 15 fonctions `adminXxx`/
  assimilées vérifiées (listUsers, setSuspension, moderationRequests, resolveFiltrageReview,
  resolveSanctionAppeal, reviewCommunityPost, seedQuestionBanks, reviewIdentity, reviewPhoto,
  manageTips, organizerRequests, listActionLogs, bootstrapFirstAdmin — verrou par transaction, pas
  de rôle à vérifier puisque c'est justement la fonction qui attribue le tout premier rôle).
- [x] **Cohérence client/serveur — vérifiée sur le cas le plus sensible (âge adulte)** :
  `profil_wizard_screen.dart`/`profil_edit_screen.dart` bloquent déjà la saisie sous 18 ans
  côté affichage, ET `saveProfil.ts` (`MIN_ADULT_AGE = 18`, calculé sur `birthDate`) la rejette
  aussi côté serveur — aucun écart trouvé entre les deux.
- [x] **Fuites indirectes — vérifiées sur les fonctions les plus récentes de cette session**
  (cancelParticipation/getEventShareCode/redeemEventInviteCode/moderatePhotoContent/
  autoApprovePhotos/adminReviewPhoto) : aucune ne renvoie de champ que l'appelant ne devrait pas
  voir ; l'identité d'un auteur de signalement n'est jamais exposée à la personne visée, uniquement
  aux admins (déjà le cas avant cette passe, reconfirmé).
- [ ] **Une seule note de confidentialité, documentée et volontairement non corrigée dans cette
  passe** : `users/{uid}.birthDate` (date de naissance exacte, pas seulement l'âge) est stocké sur
  le document public, donc techniquement lisible par tout membre connecté — caractéristique
  préexistante de l'architecture (la collection entière est pensée pour être largement lisible, pas
  une régression de cette passe), pas un accès non autorisé au sens strict. Une vraie correction
  demanderait de déplacer ce champ vers un document réservé au propriétaire et de ne plus jamais
  calculer l'âge que côté serveur pour un profil tiers — un changement d'architecture plus large que
  ce que cet audit visait à corriger, donc signalé plutôt que corrigé dans la précipitation.
- [ ] **Hors périmètre, confirmé toujours en pause** : `paiements/paypal.ts`, `paiements/stripe.ts`,
  `premium/verifyPurchase.ts` restent non exportés dans `index.ts` (donc jamais déployés) — lus pour
  l'audit, non modifiés, conformément à la règle permanente sur les paiements.

## Suivi 2026-11-12 (suite) — Découvrir : profil complet au scroll (changement de direction)

Décision initiale (écran de détail séparé en tapant la photo) annulée en cours de route par
l'utilisateur au profit d'une révélation inline au défilement vertical, façon Hinge/Bumble, suivant
une maquette visuelle précise fournie. `ProfilDetailScreen` reste utilisé tel quel pour "Mes likes".

- [x] **Testé et validé (déployé)** : contenu de fiche profil (intérêts avec icône, "À propos de
  moi", grille de faits étendue) extrait dans un widget partagé (`core/widgets/profile_fact_sheet.dart`)
  entre la carte Découvrir et `ProfilDetailScreen`, jamais dupliqué. Bandeau de filtres reflétant
  l'état réel (jamais une valeur figée). Badge "En ligne" calculé côté serveur à partir de
  `lastActiveAt`, maintenant répété toutes les 5 minutes tant que l'app reste ouverte (avant : une
  seule fois par session, donc un signal devenu faux après 10 minutes d'usage actif — corrigé par
  revue de code avant même d'être livré).
- [x] **Revue de code (effort high, deux passes) passée, corrections réelles** : grille/icônes
  lourdes extraites du widget de glissement pour ne plus être reconstruites à chaque pixel glissé ;
  minuteur de présence passé en `.autoDispose` avec erreurs interceptées (sinon il aurait continué
  d'appeler le serveur en boucle après une déconnexion) ; alignement badge/menu corrigé (seraient
  apparus en haut à gauche de la photo au lieu d'à droite).
- [ ] **Non vérifié sur appareil réel** : accès appareil toujours indisponible pendant cette passe —
  en particulier la coexistence réelle du swipe horizontal et du défilement vertical n'a été
  vérifiée que par relecture du code (reconnaisseurs de gestes orthogonaux, mécanisme Flutter
  standard), pas par un test tactile réel sur téléphone.
- [ ] **Case "Mode de vie" de la maquette : volontairement absente, pas oubliée** — aucun champ
  correspondant n'existe dans le modèle de données ; inventer une valeur aurait violé la règle de ne
  jamais afficher une donnée qui n'est pas réelle.
- [ ] **Limite assumée et documentée dans le code** : si un membre fait défiler la carte vers le bas
  PUIS swipe dans la foulée, l'estampille LIKE/NOPE peut apparaître par-dessus le texte de la fiche
  plutôt que sur la photo — cas rare, purement visuel, non corrigé dans cette passe pour rester
  proportionné (corriger ça pour de bon demanderait de synchroniser la position de l'estampille avec
  le défilement).

## Suivi 2026-11-12 (suite) — Pays/ville réels obligatoires à l'inscription

- [x] **Testé et validé (déployé)** : pays via un vrai sélecteur ISO 3166-1 (`country_picker`),
  toujours enregistré en français (jamais la locale d'affichage de l'app) pour rester cohérent avec
  `emergency_sheet.dart`, qui indexe ses numéros d'urgence par nom de pays français en dur. Validé
  côté serveur contre une liste fermée de 246 noms générée directement depuis les données du
  package (jamais retranscrite à la main), insensible à la casse pour les profils déjà enregistrés
  avant ce correctif.
- [x] **Compromis ville assumé et expliqué, pas présenté comme complet** : aucune base de villes
  exhaustive n'existe pour ce projet et il n'était pas raisonnable d'en embarquer une ou d'ajouter
  une vraie API de géocodage (nouvelle dépendance/clé/coût) pour ce besoin — suggestions de villes
  RÉELLES (jamais inventées) pour une trentaine de pays les plus pertinents pour la communauté
  visée, saisie libre toujours possible en dehors. Aucune validation fermée côté serveur sur ce
  champ, volontairement : une vraie ville absente des suggestions ne doit jamais être refusée.
- [x] **Revue de code (effort high, trois passes) passée, corrections réelles** : stockage du pays
  d'abord dépendant de la locale d'affichage — repéré comme une régression de sécurité réelle
  (numéros d'urgence cassés en silence pour un membre utilisant l'app en anglais) avant même d'être
  livré, corrigé en forçant le français ; repli de compatibilité pour les anciennes données
  initialement mal placé (aurait réécrit une resélection correcte avec l'ancienne valeur erronée),
  corrigé pour ne jamais court-circuiter la validation réelle ; fuite d'observateur dans le champ
  ville à chaque frappe ; bascule entre deux widgets différents qui perdait le focus/clavier au
  changement de pays.
- [ ] **Non vérifié sur appareil réel** : accès appareil toujours indisponible — en particulier
  l'ergonomie réelle du sélecteur (bascule clavier/sélecteur, recherche) n'a été vérifiée que par
  relecture du code et compilation propre, pas par un test tactile.
- [ ] **Limite assumée, pas un oubli** : un profil dont le pays ne correspond à AUCUNE entrée connue
  même en ignorant la casse (abréviation, écriture directe de test en dehors de l'app) reste
  bloqué pour ce seul champ tant qu'il n'est pas explicitement remis à jour via le sélecteur — aucune
  migration de données n'a été lancée pour les corriger en masse, le cas réel trouvé en vérifiant la
  base (une seule casse différente, "france") étant déjà couvert sans ça.

## Suivi 2026-11-12 (suite) — Date de naissance retirée du document public (règlement permanent section 17)

- [x] **Testé et validé (déployé)** : `birthDate` ne vit plus sur `users/{uid}` (lisible par tout
  membre connecté) — seul `age`, recalculé par `saveProfil.ts` à chaque sauvegarde, y reste public.
  La date exacte vit désormais uniquement dans `user_status/{uid}` (lecture réservée au
  propriétaire, `firestore.rules`). Écriture atomique (`WriteBatch`) des deux documents.
  `getDiscoverCandidates` et `getLikes` lisent `age` directement au lieu de le recalculer depuis
  `birthDate` ; les trois fonctions (`saveProfil`, `getDiscoverCandidates`, `getLikes`) ont été
  redéployées en production. Les 12 comptes réels existants ont été migrés (script ponctuel, pas
  dans le dépôt) : `birthDate` déplacée vers `user_status`, `age` calculé et écrit sur `users`,
  vérifié par lecture directe après migration.
- [x] **Côté client** : `watchProfil` (`profil_repository.dart`) recompose `birthDate` pour son
  propriétaire en combinant `users` + `user_status` (nécessaire pour pré-remplir le sélecteur de
  date à l'édition) ; `targetProfileProvider` (`profil_detail_controller.dart`, fiche d'un profil
  tiers) lit `age` directement et échoue bruyamment (`StateError`) plutôt que d'afficher un âge
  inventé si `age` est absent — jamais de `birthDate` d'un autre membre relu côté client.
- [x] **Incident réel identifié et corrigé en urgence pendant ce chantier** : le script de
  migration a été exécuté contre la base de production AVANT que ce correctif ne soit déployé/livré
  côté client. Résultat concret observé : un APK construit depuis le dernier commit propre
  (`a5f6391`) a planté à l'ouverture du profil (`type 'Null' is not a subtype of type 'String'`,
  `Profil.fromMap` lisait `birthDate` devenu absent) ; côté serveur, les Cloud Functions encore
  déployées à ce moment-là (anciennes, lisant aussi `birthDate` sur `users/{uid}`) renvoyaient un
  âge invalide — Découvrir aurait silencieusement renvoyé une liste vide à tout le monde, Likes un
  âge invalide. Corrigé en déployant immédiatement les trois fonctions mises à jour dès la
  confirmation du diagnostic ; le serveur est donc de nouveau cohérent avec les données réelles. Le
  correctif client est committé et poussé (`b5b1878`) mais **une nouvelle build d'APK est
  nécessaire** pour que l'appareil ayant crashé reparte d'un profil fonctionnel — celui déjà
  installé reste construit sur l'ancien code tant qu'il n'est pas remplacé.
- [ ] **Limite assumée, pas un oubli** : `age` est calculé une fois à chaque sauvegarde de profil,
  pas en continu — un profil qui ne resauvegarde jamais peut afficher un âge figé jusqu'à un an
  avant de changer, par conception (demande explicite : "recalcule age côté serveur à chaque
  sauvegarde de profil"), pas par recalcul en temps réel à chaque lecture.
- [ ] **Non vérifié sur appareil réel** : la correction du crash n'a été vérifiée que par lecture
  directe des données de production et par la logique du code, pas encore par un appareil physique
  rechargeant un profil réel après une nouvelle build — accès appareil toujours indisponible pour
  cette session.

## Suivi 2026-11-12 (suite) — Chantier 4 : audit complet des onglets (synchronisation, cohérence, parcours)

- [x] **Casse de la ville normalisée (testé et validé, déployé)** : même logique que le correctif
  pays du 12/11 — `city` est désormais capitalisée (première lettre seulement, jamais chaque mot,
  pour ne pas abîmer un nom composé comme "Aix-en-Provence") à l'enregistrement
  (`capitalizeFirstLetter`, `saveProfil.ts`, redéployé). Le seul compte réel trouvé avec une ville
  en minuscule ("paris") a été corrigé directement en production après vérification des données
  réelles — même méthode que pour le pays.
- [x] **Audit systématique passé sur les 5 onglets + la coquille de navigation, testé et validé
  (déployé)** : Messages, Communauté et `MainShell` n'ont révélé aucun problème concret (déjà
  construits sur des `StreamProvider` qui reflètent l'état serveur en direct, aucune navigation
  morte, "Devenir organisateur" est une vraie destination fonctionnelle). Six vrais bugs trouvés et
  corrigés ailleurs :
  - Bloquer un profil depuis Découvrir ou Likes ne le retirait jamais de la pile/liste déjà
    chargée dans l'AUTRE onglet (ni même le sien, pour Découvrir) — restait visible et swipable
    jusqu'à fermeture de l'onglet. `showBlockProfileSheet` appelle maintenant un `onBlocked`
    optionnel après un blocage réellement réussi (jamais dans le même try/catch que l'appel réseau,
    pour qu'une erreur locale ne s'affiche jamais comme un blocage raté) ; chaque écran retire la
    personne de SA liste et de celle de l'autre onglet.
  - Un blocage pendant un swipe déjà en cours pouvait faire réapparaître la personne ou déclencher
    le dialogue de match pour elle selon le moment exact de la réponse serveur — corrigé en suivant
    explicitement l'uid en attente plutôt que sa simple présence/absence dans la liste (qui aurait
    aussi réagi, à tort, à un changement de filtre survenu pendant la même attente).
  - Le grand avatar de l'onglet Profil restait figé après ajout/suppression d'une photo (lisait un
    `FutureProvider` à usage unique jamais invalidé) alors que la galerie juste en dessous se
    mettait à jour en direct — vient maintenant du même flux que la galerie. La "photo principale"
    (la plus ancienne approuvée) est désormais définie et triée de façon identique pour son
    propriétaire et pour les autres membres, et le tri de la galerie elle-même est refait côté
    client pour éviter qu'une photo tout juste ajoutée saute en tête pendant la fraction de seconde
    où son horodatage serveur n'est pas encore résolu.
  - Deux couleurs Material brutes (badge "En ligne" de Découvrir, bouton "Réactiver" de l'admin)
    remplacées par un unique `AppColors.online` — la seule teinte hors palette imposée, désormais
    centralisée au lieu de dupliquée à deux endroits.
- [x] **Revue de code (effort high, quatre passes) passée sur ce chantier, corrections réelles à
  chaque fois** : un correctif de la course blocage/swipe inférait d'abord le blocage depuis la
  seule absence du candidat dans la liste — un changement de filtre survenu pendant l'attente
  aurait produit le même symptôme à tort, corrigé en suivant l'uid explicitement. Une première
  version de ce même suivi gardait les uids bloqués dans un `Set` qui ne s'effaçait jamais tout
  seul — un profil débloqué puis reproposé plus tard aurait fait disparaître un vrai dialogue de
  match, corrigé en repartant de deux champs réinitialisés à chaque appel plutôt que d'un état qui
  persiste.
- [ ] **Limite assumée, pas un oubli** : la normalisation de casse ne couvre que le cas réellement
  trouvé en vérifiant les données (tout en minuscule) — une ville mal orthographiée autrement
  ("PARIS", "pAris") ne serait pas corrigée automatiquement, `city` restant du texte libre sans
  liste fermée possible (aucune base de villes exhaustive, voir le suivi du 12/11 sur le sélecteur
  pays/ville).
- [ ] **Non vérifié sur appareil réel** : les six correctifs ci-dessus n'ont été vérifiés que par
  `flutter analyze`/`flutter test` et par relecture du code — accès appareil toujours indisponible
  pour cette session, en particulier le ressenti réel du retrait immédiat d'un profil bloqué de la
  pile Découvrir pendant un swipe.

## Suivi 2026-11-12 (suite) — Refonte visuelle de Likes (prototype validé)

- [x] **Testé et validé (déployé, pas de changement serveur nécessaire)** : pilules "Reçus"/"Envoyés"
  alignées sur le système de pilules déjà en place (Communauté) via un nouveau widget partagé
  `TabPill` (`lib/core/widgets/tab_pill.dart`), qui remplace aussi la copie précédemment dupliquée
  dans `communaute_screen.dart`. Icône d'actualisation ajoutée dans l'AppBar. L'illustration en
  éventail de l'état vide existait déjà dans la palette MERUT (`EmptyStateCards`) ; ajout des deux
  boutons du prototype ("Booste ton profil", "Passe à la version supérieure") sous le texte "Aucun
  Like pour le moment".
- [x] **"Booste ton profil" relié au mécanisme gratuit déjà existant, jamais inventé** : appelle
  `activateBoost` (jetons), extrait de `PremiumScreen` vers un widget partagé
  (`activateProfileBoost`) pour ne pas dupliquer l'appel Cloud Function ni sa gestion d'erreurs —
  exactement le même bouton que l'onglet Profil, pas une nouvelle fonctionnalité.
- [x] **"Passe à la version supérieure" ne déclenche aucun achat** : route simplement vers
  `PremiumScreen` déjà existant, qui communique déjà l'état réel sans bouton d'achat fonctionnel —
  les paiements restent en pause (`functions/src/index.ts`), rien de nouveau n'a été activé.
- [ ] **Non vérifié sur appareil réel** : vérifié par `flutter analyze`/`flutter test` et relecture
  du code uniquement — accès appareil toujours indisponible pour cette session.

## Suivi 2026-11-12 (suite) — Communauté retirée de la barre du bas

- [x] **Testé et validé (pas de changement serveur nécessaire)** : barre de navigation passée à 4
  onglets (Découvrir/Likes/Messages/Profil, demande confirmée par capture d'écran annotée).
  Communauté reste pleinement fonctionnelle, atteinte depuis une pilule (même widget `TabPill`)
  dans l'AppBar de Messages, qui pousse `CommunauteScreen` comme un vrai écran. Aucune navigation
  par index numérique fixe n'existait ailleurs dans le code (vérifié), rien d'autre à ajuster.
- [x] **Trois effets de bord réels de ce changement d'architecture corrigés dans la foulée**
  (trouvés par revue de code, pas par l'audit initial) : `CommunauteScreen` n'avait jamais eu
  d'AppBar (inutile en onglet de barre du bas) — ajoutée, sinon cul-de-sac complet sans geste
  "retour" matériel ; le sous-onglet actif de Communauté et les filtres d'Événements vivaient en
  état local remis à zéro à chaque retour en arrière (l'écran est maintenant détruit/recréé à
  chaque visite au lieu de rester vivant dans l'`IndexedStack` de `MainShell`) — déplacés vers des
  `StateProvider`, même principe que `discoverFiltersProvider` ; la propre AppBar imbriquée du
  sous-onglet Événements aurait affiché une deuxième flèche retour redondante — désactivée
  explicitement.
- [ ] **Non vérifié sur appareil réel** : vérifié par `flutter analyze`/`flutter test` et relecture
  du code uniquement — accès appareil toujours indisponible pour cette session, en particulier le
  ressenti réel de la nouvelle pilule et du retour depuis Communauté.

## Suivi 2026-11-12 (suite) — État de session réinitialisé à la déconnexion

- [x] **Corrigé, pas seulement signalé cette fois** : demande explicite du propriétaire en
  application de la règle "la plus stricte gagne" (règlement permanent section 17), suite au gap
  signalé dans le suivi juste au-dessus. Les cinq `StateProvider` de session
  (`discoverFiltersProvider`, `communauteTabProvider`, `eventsCategoryFilterProvider`,
  `eventsFormatFilterProvider`, `pendingAdultConfirmationProvider`) sont désormais réinitialisés
  dans `AuthController.signOut()` lui-même — sur un appareil partagé entre plusieurs comptes l'un
  après l'autre, le compte suivant ne hérite plus silencieusement des filtres/sous-onglet choisis
  par le précédent.
- [x] **Un vrai bug de sécurité/vie privée trouvé en creusant signOut(), corrigé dans la foulée** :
  `signOut()` a en réalité QUATRE points d'entrée dans le code (Paramètres, SanctionScreen,
  FiltrageScreen, FiltragePendingScreen), et seul celui de Paramètres désinscrivait le jeton de
  notifications push côté serveur. Un compte suspendu ou encore en vérification qui se déconnectait
  depuis l'un des trois autres écrans continuait donc à recevoir des notifications (nouveau
  match/message/like) après sa déconnexion. Centralisé dans `signOut()` lui-même, qui couvre
  maintenant les quatre points d'entrée uniformément.
- [x] **Trouvé par revue de code, corrigé** : le symétrique du problème de désinscription —
  `pushRegistrationProvider` (ré-enregistrement du jeton push) n'étant pas réinitialisé non plus,
  le compte SUIVANT sur le même appareil (même session d'app, sans redémarrage) n'aurait jamais eu
  son propre jeton enregistré tant que le processus de l'app restait ouvert.
- [ ] **Non vérifié sur appareil réel** : vérifié par `flutter analyze`/`flutter test` et relecture
  du code uniquement — en particulier le scénario réel "compte A se déconnecte, compte B se
  connecte sur le même appareil sans fermer l'app" n'a pas pu être rejoué physiquement, accès
  appareil toujours indisponible pour cette session.

## Suivi 2026-11-13 — Découvrir : deux rangées de pilules de filtres (prototype validé)

- [x] **Testé et validé (compilation, tests unitaires, déployé côté serveur)** : deux rangées de
  pilules visibles sous le sous-titre, remplaçant la feuille cachée. Rangée 1 : Filtres, genre
  (Tous/Hommes/Femmes), âge, distance. Rangée 2 : interrupteur « Ma position », Pays, Ville, Plus.
  Chaque sélection modifie `discoverFiltersProvider`, qui relance `getDiscoverCandidates`.
- [x] **Nouveau filtre genre, côté serveur** (`getDiscoverCandidates`) : liste fermée partagée
  (`shared/genders.ts`, aussi utilisée par `saveProfil`). Il ne fait que RESTREINDRE `seekingGenders`
  du profil, jamais l'élargir : un genre que le profil ne recherche pas renvoie une liste vide
  (règle la plus stricte). Types validés côté serveur (genre string de la liste fermée,
  `useMyLocation` booléen).
- [x] **Interrupteur « Ma position » relié au GPS existant** : l'activer sans position enregistrée
  lance la vraie demande GPS (`updateMyLocation`) et reste coupé si elle échoue ; un nouveau champ
  serveur `useMyLocation=false` désactive la distance sans effacer les coordonnées. Le bouton
  « Mettre à jour ma position » de la feuille le réactive aussi.
- [x] **Pays/Ville réels, pas de texte libre** : pilule Pays = sélecteur ISO (changer/retirer une
  fois actif) ; pilule Ville = suggestions réelles + saisie libre ; même logique de nom français que
  l'inscription (fonction partagée `frenchCountryName`). Changer de pays efface la ville. La feuille
  complète utilise aussi ces sélecteurs ; son « Appliquer » ne réinitialise plus genre ni position.
- [x] **Choix assumés** : « Âge » est affiché sans chiffres tant qu'aucune plage n'est réglée (pas de
  valeur inventée) ; « Filtres », « Plus », âge et distance ouvrent la même feuille complète
  (réglages réels, pas décoratifs) ; la maquette claire n'est PAS reprise, thème sombre conservé
  (disposition seulement).
- [ ] **Limites connues, pas des oublis** : si `seekingGenders` du profil change alors qu'un genre
  est filtré, la liste reste vide sans message jusqu'à ce qu'on repasse sur « Tous » ; l'atténuation
  de la pilule distance est un indice d'affichage, le serveur reste l'autorité ; aucun test
  automatisé côté serveur (pas d'infrastructure de test de fonctions dans le projet) — seuls
  `DiscoverFilters.toMap/copyWith` ont des tests unitaires.
- [ ] **Non vérifié sur appareil réel** (accès indisponible) : ergonomie réelle des pilules, de
  l'interrupteur et du sélecteur de pays non testée physiquement ; le client n'est pas encore
  empaqueté en APK.

## Suivi 2026-11-13 (suite) — Audit exhaustif et corrections

- [x] **Écart production/dépôt corrigé** : 8 fonctions en ligne différaient du code commité (`recordSwipe` sans gating Super Like, `onMessageCreated` sans push, `getDiscoverCandidates`/`saveProfil`/`getLikes`/`adminReviewPhoto`/participation). Les 10 fonctions des fichiers concernés ont été redéployées ; `scripts/verify_deployed.py` confirme 64 fonctions + règles Firestore/Storage identiques au dépôt (seule `verifyPurchase` reste en ligne mais désactivée, paiements en pause).
- [x] Messages bornés à 2000 caractères et à des champs connus (`firestore.rules`, déployées) ; plafond identique dans le champ de saisie.
- [x] Toucher une notification (app en arrière-plan/fermée) ouvre l'onglet concerné (match/message → Messages, like → Likes). N'ouvre pas encore la conversation précise.
- [ ] **Non vérifié sur appareil réel** : téléphone non branché au moment du build, APK `10958ce` construit mais non installé.
- [ ] **Non corrigé, décision ou risque** : App Check non activé (l'imposer sans l'avoir câblé côté app couperait l'app) ; limite de fréquence des messages/signalements/uploads ; identifiant `com.kamalove.kamalove` à trancher avant Play ; 28 index Firestore d'une autre application ; données de test en production à supprimer avant ouverture ; pas de CI ni de tests de fonctions.

## Suivi 2026-11-13 (suite) — règles 18-24 : reprise des prototypes (commit 3495eaa)

Règles ajoutées au règlement permanent (sections 18 à 24 : prototype = implantation complète, pas de doublon, cartographie dans `architecture-technique.md` §7, contrôle prototype/code, application rétroactive).

- [x] **Messages (prototype `Messages.dc.html`)** : ajouté la rangée de ronds des matchs (photo + prénom, contour accent s'il y a du nouveau), l'heure du dernier message (aujourd'hui `HH:mm`, « hier », jour abrégé, puis jour/mois), la pastille « non lu » et le vrai portrait du membre à la place de la silhouette grise. Réutilise `candidateFirstPhotoUrlProvider` (même source que Découvrir et Likes), `MessagesRepository` (+ `watchLastMessage`), aucune nouvelle collection. Test : `message_time_test.dart` (4 cas). `flutter analyze` propre. Données de test créées en production pour le contrôle (3 matchs avec Bleuro, marqués `testData: true`, à supprimer avant ouverture : `make_test_matches.py … delete`).
- [ ] **Non vérifié sur appareil réel** : APK installé mais le téléphone était verrouillé, aucune capture de la nouvelle liste Messages.
- [ ] **Écarts constatés, pas encore implantés** (comparaison avec les 5 prototypes d'origine du 09/11 ; les captures annotées ultérieures du propriétaire ne sont pas sur disque et peuvent en avoir remplacé certains éléments — à confirmer avant de les ajouter) :
  - Découvrir : le prototype a 4 boutons (passer, **retour/annuler le dernier passage**, like, **éclair**) — **repris plus bas** (retour et éclair ajoutés, retour non déployé).
  - Communauté : une publication du fil affiche un compteur de j'aime et « N réponses » ; l'appli n'a ni j'aime ni réponses sur les publications (ni collection, ni règle).
  - Questionnaire de filtrage : le prototype a le bouton « Passer », la catégorie de la question (« Histoire et civilisation ») et une option « Je ne sais pas » ; l'appli n'a aucun des trois (règle de score à décider pour « Je ne sais pas » et « Passer »).
  - Écran vide de Messages/Likes : trois cartes en éventail sans profils — **repris plus bas** (vrais profils existants).
- [ ] Défaut noté : `onMessageCreated` écrit `lastMessagePreview` selon l'ordre de traitement des déclencheurs, pas selon la date des messages ; deux messages rapprochés peuvent laisser l'aperçu du plus ancien.

## Suivi 2026-11-13 (suite) — écarts de prototype implantés

- [x] **Questionnaire** : bouton « Passer » et option « Je ne sais pas » (prototype `Questionnaire.dc.html`), conformes à la règle déjà posée (une question non répondue = mauvaise réponse, `regles-du-projet.md` section 1, `submitAttempt.ts` inchangé) ; jamais envoyés au serveur. Tests `filtrage_skip_test.dart`. La catégorie et le compteur existaient déjà.
- [x] **Communauté, publications du fil** : j'aime (♥ + compteur), réponses (liste, saisie, compteur), auteur et ancienneté sur la carte, signalement d'une réponse (réutilise `reportCommunityPost`, champ `replyId`). Serveur : `togglePostLike`, `replyToPost` (suspension, blocage entre membres, 500 caractères, 20 réponses/heure, push à l'auteur via `sendPushToUser`) ; règles `likes`/`replies` en lecture seule.
- [x] **Déployé et vérifié en production (2026-11-13)** : `togglePostLike`, `replyToPost`, `reportCommunityPost` (modifiée) et règles Firestore `likes`/`replies`. Avant déploiement : écart avec la production relevé par `verify_deployed.py` (règles : 18 lignes ajoutées, aucune supprimée ni remplacée). Compte **actif** exigé côté serveur (ajouté pendant la revue). Après : `verify_deployed.py` = OK, 66 fonctions + 2 jeux de règles identiques ; journaux Cloud sans erreur. **Test réel `scripts/test_post_interactions.py` : 27/27** (comptes de test Amara, Fatou, Awa) : appel sans connexion refusé ; j'aime et réponse enregistrés au nom de l'appelant seulement (paramètres `uid`/`authorName` usurpés ignorés) ; écriture directe de j'aime/réponse refusée par les règles (même pour soi) ; lecture sans connexion refusée ; réponse vide, de 501 caractères et sur publication inexistante refusées ; membre bloqué refusé ; compte suspendu et compte non actif refusés ; limite de 20 réponses par heure puis refus ; signalement d'une réponse accepté et visant l'auteur de la réponse. Données de test supprimées, statut d'Awa restauré.
- [ ] Non vérifié sur appareil réel (affichage des cœurs, réponses, signalement dans l'appli). Limites connues : aucune suppression ni modération admin d'une réponse (l'écran admin affiche la publication signalée, pas la réponse) ; j'aime et réponses limités au type `publication` ; pas de plafond sur la fréquence des j'aime (aucune notification n'en découle).
- [x] **Écrans vides Likes et Messages** : les trois cartes en éventail montrent de vrais profils existants (les prochains profils de Découvrir, `suggestedProfilePhotosProvider`, même source que Découvrir donc rien de plus visible qu'avant) ; forme générique si aucun profil disponible. Réponse à la remarque du propriétaire « les trois pastilles n'affichent pas les profils existants ». Aucune référence BPM plus précise n'existe dans le dépôt ni dans les conversations conservées : interprétation à confirmer visuellement.
- [x] **Découvrir, rangée d'actions du prototype** : flèche « retour » (annule le dernier passage) et éclair (Boost, `activateProfileBoost` déjà existant) ajoutés ; le Super Like (étoile, coût en jeton) est conservé.
- [ ] **NON DÉPLOYÉ — retour** : `undoLastSwipe` (nouvelle) et `recordSwipe` (mémorise `lastPassTargetUid`) sont dans le dépôt (commit `83a2ecc`) mais pas en production : le déploiement a été refusé par le garde-fou de l'environnement, il faut un accord explicite du propriétaire. Tant que ce n'est pas fait, le bouton retour répond par une erreur. Règle posée (la plus stricte, aucune règle antérieure) : Premium uniquement, passage uniquement (jamais un like), dernier swipe uniquement.
- [ ] Non vérifié sur appareil réel : Messages (rangée de matchs, heure, non lu), Questionnaire (Passer / Je ne sais pas), Communauté (j'aime, réponses), écrans vides, rangée d'actions de Découvrir. APK `83a2ecc` construit, non installé (téléphone en appel au moment de la tentative).

## Suivi 2026-11-13 (suite) — Profil : voir mes photos et mon profil vu de l'extérieur (commit après `6206cb5`)

Demande du propriétaire : dans l'onglet Profil, les photos téléchargées ou en attente ne pouvaient pas être affichées, et il manquait une vue extérieure du profil.

- [x] **Visionneuse de mes photos** (`photo_viewer_screen.dart`) : toucher une photo de la galerie l'ouvre en plein écran (balayage entre les photos, zoom, statut Validée / En attente / Refusée et explication de la visibilité). Fonctionne pour les photos en attente ou refusées, invisibles pour les autres membres. L'appui long pour supprimer est conservé.
- [x] **Aperçu « Voir mon profil comme les autres »** : nouvelle entrée de l'onglet Profil qui ouvre la fiche existante `ProfilDetailScreen` (réutilisée, pas de seconde fiche) en mode `isPreview` : mêmes données publiques et photos approuvées seulement, sans score de compatibilité avec soi-même, avec un bandeau explicatif.
- [ ] Non vérifié sur appareil réel (téléphone verrouillé au moment de l'installation). Analyse propre, 17 tests verts.

## Suivi 2026-11-13 (suite) — retour déployé, photo refusée, RGPD (commit `96834c5`)

- [x] **Bouton retour de Découvrir : déployé et testé en production.** `recordSwipe` (mémorise le dernier passage) et `undoLastSwipe` en ligne ; `verify_deployed.py` OK (67 fonctions, 2 jeux de règles identiques au dépôt). `scripts/test_undo_swipe.py` : **14/14** (refusé sans Premium, accepté en Premium, un seul passage annulable, jamais un like, dernier swipe uniquement, cible manquante, sans connexion). Comptes de test remis en état.
- [x] **Photo refusée (Profil)** : la visionneuse affiche la raison (refus automatique ou modérateur) et un **bouton « Supprimer cette photo »** avec confirmation (le texte « appui long » seul ne se voyait pas). Vérifié à l'écran avant ce bouton (visionneuse, statut « Refusée ») ; le bouton lui-même est **non vérifié sur appareil** (téléphone en appel au moment de l'installation).
- [x] **Documentation RGPD** : `docs/rgpd-registre-des-traitements.md` (registre des traitements, données sensibles, sous-traitants et **transferts : Firestore `nam5` et Storage `US-WEST1` = États-Unis**, droits, effacement, durées, photo refusée, plan d'action). Source unique, liée depuis `architecture-technique.md`.
- [x] **Effacement de compte étendu : déployé et testé en production (2026-11-13).** `deleteAccount` supprime aussi les j'aime et réponses laissés sur les publications des autres (`likerUid`, index de groupe de collections `READY`), le lien avec le signal d'appareil (le document disparaît seulement s'il ne référence plus personne), les photos de conversation et les affiches. `verify_deployed.py` OK (67 fonctions, règles identiques). **`scripts/test_account_erasure.py` : 18/18** avec un compte jetable (données laissées partout puis `deleteAccount` : plus rien ne subsiste, les données d'Amara sont intactes, le compte d'authentification est supprimé). Test de non-régression j'aime/réponses : 27/27.
- [ ] **Non implanté (décisions)** : recours humain pour une photo refusée, purge automatique des photos refusées et du selfie après décision, export de données complet, App Check, projet de production en région UE (voir RGPD §11).

## Suivi 2026-11-13 (suite) — pages photo : voir en grand partout

- [x] **Vérifié sur appareil** (visionneuse de mes photos) : photo en attente/refusée affichée en plein écran, statut « Refusée », raison (« Refusée automatiquement : la modération a détecté un contenu sensible… »), bouton « Supprimer cette photo » visible (suppression non testée sur la vraie photo du propriétaire).
- [x] **Photos consultables en grand sur les autres pages** (visionneuse générique `core/widgets/image_viewer.dart`, balayage et zoom) : fiche profil d'un autre membre (carrousel), photo révélée d'une conversation, affiche d'un événement. Avatar de l'onglet Profil : affiche désormais ma première photo même en attente ou refusée (moi seul la vois) et un toucher l'ouvre dans la visionneuse de mes photos. Bouton « Supprimer cette photo » : marges internes ajoutées (le texte touchait le bord).
- [ ] Non vérifié sur appareil réel : ces ouvertures en grand (MERUT n'était plus au premier plan) et la fiche « Voir mon profil comme les autres » (ouverture jamais vue à l'écran). Analyse propre, 17 tests verts.

## Suivi 2026-11-13 (suite) — photos refusées : purge automatique, pas de recours

Décision du propriétaire : **aucun recours humain pour les photos refusées, sauf à l'inscription** (le questionnaire de filtrage garde son recours). Purge automatique conservée.

- [x] Code : `purgeRejectedPhotos` (tâche quotidienne, `REJECTED_PHOTO_RETENTION_DAYS = 30`) supprime le fichier Storage puis le document des photos refusées depuis plus de 30 jours (date du refus = `reviewedAt`, sinon `moderatedAt`, sinon `uploadedAt`) ; texte de la visionneuse : « Elle sera supprimée automatiquement 30 jours après le refus ». Script de test réel `scripts/test_purge_rejected_photos.py` (4 cas : refus ancien purgé ; refus récent d'une photo ancienne conservé ; refus modérateur récent conservé ; photo approuvée conservée). Analyse propre.
- [x] **Purge déployée et testée en production (2026-11-13)** : `purgeRejectedPhotos` en ligne (`verify_deployed.py` OK, 68 fonctions, règles identiques). Avant test : une seule photo refusée existe en production (celle du compte réel, refusée le jour même, donc non concernée). `scripts/test_purge_rejected_photos.py` : **10/10** (refus automatique de 40 jours supprimé avec son fichier ; photo ancienne refusée il y a 5 jours conservée ; refus modérateur récent conservé ; photo approuvée conservée). Journaux sans erreur. Données de test supprimées.
- [ ] Documentation RGPD mise à jour (§5, §7, §7 bis, §11) : recours = décision assumée et atténuée.

- [x] **Vérifié sur appareil (2026-11-13, 21:12)** : avatar du Profil affiche la photo du membre même refusée ; ligne « Voir mon profil comme les autres » ouvre l'aperçu (silhouette puisqu'aucune photo validée, bandeau « Aperçu : voici ce que les autres membres voient. Seules tes photos validées sont visibles. », nom, âge, ville, description, recherche).
- [ ] Non vérifié sur appareil : ouverture en grand d'une photo d'un autre membre, d'une photo de conversation et d'une affiche (les comptes de test n'ont aucune photo réelle ; à tester avec de vraies photos).

## Suivi 2026-11-13 (suite) — Communauté : filtres des événements, pilules centrées

Demande du propriétaire (captures annotées) : filtrer les événements par distance, pays, ville, date, etc. ; centrer la pilule de l'onglet actif ; expliquer l'onglet Conseils.

- [x] **Filtres de l'onglet Événements** (`event_filters.dart`, `event_filters_sheet.dart`, `events_tab.dart`) : date (aujourd'hui, 7 jours, 30 jours, plage choisie), pays (sélecteur existant `CountryField`), ville (contient, sans casse), distance maximale (5 à 500 km), catégorie, format, accès (libre, sur demande, sur invitation), seulement les événements avec des places. Bouton « Filtres · N » + pastilles supprimables ; quand un filtre est actif, la page montre le nombre de résultats et la liste filtrée ; sans filtre, les sections habituelles (à la une, à venir, près de moi, privés, conférences, tous). Remplace les deux anciens filtres catégorie/format (réinitialisés à la déconnexion). 7 tests (`event_filters_test.dart`).
- [x] **Distance des événements** : approximative, calculée sur l'appareil depuis la position enregistrée du membre (« Ma position ») jusqu'au centre de la ville de l'événement (géocodage direct, mis en cache) ; les événements n'ont que ville et pays publics, le lieu précis reste privé. Les événements en ligne ou à ville introuvable sont exclus quand ce filtre est actif. Sans position enregistrée, la feuille explique d'activer « Ma position ». **Limite assumée** : filtre d'affichage côté appareil, pas une règle métier ; une distance exacte demanderait des coordonnées stockées à la création d'un événement.
- [x] **Pilules de Communauté** : l'onglet actif est ramené au centre de la rangée (Actualités, Conseils), `_CommunautePillBar`.
- [ ] Non vérifié sur appareil réel. Analyse propre, 24 tests verts.

## Suivi 2026-11-13 (suite) — Conseils publiés, Communauté vérifiée sur appareil

- [x] **10 conseils publiés** dans l'onglet Conseils (3 culture, 3 relation, 3 sécurité, 1 communauté), rédigés par l'assistant et **validés par le propriétaire le 13/11/2026** ; texte du conseil 9 corrigé avant publication après vérification du code (un membre bloqué ne reçoit aucune notification mais voit la conversation devenir inaccessible : la phrase « il ne le saura pas » a été retirée). Créés en base avec `createdBy` « validé par le propriétaire » (hors fonction admin, donc sans entrée dans le journal d'administration).
- [x] **Vérifié sur appareil (21:41)** : les 10 conseils s'affichent avec leur catégorie ; les pilules de Communauté centrent l'onglet actif (Actualités, Conseils, Événements) ; le fil montre la carte d'une publication avec auteur, ♥ 0 et « Aucune réponse » ; l'onglet Événements montre le bouton « Filtres » et la feuille de filtres (date, pays, ville, distance avec la position enregistrée, catégorie…).
- [ ] Non vérifié sur appareil : application réelle d'un filtre (résultats), j'aime et réponse depuis l'appli, filtre de distance avec résultats.

## Suivi 2026-11-13 (suite) — audit des incohérences : corrections (commit `49fc145`)

Audit demandé par le propriétaire (« demander ce qui est déjà connu, contrôles sans effet ») ; plan accepté en entier (points 1 à 5, 7 à 10).

- [x] **1. Découvrir, filtre de genre** : la pastille n'apparaît que si le membre cherche les deux genres (libellé « Femmes et hommes » au lieu de « Tous ») ; un choix ancien est neutralisé dans le contrôleur quand le membre ne cherche plus qu'un genre.
- [x] **2/3. Position et barre de pastilles** : « Activer ma position » n'apparaît que tant que la position n'est pas accordée (ou coupée pour la recherche) ; la pastille de distance n'apparaît que lorsqu'elle s'applique (plus estompée). Paramètres → Confidentialité : interrupteur « Utiliser ma position » (activer = permission + enregistrement ; couper = **suppression réelle** de la position enregistrée, `updateMyLocation` `clear: true`) et ligne « Notifications » (état de l'autorisation du système).
- [x] **4. Événements** : pays et ville de la création d'un événement utilisent les sélecteurs du profil et sont préremplis depuis le profil ; le serveur refuse tout pays hors liste (`createCommunityPost`).
- [x] **5. Genre et date de naissance verrouillés** après l'inscription : champs en lecture seule dans « Modifier mon profil » (« Fixé à l'inscription. Pour une correction, contacte le support. ») et refus côté serveur (`saveProfil`, `gender-locked` / `birthdate-locked`). **Conséquence** : une correction légitime passe par un administrateur (aucun écran de support n'existe encore) ; les comptes de test (dont celui du propriétaire : genre Femme, date 1/1/2000) ne se corrigent plus depuis l'appli.
- [x] **7. Likes** : « Booste ton profil » seulement pour un Premium ; un non-Premium voit « Passe en Premium » ; un Premium ne voit plus l'abonnement. **8. Écran Premium** : « Tu es membre Premium », offres masquées pour un Premium, bouton Boost réservé aux Premium. **9. Profil** : la ligne « Test de compatibilité » indique « Terminé · modifier » ou « À faire ».
- [ ] **NON DÉPLOYÉ** : les trois changements serveur (`saveProfil`, `createCommunityPost`, `updateMyLocation`) sont dans le dépôt, mais leur déploiement a été refusé par le garde-fou. Tant qu'ils ne sont pas en ligne : le verrouillage n'existe que côté appli, un pays libre est encore accepté, et couper la position depuis Paramètres échoue. Script de test prêt : `scripts/test_audit_fixes.py`.
- [ ] Non faits (P3, hors accord) : double confirmation de majorité Google, photos présentes sur deux pages, double entrée « Devenir organisateur ». Fusion des pastilles Pays/Ville/distance en un seul contrôle « Lieu » : non faite (la barre validée garde ses deux rangées, seuls les doublons inutiles sont masqués).
- [x] **Vérifié sur appareil (22:33-22:34)** après installation de `49fc145` : Découvrir sans pastille de genre ni interrupteur de position, pastille de distance « ≤ 100 km » active, Pays/Ville/« Plus » ; Paramètres → Confidentialité avec « Utiliser ma position » (activé) et « Notifications · Activées » ; Modifier mon profil avec date de naissance et genre en lecture seule (message « Fixé à l'inscription… », tronqué : `helperMaxLines: 2` ajouté ensuite) ; Likes avec le seul bouton « Passe à la version supérieure » pour un non-Premium.
- [ ] Non vérifié sur appareil : couper la position depuis Paramètres (dépend du déploiement serveur, volontairement non essayé), écran Premium d'un membre Premium, ligne « Test de compatibilité » du Profil, création d'un événement avec les nouveaux sélecteurs.

## Suivi 2026-11-13 (suite) — audit : serveur déployé et testé ; une seule ligne de pastilles ; Profil sans doublon

- [x] **Serveur de l'audit déployé et testé en production** : `saveProfil`, `createCommunityPost`, `updateMyLocation` en ligne ; `verify_deployed.py` OK (68 fonctions, règles identiques) ; `scripts/test_audit_fixes.py` **10/10** (enregistrement identique accepté ; changement de genre et de date de naissance refusés, valeurs en base inchangées ; pays d'événement inventé refusé, « france » accepté ; position supprimée en base ; coordonnées invalides toujours refusées). Le verrou du genre et de la date de naissance est donc maintenant appliqué côté serveur.
- [x] **Découvrir** : une seule ligne de pastilles défilante (demande du propriétaire sur capture), pastille « Plus » supprimée (même action que « Filtres »). **Profil** : crayon de la photo et crayon de la pilule « 8 % » supprimés (trois chemins vers « Modifier mon profil » ramenés à deux : la pilule de complétion et la ligne). APK construit et installé, **non vérifié à l'écran** (téléphone occupé).
- [ ] **Audit des incohérences : reconnu incomplet** (lecture du code, pas de passage de tous les écrans sur appareil). Doublons restants constatés : cases Jetons/Boost et ligne « Premium & jetons » (même page) ; l'onglet Communauté affiche aussi annonces et événements, qui ont leurs onglets. À faire : audit écran par écran avec captures.
- [ ] **Paramètres : écarts avec le prototype** (capture du propriétaire) : manquent Notifications par type, Préférences de rencontre enregistrées, Visibilité de mon profil, Signalements, titre « Données et compte ». **Manquent aussi** : Conditions d'utilisation, Politique de confidentialité, Mentions légales, aide/contact, version (obligations des boutiques et du RGPD, voir `rgpd-registre-des-traitements.md` §10). Non construits : en attente de « construis les Paramètres » ; les textes juridiques seraient des brouillons à faire valider par un juriste.
- [ ] Revue indépendante non lancée sur les derniers lots (verrou du profil, effacement, purge, règles) : recommandée à effort moyen.

## Suivi 2026-11-14 — thème clair (demande du propriétaire : « pas que le noir, c'est très sombre »)

- [x] **Trois choix d'apparence** : Paramètres → Apparence → Thème du système (défaut) / Clair / Sombre, mémorisé sur l'appareil (`theme_provider.dart`). Palette claire complète (`AppPalette.light` : fond ivoire, texte noir chaud, or plus profond pour rester lisible, cartes ivoire clair, barre du bas claire) à côté de la palette sombre inchangée.
- [x] **Mise en œuvre** : les rôles de `AppColors` sont devenus des accesseurs lisant la palette active ; `ThemeSync` (main.dart) fixe la palette et force la reconstruction de l'arbre quand le thème change (état et navigation conservés). 160 usages `const` rendus invalides par les couleurs dynamiques corrigés automatiquement (45 fichiers) ; l'analyse est propre.
- [x] **Contrastes vérifiés par test** (`theme_contrast_test.dart`, 10 cas) pour les deux thèmes : texte principal ≥ 7:1, texte secondaire ≥ 4,5:1, or d'accent ≥ 3:1, texte noir sur bouton or ≥ 4:1, onglet inactif lisible. 34 tests verts.
- [ ] **Non vérifié sur appareil** : APK installé mais téléphone verrouillé. À contrôler écran par écran dans les deux thèmes (textes posés sur des photos ou des bandeaux sombres, pilules, cartes, formulaires). Les bandeaux de marque (tuile Premium, pastille de Likes) restent volontairement sombres dans les deux thèmes.

## Suivi 2026-11-14 (suite) — modernisation visuelle (demande du propriétaire)

Demande : « pas de fond crème », « pas de bordures arrondies sur les onglets ni sous-onglets », « les pages ressemblent à de l'IA » → modernisation guidée par les compétences de design installées (`redesign-skill` : typographie, surfaces, composants génériques à éviter ; `ui-ux-pro-max` : accessibilité, contrastes, navigation).

- [x] **Couleurs** : thème clair sur **fond blanc** (plus de crème), surfaces gris très clair, texte presque noir, un seul accent or (plus profond en clair pour rester lisible) ; thème sombre passé à un gris anthracite neutre (plus de noir presque pur ni de brun), un seul gris. Contrastes toujours vérifiés par test (10 cas).
- [x] **Onglets** : `TabPill` remplacé par `AppTab` à soulignement (texte seul, trait d'or de 2 px sous l'actif, filet sous la rangée) : Communauté, Likes ; « Filtres » des événements devient un bouton, « Communauté » de Messages un lien texte. **Aucune pastille arrondie** sur les onglets.
- [x] **Composants** : échelle de rayons plus franche (4/6/8/12, la forme ronde réservée aux vrais ronds) appliquée aux 24 fichiers qui avaient des valeurs au hasard ; boutons à 8 px de rayon, sans ombre, libellé semi-gras ; champs de saisie sur fond doux ; puces carrées ; barre du bas sans pastille d'indicateur, avec un filet au-dessus ; avatars des membres en carrés arrondis ; capitales retirées des titres de section (Photos, Ta fiche, Confidentialité, Charte communautaire) ; emoji retiré (« Dites bonjour »).
- [x] **Typographie** : Manrope pour tout le contenu et les titres de barre (semi-gras, léger resserrement), le serif Tinos restant réservé à la marque.
- [ ] **Non vérifié sur appareil** (téléphone hors ligne au moment de la construction) : rendu réel des deux thèmes, pilules de filtres de Découvrir (rayon réduit mais forme conservée), cartes. 34 tests verts, analyse propre.
