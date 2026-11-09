# Organisation du code — lib/

Architecture par fonctionnalité (feature-first), comme décidé dans [docs/regles-du-projet.md](../docs/regles-du-projet.md) section 3.

- `core/` — ce qui est partagé par toute l'app : thème (`theme/`), navigation (`router/`), services transverses (`services/`, ex. connexion à Firebase).
- `features/` — un dossier par fonctionnalité du cahier des charges, chacun avec ses sous-dossiers `data/` (accès Firestore/Functions), `domain/` (modèles, logique) et `presentation/` (écrans, widgets) :
  - `auth/` — inscription, connexion, suppression de compte (section 4.1 du cahier des charges)
  - `onboarding/` — accueil et charte communautaire
  - `filtrage/` — questionnaire de vérification d'engagement à l'inscription (section 4.3 + docs/regles-du-projet.md section 1)
  - `profil/` — création et édition du profil (section 4.2)
  - `decouvrir/` — swipe et compatibilité (section 4.4)
  - `likes/` — qui m'a liké, mes likes (section 4.5)
  - `messages/` — messagerie post-match (section 4.6 + docs/regles-messagerie-securite.md)
  - `communaute/` — annonces et événements (section 4.7 + docs/regles-annonces-evenements.md)
  - `premium/` — abonnement et jetons (docs/regles-economie-et-compatibilite.md)
  - `admin/` — espace d'administration (section 6)

Règle importante : **aucune logique sensible ici** (score de compatibilité, droits Premium, modération). Ce code n'affiche et n'envoie des demandes ; le calcul et la décision finale viennent toujours des Cloud Functions, dans `functions/`.
