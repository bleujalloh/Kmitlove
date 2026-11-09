# Règles du projet — app-rencontre

Ce document est la référence commune pour tout ce qui touche au code, au dépôt, à la sécurité et au filtrage des inscriptions. Toute décision qui s'écarte de ce document doit être discutée et validée avant d'être appliquée.

---

## 1. Filtrage à l'inscription (vérification d'engagement, pas de race)

Principe : on ne vérifie jamais l'origine, la couleur de peau ou l'ascendance. On vérifie la connaissance de la culture/histoire kamite et l'adhésion aux valeurs de la charte communautaire. C'est un filtre d'engagement, pas un filtre racial — légalement et éthiquement, c'est la seule approche possible.

- Questionnaire posé après la création du compte, avant son activation.
- Banque de questions large (histoire, civilisations, valeurs, charte communautaire), piochée aléatoirement à chaque tentative pour qu'on ne puisse pas se partager les réponses.
- Une question non répondue compte comme une mauvaise réponse.
- **Seuil de réussite : 80-90 %.**
- Correction et seuil calculés **uniquement côté serveur** (Cloud Functions), jamais côté client — sinon n'importe qui peut lire le code de l'app et trouver les bonnes réponses ou le seuil.
- En cas d'échec :
  - Le compte reste en attente (pas de suppression).
  - Nouvel essai possible après un délai (7 à 30 jours), pour empêcher de réessayer en boucle jusqu'à deviner les bonnes réponses.
  - Droit de recours : demande de révision humaine par un modérateur, pour les cas où quelqu'un est sincère mais s'est mal exprimé ou a mal compris une question.
- Limiter le nombre de comptes par appareil et par e-mail, pour empêcher de créer un nouveau compte à chaque échec.
- Journaliser chaque tentative (date, score, résultat) côté admin, pour détecter les abus et ajuster les questions trop ambiguës.

## 2. Règles de sécurité (non négociables)

- **Toute logique sensible tourne côté serveur** (Cloud Functions / règles Firestore), jamais côté client : correction du questionnaire, calcul de compatibilité, droits Premium, modération. Le client ne fait qu'afficher et envoyer des demandes.
- **Règles de sécurité Firestore/Storage strictes dès le départ** : par défaut, tout est interdit, puis on ouvre uniquement ce qui est nécessaire (principe du moindre privilège). Jamais de règle du type "tout le monde peut tout lire/écrire" même temporairement pendant le dev.
- **Aucune coordonnée précise exposée publiquement** : position GPS, adresse exacte, numéro de téléphone — jamais stockés en clair dans un champ lisible par n'importe quel utilisateur.
- **Aucun secret dans le code ou le dépôt** : clés API, clés de service Firebase, identifiants admin → toujours dans des variables d'environnement ou le gestionnaire de secrets, jamais commités. Un fichier `.gitignore` bloque dès le départ les fichiers de clés (`*.json` de service account, `.env`, etc.).
- **Protection anti-bot** : Firebase App Check obligatoire sur toutes les Cloud Functions sensibles (inscription, questionnaire, like/swipe) pour bloquer les clients automatisés.
- **Limitation des tentatives** : connexion, questionnaire, signalement — toutes les actions sensibles sont limitées en fréquence (rate limiting) pour empêcher le brute-force et le spam.
- **Modération humaine en dernier recours** : aucune décision automatique de bannissement définitif sans possibilité de recours humain.

## 3. Règles de code

- **Architecture en couches par fonctionnalité** (feature-first) : chaque fonctionnalité (auth, profil, swipe, messagerie, communauté, admin) dans son propre dossier sous `lib/features/`, avec sa logique, ses écrans et ses modèles séparés.
- **Gestion d'état** : un seul outil de gestion d'état pour tout le projet (à choisir ensemble — ex. Riverpod), pas de mélange de plusieurs approches.
- **Pas de logique métier dans les widgets d'écran** : un écran affiche, il ne calcule pas. La logique va dans des classes séparées (services/contrôleurs), testables indépendamment de l'interface.
- **Linting actif dès le départ** (`flutter_lints` ou équivalent strict) : le code qui ne respecte pas les règles de style ne doit pas être mergé.
- **Pas de code mort ni de fonctionnalité à moitié faite laissée dans le code principal** : soit c'est fini et testé, soit ça reste dans une branche à part.

## 4. Règles du dépôt et des dossiers

- **Un seul projet par dossier/dépôt** : `app-rencontre` ne doit jamais partager de code, de dépendances ou de configuration avec NEEGUI ou le site e-commerce.
- **Branches** :
  - `main` = toujours stable et déployable, jamais de code cassé dessus.
  - Une branche par fonctionnalité (`feature/nom-de-la-fonctionnalite`), fusionnée dans `main` seulement après vérification.
- **Commits** : messages clairs en français, un commit = un changement cohérent (pas de "fourre-tout").
- **Pas de push direct sur `main` sans relecture**, même seul — se relire avant de merger évite les régressions silencieuses.

## 5. Règles de non-régression

- **Aucune fonctionnalité qui marchait avant ne doit casser silencieusement.** Avant de merger un changement, on vérifie que les fonctionnalités déjà en place fonctionnent toujours.
- **Tests automatiques sur la logique sensible** (calcul du score du questionnaire, calcul de compatibilité, droits Premium, règles de sécurité Firestore) — pas besoin de tout tester, mais ce qui touche à l'argent, à la sécurité ou à l'accès ne doit jamais partir sans test.
- **Avant toute mise à jour d'une dépendance majeure** (Flutter, Firebase), vérifier que l'application démarre et que les parcours critiques (inscription, swipe, match, message) fonctionnent toujours.

## 6. Règles détaillées de l'espace Communauté (annonces et événements)

Voir le document dédié [regles-annonces-evenements.md](regles-annonces-evenements.md) : qui peut créer une annonce ou un événement, modération mixte (pré-modération obligatoire pour tout événement physique, post-modération pour les publications simples du fil), règles de contenu, masquage des adresses, gestion des no-shows, et escalade en cas d'abus.

## 7. Règles détaillées — Photos et messagerie

Voir le document dédié [regles-messagerie-securite.md](regles-messagerie-securite.md) : validation humaine systématique de toute photo de profil (pas d'IA de modération au lancement), règles de la messagerie privée (réservée aux matchs, indicateur de lecture activé par défaut, gestion des photos échangées en message), et flux commun de signalement/blocage.

## 8. Règles anti-contournement spécifiques

- Le seuil et les réponses du questionnaire ne sont **jamais présents dans le code de l'application** envoyée sur les téléphones (sinon n'importe qui peut décompiler l'app et trouver les réponses).
- Limiter la création de comptes multiples (par appareil, par e-mail, éventuellement par numéro de téléphone à terme).
- Détecter les comptes qui échouent puis recréent un compte immédiatement avec les mêmes informations (appareil, e-mail similaire) pour contourner le délai d'attente.
- Toute évolution de ces règles de filtrage doit être documentée ici et expliquée avant d'être codée.

---

Ce document doit être relu et mis à jour à chaque évolution importante du projet.
