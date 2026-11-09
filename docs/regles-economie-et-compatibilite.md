# Règles détaillées — Jetons, calcul de compatibilité, suites du signalement

Complète [regles-du-projet.md](regles-du-projet.md), [regles-annonces-evenements.md](regles-annonces-evenements.md) et [regles-messagerie-securite.md](regles-messagerie-securite.md).

## 1. Jetons à l'unité (nouvelle brique du modèle économique)

En plus de l'abonnement Premium (9,99 €/mois, cahier des charges section 5), on ajoute un **achat à la carte indépendant de l'abonnement** : des jetons vendus en packs (ex. pack de 5, pack de 15 — tarifs précis à fixer plus tard).

**Usage** : 1 jeton consommé permet de faire réapparaître, une seule fois, un profil qu'on a précédemment passé dans "Découvrir", pour pouvoir lui envoyer un like.

Règles :

- Un jeton **ne garantit jamais un match** : il ne fait que renvoyer un like, le match dépend toujours de la réciprocité de l'autre personne.
- **Un seul rachat par profil passé** : même avec plusieurs jetons, on ne peut pas faire réapparaître indéfiniment la même personne si elle continue de passer. Ça éviterait qu'un jeton devienne un outil de harcèlement envers quelqu'un qui a clairement ignoré un profil.
- Jeton consommé **au moment de la réapparition**, pas remboursé si le profil ciblé a supprimé son compte, désactivé son compte, ou n'est plus dans la zone de recherche entre-temps — ce cas est signalé clairement à l'utilisateur avant la dépense ("ce profil n'est peut-être plus disponible").
- Le crédit, la consommation et la vérification des jetons sont calculés **côté serveur uniquement** (Cloud Functions), jamais côté client — même règle que les droits Premium, pour éviter toute manipulation.
- Remboursement : non remboursable une fois utilisé ; remboursable via le support uniquement en cas de bug technique démontré (ex. jeton consommé sans effet).

## 2. Calcul précis de la compatibilité

Rappel de la pondération déjà actée (cahier des charges, section 4.3) :

- Vision du couple : 30 %
- Valeurs et culture : 25 %
- Famille : 20 %
- Mode de vie : 15 %
- Communication : 10 %

Règles précises de calcul :

1. Chaque thème contient plusieurs questions à choix multiples ou à échelle (ex. de 1 à 5). Pour chaque question commune aux deux profils, on calcule une **similarité de réponse** (identique = score maximal, proche = score partiel, opposé = score minimal).
2. Le **score du thème** = moyenne des similarités de toutes les questions de ce thème **répondues par les deux membres**. Une question facultative non répondue par l'un des deux est simplement exclue du calcul de ce thème — elle n'est jamais comptée comme une mauvaise réponse (contrairement au questionnaire de filtrage à l'inscription, qui lui est obligatoire).
3. **Seuil de validité d'un thème** : si moins de 60 % des questions d'un thème ont été répondues par les deux membres, ce thème est exclu du calcul global et son poids est redistribué proportionnellement sur les autres thèmes — pour ne pas afficher un score basé sur trop peu d'informations.
4. **Score global de compatibilité** = somme des scores de thème multipliés par leur poids (redistribué si besoin).
5. **Affichage** : arrondi à l'entier le plus proche (ex. "92 % compatible"), jamais de fausse précision à la décimale.
6. **Recalcul** : dès qu'un membre modifie une réponse, son score de compatibilité est recalculé pour tous les profils déjà croisés, pas seulement pour les futurs — pour que l'information reste toujours à jour.

Règles anti-triche (cohérentes avec [architecture-technique.md](architecture-technique.md)) :

- Le calcul tourne **uniquement côté serveur**, jamais dans l'application.
- Les **réponses détaillées d'un membre ne sont jamais visibles par un autre membre** — seul le score final de compatibilité est affiché. Ça évite qu'on "triche" en copiant les réponses de la personne qu'on veut matcher après avoir vu son profil.
- Un membre peut voir et modifier **ses propres réponses** à tout moment, mais pas celles des autres.

## 3. Signalement et blocage — règles de suite

En complément des règles déjà posées ([regles-messagerie-securite.md](regles-messagerie-securite.md), section 3) :

- **Priorité selon la gravité** : un signalement classé "danger / sécurité physique" (ex. menace, comportement dangereux avant un événement) est traité en priorité absolue, délai cible **moins de 4h**. Les autres signalements suivent le délai standard de 48h.
- **Confidentialité pendant l'instruction** : le compte signalé n'est jamais informé qu'il fait l'objet d'un signalement tant que l'enquête est en cours — pour éviter qu'il efface des preuves ou se venge sur la personne qui a signalé.
- **Protection du plaignant** : son identité n'est jamais communiquée au compte signalé, à aucune étape.
- **Retour au plaignant** : une fois le signalement traité, il reçoit une notification générique du résultat ("Nous avons traité ton signalement et pris les mesures appropriées"), sans détail disciplinaire précis sur l'autre compte — pour rester proportionné et respecter la vie privée de la personne signalée.
- **Droit de recours** : la personne sanctionnée peut contester via un formulaire dédié ; dans la mesure du possible, la révision est faite par un modérateur différent de celui qui a pris la décision initiale, pour limiter les biais.
- **Conservation des preuves** : messages et photos signalés sont conservés même après suppression du compte concerné, pendant une durée définie (à fixer avec un conseil juridique, à titre indicatif 1 an), en cas de besoin légal.
- **Signalements abusifs répétés** : un membre qui signale de façon répétée et manifestement non fondée est lui-même examiné — le système de signalement ne doit pas devenir un outil de harcèlement détourné.

---

Ce document doit être relu avant le développement du système de jetons, du calcul de compatibilité et du module de signalement.
