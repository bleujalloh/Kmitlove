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
- [x] **Passe « sans lignes ni pictogrammes »** (demande du propriétaire, 14/11/2026 : « supprime toutes les lignes, sous-lignes et emoji ; les widgets ne doivent pas être des IA ») : onglets en **texte seul** (actif en gras et en or, sans pastille, sans trait de soulignement, sans pictogramme) ; filets sous les rangées d'onglets et au-dessus de la barre du bas supprimés ; séparateurs (`Divider`) rendus invisibles dans tout le thème ; contours des cartes et champs ramenés à la couleur de surface (invisibles), boutons « contour » devenus des aplats doux ; pastilles de filtre de Découvrir sans pictogramme ni contour ; pictogrammes retirés des boutons « Filtres » et « Communauté » ; **écrans vides** : plus de cartes en éventail ni d'icône décorative, un titre, une phrase et, quand Découvrir en propose, jusqu'à trois profils alignés. Les options non sélectionnées (questionnaire, compatibilité, assistant de profil) et les boutons ronds de Découvrir reçoivent un fond doux pour rester visibles sans contour.
- [ ] Interprétation : « lignes / sous-lignes » compris comme traits, contours et soulignements ; « emoji » compris comme pictogrammes décoratifs des onglets et pastilles (les icônes fonctionnelles — retour, envoi, cœur, barre du bas, lignes de Paramètres du prototype — sont conservées). À confirmer à l'écran.

## Suivi 2026-11-14 (suite) — Paramètres du prototype, doublons restants (commit `196c966` et suivant)

- [x] **Paramètres refaits d'après le prototype du propriétaire** : Langue, Apparence, **Notifications** (page : likes, messages, matchs, réponses de la communauté, événements ; état de l'autorisation du téléphone), **Préférences de rencontre** (page : tranche d'âge, distance, pays ; « Je recherche » en lecture seule renvoyant vers Modifier mon profil ; enregistrées sur l'appareil par compte et appliquées comme valeurs de départ des filtres de Découvrir), section Confidentialité (**Visibilité de mon profil** : visible / masqué dans Découvrir ; Utiliser ma position ; indicateur de lecture ; score de compatibilité ; Mes blocages ; **Signalements** : la liste de mes signalements, avec leur état), section **Données et compte** (Exporter, Se déconnecter, Supprimer), section **Informations** : **Conditions d'utilisation, Politique de confidentialité, Mentions légales, À propos (version)**, en français et en anglais.
- [x] **Textes juridiques** rédigés d'après ce que l'appli fait réellement (`rgpd-registre-des-traitements.md`) avec un bandeau « Version provisoire, en cours de validation juridique » (`kLegalDraft` dans `legal_texts.dart`, à passer à `false` après relecture par un juriste). L'identité de l'éditeur, l'adresse de contact et le droit applicable restent à publier (société en cours d'immatriculation) : les mentions légales le disent sans inventer d'information.
- [x] **Doublons de l'audit** : cases Jetons et Boost du Profil non cliquables (la ligne « Premium & jetons » reste l'accès) ; l'onglet Communauté ne montre plus que les publications (annonces et événements ont leurs onglets). « Devenir organisateur » gardé aux deux endroits (ligne du Profil et bouton des Événements), les deux s'adaptent à l'état de la demande.
- [ ] **NON DÉPLOYÉ — serveur des Paramètres** : `setNotificationPreferences`, `setProfileVisibility`, `listMyReports` (nouvelles), `getDiscoverCandidates` (exclut les profils masqués) et tous les envoyeurs de notifications (`recordSwipe`, `onMessageCreated`, `replyToPost`, `cancelParticipation`, `sendEventReminders`, qui lisent désormais les préférences) sont dans le dépôt mais pas en production : le déploiement a été refusé par le garde-fou, il faut « déploie les Paramètres ». Tant que ce n'est pas fait, les réglages de notification et de visibilité échouent côté appli. Script de test prêt : `scripts/test_settings_functions.py`.
- [ ] Non vérifié sur appareil : toutes ces pages. Limites : les préférences de rencontre ne suivent pas le compte sur un autre appareil ; les types de notification « visites » du prototype n'existent pas (l'appli n'a pas de visites de profil).

## Suivi 2026-11-14 (suite) — swipe de Découvrir corrigé ; plus de texte gris ; plus aucun trait

