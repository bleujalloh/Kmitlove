# Banque de questions — Questionnaire de filtrage

Contenu initial à charger dans la collection Firestore `filtrage_question_bank` (jamais accessible au client directement, voir firestore.rules). Chaque document : `{ theme, question, options: [string, string, string, string], correctIndex, active: true }`.

Basé sur le repère culturel posé dans [architecture-technique.md](architecture-technique.md) (Cheikh Anta Diop, Molefi Kete Asante, mouvement kémite/afrocentriste). **15 questions minimum requises pour qu'une tentative puisse être tirée** (FILTRAGE_QUESTIONS_PER_ATTEMPT dans functions/src/config.ts) — en prévoir davantage pour que le tirage aléatoire ait du sens (30-40 recommandé avant le lancement réel).

| # | Thème | Question | Options | Bonne réponse |
|---|---|---|---|---|
| 1 | Histoire et civilisation | Quelle figure a défendu la thèse de l'origine africaine de la civilisation égyptienne antique ? | Hérodote / **Cheikh Anta Diop** / Jean Champollion / Je ne sais pas | 1 |
| 2 | Histoire et civilisation | "Kemet" est le nom ancien de quel territoire ? | Le Ghana actuel / **L'Égypte ancienne** / Le Mali actuel / L'Éthiopie actuelle | 1 |
| 3 | Histoire et civilisation | Quel universitaire américain est à l'origine du courant afrocentriste moderne (Temple University, années 1980) ? | W.E.B. Du Bois / **Molefi Kete Asante** / Frantz Fanon / Kwame Nkrumah | 1 |
| 4 | Histoire et civilisation | Thomas Sankara était président de quel pays ? | Le Sénégal / Le Ghana / **Le Burkina Faso** / La Guinée | 2 |
| 5 | Histoire et civilisation | Kwame Nkrumah est une figure majeure de quel mouvement ? | Le mouvement kémite uniquement / **Le panafricanisme et l'indépendance du Ghana** / La Renaissance italienne / Le mouvement surréaliste | 1 |
| 6 | Valeurs et culture | Dans la vision portée par le mouvement kémite, redevenir "sujet de sa propre histoire" signifie surtout... | Oublier le passé / **Raconter et comprendre sa propre histoire au lieu de la recevoir d'un point de vue extérieur** / Rejeter toute autre culture / Ne concerne que la religion | 1 |
| 7 | Valeurs et culture | Quelle est l'idée centrale du panafricanisme ? | La domination d'un pays africain sur les autres / **L'unité et la solidarité entre les peuples africains et leur diaspora** / Le refus de toute relation avec l'Europe / Un courant uniquement religieux | 1 |
| 8 | Valeurs et culture | Que signifie généralement transmettre "l'histoire précoloniale" à ses enfants ? | Leur apprendre uniquement la période coloniale / **Leur faire connaître les civilisations et royaumes africains avant la colonisation** / Leur apprendre une langue étrangère / Aucun rapport avec l'éducation | 1 |
| 9 | Valeurs et culture | Lequel de ces royaumes a existé en Afrique de l'Ouest avant la colonisation ? | L'Empire romain / **L'Empire du Mali** / L'Empire ottoman / Le royaume de Prusse | 1 |
| 10 | Valeurs et culture | Qu'est-ce qu'un "Adinkra" (symbole couramment associé à la culture akan, Ghana) ? | Un plat traditionnel / **Un symbole porteur d'une signification ou d'une valeur** / Une danse uniquement / Un instrument de musique uniquement | 1 |
| 11 | Famille et société | Dans de nombreuses traditions africaines, quel rôle joue généralement le conseil des anciens ? | Aucun rôle social / **Transmettre l'expérience et aider à régler les décisions importantes de la communauté** / Un rôle uniquement religieux dans toutes les cultures / Remplacer les parents | 1 |
| 12 | Famille et société | Que signifie l'expression "philosophie Ubuntu" (Afrique du Sud/australe) ? | L'individualisme avant tout / **"Je suis parce que nous sommes" — l'interdépendance entre les personnes** / Un système politique précis / Une religion monothéiste | 1 |
| 13 | Communication et personnalité | Dans un couple qui partage les valeurs de la charte Kamalove, la gestion des désaccords repose avant tout sur... | L'évitement total du conflit / **Le dialogue, le respect mutuel et l'écoute** / Le silence jusqu'à ce que ça passe / Laisser un tiers décider systématiquement | 1 |
| 14 | Valeurs et culture | Quel est le nom donné au commerce triangulaire ayant déporté des millions d'Africains vers les Amériques ? | La route de la soie / **La traite négrière transatlantique** / La conquête de l'Ouest / La révolution industrielle | 1 |
| 15 | Histoire et civilisation | Quelle est la capitale de l'Éthiopie, pays jamais colonisé durablement et symbole fort pour le mouvement panafricaniste ? | Nairobi / Accra / **Addis-Abeba** / Dakar | 2 |
| 16 | Valeurs et culture | Le mot "Sankofa" (symbole adinkra bien connu) signifie approximativement... | "Avancer sans se retourner" / **"Revenir chercher ce qui a été oublié / apprendre du passé"** / "La richesse avant tout" / Un salut de bienvenue | 1 |
| 17 | Histoire et civilisation | Quel événement a eu lieu à Bandung en 1955 et a marqué la solidarité des pays colonisés ou récemment indépendants ? | Un sommet économique européen / **La conférence afro-asiatique de Bandung** / Les premiers Jeux Olympiques africains / La création de l'ONU | 1 |

---

À ajouter dans Firestore via la console (manuellement au lancement, puis via l'espace admin une fois construit — section 6 du cahier des charges). Ne jamais republier ce tableau dans le code de l'application ou dans un fichier accessible au client, conformément aux règles anti-contournement (regles-du-projet.md section 9).
