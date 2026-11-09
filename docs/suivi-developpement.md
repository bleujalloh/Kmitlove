# Suivi de développement — Kamalove

Checklist de toutes les parties du cahier des charges et des règles, pour qu'aucune ne soit oubliée. Mise à jour à chaque session de travail. `[ ]` à faire, `[~]` en cours, `[x]` fait.

## Fondations

- [x] Projet Flutter créé, structure par fonctionnalité, Riverpod, thème
- [x] Firebase connecté (projet djama-1c7f8), règles Firestore/Storage par défaut déployées
- [x] Squelette Cloud Functions
- [x] **L'APK Android compile avec succès** (`flutter build apk --debug`, 2026-11-09) — minSdk 23 fixé dans android/app/build.gradle.kts (attention : l'outil de migration Gradle de Flutter peut réécrire ce fichier lors d'un futur `flutter build`, à vérifier si ça revient)
- [ ] Plan Firebase Blaze — volontairement repoussé à la fin (décision du 2026-11-09), donc Cloud Functions pas encore déployées/testables en conditions réelles malgré le code prêt et relu
- [x] Firebase Storage activé (2026-11-10, mode production) — règles de sécurité réelles déployées (photos approuvées uniquement, vérification d'identité jamais visible par un autre membre)
- [x] Fournisseur Google activé dans Firebase Authentication (2026-11-10) — OAuth client Android confirmé et lié au SHA-1 de debug, config régénérée. **Fonctionnel pour le debug ; il faudra refaire la même vérification avec le SHA-1 de la clé de release avant publication sur le Play Store.**
- [x] Plan Blaze activé (2026-11-09) — toutes les Cloud Functions déployées en production (europe-west1)
- [x] Navigation de premier niveau (AuthGate : onboarding → auth → vérification e-mail → app). go_router à brancher pour la navigation interne (Découvrir/Likes/Messages/Communauté) à l'étape suivante.
- [ ] Firebase App Check (anti-bot, section 2 regles-du-projet.md)
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
- [ ] Banque de questions **chargée dans Firestore** — le contenu est rédigé (docs/banque-questions-filtrage.md), reste à l'importer dans `filtrage_question_bank` avant de pouvoir tester réellement
- [ ] Limite de comptes par appareil/e-mail (nécessite App Check / un dispositif anti-abus, pas encore fait)
- [x] Revue indépendante passée sur cette fonctionnalité (2026-11-09) : 5 problèmes trouvés et corrigés (course d'affichage, double soumission, contournement du délai, suppression de compte, nonce Apple)

## 4.2 Profil

- [x] Création du profil (toutes les informations texte de la section 4.2), validation 18 ans sur la vraie date de naissance
- [x] Fiche étoffée comme les applications de rencontre courantes (2026-11-09) : taille, niveau d'études, tabac/alcool, enfants, "ce que tu recherches chez l'autre" — tous facultatifs
- [ ] **Accès en modification depuis les paramètres** — le formulaire supporte déjà l'édition (`ProfilEditScreen(existing: ...)`) mais rien n'y mène encore ; à faire avec l'écran Paramètres
- [x] Upload de photos (jusqu'à 6), statut "en attente" visible, suppression — le code est prêt mais **ne fonctionnera qu'une fois Storage activé** (action manuelle restante, voir Fondations)
- [x] Modération planifiée des photos (`autoApprovePhotos`, toutes les heures, approuve après 48h si aucun modérateur n'a traité) + onglet admin pour valider/refuser manuellement avant ce délai
- [x] Vérification d'identité par selfie (ouverte à tout membre, pas réservée aux organisateurs) + onglet admin avec aperçu de la photo (URL signée temporaire) — **ne fonctionnera qu'une fois Storage activé**
- [x] Revue indépendante passée (2026-11-09, deux passes) : erreur réseau non affichée ; puis date falsifiable, lecture Storage non alignée sur le vrai statut, lot de modération non borné, ordre de suppression, URL recalculée à chaque reconstruction — toutes corrigées

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

- [x] Abonnement Premium — achat via Google Play (API Subscriptions v2), vérification serveur, crédit anti-fraude (registre global des jetons de paiement)
- [ ] Vérification Apple/App Store — **pas construite**, compte développeur Apple pas ouvert (99$/an). Le code est structuré pour l'accueillir de la même façon (functions/src/premium/verifyPurchase.ts), mais aucun achat iOS ne peut être crédité tant que ce n'est pas fait.
- [ ] **Révocation/expiration de Premium** — `isPremium` passe à `true` à l'achat mais rien ne le repasse à `false` en cas d'annulation/non-renouvellement/remboursement. Nécessite les Realtime Developer Notifications (webhook Pub/Sub de Google Play), pas mis en place — **à faire avant un vrai lancement payant**, sinon un abonnement annulé reste actif indéfiniment.
- [ ] Résiliation en 3 clics — dépend du flux natif Google Play/App Store (géré par eux une fois l'app en ligne), rien à construire côté app pour l'abonnement lui-même, mais à vérifier que le parcours réel respecte bien la règle une fois publié
- [ ] Transparence sur le renouvellement automatique avant achat — pas d'écran dédié, à ajouter dans l'UI du PremiumScreen
- [x] Jetons à l'unité (achat consommable, relance d'un profil passé via `useJetonToResurface`, un seul rachat par profil)
- [ ] Boost (30 min, 1x/semaine Premium) — pas construit
- [x] Espace admin minimal (section 6) : traitement des signalements (classer/avertir/suspendre), des révisions de filtrage (activer/maintenir le refus), validation/refus des annonces et événements en attente
- [ ] Rôle admin : custom claim Firebase Auth `admin: true` à poser **manuellement** sur le premier compte (console Firebase/Admin SDK) — aucune fonction ne le fait, volontairement (pas de façon de "s'auto-nommer admin" depuis l'app)
- [ ] Gestion des utilisateurs (lister/consulter un profil depuis l'admin) — pas construit
- [ ] Gestion des abonnements, statistiques, journaux d'activité détaillés — pas construits (chaque action admin trace déjà qui/quand/quoi sur le document concerné, mais pas de vue d'ensemble dédiée)
- [ ] Modération photo — sans objet tant que Storage n'est pas activé
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
- [ ] **Paiement Stripe non configuré — décision assumée, pas un oubli** : les abonnements/achats intégrés dans une app mobile doivent obligatoirement passer par les systèmes natifs Google Play / Apple (politique des stores, pas un choix technique) — Stripe ne peut pas servir à ça sur mobile. C'est pour ça qu'on a construit `verifyPurchase` avec l'API Google Play plutôt que Stripe. Si un jour il faut un paiement web (site vitrine, pas l'app), Stripe redeviendrait pertinent à ce moment-là.
- [x] Revue indépendante passée (2026-11-10, deux passes) : race condition sur le bootstrap admin (deux comptes auraient pu devenir admin simultanément), gestion d'erreur trop générique, puis un verrou qui aurait pu bloquer définitivement le bootstrap en cas d'échec partiel — toutes corrigées

## RGPD / légal (transverse, à ne pas traiter en dernier)

- [ ] Export des données personnelles (portabilité)
- [ ] Suppression/anonymisation réelle à la demande
- [ ] Résiliation Premium en 3 clics
