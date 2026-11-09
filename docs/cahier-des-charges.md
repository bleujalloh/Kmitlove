# Cahier des charges — Application de rencontres kamites

Version : 1.0 — Cadrage initial
Plateforme : Android et iOS
Framework : Flutter / Dart
Backend : Firebase
Positionnement : Application de rencontres amoureuses exclusivement kamite.

---

## 1. Vision et positionnement

Créer une plateforme de rencontres amoureuses destinée aux personnes qui se reconnaissent dans l'identité et la communauté kamites.

L'application ne doit pas être une simple copie de Tinder. Elle doit associer trois dimensions :

- Le dating : découverte, compatibilité, likes, matchs et conversations.
- La culture : identité, valeurs, histoire et références culturelles kamites.
- La communauté : annonces, publications, événements et lieux qui favorisent les rencontres.

Objectif : permettre aux membres de rencontrer des personnes avec lesquelles ils partagent une vision de la relation, des valeurs et une identité culturelle.

L'appartenance à la communauté repose sur l'auto-identification et l'adhésion à la charte communautaire, et non sur une prétendue vérification biologique ou raciale.

## 2. Public cible

- Adultes de 18 ans et plus.
- Personnes s'identifiant à la communauté kamite.
- Personnes recherchant une relation amoureuse.
- Membres de la diaspora et personnes résidant sur le continent africain.
- Utilisateurs souhaitant rencontrer des personnes partageant leurs références culturelles.

Déploiement progressif : France, Europe, Afrique et diaspora internationale.

## 3. Navigation principale

La navigation principale comprend quatre espaces :

1. Likes.
2. Messages.
3. Découvrir (swipe central).
4. Communauté.

Le profil personnel et les paramètres sont accessibles indépendamment de cette navigation.

## 4. Fonctionnalités détaillées

### 4.1 Authentification

- Inscription par e-mail.
- Connexion par e-mail.
- Connexion Google et Apple.
- Vérification de l'adresse e-mail.
- Réinitialisation du mot de passe.
- Validation obligatoire de l'âge minimum.
- Acceptation des conditions d'utilisation et de la politique de confidentialité.
- Suppression du compte.

### 4.2 Création du profil

Informations :

- Prénom ou pseudonyme.
- Date de naissance.
- Genre et préférences de recherche.
- Pays et ville.
- Photos de profil.
- Description personnelle.
- Profession (facultative).
- Langues parlées.
- Centres d'intérêt.
- Origines culturelles déclarées (facultatives).
- Présentation de ses valeurs.
- Intention relationnelle.

Intentions possibles :

- Relation sérieuse.
- Relation durable en vue d'une famille.
- Découverte amoureuse.
- Mariage.

Le profil doit pouvoir être modifié à tout moment.

### 4.3 Test de compatibilité kamite

Un questionnaire doit permettre de mieux comprendre la personnalité, les attentes et la vision du couple.

Les thèmes du questionnaire :

**A. Vision du couple**

- Quelle est ta conception d'une relation amoureuse ?
- Quelle importance accordes-tu à la fidélité ?
- Quelle place occupent la communication et le respect ?
- Comment envisages-tu la gestion des conflits ?

**B. Valeurs et culture**

- Quelle place occupent les références culturelles kamites dans ta vie ?
- Souhaites-tu transmettre une culture et une histoire à tes enfants ?
- Quelle importance accordes-tu à la connaissance de l'histoire africaine ?
- Quelle place accordes-tu aux traditions et aux pratiques culturelles ?

**C. Famille**

- Souhaites-tu avoir des enfants ?
- Quelle place doit occuper la famille dans le couple ?
- Quelle vision as-tu de l'éducation des enfants ?

**D. Mode de vie**

- Préfères-tu vivre en ville ou à la campagne ?
- Quelle importance accordes-tu à la stabilité financière ?
- Comment imagines-tu la répartition des responsabilités dans le couple ?

**E. Communication et personnalité**

- Es-tu plutôt réservé ou extraverti ?
- Comment exprimes-tu ton affection ?
- Comment réagis-tu face aux désaccords ?

Le questionnaire ne doit pas être un examen d'appartenance à la communauté. Il doit aider à déterminer les affinités amoureuses.

Calcul de compatibilité proposé :

- Vision du couple : 30 %.
- Valeurs et culture : 25 %.
- Famille : 20 %.
- Mode de vie : 15 %.
- Communication : 10 %.

Les réponses sensibles ou facultatives ne doivent pas être imposées. Les membres doivent pouvoir modifier leurs réponses et contrôler leur visibilité.

