# MERUT — Règlement permanent de développement, d'architecture, de qualité et de conformité

> Directive permanente, obligatoire pour l'ensemble du projet, posée par le propriétaire du
> projet le 2026-11-11. Ce règlement ne remplace aucune règle existante (`docs/regles-*.md`,
> `docs/cahier-des-charges.md`, `docs/architecture-technique.md`, etc.) : il les complète, les
> renforce et impose leur application cohérente à l'ensemble de l'application. Il s'applique
> rétroactivement à tout le code déjà développé, à toutes les fonctionnalités existantes, à tous
> les documents techniques, et à tous les développements futurs. Ce n'est pas une recommandation :
> c'est le référentiel permanent de qualité et d'exécution du projet, pour toute personne ou
> agent (y compris tout agent autonome) qui travaille sur ce dépôt.

---

## 1. Principe fondamental : exécution intégrale

Aucune fonctionnalité ne doit être abandonnée, oubliée, reportée volontairement ou déclarée
terminée prématurément. Chaque exigence définie dans les cahiers des charges, les documents de
référence, les décisions prises et les demandes de développement doit être effectivement
respectée.

Obligations :
- Développer intégralement toutes les fonctionnalités prévues.
- Terminer systématiquement les fonctionnalités commencées.
- Corriger les fonctionnalités mal développées.
- Implanter tous les composants techniques nécessaires.
- Corriger les bugs et les incohérences découverts.
- Assurer la cohérence entre toutes les parties de l'application.
- Vérifier que chaque fonctionnalité fonctionne réellement dans son environnement final.

**Interdiction** de remplacer une implantation réelle par une simple interface visuelle, une
maquette, un bouton sans action ou une simulation. Le travail demandé doit être réalisé, pas
simplement décrit.

## 2. Respect absolu des spécifications existantes

Les documents de référence constituent la base de développement de MERUT. Avant toute
intervention, consulter les spécifications, les décisions précédentes, les règles métier, les
demandes et les documents techniques concernés. Aucune fonctionnalité ne doit être développée en
contradiction avec une décision déjà prise.

Il est interdit de :
- Supprimer silencieusement une exigence.
- Simplifier arbitrairement une fonctionnalité.
- Modifier une règle métier sans justification et validation.
- Remplacer une fonctionnalité demandée par une alternative moins complète.
- Inventer des règles métier non validées.
- Oublier des cas particuliers ou des parcours secondaires.

Toute contradiction entre documents doit être identifiée et résolue en respectant les décisions
les plus récentes et les instructions explicites du propriétaire du projet.

## 3. Architecture et organisation globale

L'application doit conserver une architecture claire, cohérente, modulaire et maintenable. Chaque
module doit avoir une responsabilité définie. Les modules doivent communiquer correctement sans
créer de dépendances anarchiques.

Exigences :
- Séparation claire des responsabilités.
- Réutilisation des composants communs.
- Gestion centralisée des configurations lorsque cela est pertinent.
- Absence de duplication inutile.
- Gestion cohérente des erreurs.
- Gestion correcte des états de chargement, de succès et d'échec.
- Interfaces frontend reliées à leurs véritables services.
- Services backend documentés et cohérents.
- Modèles de données compatibles avec les fonctionnalités qui les utilisent.

Toute modification architecturale doit préserver les fonctionnalités existantes et leur
compatibilité. Aucune correction ne doit créer une nouvelle incohérence ailleurs.

## 4. Règles métier et parcours utilisateur

Toutes les règles métier doivent être appliquées de manière uniforme dans l'application. Une même
règle ne doit jamais produire des résultats différents selon l'écran, le module ou le parcours
utilisé. Chaque parcours doit être vérifié de bout en bout, notamment : inscription et
authentification, création et gestion des profils, découverte des membres, préférences et
filtres, likes et interactions, matchs, messagerie, blocage et signalement, vérification des
comptes, communauté, publications, événements et annonces, abonnements et accès aux
fonctionnalités, notifications, paramètres et gestion du compte.

Chaque fonctionnalité doit respecter ses propres règles, ses permissions et ses dépendances. Aucun
parcours ne doit être considéré comme fonctionnel si une étape indispensable manque.

## 5. Base de données, backend et intégrité

Toute donnée doit être correctement structurée, validée, sécurisée et cohérente.

Exigences obligatoires : vérification des modèles de données, vérification des relations entre
les données, validation des entrées, gestion des erreurs backend, protection contre les accès non
autorisés, vérification des permissions côté serveur, prévention des accès croisés entre
utilisateurs, gestion des suppressions et mises à jour, cohérence entre données enregistrées et
données affichées, prévention des doublons et des opérations répétées involontairement, gestion
des opérations concurrentes, traçabilité des opérations sensibles.

Aucune sécurité ne doit dépendre uniquement des contrôles de l'interface mobile. Les règles de
sécurité doivent être effectives côté backend. Ne jamais désactiver une protection pour faire
fonctionner artificiellement une fonctionnalité.

