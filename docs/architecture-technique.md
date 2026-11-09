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