### 4.4 Découvrir — Swipe

Fonction centrale de l'application.

- Affichage des profils sous forme de cartes.
- Photo principale.
- Prénom, âge et distance approximative.
- Description.
- Centres d'intérêt communs.
- Indicateur de compatibilité.
- Galerie de photos.
- Bouton Like.
- Bouton Passer.
- Super Like (Premium).
- Retour au profil précédent (Premium).
- Filtres de recherche.

Le système ne doit pas afficher plusieurs fois les profils déjà ignorés, sauf si une fonction de retour est utilisée.

### 4.5 Likes

- Voir les personnes ayant aimé son profil.
- Voir les matchs.
- Retirer un Like.
- Filtrer les profils.
- Voir les interactions récentes.

Les possibilités sont limitées dans la formule gratuite et étendues dans la formule Premium.

### 4.6 Matchs et messagerie

Un match est créé lorsque deux membres se donnent mutuellement un Like.

Fonctionnalités :

- Messagerie privée.
- Messages texte.
- Photos partagées avec contrôle de sécurité.
- Notifications de nouveaux messages.
- Indicateur de lecture (paramétrable).
- Blocage.
- Signalement.
- Suppression d'une conversation selon les règles de conservation applicables.

La messagerie est réservée aux membres ayant établi une connexion mutuelle, sauf fonctionnalité explicitement introduite ultérieurement.

### 4.7 Communauté

La communauté doit favoriser les rencontres sans devenir un réseau social généraliste.

Publications :

- Annonces publiques.
- Publications communautaires.
- Annonces privées.
- Commentaires et réactions.
- Signalement des publications.

Annonces privées :

- Un membre publie une annonce.
- Il définit les personnes autorisées à accéder à l'annonce.
- Les personnes intéressées envoient une demande.
- L'auteur accepte ou refuse.
- L'adresse exacte reste masquée jusqu'à l'autorisation appropriée.

Événements :

- Création d'événements.
- Événements publics ou privés.
- Description, date, lieu et capacité.
- Demandes de participation.
- Acceptation ou refus.
- Liste d'attente.
- QR code de participation.
- Vérification à l'entrée.
- Signalement des organisateurs et événements.

Les événements sont un outil de rencontre, pas un mode de recherche d'amis.

### 4.8 Sécurité et modération

- Vérification d'adresse e-mail.
- Vérification facultative de profil par selfie ou vidéo.
- Modération des photos.
- Signalement des faux profils.
- Blocage immédiat.
- Modération des annonces.
- Modération des messages signalés.
- Détection des comportements abusifs.
- Limitation des tentatives de connexion.
- Protection contre les bots.
- Charte de bonne conduite.
- Procédure de suspension et d'appel.

Les coordonnées précises, adresses personnelles et positions GPS exactes ne doivent jamais être exposées publiquement.

## 5. Modèle économique

**Formule gratuite**

- Création de profil.
- Questionnaire de compatibilité.
- Découverte des profils.
- Likes limités.
- Matchs.
- Messagerie après match.
- Accès aux événements publics.
- Publications communautaires.

**Formule Premium**

Prix de référence : 9,99 €/mois.

Avantages envisagés :

- Likes illimités ou quota supérieur.
- Voir les personnes qui ont aimé son profil.
- Retour au profil précédent.
- Filtres avancés.
- Filtres par valeurs et compatibilité.
- Boost de visibilité.
- Mode invisible.
- Affichage des membres récemment actifs.
- Distance de recherche étendue.
- Accès prioritaire à certaines fonctionnalités événementielles.

La facturation et les droits d'accès doivent être gérés côté serveur.

## 6. Administration

Un espace d'administration sera développé pour :

- Consulter les utilisateurs.
- Gérer les suspensions.
- Traiter les signalements.
- Modérer les photos.
- Modérer les annonces.
- Gérer les événements.
- Gérer les abonnements.
- Consulter les statistiques.
- Gérer les catégories et paramètres.
- Consulter les journaux d'activité.

Les administrateurs doivent avoir des rôles et permissions distincts.

## 7. Évolutions futures

- Appels audio et vidéo après consentement.
- Traduction automatique.
- Suggestions intelligentes de compatibilité.
- Recommandations personnalisées.
- Billetterie avancée.
- Vérification renforcée des organisateurs.
- Développement international.
- Application web communautaire.

Ces éléments ne bloquent pas la première version.

---

FIN DU CAHIER DES CHARGES
