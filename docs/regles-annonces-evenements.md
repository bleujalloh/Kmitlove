# Règles détaillées — Annonces et Événements (espace Communauté)

Ce document précise, pour chaque type de contenu de l'espace Communauté, qui peut le créer, comment il est modéré, et quelles règles de sécurité s'appliquent. Il complète [regles-du-projet.md](regles-du-projet.md).

## 1. Les cinq types de contenu communauté

| Type | Description | Visibilité |
|---|---|---|
| Publication (fil) | Message simple, discussion, question | Publique à tous les membres |
| Annonce publique | Propose une rencontre/activité ouverte, sans lieu précis engageant | Publique à tous les membres |
| Annonce privée | Propose une rencontre avec accès restreint (ex. chez soi) | Visible mais lieu masqué jusqu'à acceptation |
| Événement public | Rassemblement avec date/lieu/capacité, ouvert à candidature | Publique, lieu précis visible seulement aux participants acceptés |
| Événement privé | Rassemblement sur invitation ou cercle restreint | Visible seulement aux personnes autorisées par l'organisateur |

## 2. Qui peut créer quoi

- **Publication (fil)** : tout membre dont le compte est activé (a passé le questionnaire de filtrage).
- **Annonce publique ou privée** : tout membre activé. Limite de **3 annonces actives simultanées par membre** pour éviter le spam et les comptes utilisés comme vitrine commerciale.
- **Événement public ou privé (rencontre physique)** : **réservé aux membres vérifiés** (vérification d'identité par selfie/vidéo en plus du compte activé). Cette vérification supplémentaire est nécessaire parce qu'organiser une rencontre en personne expose les autres membres à un risque plus élevé qu'une simple conversation — on ne peut pas se permettre qu'un faux profil organise un événement physique.
- **Administrateurs** : peuvent créer des événements officiels "Kamalove" dès le lancement, avant que la vérification des membres soit pleinement opérationnelle.

## 3. Modération par type (règle mixte)

- **Publications (fil)** : **post-modération**. Publié immédiatement, retiré uniquement si signalé et confirmé abusif par un modérateur. Adapté car le risque est faible (pas de rencontre physique engagée).
- **Annonces publiques et privées** : **pré-modération légère automatisée + revue humaine en cas de doute**. Une Cloud Function vérifie automatiquement l'absence de mots-clés interdits (sollicitation d'argent, contenu explicite, promotion commerciale) avant publication ; en cas de doute, mise en attente pour revue humaine sous 24h.
- **Événements physiques (publics et privés)** : **pré-modération humaine obligatoire**, jamais automatique seule. Un modérateur vérifie la cohérence de l'événement (lieu plausible, description claire, organisateur vérifié) avant qu'il soit visible par qui que ce soit. C'est le point le plus sensible de l'app : des inconnus vont physiquement se rencontrer.

## 4. Règles de contenu (toutes annonces et événements)

Interdits dans toute annonce ou événement :

- Demande ou offre d'argent, de cadeaux ou d'avantages matériels en échange d'une rencontre ou d'une présence.
- Contenu à caractère sexuel explicite ou sollicitation de nature sexuelle directe.
- Publicité commerciale déguisée (vente de produits/services sans lien avec la rencontre communautaire).
- Coordonnées précises (adresse complète, numéro de téléphone) affichées publiquement — toujours masquées jusqu'à l'étape d'autorisation prévue.
- Discours de haine, propos dégradants envers un groupe, une religion, une orientation, un genre.
- Fausses informations sur l'identité de l'organisateur ou le lieu réel de l'événement.

Toute violation déclenche : retrait du contenu, avertissement au membre, puis suspension progressive en cas de récidive (voir section 6).

## 5. Règles spécifiques aux événements

- **Capacité** : définie par l'organisateur à la création, ne peut pas être dépassée ; liste d'attente automatique au-delà.
- **Adresse** : jamais affichée en texte libre public. Le lieu précis n'est révélé qu'aux participants dont la demande a été acceptée, généralement 24 à 48h avant l'événement.
- **QR code de participation** : généré pour chaque participant accepté, scanné à l'entrée pour confirmer la présence réelle — permet aussi de détecter les no-shows répétés.
- **Annulations et no-shows** : trois annulations tardives ou absences sans prévenir en moins de 3 mois déclenchent un avertissement ; au-delà, suspension temporaire du droit d'organiser.
- **Signalement d'un organisateur ou d'un événement** : accessible à tout participant depuis la fiche événement, traité en priorité (délai cible 24h) parce qu'un événement à venir est plus urgent qu'un signalement classique.
- **Vérification à l'entrée** : l'organisateur confirme l'identité via le QR code, pas de contrôle d'identité physique supplémentaire imposé par l'app (ce serait intrusif et hors de notre responsabilité légale).

## 6. Escalade en cas d'abus (annonces et événements)

1. **1er signalement confirmé** : retrait du contenu + avertissement envoyé au membre, expliquant la règle enfreinte.
2. **2e signalement confirmé (90 jours)** : suspension du droit de publier des annonces/événements pendant 30 jours, compte toujours actif pour le reste de l'app.
3. **3e signalement confirmé** : suspension complète du compte, avec droit de recours auprès d'un modérateur humain (cohérent avec la règle générale de modération du projet).

Chaque signalement, décision et action de modérateur est journalisé (qui, quoi, quand) dans l'espace admin, pour pouvoir vérifier qu'aucune décision n'est arbitraire.

## 7. Ce qui reste à trancher plus tard (hors V1)

- Billetterie payante pour les événements (mentionnée comme évolution future dans le cahier des charges) — nécessitera des règles financières et fiscales en plus de ces règles de contenu.
- Vérification renforcée des organisateurs réguliers (au-delà de la vérification de base).

---

Ce document doit être relu avant le développement de l'espace Communauté et mis à jour si une nouvelle règle est décidée.
