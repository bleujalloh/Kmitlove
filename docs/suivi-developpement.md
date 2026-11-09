# Suivi de développement — Kamalove

Checklist de toutes les parties du cahier des charges et des règles, pour qu'aucune ne soit oubliée. Mise à jour à chaque session de travail. `[ ]` à faire, `[~]` en cours, `[x]` fait.

## Fondations

- [x] Projet Flutter créé, structure par fonctionnalité, Riverpod, thème
- [x] Firebase connecté (projet djama-1c7f8), règles Firestore/Storage par défaut déployées
- [x] Squelette Cloud Functions
- [ ] Firebase Storage activé (action manuelle requise — console web, région à choisir)
- [~] Navigation (go_router) avec gardes (onboarding → auth → filtrage → app)
- [ ] Firebase App Check (anti-bot, section 2 regles-du-projet.md)
- [ ] Projets Firebase séparés dev/staging/prod (actuellement un seul projet — à faire avant la mise en production réelle)

## 4.1 Authentification

- [~] Inscription par e-mail
- [ ] Connexion par e-mail
- [ ] Connexion Google
- [ ] Connexion Apple
- [ ] Vérification de l'adresse e-mail
- [ ] Réinitialisation du mot de passe
- [ ] Validation de l'âge minimum (case à cocher + badge vérifié plus tard)
- [ ] Acceptation CGU/charte (écran déjà prototypé)
- [ ] Suppression du compte (Cloud Function, anonymisation RGPD)

## Filtrage à l'inscription (regles-du-projet.md section 1)

- [ ] Banque de questions en base (Firestore, admin peut en ajouter)
- [ ] Tirage aléatoire des questions côté serveur
- [ ] Cloud Function de correction + seuil 80-90 %
- [ ] Écran questionnaire (déjà prototypé visuellement)
- [ ] Compte en attente + nouvel essai après délai + recours humain
- [ ] Anti-contournement (limite comptes par appareil/e-mail)

## 4.2 Profil

- [ ] Création/édition de toutes les informations (section 4.2)
- [ ] Upload photo + statut "en attente de validation" (délai 48h, regles-messagerie-securite.md)
- [ ] Badge de vérification d'identité (regles-complementaires-concurrents.md)

## 4.3 Test de compatibilité kamite

- [ ] Questionnaire (5 thèmes)
- [ ] Cloud Function de calcul (formule précise, regles-economie-et-compatibilite.md section 2)
- [ ] Recalcul automatique si modification des réponses

## 4.4 Découvrir

- [ ] Candidats précalculés (Cloud Scheduler, architecture-technique.md section 4)
- [ ] Écran swipe (déjà prototypé)
- [ ] Filtres (âge ±8 ans par défaut, distance 5-100 km, intention)
- [ ] Limite 20 likes/jour gratuit, illimité Premium
- [ ] Masquage des comptes inactifs (30 jours)

## 4.5 Likes

- [ ] Écran "m'ont liké" / "mes likes" (déjà prototypé)
- [ ] Teaser Premium pour débloquer

## 4.6 Matchs et messagerie

- [ ] Création de match (Cloud Function, vérifie les deux likes)
- [ ] Expiration d'un match sans message sous 7 jours
- [ ] Messagerie temps réel (Firestore)
- [ ] Indicateur de lecture (activé par défaut, désactivable + réciprocité)
- [ ] Photos en message floutées par défaut à la première réception
- [ ] Blocage / signalement (flux commun, regles-economie-et-compatibilite.md section 3)

## 4.7 Communauté

- [ ] Publications (post-modération)
- [ ] Annonces publiques/privées (pré-modération légère + revue humaine si doute), max 3 actives
- [ ] Événements (pré-modération humaine obligatoire), réservés aux membres vérifiés
- [ ] Capacité, liste d'attente, QR code de participation
- [ ] Bouton d'urgence sur événement accepté

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
