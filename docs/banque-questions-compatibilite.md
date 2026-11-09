# Banque de questions — Test de compatibilité kamite

Contenu initial pour la collection Firestore `compat_question_bank` (lisible par tous les membres connectés, jamais modifiable depuis le client). Chaque document : `{ theme, question, active: true }`.

Adaptation retenue par rapport au cahier des charges section 4.3 : les questions ouvertes ("Quelle est ta conception d'une relation amoureuse ?") sont reformulées en **affirmations notées sur une échelle de 1 (pas du tout d'accord) à 5 (tout à fait d'accord)**, pour pouvoir calculer une similarité entre deux profils (docs/regles-economie-et-compatibilite.md section 2). C'est un choix de mise en forme, pas un changement du fond des thèmes ni de leur pondération.

Pondération rappelée : Vision du couple 30 % · Valeurs et culture 25 % · Famille 20 % · Mode de vie 15 % · Communication 10 %.

| Thème | Question (affirmation, 1-5) |
|---|---|
| vision_couple | La fidélité est une condition non négociable dans un couple. |
| vision_couple | Je préfère régler un désaccord par la discussion plutôt que de laisser du temps passer. |
| vision_couple | Le respect mutuel compte plus pour moi que la passion au quotidien. |
| vision_couple | Je m'engage pleinement dès que je sais qu'une relation est sérieuse. |
| valeurs_culture | Les références culturelles kamites occupent une place importante dans ma vie quotidienne. |
| valeurs_culture | Je veux transmettre l'histoire et la culture africaine à mes enfants. |
| valeurs_culture | Connaître l'histoire précoloniale africaine est important pour moi. |
| valeurs_culture | Je participe régulièrement à des pratiques ou traditions culturelles. |
| famille | Je souhaite avoir des enfants. | 
| famille | La famille doit occuper une place centrale dans la vie du couple. |
| famille | Je veux une éducation des enfants fortement ancrée dans nos valeurs culturelles. |
| mode_vie | Je préfère vivre en ville plutôt qu'à la campagne. |
| mode_vie | La stabilité financière est une priorité avant de s'engager durablement. |
| mode_vie | Les responsabilités du couple doivent être partagées à parts égales. |
| communication | Je suis plutôt extraverti(e) que réservé(e). |
| communication | J'exprime facilement mon affection à l'autre. |
| communication | Face à un désaccord, je cherche à comprendre l'autre avant de défendre mon point de vue. |

---

À charger dans Firestore (console, puis espace admin une fois construit). Prévoir au moins 3-4 questions par thème pour un calcul fiable ; cette liste peut être enrichie librement sans casser le calcul (docs/architecture-technique.md), qui s'adapte au nombre de questions répondues.
