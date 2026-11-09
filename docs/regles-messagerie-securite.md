# Règles détaillées — Messagerie, photos et sécurité

Ce document complète [regles-du-projet.md](regles-du-projet.md) et [regles-annonces-evenements.md](regles-annonces-evenements.md) pour deux zones restantes : les photos de profil et la messagerie privée.

## 1. Photos de profil — validation humaine avec délai maximal garanti

Décision : pas de détection automatique par IA au lancement (pas d'outil de ce type en place actuellement), **et** pas de validation humaine purement systématique non plus, parce que l'administrateur ne sera pas disponible en permanence. Solution retenue : **un délai maximal garanti, avec approbation automatique si personne n'a traité la photo à temps.**

Processus :

1. Le membre met en ligne une photo → elle est stockée mais marquée **"en attente de validation"**.
2. Le membre voit sa propre photo en attente sur son profil, avec la mention claire "en cours de vérification".
3. Les autres membres ne voient jamais une photo en attente — ni sur le swipe, ni sur les likes, ni dans la communauté.
4. Un modérateur peut valider ou refuser la photo depuis l'espace admin à tout moment.
5. **Si personne ne l'a traitée sous 48h**, la photo devient **automatiquement visible** — pour qu'un nouveau membre ne reste jamais bloqué indéfiniment faute de modérateur disponible.
6. Une photo auto-approuvée par expiration du délai reste **signalable comme toute autre photo** après coup ; un signalement confirmé entraîne son retrait immédiat, que la validation ait été humaine ou automatique par délai.
7. Si refusée explicitement par un modérateur : notification au membre avec le motif (ex. "photo de groupe", "visage non visible", "contenu inapproprié"), possibilité de soumettre une nouvelle photo.
8. Un membre sans aucune photo (en attente, validée ou auto-approuvée) n'apparaît pas dans "Découvrir".

**Limite assumée** : ce système accepte qu'une photo problématique reste visible jusqu'à 48h avant d'être retirée si elle est signalée, en échange de ne jamais bloquer un membre faute de disponibilité humaine. À réévaluer (filtre automatique type Google Cloud Vision, ou recrutement de plusieurs modérateurs) si ce compromis devient insuffisant avec la croissance du nombre d'inscriptions.

## 2. Messagerie privée

### Qui peut écrire à qui

- Un membre ne peut écrire à un autre **qu'après un match** (like mutuel confirmé côté serveur). Pas d'exception en V1.
- Dès qu'un membre bloque l'autre, la conversation devient inaccessible aux deux, immédiatement et sans préavis.

### Indicateur de lecture

- **Activé par défaut**, visible par les deux membres d'une conversation (l'un sait que l'autre a lu son message).
- Désactivable individuellement dans les paramètres de confidentialité ; si un membre le désactive, il ne voit plus non plus l'indicateur de lecture des autres (réciprocité : on ne peut pas voir si on refuse d'être vu).

### Photos partagées en conversation

Contrairement aux photos de profil, les photos échangées en message privé sont one-to-one et ne peuvent pas attendre une validation humaine avant envoi (ça casserait complètement l'usage d'une conversation). Règle adoptée :

- La photo part immédiatement au destinataire (pas de délai).
- Un **avertissement visible** s'affiche avant le premier envoi de photo dans une conversation, rappelant la charte de bonne conduite.
- Le destinataire peut **signaler une photo reçue** en un geste ; un signalement confirmé entraîne la suppression immédiate de la photo pour les deux et une sanction pour l'expéditeur (voir l'escalade ci-dessous).
- Aucune photo de message n'est jamais visible par un tiers, seulement par les deux membres de la conversation et, en cas de signalement, par un modérateur qui traite ce signalement précis.

### Suppression et conservation

- Un membre peut supprimer une conversation de son côté ; elle reste visible pour l'autre jusqu'à ce qu'il la supprime aussi.
- Une conversation signalée est conservée (non supprimable par les parties) jusqu'à la résolution du signalement, pour que le modérateur puisse l'examiner.
- Au-delà de la résolution d'un signalement, conservation des messages alignée sur les durées légales minimales (pas de conservation indéfinie "au cas où").

## 3. Signalement et blocage — flux commun

- **Blocage** : effet immédiat, pas de confirmation nécessaire de l'autre côté, réversible par celui qui bloque.
- **Signalement** : motif obligatoire parmi une liste (faux profil, comportement abusif, contenu inapproprié, arnaque, autre) + champ libre optionnel.
- Un signalement confirmé par un modérateur suit la même escalade que les annonces/événements : avertissement → suspension temporaire → suspension définitive avec droit de recours (cohérent avec [regles-annonces-evenements.md](regles-annonces-evenements.md), section 6).
- Un compte visé par 3 signalements distincts et confirmés, tous domaines confondus (photo, message, annonce, événement), passe automatiquement en revue prioritaire par un modérateur, même si chaque signalement pris isolément n'aurait pas suffi.

---

Ce document doit être relu avant le développement de la messagerie et de l'upload de photos, et mis à jour si un outil de modération automatique est ajouté plus tard.
