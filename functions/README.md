# Cloud Functions — logique sensible côté serveur

Ce dossier contiendra tout ce qui doit tourner côté serveur et jamais dans l'app, conformément à [docs/regles-du-projet.md](../docs/regles-du-projet.md) section 2 et [docs/architecture-technique.md](../docs/architecture-technique.md) :

- Correction du questionnaire de filtrage à l'inscription (score, seuil 80-90 %)
- Calcul du score de compatibilité (docs/regles-economie-et-compatibilite.md)
- Création d'un match (vérification des deux likes en base)
- Gestion des jetons (crédit, consommation, anti-abus)
- Vérification des droits Premium
- Modération des photos (délai de 48h, docs/regles-messagerie-securite.md)
- Traitement des signalements et suspensions

À initialiser avec `firebase init functions` (TypeScript) une fois le projet Firebase créé — pas encore fait à ce stade.