## 6. Sécurité et protection des utilisateurs

MERUT étant une application de rencontre, la sécurité des utilisateurs est une priorité
structurelle. Toutes les fonctionnalités doivent être examinées sous l'angle de la confidentialité
et de la protection des personnes : confidentialité des profils, permissions d'accès aux
informations, protection des conversations, blocage effectif des utilisateurs, signalements et
modération, protection contre les faux comptes, protection contre les abus et les comportements
malveillants, contrôle des publications, sécurisation des données personnelles, contrôle des
abonnements et des droits d'accès.

Une fonctionnalité de sécurité n'est pas terminée simplement parce qu'un bouton existe. Elle doit
réellement produire l'effet attendu et être vérifiée.

## 7. Identité visuelle et cohérence graphique

L'identité visuelle définie pour MERUT doit être respectée dans l'intégralité de l'application.

Palette de référence :
- Noir profond : `#11110F`
- Ivoire : `#F6F0E5`
- Or antique : `#D7B66E`
- Or doux : `#E0BD76`
- Brun profond : `#29251D`
- Brun terre : `#49351E`

Typographie : Georgia Serif pour l'identité de marque et certains titres ; Inter ou sans-serif
système pour l'interface.

Direction artistique : afro-contemporaine, inspirée de l'héritage kamite, premium et élégante,
moderne et fonctionnelle, géométrie et symboles subtils, contrastes maîtrisés.

**Interdiction** de réintroduire arbitrairement des palettes rose pastel, orange corail ou des
composants génériques incompatibles avec cette identité. Tous les écrans doivent respecter le même
système de design, y compris les composants secondaires, les fenêtres, les menus, les formulaires,
les notifications, les états vides et les écrans d'erreur. Une interface ne doit jamais être
considérée comme terminée si elle est visuellement incohérente avec le reste de MERUT.

## 8. Qualité du code et maintenabilité

Tout code ajouté ou modifié doit respecter les conventions techniques du projet : code propre et
compréhensible, fonctions correctement structurées, nommage cohérent, gestion des exceptions,
absence de code mort inutile, absence de duplication injustifiée, absence de contournements
temporaires non résolus, suppression des anciennes implémentations devenues inutiles après
vérification de leur absence d'utilisation, documentation des mécanismes complexes, compatibilité
avec l'architecture existante.

Ne jamais introduire une solution rapide qui compromet la stabilité future.

## 9. Tests obligatoires et non-régression

Chaque fonctionnalité doit faire l'objet de vérifications adaptées à sa nature : fonctionnement
normal, cas limites, données incorrectes, permissions insuffisantes, absence de données, erreurs
réseau, erreurs serveur, échecs d'enregistrement, interactions entre modules, compatibilité avec
les autres fonctionnalités.

Exécuter les tests automatisés disponibles, les analyses statiques, les tests d'intégration et les
compilations nécessaires. Après chaque correction, vérifier qu'aucune fonctionnalité existante n'a
été cassée. Une compilation réussie ne signifie pas que l'application est terminée.

## 10. Auto-audit permanent et obligatoire

L'auto-vérification ne doit pas être une opération exceptionnelle : elle fait partie intégrante de
chaque intervention de développement.

Avant de commencer : identifier les exigences concernées, examiner le code existant, vérifier les
dépendances, comprendre les conséquences sur les autres modules.

Pendant le développement : vérifier les implantations, contrôler la cohérence, détecter les
oublis, corriger les erreurs découvertes, contrôler les interactions avec les autres modules.

Après le développement : comparer les exigences avec le résultat réel, vérifier chaque point,
exécuter les tests, corriger les problèmes, vérifier les éventuelles régressions.

Cette obligation concerne également le code historique, et pas seulement les nouveaux
développements.

## 11. Gestion des bugs et des anomalies

Tout bug identifié doit être pris en charge. Il est interdit de se contenter de le signaler dans
un rapport lorsqu'il peut être corrigé dans le cadre du travail en cours.

Pour chaque problème : identifier précisément le problème, rechercher sa cause réelle, identifier
les éléments affectés, corriger la cause et pas uniquement le symptôme, tester la correction,
vérifier l'absence de régression.

Les bugs découverts pendant une intervention doivent être traités dans cette même intervention,
dans la mesure où ils sont techniquement accessibles. Aucun problème ne doit disparaître d'un
rapport simplement parce qu'il est difficile à résoudre.

## 12. Interdiction des fausses déclarations de fin

Règle particulièrement importante. Il est strictement interdit de déclarer une fonctionnalité, un
module, un document ou une étape comme terminé lorsque le travail correspondant n'a pas été
intégralement effectué. Les statuts doivent correspondre à la réalité du code.

