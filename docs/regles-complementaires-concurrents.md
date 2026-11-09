# Règles complémentaires — issues de la comparaison avec Tinder, Bumble, Happn, Meetic

Ce document ajoute les règles identifiées en comparant Kamalove aux applications de référence du marché. Il complète [regles-du-projet.md](regles-du-projet.md), [regles-annonces-evenements.md](regles-annonces-evenements.md), [regles-messagerie-securite.md](regles-messagerie-securite.md) et [regles-economie-et-compatibilite.md](regles-economie-et-compatibilite.md).

## 1. Sécurité

### Bouton d'urgence pendant un rendez-vous (inspiré de Bumble/Tinder)

- Sur la fiche d'un événement accepté et sur une conversation ayant conduit à un rendez-vous déclaré, un bouton **"Signaler un danger immédiat"** est toujours visible.
- Déclenché, il envoie en priorité absolue (cible : moins d'une heure, pas 4h comme un signalement standard) une alerte à l'équipe de modération avec les dernières informations disponibles (dernier événement accepté, dernière conversation active).
- Ce bouton **n'appelle jamais les secours automatiquement** (on n'est pas un service d'urgence) — il affiche aussi, de façon permanente et indépendamment de tout signalement, les numéros d'urgence locaux (17/112 en France, adaptés selon le pays de résidence déclaré).

### Photos partagées en message — floutées par défaut à la première réception

- Puisqu'on n'a pas de détection automatique de contenu explicite ([regles-messagerie-securite.md](regles-messagerie-securite.md)), on applique une protection qui ne dépend pas de l'IA, inspirée de la fonction "Private Detector" de Bumble : **toute photo reçue pour la première fois d'une personne est floutée par défaut**, avec un bouton "Afficher" que le destinataire doit cliquer volontairement.
- Ce flou par défaut s'applique uniquement à la **première** photo de chaque nouvelle conversation ; les photos suivantes s'affichent normalement, sauf si le destinataire réactive le flou dans ses paramètres pour toutes les photos.
- Objectif : laisser le choix au destinataire plutôt que de lui imposer un contenu non désiré d'un coup, sans dépendre d'une IA de modération qu'on n'a pas.

### Vérification d'identité — badge visible, pas réservé aux organisateurs

- La vérification par selfie/vidéo (déjà prévue pour les organisateurs d'événements, [regles-annonces-evenements.md](regles-annonces-evenements.md)) est **ouverte à tout membre qui le souhaite**, pas seulement aux organisateurs.
- Un membre vérifié affiche un **badge visible** sur son profil, dans Découvrir, dans les likes et dans la messagerie.
- La vérification n'est jamais obligatoire pour utiliser l'app normalement (seulement pour organiser un événement physique), mais elle est encouragée activement (ex. mise en avant dans Découvrir pour les profils vérifiés).

### Vérification de l'âge — au-delà d'une case à cocher

- La case "J'ai 18 ans et plus" reste à l'inscription, mais ne suffit pas seule pour couvrir Kamalove légalement (les plateformes européennes sont de plus en plus tenues de vérifier réellement l'âge, pas juste de le déclarer).
- Dès que la vérification d'identité (ci-dessus) est passée par un membre, elle confirme aussi son âge réel — un double usage pour une seule démarche.
- Pour les membres non vérifiés, prévoir un futur contrôle d'âge plus robuste qu'une case à cocher (ex. estimation d'âge par un tiers spécialisé) **si la réglementation l'exige** — à surveiller plutôt qu'à construire dès la V1, mais à ne pas oublier.

## 2. Règles légales de facturation (obligatoires en France/UE, pas optionnelles)

- **Résiliation en 3 clics maximum** : l'abonnement Premium doit pouvoir être annulé en ligne aussi facilement qu'il a été souscrit, obligation légale française depuis 2023. Jamais de parcours de résiliation plus long ou plus compliqué que la souscription.
- **Transparence sur le renouvellement automatique** : avant tout paiement (abonnement ou pack de jetons), afficher clairement la date de prochain prélèvement et comment annuler, pas seulement dans les conditions générales.
- **Droit à la portabilité des données (RGPD)** : en plus du droit à l'oubli déjà prévu ([architecture-technique.md](architecture-technique.md)), un membre doit pouvoir **demander et recevoir une copie de ses propres données** (profil, réponses au questionnaire, historique de messages) dans un format lisible.

## 3. Fonctionnement — ajustements inspirés des concurrents

- **Expiration d'un match sans message (inspiré de Bumble)** : un match créé sans qu'aucun message ne soit envoyé par les deux parties sous **7 jours** disparaît automatiquement de la liste active (déplacé dans un onglet "matchs expirés", récupérable mais plus mis en avant). Objectif : éviter l'accumulation de matchs morts et encourager à engager la conversation. Délai choisi plus long que les 24h de Bumble, cohérent avec le positionnement "relation sérieuse" plutôt que rencontre rapide.
- **Nombre de likes gratuits par jour** : fixé à **20 likes/jour** pour la formule gratuite (à ajuster après les premiers retours d'usage), illimité en Premium. Calculé et appliqué côté serveur.
- **Masquage des comptes inactifs** : un profil sans connexion depuis plus de **30 jours** n'apparaît plus dans Découvrir (il réapparaît automatiquement à la prochaine connexion). Évite de proposer des profils qui ne répondront jamais.
- **Règles du Boost (Premium)** : un Boost dure **30 minutes**, utilisable **une fois par semaine** inclus dans Premium (achat de Boosts supplémentaires à l'unité possible, même mécanique que les jetons).
- **Filtres d'âge et de préférences précis** : tranche d'âge réglable par le membre (par défaut ±8 ans autour de son âge), distance réglable de 5 à 100 km, filtre par intention relationnelle (section 4.2 du cahier des charges) disponible dès la formule gratuite.

## 4. Ce qu'on choisit explicitement de ne pas reproduire

- **L'historique de position passive ("vous vous êtes croisés ici") de Happn** n'est pas repris. Cette fonctionnalité suppose de suivre la position d'un membre même quand l'app est fermée, ce qui contredit nos propres règles de minimisation des données et de protection de la position ([architecture-technique.md](architecture-technique.md), [regles-du-projet.md](regles-du-projet.md) section 2). La distance approximative affichée dans Découvrir reste calculée au moment présent, jamais via un historique de déplacements.

---

Ce document doit être relu avant le développement des fonctionnalités de sécurité, de facturation et des mécaniques de match/boost.