- [x] **Swipe de Découvrir** (« quand on swipe à droite ou à gauche, ça ne marche pas selon le contexte, ça plante ») : nouvelle carte `SwipeableCard` (`presentation/widgets/swipeable_card.dart`). Causes corrigées : le geste n'était validé que par la distance (110 px) — il l'est maintenant aussi par la **vitesse** (un coup de doigt rapide suffit) ; quand l'action était **ignorée** (appel déjà en cours, plus de profil) la carte restait **bloquée de travers** à l'écran — elle sort maintenant de l'écran puis **revient au centre** si l'action est refusée (`swipe()` renvoie `true`/`false`) ; toute **erreur** de l'action est absorbée dans la carte (plus de plantage possible) ; plus de `setState` après le retrait de la carte ; zone de geste opaque. **7 tests de widget** (coup rapide à droite = like une seule fois, glissement long à gauche = passe, petit glissement lent = rien, action refusée = retour au centre, exception = pas de plantage, second geste ignoré pendant une action, carte retirée en cours d'action). Cause exacte du plantage vu par le propriétaire **non reproduite** (pas de trace d'erreur fournie) : à confirmer sur appareil.
- [x] **Plus aucun texte gris** : le texte secondaire prend la couleur du texte principal dans les deux thèmes (`muted` = `ink`), de même pour les pictogrammes, les onglets inactifs, les indications de champ et les sous-titres de liste (rôles « gris » de Material réalignés : `onSurfaceVariant`, `disabledColor`, `hintColor`) ; boutons désactivés teintés d'or plutôt que grisés ; fonds de silhouette teintés d'or. La hiérarchie passe par la taille et la graisse, plus par un gris.
- [x] **Plus aucun trait, contour ni soulignement** (confirmé par le propriétaire : « oui les traits, contours et soulignements ») : 30 contours supprimés dans 20 fichiers (cartes, champs, puces, avatars, bulles, cartes d'options, bouton de visionneuse, bandeaux), y compris les contours de sélection (la sélection se lit par le fond) ; mention LIKE / PASSE du swipe sans cadre ; pastilles de filtre et boutons ronds sans trait. Resté volontairement : le logo Google (charte de la marque).
- [ ] Non vérifié sur appareil : swipe réel, rendu des deux thèmes sans gris ni trait. 41 tests verts.

## Suivi 2026-11-14 (suite) — audit complet des couleurs de texte ; page Profil refaite

- [x] **Audit des couleurs de l'ensemble de l'appli** (demande du propriétaire sur capture : textes encore gris sur le Profil — « Paris, France », description, libellés des compteurs, barre du bas) : relevé de toutes les couleurs de texte, de pictogramme et d'indication du code. Résultat : plus aucune couleur de texte codée en dur hors texte principal, or, blanc et noir (seules restent deux surcouches noires sur des photos de conversation) ; l'indication des champs (`hintStyle`) portait encore une transparence qui la grisait — corrigée. Réglages de thème ajoutés pour qu'aucun composant Material ne retombe sur un gris : interrupteurs (piste teintée d'or éteinte, pouce doré), cases et boutons radio dorés, curseurs et indicateurs de progression à piste teintée d'or, sans contour.
- [x] **Page Profil refaite sur le modèle d'un profil de réseau social moderne** (capture Instagram du propriétaire) : « + » (nouvelle publication) à gauche et menu des réglages à droite de la barre ; avatar rond avec anneau de complétion et « + » d'ajout de photo, à côté des trois chiffres (Jetons, Boost, Profil en %) ; nom, âge et badge vérifié, ville, description ; puces (profession, trois centres d'intérêt, « + Ajouter ») ; deux boutons côte à côte **Modifier le profil** et **Partager le profil** ; rangée de photos avec tuile « Nouveau » et état de chaque photo ; puis les raccourcis du compte (aperçu, vérification, compatibilité, participations, organisateur, Premium en fond doré léger sans bandeau sombre, administration). **Non reproduits, comme demandé** : abonnés/publications, onglets de contenu, notifications de réseau, suggestion de personnes, illustration d'état vide.
- [x] **« Partager le profil » implanté** : feuille de partage du système avec un message court (« Retrouve-moi sur MERUT : prénom, ville. L'amour a ses racines. »), à l'initiative du membre ; **limite** : pas de lien direct vers le profil tant que l'appli n'est pas publiée (pas de lien profond ni de page web).
- [ ] Non vérifié sur appareil : rendu des deux thèmes sans gris, nouvelle page Profil, swipe. 41 tests verts.

## Suivi 2026-11-14 (suite) — arrière-plan « Alarme », pages modernisées, lot serveur RGPD / limites, revue indépendante

Demande du propriétaire : « ce qui doit être fait doit être fait » (modernisation page par page, audit des doublons, App Check et limites de fréquence, revue indépendante, écarts RGPD, points à faible priorité, région Europe) et « copier l'arrière-plan de la photo de l'alarme ».

- [x] **Arrière-plan copié de l'écran « Alarme »** : dégradé pastel (menthe en haut à gauche, rose pâle en haut à droite, bleu clair en bas ; version sombre aux mêmes teintes, profondes) peint derrière **toutes** les pages (`core/theme/app_background.dart`, branché sur la transition de page) ; cartes **translucides** type verre (`AppColors.backgroundSoft`), rayon des cartes 20 px (`AppRadii.lg`), 28 px pour la carte Découvrir (`xl`), champs et boutons 14 px (`field`) ; menus, notifications et sélecteurs en surface **pleine** (`AppColors.surfaceSolid`) pour rester lisibles. Contrastes testés sur **chaque teinte du dégradé**, avec et sans carte (10 cas ; la teinte menthe sombre et la carte sombre ont été ajustées pour tenir le 7:1). Aperçus générés par test (clair et sombre) : dégradé et cartes conformes à la référence.
- [x] **Pages modernisées** (sur la même base) : carte **Découvrir** (photo pleine carte, nom, âge, ville et compatibilité posés sur la photo avec voile, reste du profil au défilement) ; **Likes** (tuiles photo avec nom et ville sur la photo, tuiles verrouillées en verre) ; **Messages** (chaque conversation = carte verre) ; **Premium** (statut, boost, offres en cartes) ; **formulaires** (champs et boutons plus arrondis) ; Communauté (cartes, événements) par le thème. **Plus aucun séparateur** : traits « ou » de connexion/inscription, séparateurs des listes de messages, blocages et participations, ligne d'horizon du motif d'accueil supprimés.
- [x] **Audit des doublons (lecture du code)** : (1) **deux visionneuses d'images** (mes photos / photos des autres) → un seul mécanisme `ZoomPager` (`core/widgets/image_viewer.dart`) ; (2) **double confirmation de majorité Google** (case obligatoire avant le bouton Google **et** écran de confirmation après) → écran `AdultConfirmationScreen` et son état supprimés (le bouton Google reste bloqué tant que la case n'est pas cochée, l'âge est de toute façon contrôlé par la date de naissance côté serveur) ; (3) **trois mécanismes de limite de fréquence** (réponses = compteur dans le statut, messages et signalements à créer) → un seul `shared/rateLimit.ts` ; (4) **suppression de compte à écrire deux fois** (demande + purge) → `shared/eraseAccount.ts` ; (5) annulation de participation recopiée → `shared/participation.ts`. **Gardé volontairement** : « Devenir organisateur » aux deux endroits (ligne du Profil et bouton des Événements). **NON FUSIONNÉ, à décider** : l'**écran de modification du profil** (`profil_edit_screen.dart`, formulaire unique) et l'**assistant de profil** (`profil_wizard_screen.dart`, une question par écran) saisissent les mêmes champs avec deux interfaces et du code en double ; la fusion (faire de l'assistant l'unique éditeur, ou composer les deux avec les mêmes blocs) change l'interface et ne peut pas être vérifiée tant que le téléphone reste verrouillé.
- [x] **Serveur — App Check** : constante `ENFORCE_APP_CHECK` (`shared/appCheck.ts`) appliquée à **toutes** les fonctions appelables (y compris les quatre de paiement en pause), **désactivée** (`false`) : l'activer avant l'enregistrement de l'appli dans la console (Play Integrity, empreinte SHA-256 de la version publiée) couperait l'accès à tous les membres. Procédure écrite dans le fichier.
- [x] **Serveur — limites de fréquence** : `sendMessage` devient le **seul chemin d'envoi** des messages (règles Firestore : création directe refusée) avec compte actif, appartenance au match, blocage, longueur, quota (20 par minute, 600 par jour) ; signalements 10 par heure et 30 par jour (quota commun, validation **avant** de consommer le quota, détails bornés à 1000 caractères) ; réponses 20 par heure. L'appli annonce maintenant chaque refus (message non envoyé, trop de messages, signalement non envoyé / trop de signalements) et ne perd plus le texte saisi.
- [x] **Serveur — RGPD** : consentement art. 9 (écran, `recordSensitiveConsent` versionné, exigé par `saveProfil`, la découverte, les likes, les swipes et les messages ; retrait depuis Paramètres) ; **export complet** (messages envoyés, photos en fichier, j'aime/réponses/participations/avis/signalements faits, favoris, tentatives de filtrage, appareils, e-mail ; jamais le nom ni les messages d'un autre membre) ; **selfie supprimé** dès la décision (tout le dossier) ; **purge des comptes inactifs** (`purgeInactiveAccounts`) ; **suppression de compte complétée** (avis, favoris, blocages reçus, listes d'invités, codes d'invitation, contenu des publications, jetons d'achat, places libérées avec liste d'attente promue, erreurs Storage plus avalées, compte déjà absent toléré, délai porté à 300 s) ; `recordActivity` et `recordSensitiveConsent` ne recréent plus un statut supprimé.
- [x] **Revue indépendante** (sous-agent distinct, lecture seule, sur les changements sensibles ci-dessus) : 17 constats. **Corrigés dans le dépôt** : (1) **bloquant** — `exportMyData` signait un chemin Storage écrit par le client (un membre pouvait obtenir le selfie d'un autre) : chemin imposé par les règles Firestore **et** vérifié côté serveur (export, purge des photos refusées, analyse des photos) ; (2) erreurs Storage avalées avant suppression du compte ; (3) purge sans avertissement réellement remis ; (4) garde « administrateur » qui cédait sur erreur ; (5) purge sur instantané périmé et pages bloquées ; (6) données oubliées à la suppression ; (7) non-idempotence et délai ; (8) retrait du consentement qui ne cachait que de la découverte ; (9) montée de version du consentement ; (10) photos de conversation écrasables / listables / orphelines (règles Storage durcies, auteur du dépôt inscrit et vérifié, fichier retiré si l'envoi échoue) ; (11) signalements refusés sans message ; (12) App Check manquant sur les fonctions de paiement ; (13)-(15) validations et export. **Non résolus, à décider par le propriétaire** : canal d'avertissement fiable (e-mail) pour purger les comptes inactifs sans appareil joignable ; comptes jamais arrivés à l'écran principal non couverts par la purge ; relecture du texte de consentement par un juriste. Le constat 17 (index de la liste d'attente) a été vérifié sur la production par une requête en lecture : elle fonctionne, aucun correctif.
- [x] **Région Europe** : décision du propriétaire prise (Europe, Bruxelles ou ailleurs) ; plan complet et état dans `docs/migration-region-europe.md`. **Rien n'est créé** : l'identifiant du nouveau projet et le compte de facturation attendent confirmation (création = dépense et acte définitif).
- [ ] **NON DÉPLOYÉ** — tout le serveur ci-dessus (Paramètres, `sendMessage`, consentement, export, selfie, purge des inactifs, suppression complétée, règles Firestore et Storage, deux index) est dans le dépôt, compilé (`tsc` propre), mais **pas en production** : le déploiement attend un « déploie » explicite du propriétaire. **Ordre à respecter** : (1) créer les index `reviews.uid` et `private.invitedUids` (groupe de collections) et attendre qu'ils soient prêts, sinon l'export et la suppression de compte échouent ; (2) déployer fonctions et règles ; (3) lancer `scripts/grant_test_consent.py` (comptes de test seulement) ; (4) **seulement alors** installer le nouvel APK (sinon l'écran de consentement bloque l'appli et l'envoi de messages échoue) ; (5) lancer `scripts/test_messaging_rgpd.py`, `test_settings_functions.py`, `test_post_interactions.py`, `test_account_erasure.py`, puis `scripts/verify_deployed.py`. Chaque membre existant (dont le propriétaire) devra donner son consentement au prochain lancement : tant qu'il ne l'a pas fait, il n'est montré à personne.
- [ ] **Non vérifié sur appareil** : le téléphone (`RFCX61BC0XA`) est resté **verrouillé** (écran de verrouillage). Rendu réel des deux thèmes avec le dégradé, carte Découvrir refaite, Likes, Messages, Premium, nouvelle page Profil, swipe, Paramètres, écran de consentement : **non vus**. 45 tests Flutter verts, analyse propre ; scripts de test serveur écrits mais **non exécutés** (rien n'est déployé).

## Suivi 2026-11-14 (suite) — DÉPLOIEMENT en production (demandé : « déploie »)

- [x] **Déployé** sur `djama-1c7f8` : les deux index de groupe de collections (`reviews.uid`, `private.invitedUids`, prêts avant tout le reste), **toutes les 73 fonctions du dépôt** (jamais d'option de suppression : le projet est partagé avec d'autres applications), règles Firestore et Storage. `scripts/verify_deployed.py` : « 74 fonctions et les 2 jeux de règles sont identiques au dépôt » (74 = les 73 + `verifyPurchase`, en ligne mais désactivée, paiements en pause). Consentement donné aux 10 comptes de test (`scripts/grant_test_consent.py`, adresses en @example.com seulement) ; **les 2 autres comptes dont celui du propriétaire devront le donner au prochain lancement**.
- [x] **Tests réels en production** (comptes de test et comptes jetables, tout nettoyé) : `test_messaging_rgpd.py` **64/64**, `test_settings_functions.py` 14/14, `test_post_interactions.py` 27/27, `test_account_erasure.py` 18/18, `test_undo_swipe.py` 14/14, `test_audit_fixes.py` 10/10, `test_purge_rejected_photos.py` 10/10. Dont : message, photo, limites (20 messages par minute, 10 signalements par heure), consentement (refus sans, avec mauvaise version, retrait), export, selfie supprimé, purge des inactifs (sans appareil joignable : aucun compte à rebours ; 30 jours après l'avertissement : compte supprimé), suppression de compte (avis, places, invitations, blocages, favoris).
- [x] **Deux vrais défauts trouvés par ces tests, corrigés et redéployés** : (1) **`cancelParticipation` échouait toujours pour une place confirmée** (« toutes les lectures avant les écritures » : la liste d'attente était lue après la première écriture) — défaut déjà présent avant ce lot, jamais vu car jamais testé ; il aurait aussi fait échouer la suppression de compte d'un participant ; corrigé dans `shared/participation.ts` ; (2) **les liens de téléchargement signés échouaient** (le compte de service n'a pas la permission de signature) : l'export des photos et la revue des selfies par un modérateur renvoyaient « aucun lien » sans erreur visible ; ils utilisent maintenant le jeton de téléchargement posé par Firebase sur chaque fichier envoyé depuis l'appli (`shared/storageLinks.ts`, signature en repli). **Limite** : ce lien n expire pas (c'est le même que l'appli utilise déjà pour afficher la photo à son propriétaire) ; il n'est donné qu'au propriétaire, et au modérateur pour un selfie en attente.
- [x] **Pourcentage de complétion du profil** (demande du propriétaire : tout le facultatif compte) : « Présentation de tes valeurs » ajoutée (elle manquait) — désormais 14 éléments : métier, langues, centres d'intérêt, origines culturelles, taille, études, tabac, alcool, enfants, ce qu'on recherche chez l'autre, qualités, valeurs, 3 photos validées, badge vérifié. Le même calcul sert l'affichage et le classement de Découvrir. Déployé (`getProfileCompletion`, `getDiscoverCandidates`).
- [x] **Cartes en éventail rétablies** dans les états vides (Likes, Messages) ; nouvel APK installé sur le téléphone le 14/11/2026 à 13 h 20 (serveur déjà en ligne).
- [ ] **À discuter avec le propriétaire** (demande du 14/11/2026 : mettre en avant les contenus comme les autres sites) : cinq champs saisis ne sont affichés nulle part — valeurs, ce que l'on recherche chez l'autre, qualités, langues, origines culturelles — alors que la carte Découvrir et la page profil n'affichent que présentation, centres d'intérêt et fiche de faits ; ordre d'affichage recommandé et quatre questions posées au propriétaire (voir la conversation).
- [ ] **Non vérifié sur appareil** : le téléphone s'est reverrouillé juste après l'installation ; rendu des pages refaites, carte Découvrir, éventail de Likes, écran de consentement, swipe, Paramètres : à voir dès qu'il est déverrouillé.

## Suivi 2026-11-14 (suite) — profils mis en avant (recommandations acceptées par le propriétaire)

Demande : « tout ce qui est facultatif doit compter pour le pourcentage » et « mettre en avant comme les autres sites » ; recommandations acceptées (« oui j'accepte tes recommandations, on corrige et on implémente »).

- [x] **Fiche profil refaite, une seule mise en page** (`core/widgets/profile_fact_sheet.dart`, partagée par la carte Découvrir et la page de détail) dans l'ordre voulu : (1) l'intention en étiquette (« Recherche : Relation sérieuse »), (2) la compatibilité expliquée (« Vous vous accordez surtout sur : Famille, Valeurs et culture » — les deux thèmes les plus nets, au moins 70 %), (3) la **Présentation** (renommée depuis « À propos de moi »), (4) **« Ce que je recherche chez l'autre » et « Mes valeurs »** en citations, (5) les **qualités** puis les **centres d'intérêt** en pastilles (sans pictogramme décoratif), (6) **« En bref »** (âge, taille, études, métier, **langues**, enfants, tabac et alcool), (7) les **origines culturelles** (affichées seulement si renseignées — le membre a donné son accord pour ces données). Un bloc sans contenu n'apparaît jamais.
- [x] **Photos intercalées** : la carte Découvrir n'affichait que la première photo ; les suivantes s'insèrent maintenant entre les blocs (page de détail : elles restent dans le carrousel du haut).
- [x] **Cinq champs saisis mais jamais affichés** le sont désormais : valeurs, ce que l'on recherche, qualités, langues, origines (`getDiscoverCandidates` les renvoie ; la page de détail les lit sur le profil public).
- [x] **Pourcentage de complétion** : désormais **15 éléments** — aux 14 précédents s'ajoute le **test de compatibilité** (au moins une session complète, 18 réponses : `COMPAT_ANSWERS_FOR_FULL_COMPLETION`) ; la position n'est volontairement pas comptée (certains préfèrent la garder privée). Même calcul pour l'affichage et le classement de Découvrir.
- [x] **Assistant de création du profil** : la « présentation de tes valeurs » peut maintenant y être saisie (elle n'existait que dans la modification).
- [x] 48 tests Flutter verts (dont fiche complète / presque vide et ordre des blocs), analyse propre, `tsc` propre. `scripts/test_messaging_rgpd.py` complété (pourcentage 0 / 7 / 13 %, cartes, thèmes de compatibilité).
- [ ] **NON DÉPLOYÉ** : `computeCompatibility` (thèmes), `getDiscoverCandidates` (nouveaux champs, pourcentage), `getProfileCompletion` (test de compatibilité) attendent un « déploie » explicite du propriétaire. Le nouvel APK est compatible avec le serveur actuel (les champs absents s'affichent comme vides) ; sur la carte Découvrir, les nouveaux blocs n'apparaissent qu'après ce déploiement (la page de détail les lit déjà). Le téléphone était débranché au moment de la construction : **non vérifié sur appareil**.

## Suivi 2026-11-14 (suite) — chasse aux défauts cachés (demande du propriétaire : « cherche ces mêmes défauts ou des défauts existants, cachés, non signalés, et corrige »)

Méthode : (1) recherche de la même famille de défauts dans tout le code ; (2) **test de robustesse de toutes les fonctions** (`scripts/smoke_all_callables.py` : 305 appels avec entrées absentes ou malformées) ; (3) **parcours complet d'un événement jamais joué de bout en bout** (`scripts/test_events_flow.py`, 43 vérifications) ; (4) relecture des boutons de l'appli qui n'annoncent pas leurs échecs.

- [x] **Famille « lectures après écritures » dans une transaction** (défaut n° 1 d'hier) : les 21 transactions du serveur ont été analysées une à une ; aucune autre n'est concernée (un faux positif, `moderationRequests`, sort de la transaction juste après l'écriture). **Famille « lien signé sans permission »** (défaut n° 2) : un seul appel, déjà corrigé.
- [x] **57 plantages sur 305 appels** (36 fonctions) : une demande sans donnée, ou avec un champ de mauvais type, faisait planter la fonction en « erreur interne » au lieu de répondre « paramètres invalides ». Corrigé **pour toutes les fonctions d'un coup** par une enveloppe commune (`functions/src/shared/callable.ts`, remplaçant `onCall` dans 55 fichiers) : aucune donnée → objet vide ; identifiants (`postId`, `uid`…) = texte simple sans « / » ; textes connus = texte ; décisions (`approve`, `accept`, `suspend`…) = vrais booléens.
- [x] **Trois défauts réels confirmés en production par le parcours d'événement** : (1) `checkInParticipant` **plantait pour toute demande incomplète** (aucune vérification) ; (2) **un participant pouvait noter un événement avant qu'il ait lieu, ou annulé** (le commentaire de la fonction disait « après un événement », le code ne vérifiait rien) — corrigé dans `submitEventReview` ; (3) **`respondToParticipation` acceptait une demande avec « accept: "false" »** (du texte non vide vaut « oui » en JavaScript) — corrigé par l'enveloppe.
- [x] **Boutons qui n'annonçaient pas leurs échecs** (le même silence qui cachait l'annulation de place) : un assistant commun `runWithFeedback` (`core/widgets/action_feedback.dart`) appliqué à : annuler sa participation, demander à participer, voir le lieu précis, inviter, accepter/refuser une demande, favori, débloquer, demander une révision humaine du filtrage, acheter (Premium), laisser un avis. Le membre voit « Une erreur est survenue, réessaie » (ou « trop de demandes ») au lieu de rien.
- [x] **L'organisateur voyait un identifiant technique** (suite de caractères) à la place du prénom de chaque demandeur : il voit maintenant le prénom.
- [ ] **Constaté, non corrigé, à décider** : l'organisateur d'un événement « sur invitation » doit **saisir à la main l'identifiant technique** d'un membre pour l'inviter (champ « inviteMemberHint ») — inutilisable en pratique ; à remplacer par une recherche par prénom ou par l'invitation depuis ses matchs (le code de partage, lui, fonctionne).
- [ ] **NON DÉPLOYÉ** : tout le serveur de ce lot (enveloppe commune sur les 55 fonctions, `checkInParticipant`, `submitEventReview`, plus les trois fonctions du profil mis en avant) attend un « déploie » explicite. En production aujourd'hui : les 4 vérifications du parcours d'événement qui dépendent de ces correctifs échouent comme prévu (3 défauts + 1 conséquence) ; les 39 autres passent.
- [x] 48 tests Flutter verts, analyse propre, `tsc` propre. APK de test envoyé au propriétaire (`MERUT-test-14nov.apk`).

## Suivi 2026-11-14 (suite) — DÉPLOIEMENT n° 2 (demandé : « deploi, commit et push pour que tout soit aligné »)

- [x] **Déployé** : les **73 fonctions** du dépôt (dont l'enveloppe commune des fonctions appelables, `checkInParticipant`, `submitEventReview`, `computeCompatibility` avec les thèmes, `getDiscoverCandidates` avec les nouveaux champs et le pourcentage, `getProfileCompletion` avec le test de compatibilité). Un lot a d'abord échoué (« impossible de lister les fonctions », panne passagère de l'API) et a été rejoué : 25/25. Aucune règle ni aucun index à redéployer ce tour-ci (inchangés depuis le déploiement n° 1).
- [x] **Production = dépôt** : `scripts/verify_deployed.py` → « 74 fonctions et les 2 jeux de règles sont identiques au dépôt » (74 = 73 + `verifyPurchase`, désactivée, paiements en pause).
- [x] **Tous les tests réels passent en production** : robustesse **305 appels, 0 plantage** (57 avant) ; parcours d'événement **43/43** (4 échecs avant : les trois défauts et leur conséquence) ; `test_messaging_rgpd.py` **70/70** (avec les pourcentages 0 / 7 / 13 %, les champs de la carte et les thèmes de compatibilité) ; `test_settings_functions` 14/14 ; `test_post_interactions` 27/27 ; `test_account_erasure` 18/18 ; `test_undo_swipe` 14/14 ; `test_audit_fixes` 10/10 ; `test_purge_rejected_photos` 10/10. Aucune donnée de test ne reste en production (publications, signalements, comptes jetables, compteurs vérifiés).
- [x] **Dépôt aligné** : tout est commité et poussé ; l'APK de test envoyé au propriétaire (`MERUT-test-14nov.apk`) est construit à partir du même code et fonctionne maintenant **avec** le serveur à jour (les nouveaux blocs de la carte Découvrir et le pourcentage à 15 éléments sont actifs).
- [ ] Restent à décider ou à faire : confirmation de l'identifiant du projet européen (`merut-prod`) et du compte de facturation ; invitation à un événement « sur invitation » par prénom au lieu de l'identifiant technique ; relecture juridique du consentement ; canal d'avertissement (e-mail) pour purger les comptes inactifs sans appareil joignable ; fusion de l'écran de modification et de l'assistant du profil ; vérification visuelle sur téléphone (en cours par le propriétaire avec l'APK de test).

## Suivi 2026-11-14 (suite) — points 2, 3, 4 et 5 acceptés par le propriétaire (« ok on fait 2, 3, 4 vérifie s'il est bien imposé, 5 fait »)

- [x] **2. Invitation par prénom** : nouvelle fonction `searchMembersToInvite` (organisateurs approuvés seulement, 3 lettres au moins, 20 recherches par minute, 10 résultats au plus ; ne renvoie que prénom, âge et ville de membres actifs, ayant consenti, au profil non masqué et non bloqués dans un sens ou dans l'autre) ; l'organisateur cherche et touche un nom au lieu de saisir un identifiant technique (`_InviteSearchDialog`). Vérifications ajoutées à `scripts/test_events_flow.py` (5).
- [x] **3. Purge des comptes inactifs — canal e-mail** : prêt dans le code, **désactivé** (`INACTIVE_WARNING_EMAIL_ENABLED = false`) : message déposé dans la collection `mail` de l'extension « Trigger Email from Firestore », compte à rebours lancé seulement à la **confirmation de remise** de l'extension. **Il manque une action du propriétaire** : installer l'extension avec un fournisseur d'envoi (SMTP, SendGrid, Mailgun ou Resend), tester, puis passer la constante à `true` et redéployer. Tant que ce n'est pas fait, un compte inactif sans appareil joignable reste conservé (jamais supprimé sans avertissement remis).
- [x] **4. Le consentement est-il bien imposé ? — NON, il ne l'était pas.** Test `scripts/test_consent_enforced.py` sur la production : **26 fonctions de membre sur 31 laissaient agir un membre sans consentement** (dont publier dans la Communauté, participer, inviter, noter, demander la vérification d'identité…) et **Storage acceptait le dépôt d'une photo** (analysée par Cloud Vision) — seules la découverte, les likes, les swipes, les messages et l'enregistrement du profil étaient protégés. **Corrigé** : l'enveloppe commune `onCall` (`shared/callable.ts`) **exige le consentement par défaut pour toute fonction de membre** (les administrateurs en sont dispensés ; 12 fichiers de fonctions volontairement ouvertes utilisent `onCallNoConsent` : consentement, suppression, export, signalements, urgence, recours, réglages, jetons, activité) ; règles **Storage** (photo de profil, pièce d'identité, affiche) et **Firestore** (document d'une photo) refusent sans consentement valide ; **l'écran de consentement passe avant le questionnaire de filtrage** (il révèle l'appartenance à la communauté) et `recordSensitiveConsent` crée le statut d'un compte neuf (seulement si le compte d'authentification existe). **Limites assumées, écrites au registre** : le profil public `users/{uid}` reste lisible d'un membre qui connaît l'identifiant ; une photo de conversation peut être déposée dans Storage sans consentement (limite de 2 lectures des règles) mais n'est jamais publiée (`sendMessage` refuse).
- [x] **5. Éditeur de profil unique** : l'écran de modification et l'assistant de création saisissaient les mêmes champs avec du code recopié. Désormais **un seul écran** (`profil_wizard_screen.dart`) : la création reste pas à pas ; la **modification s'ouvre sur une vue d'ensemble** (une carte par rubrique avec son résumé, « À compléter » en or pour une rubrique obligatoire vide) et toucher une rubrique ouvre exactement l'écran de l'étape ; genre et date de naissance figés (explication affichée) ; l'enregistrement confirme et revient en arrière. `profil_edit_screen.dart` supprimé (483 lignes de doublon). 3 tests (vue d'ensemble sans le genre, rubrique vide bloquante, ouverture/retour d'une rubrique). **Non vérifié sur appareil.**
- [x] 51 tests Flutter verts, analyse propre, `tsc` propre.
- [ ] **NON DÉPLOYÉ** : fonctions (enveloppe avec consentement par défaut, `searchMembersToInvite`, canal e-mail, `recordSensitiveConsent`), règles Firestore et Storage. **Effet à connaître au déploiement** : tout membre sans consentement valide — dont les **comptes réels** du propriétaire — ne pourra plus rien faire dans l'appli avant d'avoir donné son consentement (l'écran s'affiche au lancement) ; les 10 comptes de test l'ont déjà (`scripts/grant_test_consent.py`). Après déploiement : relancer `test_consent_enforced.py`, la robustesse, le parcours d'événement et les autres scripts.