Distinction obligatoire des statuts : non commencé / en cours / implanté mais non testé / testé
avec échec / testé et validé / bloqué par une dépendance externe réelle.

Ne jamais utiliser le statut "terminé" pour une fonctionnalité partielle. Ne jamais présenter un
test non exécuté comme réussi. Ne jamais inventer des résultats de validation.

## 13. Règle absolue : aucun report volontaire

Aucun travail ne doit être volontairement laissé pour plus tard. Aucune fonctionnalité prévue ne
doit être retirée du périmètre pour simplifier le développement. Aucune correction identifiée ne
doit être abandonnée. Aucune dette technique créée volontairement ne doit être dissimulée.

Lorsqu'un problème nécessite une intervention extérieure réellement indispensable, effectuer
toutes les opérations possibles sans attendre, documenter précisément la dépendance et ne pas
prétendre que le résultat est complet. Cette exception ne doit jamais servir de prétexte pour
éviter un travail réalisable.

## 14. Traçabilité et preuves

Chaque exigence doit pouvoir être reliée à son implantation réelle. Conserver une traçabilité
comprenant : exigence d'origine, module concerné, fichiers et composants concernés, implantation
réalisée, tests exécutés, résultats obtenus, état réel de validation.

Les affirmations techniques importantes doivent être accompagnées de preuves vérifiables dans le
code ou les résultats des tests. Les documents de suivi (`docs/suivi-developpement.md` et
équivalents) doivent refléter l'état réel du projet et être mis à jour après les modifications.

## 15. Application rétroactive à tout le projet

Impératif : ce règlement ne commence pas uniquement à la prochaine fonctionnalité, il s'applique à
tout ce qui a déjà été produit. Reprendre l'ensemble du projet MERUT et contrôler : les anciens
développements, les fonctionnalités déjà déclarées terminées, les fonctionnalités partiellement
implantées, les interfaces existantes, les services backend, les intégrations, les règles métier,
les mécanismes de sécurité, les documents de suivi, les tests existants.

Tout élément non conforme doit être corrigé. Tout élément absent mais prévu doit être implanté.
Tout élément mal implanté doit être repris. Tout élément incohérent doit être aligné. Il ne suffit
pas de promettre le respect de ces règles pour les prochains développements : le travail antérieur
doit lui aussi être remis en conformité.

## 16. Ordre d'exécution et critère final de réussite

Ordre de travail obligatoire :

1. **Audit global** — examiner les documents, les spécifications, les décisions et l'intégralité
   du code existant.
2. **Comparaison** — comparer chaque exigence à son implantation réelle et identifier tous les
   écarts.
3. **Correction et implantation** — développer les fonctionnalités manquantes, terminer les
   fonctionnalités partielles, corriger les bugs et résoudre les incohérences.
4. **Harmonisation** — vérifier l'alignement global entre les modules, les données, le backend,
   les interfaces, les permissions et les règles métier.
5. **Validation** — effectuer les tests nécessaires, corriger les échecs et contrôler les
   régressions.
6. **Contrôle final** — reprendre la liste complète des exigences et vérifier que chacune
   correspond à une réalisation effective.

Ne pas arrêter le travail après la phase d'audit ou après avoir produit un rapport. L'audit est un
outil pour terminer le développement, pas un livrable qui remplace le développement.

**Critère final** : MERUT ne peut être déclaré intégralement terminé que lorsque toutes les
exigences du périmètre défini sont implantées, cohérentes et validées. Aucune fausse déclaration
de réussite n'est acceptable. Aucune fonctionnalité ne doit être oubliée. Aucun travail réalisable
ne doit être abandonné ou reporté volontairement.

## 17. Autonomie accordée : la règle la plus stricte gagne

Ajout du propriétaire du projet, 2026-11-12 : le travail doit se faire de bout en bout, et ses
recommandations d'implémentation sont acceptées par avance. Concrètement :

- Ne pas interrompre le travail pour demander l'approbation d'un choix d'implémentation (quelle
  bibliothèque, quel compromis de couverture de données, quel motif d'interface) — décider et
  avancer, en expliquant le choix dans le rapport plutôt qu'en le soumettant avant d'agir.
- Lorsque deux règles ou considérations de ce document pourraient pointer vers des directions
  différentes (rapidité contre rigueur, confort contre sécurité, permissif contre restrictif),
  **l'option la plus stricte, la plus sûre et la plus protectrice des données et de la sécurité des
  membres l'emporte toujours** — jamais l'option la plus rapide ou la plus confortable en cas de
  conflit réel.
- Ceci n'affaiblit aucune règle déjà posée dans ce document (exécution intégrale, interdiction des
  fausses déclarations de fin, sécurité côté serveur, etc.) — ça retire seulement l'obligation de
  faire valider chaque arbitrage d'implémentation avant d'agir dessus.

---

*Ces règles sont permanentes, obligatoires et applicables à l'ensemble du code existant et futur
de MERUT.*
