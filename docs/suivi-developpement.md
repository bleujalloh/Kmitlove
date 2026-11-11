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
- [ ] **Refonte de l'écran Communauté** (structure à onglets Communauté/Événements/Actualités/
  Conseils, zone de composition, cartes de publication avec badges vérifiés or/bleu, mini-carte
  événement) : référence visuelle reçue et analysée, **non commencée** — à réconcilier avec la
  spécification fonctionnelle détaillée déjà annoncée mais toujours pas transmise dans cette
  session (types d'événements, tableau de bord organisateur...). Ne sera pas inventée sans elle.
