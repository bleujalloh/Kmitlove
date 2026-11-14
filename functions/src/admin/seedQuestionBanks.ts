import { onCall } from "firebase-functions/v2/https";
import { getFirestore } from "firebase-admin/firestore";

import { REGION } from "../config";
import { ENFORCE_APP_CHECK } from "../shared/appCheck";
import { requireAdmin } from "../shared/requireAdmin";
import { logAdminAction } from "../shared/adminLog";

// Contenu repris tel quel de docs/banque-questions-filtrage.md — jamais
// exposé au client (firestore.rules : filtrage_question_bank totalement
// verrouillée), seule cette fonction côté serveur en a connaissance.
const FILTRAGE_QUESTIONS: {
  theme: string;
  question: string;
  options: string[];
  correctIndex: number;
}[] = [
  { theme: "Histoire et civilisation", question: "Quelle figure a défendu la thèse de l'origine africaine de la civilisation égyptienne antique ?", options: ["Hérodote", "Cheikh Anta Diop", "Jean Champollion", "Je ne sais pas"], correctIndex: 1 },
  { theme: "Histoire et civilisation", question: "\"Kemet\" est le nom ancien de quel territoire ?", options: ["Le Ghana actuel", "L'Égypte ancienne", "Le Mali actuel", "L'Éthiopie actuelle"], correctIndex: 1 },
  { theme: "Histoire et civilisation", question: "Quel universitaire américain est à l'origine du courant afrocentriste moderne (Temple University, années 1980) ?", options: ["W.E.B. Du Bois", "Molefi Kete Asante", "Frantz Fanon", "Kwame Nkrumah"], correctIndex: 1 },
  { theme: "Histoire et civilisation", question: "Thomas Sankara était président de quel pays ?", options: ["Le Sénégal", "Le Ghana", "Le Burkina Faso", "La Guinée"], correctIndex: 2 },
  { theme: "Histoire et civilisation", question: "Kwame Nkrumah est une figure majeure de quel mouvement ?", options: ["Le mouvement kémite uniquement", "Le panafricanisme et l'indépendance du Ghana", "La Renaissance italienne", "Le mouvement surréaliste"], correctIndex: 1 },
  { theme: "Valeurs et culture", question: "Dans la vision portée par le mouvement kémite, redevenir \"sujet de sa propre histoire\" signifie surtout...", options: ["Oublier le passé", "Raconter et comprendre sa propre histoire au lieu de la recevoir d'un point de vue extérieur", "Rejeter toute autre culture", "Ne concerne que la religion"], correctIndex: 1 },
  { theme: "Valeurs et culture", question: "Quelle est l'idée centrale du panafricanisme ?", options: ["La domination d'un pays africain sur les autres", "L'unité et la solidarité entre les peuples africains et leur diaspora", "Le refus de toute relation avec l'Europe", "Un courant uniquement religieux"], correctIndex: 1 },
  { theme: "Valeurs et culture", question: "Que signifie généralement transmettre \"l'histoire précoloniale\" à ses enfants ?", options: ["Leur apprendre uniquement la période coloniale", "Leur faire connaître les civilisations et royaumes africains avant la colonisation", "Leur apprendre une langue étrangère", "Aucun rapport avec l'éducation"], correctIndex: 1 },
  { theme: "Valeurs et culture", question: "Lequel de ces royaumes a existé en Afrique de l'Ouest avant la colonisation ?", options: ["L'Empire romain", "L'Empire du Mali", "L'Empire ottoman", "Le royaume de Prusse"], correctIndex: 1 },
  { theme: "Valeurs et culture", question: "Qu'est-ce qu'un \"Adinkra\" (symbole couramment associé à la culture akan, Ghana) ?", options: ["Un plat traditionnel", "Un symbole porteur d'une signification ou d'une valeur", "Une danse uniquement", "Un instrument de musique uniquement"], correctIndex: 1 },
  { theme: "Famille et société", question: "Dans de nombreuses traditions africaines, quel rôle joue généralement le conseil des anciens ?", options: ["Aucun rôle social", "Transmettre l'expérience et aider à régler les décisions importantes de la communauté", "Un rôle uniquement religieux dans toutes les cultures", "Remplacer les parents"], correctIndex: 1 },
  { theme: "Famille et société", question: "Que signifie l'expression \"philosophie Ubuntu\" (Afrique du Sud/australe) ?", options: ["L'individualisme avant tout", "\"Je suis parce que nous sommes\" — l'interdépendance entre les personnes", "Un système politique précis", "Une religion monothéiste"], correctIndex: 1 },
  { theme: "Communication et personnalité", question: "Dans un couple qui partage les valeurs de la charte Kamalove, la gestion des désaccords repose avant tout sur...", options: ["L'évitement total du conflit", "Le dialogue, le respect mutuel et l'écoute", "Le silence jusqu'à ce que ça passe", "Laisser un tiers décider systématiquement"], correctIndex: 1 },
  { theme: "Valeurs et culture", question: "Quel est le nom donné au commerce triangulaire ayant déporté des millions d'Africains vers les Amériques ?", options: ["La route de la soie", "La traite négrière transatlantique", "La conquête de l'Ouest", "La révolution industrielle"], correctIndex: 1 },
  { theme: "Histoire et civilisation", question: "Quelle est la capitale de l'Éthiopie, pays jamais colonisé durablement et symbole fort pour le mouvement panafricaniste ?", options: ["Nairobi", "Accra", "Addis-Abeba", "Dakar"], correctIndex: 2 },
  { theme: "Valeurs et culture", question: "Le mot \"Sankofa\" (symbole adinkra bien connu) signifie approximativement...", options: ["\"Avancer sans se retourner\"", "\"Revenir chercher ce qui a été oublié / apprendre du passé\"", "\"La richesse avant tout\"", "Un salut de bienvenue"], correctIndex: 1 },
  { theme: "Histoire et civilisation", question: "Quel événement a eu lieu à Bandung en 1955 et a marqué la solidarité des pays colonisés ou récemment indépendants ?", options: ["Un sommet économique européen", "La conférence afro-asiatique de Bandung", "Les premiers Jeux Olympiques africains", "La création de l'ONU"], correctIndex: 1 },
  { theme: "Histoire et civilisation", question: "Marcus Garvey, figure jamaïcaine du début du XXe siècle, est surtout connu pour...", options: ["Avoir fondé l'UNIA et popularisé l'idée d'un retour vers l'Afrique", "Avoir été roi du Dahomey", "Avoir négocié l'indépendance du Kenya", "Un traité de paix européen"], correctIndex: 0 },
  { theme: "Histoire et civilisation", question: "W.E.B. Du Bois, intellectuel afro-américain, a notamment cofondé quelle organisation ?", options: ["L'Union africaine", "La NAACP", "L'OUA", "L'Unesco"], correctIndex: 1 },
  { theme: "Histoire et civilisation", question: "Quel pays a été la première République noire indépendante au monde, en 1804 ?", options: ["Le Liberia", "Haïti", "Le Ghana", "L'Éthiopie"], correctIndex: 1 },
  { theme: "Histoire et civilisation", question: "Toussaint Louverture est une figure majeure de...", options: ["La révolution haïtienne", "La conférence de Berlin", "L'indépendance du Sénégal", "La guerre des Boers"], correctIndex: 0 },
  { theme: "Histoire et civilisation", question: "L'ancien empire du Ghana (à ne pas confondre avec le Ghana moderne) était surtout prospère grâce au commerce de...", options: ["Le pétrole", "L'or et le sel", "Le café", "Le coton uniquement"], correctIndex: 1 },
  { theme: "Histoire et civilisation", question: "L'empire Songhaï et la ville de Tombouctou étaient notamment réputés pour...", options: ["Leurs mines de diamants", "Leur savoir, leurs manuscrits et leurs universités", "Leur flotte militaire", "Leur industrie textile moderne"], correctIndex: 1 },
  { theme: "Histoire et civilisation", question: "Mansa Moussa, empereur de l'empire du Mali au XIVe siècle, est resté célèbre pour...", options: ["Sa défaite militaire face à l'Empire romain", "Son immense richesse et son pèlerinage à La Mecque", "La fondation de Tombouctou", "Un traité avec le Portugal"], correctIndex: 1 },
  { theme: "Histoire et civilisation", question: "La reine Nzinga, souveraine du Ndongo et du Matamba (Angola actuel), est connue pour...", options: ["Avoir résisté pendant des décennies à la colonisation portugaise", "Avoir fondé l'Empire du Mali", "Un rôle uniquement légendaire sans fondement historique", "Avoir signé la paix immédiatement avec les colons"], correctIndex: 0 },
  { theme: "Histoire et civilisation", question: "Shaka Zulu est principalement connu pour avoir...", options: ["Fondé et structuré le royaume zoulou en Afrique australe", "Été le premier président d'Afrique du Sud", "Négocié l'indépendance du Zimbabwe", "Écrit la Charte africaine des droits de l'homme"], correctIndex: 0 },
  { theme: "Histoire et civilisation", question: "Hailé Sélassié, empereur d'Éthiopie, est une figure centrale de quel mouvement spirituel né en Jamaïque ?", options: ["Le vaudou", "Le mouvement rastafari", "Le soufisme", "Le candomblé"], correctIndex: 1 },
  { theme: "Histoire et civilisation", question: "Nelson Mandela est avant tout connu pour avoir lutté contre...", options: ["La colonisation française en Algérie", "L'apartheid en Afrique du Sud", "La traite négrière transatlantique", "La partition de l'Inde"], correctIndex: 1 },
  { theme: "Histoire et civilisation", question: "L'apartheid, aboli au début des années 1990, désignait...", options: ["Un système agricole", "Un système de ségrégation raciale institutionnalisé en Afrique du Sud", "Une monnaie régionale", "Un traité commercial"], correctIndex: 1 },
  { theme: "Histoire et civilisation", question: "Patrice Lumumba a été le premier Premier ministre de quel pays nouvellement indépendant, avant d'être assassiné en 1961 ?", options: ["Le Congo", "Le Nigeria", "La Côte d'Ivoire", "Le Cameroun"], correctIndex: 0 },
  { theme: "Histoire et civilisation", question: "Léopold Sédar Senghor, poète et cofondateur du mouvement de la négritude, a été le premier président de quel pays ?", options: ["La Côte d'Ivoire", "Le Sénégal", "Le Mali", "La Guinée"], correctIndex: 1 },
  { theme: "Histoire et civilisation", question: "Aimé Césaire, poète et homme politique martiniquais, a cofondé avec Senghor le concept de...", options: ["La négritude", "Le panafricanisme politique uniquement", "L'Ubuntu", "Le Kwanzaa"], correctIndex: 0 },
  { theme: "Histoire et civilisation", question: "Frantz Fanon, psychiatre et penseur, est surtout connu pour ses écrits sur...", options: ["L'astronomie", "La décolonisation et l'aliénation coloniale", "L'économie agricole", "La musique traditionnelle"], correctIndex: 1 },
  { theme: "Histoire et civilisation", question: "Le Grand Zimbabwe, vaste cité médiévale bâtie en pierre, se trouve en...", options: ["Afrique australe (Zimbabwe actuel)", "Afrique du Nord", "Amérique du Sud", "Asie du Sud-Est"], correctIndex: 0 },
  { theme: "Histoire et civilisation", question: "Le royaume d'Axoum, ancienne puissance commerciale antique, était situé dans quelle région ?", options: ["La Corne de l'Afrique (actuelle Éthiopie/Érythrée)", "L'Afrique du Nord", "L'Afrique centrale", "La péninsule arabique uniquement"], correctIndex: 0 },
  { theme: "Histoire et civilisation", question: "L'Union africaine, organisation continentale actuelle, a succédé en 2002 à...", options: ["L'ONU", "L'Organisation de l'unité africaine (OUA)", "La Société des Nations", "La CEDEAO"], correctIndex: 1 },
  { theme: "Valeurs et culture", question: "Kwanzaa, fête créée par Maulana Karenga, célèbre notamment...", options: ["Sept principes centrés sur la communauté et l'unité (Nguzo Saba)", "La victoire d'une bataille coloniale", "Une fête uniquement religieuse chrétienne", "Un jour férié européen"], correctIndex: 0 },
  { theme: "Valeurs et culture", question: "La négritude, mouvement littéraire porté par Senghor, Césaire et Damas, visait avant tout à...", options: ["Effacer toute référence à l'Afrique", "Affirmer et valoriser l'identité et la culture noires face à l'assimilation coloniale", "Promouvoir uniquement la langue française", "Un courant purement religieux"], correctIndex: 1 },
  { theme: "Valeurs et culture", question: "L'Organisation de l'unité africaine (OUA), ancêtre de l'Union africaine, a été fondée en 1963 dans quelle ville ?", options: ["Le Caire", "Addis-Abeba", "Dakar", "Nairobi"], correctIndex: 1 },
  { theme: "Valeurs et culture", question: "Le symbole égyptien antique \"Ankh\" représente généralement...", options: ["La mort", "La vie", "Le commerce", "La royauté uniquement"], correctIndex: 1 },
  { theme: "Valeurs et culture", question: "La \"Teranga\", valeur très présente en Afrique de l'Ouest (notamment au Sénégal), désigne surtout...", options: ["L'hospitalité et l'accueil de l'autre", "Un plat traditionnel", "Une danse rituelle uniquement", "Un impôt traditionnel"], correctIndex: 0 },
  { theme: "Valeurs et culture", question: "Dans de nombreuses sociétés d'Afrique de l'Ouest, le griot est avant tout...", options: ["Un simple musicien de rue", "Le gardien de la tradition orale, de la généalogie et de l'histoire de la communauté", "Un titre purement honorifique sans rôle réel", "Un chef militaire"], correctIndex: 1 },
  { theme: "Valeurs et culture", question: "Le Kente, tissu tissé à la main reconnaissable à ses motifs colorés, est traditionnellement associé à quel peuple ?", options: ["Les Zoulous", "Les Akans (Ghana)", "Les Berbères", "Les Maasaï"], correctIndex: 1 },
  { theme: "Valeurs et culture", question: "Le mot \"Kemet\", nom que se donnaient les habitants de l'Égypte antique, signifie approximativement...", options: ["\"Terre du soleil\"", "\"Terre noire\" (en référence au limon fertile du Nil)", "\"Terre des dieux\"", "\"Grand fleuve\""], correctIndex: 1 },
  { theme: "Valeurs et culture", question: "Les hiéroglyphes désignent...", options: ["Un système d'écriture de l'Égypte antique", "Une technique de construction de pyramides", "Une langue encore parlée aujourd'hui en Égypte", "Un type de bijou royal uniquement"], correctIndex: 0 },
  { theme: "Valeurs et culture", question: "Néfertiti, dont le buste est mondialement connu, était...", options: ["Une reine de l'Égypte antique", "Une déesse uniquement mythologique", "Une reine d'Éthiopie médiévale", "Une figure uniquement littéraire moderne"], correctIndex: 0 },
  { theme: "Valeurs et culture", question: "Les pyramides de Gizeh ont été construites par...", options: ["Les Égyptiens de l'Antiquité eux-mêmes", "Des ingénieurs venus d'Europe", "Une civilisation restée totalement inconnue", "Des esclaves uniquement, sans aucun artisan libre ni organisation étatique"], correctIndex: 0 },
  { theme: "Valeurs et culture", question: "L'expression \"diaspora africaine\" désigne...", options: ["Uniquement les Africains vivant encore sur le continent", "Les populations d'origine africaine dispersées hors du continent, notamment via la traite négrière", "Une organisation politique précise", "Un courant musical uniquement"], correctIndex: 1 },
  { theme: "Valeurs et culture", question: "Le panafricanisme vise avant tout...", options: ["L'unité et la solidarité entre les peuples africains et leur diaspora", "La domination d'un pays africain sur les autres", "Le rejet total de toute relation avec le reste du monde", "Un courant uniquement artistique"], correctIndex: 0 },
  { theme: "Valeurs et culture", question: "L'ancien royaume de Koush (Nubie), situé au sud de l'Égypte antique, est connu pour...", options: ["N'avoir jamais existé", "Avoir été une civilisation florissante, parfois rivale de l'Égypte", "Être une légende moderne sans preuve archéologique", "Se situer en Amérique du Sud"], correctIndex: 1 },
  { theme: "Valeurs et culture", question: "Léon-Gontran Damas, poète guyanais, est l'un des trois cofondateurs historiques, avec Senghor et Césaire, de...", options: ["La négritude", "L'Union africaine", "Le mouvement rastafari", "L'OUA"], correctIndex: 0 },
  { theme: "Valeurs et culture", question: "Dans la tradition akan (Ghana), un enfant appelé \"Kwame\" est généralement...", options: ["Né un samedi", "Le premier-né de la famille obligatoirement", "Un nom réservé à la royauté uniquement", "Choisi au hasard sans signification"], correctIndex: 0 },
  { theme: "Valeurs et culture", question: "Le proverbe souvent cité \"il faut tout un village pour élever un enfant\" illustre surtout...", options: ["Une conception individualiste de l'éducation", "Une conception collective et communautaire de l'éducation", "Un principe économique uniquement", "Un dicton sans rapport avec l'éducation"], correctIndex: 1 },
  { theme: "Valeurs et culture", question: "Avant la généralisation de l'écriture, la transmission du savoir et de l'histoire reposait en Afrique largement sur...", options: ["Les archives notariales", "La tradition orale (contes, griots, proverbes)", "Les journaux imprimés", "Les cartes géographiques uniquement"], correctIndex: 1 },
  { theme: "Valeurs et culture", question: "Le mouvement rastafari, né en Jamaïque, considère traditionnellement Hailé Sélassié comme...", options: ["Un simple chef d'État parmi d'autres", "Une figure spirituelle et messianique centrale", "Un adversaire historique", "Un personnage de fiction"], correctIndex: 1 },
  { theme: "Famille et société", question: "Dans la vision portée par la charte, le parrain ou la marraine joue généralement un rôle de...", options: ["Simple témoin administratif sans implication réelle", "Figure complémentaire impliquée dans l'éducation et la transmission des valeurs", "Remplaçant des parents en toutes circonstances", "Aucun rôle reconnu dans la tradition"], correctIndex: 1 },
  { theme: "Famille et société", question: "La \"famille élargie\" (oncles, tantes, cousins, grands-parents) occupe, dans de nombreuses traditions africaines, une place...", options: ["Centrale, souvent aussi importante que la famille nucléaire", "Totalement secondaire et sans réel rôle", "Uniquement symbolique lors des mariages", "Inexistante une fois les enfants adultes"], correctIndex: 0 },
  { theme: "Famille et société", question: "Dans beaucoup de traditions africaines, la dot (ou compensation matrimoniale) est avant tout...", options: ["Un achat de la mariée comme une marchandise", "Un geste symbolique d'alliance et de reconnaissance entre deux familles", "Une pratique sans aucune signification", "Une obligation réservée uniquement à la mariée"], correctIndex: 1 },
  { theme: "Famille et société", question: "Les rites de passage (initiation, passage à l'âge adulte...) ont traditionnellement pour fonction de...", options: ["N'avoir aucune utilité sociale", "Marquer et accompagner une étape importante de la vie au sein de la communauté", "Remplacer totalement l'éducation familiale", "Être réservés uniquement aux chefs traditionnels"], correctIndex: 1 },
  { theme: "Famille et société", question: "L'arbre à palabres, dans de nombreuses sociétés ouest-africaines, est traditionnellement un lieu pour...", options: ["Le commerce exclusivement", "Discuter et résoudre collectivement les conflits ou décisions importantes", "Les cérémonies funéraires uniquement", "Un simple point de repère géographique sans usage social"], correctIndex: 1 },
  { theme: "Famille et société", question: "Dans la vision portée par la charte, transmettre sa langue maternelle ou une langue africaine à ses enfants est considéré comme...", options: ["Sans importance particulière", "Un vecteur important de transmission culturelle", "Un obstacle à l'intégration", "Réservé uniquement aux linguistes"], correctIndex: 1 },
  { theme: "Famille et société", question: "Le respect des aînés, valeur largement partagée dans les traditions africaines, implique notamment de...", options: ["Ne jamais les consulter sur les décisions importantes", "Écouter leur expérience et leur accorder une place de considération dans la famille", "Les tenir totalement à l'écart de la vie du foyer", "Un simple salut protocolaire sans substance"], correctIndex: 1 },
  { theme: "Famille et société", question: "Dans de nombreuses cultures africaines, le choix du prénom d'un enfant peut traditionnellement dépendre de...", options: ["Jamais d'aucune règle ou signification particulière", "Des circonstances de la naissance (jour, ordre, événement) ou de valeurs que l'on souhaite transmettre", "Uniquement d'un tirage au sort", "D'une loi administrative uniquement"], correctIndex: 1 },
  { theme: "Famille et société", question: "La cuisine traditionnelle, au sein du foyer, est généralement considérée par la charte comme...", options: ["Un détail sans aucun rapport avec la culture", "Un vecteur important de transmission culturelle et familiale", "Une contrainte à éviter autant que possible", "Réservée uniquement aux grandes occasions"], correctIndex: 1 },
  { theme: "Famille et société", question: "Dans la vision portée par la charte, les décisions importantes concernant les enfants devraient en priorité être prises...", options: ["Par un seul des deux parents sans concertation", "D'un commun accord entre les deux parents", "Uniquement par la famille élargie", "Par les enfants eux-mêmes dès le plus jeune âge"], correctIndex: 1 },
  { theme: "Famille et société", question: "La transmission de l'histoire précoloniale aux enfants vise notamment à...", options: ["Leur donner une image uniquement négative du continent", "Leur permettre de connaître les civilisations et royaumes africains avant la colonisation", "Remplacer l'école par la tradition orale", "N'avoir aucun objectif particulier"], correctIndex: 1 },
  { theme: "Famille et société", question: "Dans de nombreuses sociétés traditionnelles africaines, les repas pris en commun au sein du foyer sont généralement vus comme...", options: ["Un moment sans importance particulière", "Un moment de cohésion et de transmission familiale", "Réservés uniquement aux invités", "Une obligation purement religieuse"], correctIndex: 1 },
  { theme: "Famille et société", question: "Le soutien financier ponctuel à la famille élargie (parents, frères et sœurs...) est, dans de nombreuses traditions africaines, perçu comme...", options: ["Une anomalie à éviter", "Une solidarité familiale normale et valorisée", "Interdit par la tradition", "Réservé uniquement aux plus riches"], correctIndex: 1 },
  { theme: "Famille et société", question: "Dans la vision portée par la charte, l'éducation des enfants est avant tout...", options: ["La responsabilité unique de l'école", "Une responsabilité partagée entre les parents, la famille élargie et la communauté", "Une affaire strictement privée sans aucun rôle pour la communauté", "Sans lien avec les valeurs culturelles transmises"], correctIndex: 1 },
  { theme: "Famille et société", question: "Les réunions de famille régulières (fêtes, anniversaires, retrouvailles...) sont généralement considérées comme...", options: ["Facultatives et sans réelle importance", "Un moyen important de maintenir les liens familiaux", "Réservées uniquement aux décès", "Une contrainte à éviter"], correctIndex: 1 },
  { theme: "Famille et société", question: "La bilingue ou le plurilinguisme (langue locale + langue africaine ou autre) chez l'enfant est généralement vu, dans cette vision, comme...", options: ["Un handicap pour son développement", "Un atout culturel et cognitif à encourager", "Sans aucun intérêt particulier", "Réservé uniquement à l'école privée"], correctIndex: 1 },
  { theme: "Famille et société", question: "Dans beaucoup de traditions africaines, les contes et légendes racontés aux enfants ont avant tout pour but de...", options: ["Simplement les endormir sans message particulier", "Transmettre des valeurs, une morale ou une mémoire collective", "Remplacer l'éducation scolaire", "N'avoir aucune utilité pédagogique"], correctIndex: 1 },
  { theme: "Famille et société", question: "Le rôle du \"conseil des anciens\", déjà évoqué dans la tradition, s'étend généralement aussi à...", options: ["La gestion exclusive du commerce", "La médiation des conflits familiaux et communautaires", "Aucun rôle social reconnu", "Uniquement des cérémonies sans pouvoir réel"], correctIndex: 1 },
  { theme: "Famille et société", question: "La notion de \"famille\" dans la vision portée par la charte inclut généralement...", options: ["Uniquement les parents et les enfants", "Les parents, les enfants et la famille élargie au sens large", "Uniquement les liens du sang direct", "Une définition strictement légale uniquement"], correctIndex: 1 },
  { theme: "Communication et personnalité", question: "Face à un malentendu dans un couple, la charte recommande avant tout de...", options: ["Laisser traîner sans en parler", "En parler calmement dès que possible", "Attendre que l'autre devine le problème", "Couper immédiatement toute communication"], correctIndex: 1 },
  { theme: "Communication et personnalité", question: "L'écoute active, valorisée par la charte, consiste surtout à...", options: ["Préparer sa réponse pendant que l'autre parle", "Chercher à comprendre le point de vue de l'autre avant de répondre", "Rester silencieux sans aucune réaction", "Interrompre pour corriger immédiatement"], correctIndex: 1 },
  { theme: "Communication et personnalité", question: "Selon la charte, l'honnêteté dans une relation sérieuse est considérée comme...", options: ["Secondaire par rapport à la passion", "Une base essentielle de la confiance", "Sans lien avec la confiance", "Facultative selon les sujets"], correctIndex: 1 },
  { theme: "Communication et personnalité", question: "Reconnaître ses torts après une erreur est généralement présenté, dans cette vision, comme...", options: ["Un signe de faiblesse à éviter", "Un signe de maturité et de force", "Inutile si l'autre ne le fait pas aussi", "Réservé à de rares occasions"], correctIndex: 1 },
  { theme: "Communication et personnalité", question: "Face à une forte émotion pendant une dispute, la charte recommande plutôt de...", options: ["Réagir immédiatement sous le coup de l'émotion", "Prendre un moment de recul avant de répondre", "Ignorer définitivement le sujet", "Couper tout contact pendant plusieurs semaines"], correctIndex: 1 },
  { theme: "Communication et personnalité", question: "Exprimer clairement ses besoins à son/sa partenaire est généralement considéré comme...", options: ["Inutile, l'autre devrait deviner", "Une pratique saine qui évite les malentendus", "Une faiblesse à cacher", "Réservé aux grandes occasions uniquement"], correctIndex: 1 },
  { theme: "Communication et personnalité", question: "Selon cette vision du couple, les désaccords occasionnels sont...", options: ["Toujours le signe d'une relation qui échoue", "Normaux, s'ils sont gérés avec respect et dialogue", "À éviter à tout prix, même en se taisant sur tout", "Le signe qu'il faut rompre immédiatement"], correctIndex: 1 },
  { theme: "Communication et personnalité", question: "Le respect mutuel, valeur centrale de la charte, implique notamment de...", options: ["Ne jamais exprimer de désaccord", "Accepter les différences de l'autre sans chercher à le rabaisser", "Imposer systématiquement son point de vue", "Éviter toute discussion profonde"], correctIndex: 1 },
  { theme: "Communication et personnalité", question: "Selon la charte, se disputer devant de jeunes enfants est généralement considéré comme...", options: ["Sans aucune conséquence", "À éviter autant que possible, pour préserver leur sécurité affective", "Une bonne façon de les endurcir", "Une obligation éducative"], correctIndex: 1 },
  { theme: "Communication et personnalité", question: "Dans cette vision du couple, la transparence sur les finances est généralement perçue comme...", options: ["Un sujet tabou à éviter entre partenaires", "Un élément utile à aborder ouvertement dans une relation sérieuse", "Sans aucun lien avec la confiance", "Réservée uniquement après le mariage"], correctIndex: 1 },
  { theme: "Communication et personnalité", question: "Complimenter régulièrement son/sa partenaire est généralement présenté comme...", options: ["Superflu une fois la relation installée", "Une habitude saine qui entretient la relation", "Réservé aux débuts de la relation uniquement", "Un signe de dépendance affective"], correctIndex: 1 },
  { theme: "Communication et personnalité", question: "Selon la charte, la jalousie excessive dans un couple est généralement considérée comme...", options: ["Une preuve d'amour à encourager", "Un signal à travailler, pas un objectif à atteindre", "Sans aucune importance", "Un droit légitime systématique"], correctIndex: 1 },
  { theme: "Communication et personnalité", question: "Prendre le temps de bien connaître quelqu'un avant de s'engager sérieusement est généralement vu, dans cette vision, comme...", options: ["Une perte de temps", "Une démarche saine et recommandée", "Un manque de confiance en soi", "Inutile si l'attirance est immédiate"], correctIndex: 1 },
  { theme: "Communication et personnalité", question: "Demander pardon après avoir blessé son/sa partenaire est généralement présenté comme...", options: ["Un aveu de faiblesse à éviter", "Un acte de courage qui renforce la relation", "Inutile si l'autre ne s'en rend pas compte", "Réservé aux fautes graves uniquement"], correctIndex: 1 },
  { theme: "Communication et personnalité", question: "La communication non-verbale (ton, gestes, attitude) est généralement considérée, dans la vision de la charte, comme...", options: ["Sans aucune importance face aux mots", "Tout aussi importante que les mots eux-mêmes", "Un simple détail négligeable", "Réservée aux professionnels de la communication"], correctIndex: 1 },
  { theme: "Communication et personnalité", question: "Garder des espaces et des amitiés en dehors du couple est généralement considéré comme...", options: ["Un danger pour la relation", "Sain, tant que la confiance et le respect sont présents", "Incompatible avec un engagement sérieux", "Réservé à une seule des deux personnes du couple"], correctIndex: 1 },
  { theme: "Communication et personnalité", question: "Selon la charte, l'humour dans le couple peut notamment servir à...", options: ["Éviter définitivement tout sujet sérieux", "Désamorcer certaines tensions tout en respectant l'autre", "Remplacer toute communication profonde", "Humilier l'autre sans conséquence"], correctIndex: 1 },
  { theme: "Communication et personnalité", question: "La patience face aux différences de rythme ou de caractère de l'autre est généralement présentée comme...", options: ["Inutile si l'on s'aime vraiment", "Une qualité utile à cultiver dans la durée", "Un signe de faiblesse", "Réservée aux débuts de la relation"], correctIndex: 1 },
  { theme: "Histoire et civilisation", question: "La traite négrière transatlantique a déporté de force des millions d'Africains principalement vers...", options: ["L'Asie du Sud-Est", "Les Amériques et les Caraïbes", "L'Europe du Nord uniquement", "L'Océanie"], correctIndex: 1 },
  { theme: "Histoire et civilisation", question: "La conférence de Berlin (1884-1885) est restée dans l'histoire pour avoir...", options: ["Organisé le partage colonial du continent africain entre puissances européennes", "Proclamé l'indépendance du Ghana", "Créé l'Union africaine", "Mis fin à l'apartheid"], correctIndex: 0 },
  { theme: "Histoire et civilisation", question: "Kwame Ture (Stokely Carmichael) est une figure associée à...", options: ["Le mouvement Black Power aux États-Unis", "La conquête spatiale", "La révolution industrielle britannique", "La fondation de l'OUA"], correctIndex: 0 },
  { theme: "Valeurs et culture", question: "Le mot \"Maât\", concept central de l'Égypte antique, renvoie surtout à l'idée de...", options: ["La guerre", "L'ordre, la vérité et la justice", "Le commerce maritime", "La monnaie"], correctIndex: 1 },
  { theme: "Valeurs et culture", question: "Dans plusieurs traditions ouest-africaines, le masque rituel sert traditionnellement à...", options: ["La décoration uniquement, sans fonction rituelle", "Incarner des esprits ou ancêtres lors de cérémonies", "Un simple accessoire de théâtre moderne", "Un usage strictement militaire"], correctIndex: 1 },
  { theme: "Valeurs et culture", question: "Le concept d'Ubuntu, popularisé notamment par Desmond Tutu et Nelson Mandela, met l'accent sur...", options: ["L'individualisme avant tout", "L'interdépendance et l'humanité partagée entre les personnes", "La compétition entre individus", "Un système économique précis"], correctIndex: 1 },
  { theme: "Famille et société", question: "Dans de nombreuses traditions africaines, le lévirat et le sororat (mariage avec un parent du conjoint décédé) illustrent avant tout...", options: ["Une pratique sans aucune logique sociale", "Une logique de protection et de solidarité familiale, aujourd'hui en net recul", "Une obligation universelle encore appliquée partout", "Un simple mythe sans fondement historique"], correctIndex: 1 },
  { theme: "Famille et société", question: "La notion de \"doyen\" ou \"aîné\" de famille implique traditionnellement un rôle de...", options: ["Simple figurant sans responsabilité", "Référent moral et arbitre respecté au sein de la famille élargie", "Autorité uniquement financière", "Aucun rôle reconnu par la tradition"], correctIndex: 1 },
  { theme: "Communication et personnalité", question: "Dans un désaccord, chercher un compromis plutôt qu'une victoire à tout prix est généralement vu, dans cette vision, comme...", options: ["Un signe de faiblesse", "Une preuve de maturité relationnelle", "Inutile si on a raison", "Réservé aux conflits mineurs uniquement"], correctIndex: 1 },
  { theme: "Communication et personnalité", question: "Fixer des limites claires et respectueuses dans une relation est généralement considéré comme...", options: ["Un manque de confiance envers l'autre", "Une pratique saine qui protège la relation", "Inutile entre partenaires sérieux", "Réservé aux débuts de la relation uniquement"], correctIndex: 1 },
];

// Contenu repris de docs/banque-questions-compatibilite.md.
const COMPAT_QUESTIONS: { theme: string; question: string }[] = [
  { theme: "vision_couple", question: "La fidélité est une condition non négociable dans un couple." },
  { theme: "vision_couple", question: "Je préfère régler un désaccord par la discussion plutôt que de laisser du temps passer." },
  { theme: "vision_couple", question: "Le respect mutuel compte plus pour moi que la passion au quotidien." },
  { theme: "vision_couple", question: "Je m'engage pleinement dès que je sais qu'une relation est sérieuse." },
  { theme: "valeurs_culture", question: "Les références culturelles kamites occupent une place importante dans ma vie quotidienne." },
  { theme: "valeurs_culture", question: "Je veux transmettre l'histoire et la culture africaine à mes enfants." },
  { theme: "valeurs_culture", question: "Connaître l'histoire précoloniale africaine est important pour moi." },
  { theme: "valeurs_culture", question: "Je participe régulièrement à des pratiques ou traditions culturelles." },
  { theme: "famille", question: "Je souhaite avoir des enfants." },
  { theme: "famille", question: "La famille doit occuper une place centrale dans la vie du couple." },
  { theme: "famille", question: "Je veux une éducation des enfants fortement ancrée dans nos valeurs culturelles." },
  { theme: "mode_vie", question: "Je préfère vivre en ville plutôt qu'à la campagne." },
  { theme: "mode_vie", question: "La stabilité financière est une priorité avant de s'engager durablement." },
  { theme: "mode_vie", question: "Les responsabilités du couple doivent être partagées à parts égales." },
  { theme: "communication", question: "Je suis plutôt extraverti(e) que réservé(e)." },
  { theme: "communication", question: "J'exprime facilement mon affection à l'autre." },
  { theme: "communication", question: "Face à un désaccord, je cherche à comprendre l'autre avant de défendre mon point de vue." },
  { theme: "vision_couple", question: "Je crois que la confiance se reconstruit difficilement après une trahison." },
  { theme: "vision_couple", question: "Je considère le mariage comme un engagement pour la vie." },
  { theme: "vision_couple", question: "Je préfère prendre le temps de bien connaître quelqu'un avant de m'engager sérieusement." },
  { theme: "vision_couple", question: "La jalousie n'a pas sa place dans une relation saine." },
  { theme: "vision_couple", question: "Je pense qu'un couple doit avoir des projets communs clairs." },
  { theme: "vision_couple", question: "Je suis à l'aise pour exprimer mes besoins dans une relation." },
  { theme: "vision_couple", question: "Je considère l'indépendance financière de chacun comme importante dans le couple." },
  { theme: "vision_couple", question: "Je pense que les disputes occasionnelles sont normales et saines si elles restent respectueuses." },
  { theme: "vision_couple", question: "Je crois en l'importance des compromis dans une relation durable." },
  { theme: "vision_couple", question: "Je préfère une relation où les rôles de chacun sont clairement définis." },
  { theme: "vision_couple", question: "Je pense que la passion doit rester aussi forte tout au long de la relation." },
  { theme: "vision_couple", question: "Je considère important de garder des espaces personnels au sein du couple." },
  { theme: "vision_couple", question: "J'accorde une grande importance à la ponctualité et à la fiabilité de mon/ma partenaire." },
  { theme: "vision_couple", question: "Je pense que les valeurs communes comptent plus que l'attirance initiale." },
  { theme: "vision_couple", question: "Je suis prêt(e) à faire des compromis importants pour une relation sérieuse." },
  { theme: "vision_couple", question: "Je considère que la vie de couple doit inclure des moments réguliers en tête-à-tête." },
  { theme: "vision_couple", question: "Je pense qu'il est important de se projeter rapidement sur le long terme dans une relation." },
  { theme: "valeurs_culture", question: "Je souhaite célébrer les fêtes culturelles kamites avec mon/ma partenaire." },
  { theme: "valeurs_culture", question: "Porter des tenues traditionnelles lors d'occasions importantes compte pour moi." },
  { theme: "valeurs_culture", question: "Je m'intéresse activement à l'histoire précoloniale de mon pays d'origine." },
  { theme: "valeurs_culture", question: "Je pense qu'il est important de parler au moins une langue africaine à la maison." },
  { theme: "valeurs_culture", question: "Je souhaite que mes enfants connaissent les traditions orales (contes, griots...)." },
  { theme: "valeurs_culture", question: "Je considère important de soutenir des commerces ou artistes afrodescendants." },
  { theme: "valeurs_culture", question: "Je m'intéresse à la musique traditionnelle africaine." },
  { theme: "valeurs_culture", question: "Je pense que la cuisine traditionnelle doit occuper une place importante dans le foyer." },
  { theme: "valeurs_culture", question: "Je souhaite visiter régulièrement le pays d'origine de ma famille." },
  { theme: "valeurs_culture", question: "Je considère important de transmettre des noms traditionnels à mes enfants." },
  { theme: "valeurs_culture", question: "Je m'intéresse à la spiritualité ou aux pratiques kemites/afrocentrées." },
  { theme: "valeurs_culture", question: "Je pense que la connaissance de Kemet (Égypte antique) est un pilier identitaire important." },
  { theme: "valeurs_culture", question: "Je souhaite que mon couple s'investisse dans des causes panafricanistes." },
  { theme: "valeurs_culture", question: "Je pense que la littérature afrodescendante doit avoir une place dans notre foyer." },
  { theme: "valeurs_culture", question: "Je considère important de connaître les grandes figures historiques du panafricanisme." },
  { theme: "valeurs_culture", question: "Je souhaite célébrer Kwanzaa ou des fêtes culturelles similaires." },
  { theme: "valeurs_culture", question: "Je pense que la transmission culturelle est une responsabilité partagée du couple." },
  { theme: "famille", question: "Je souhaite vivre proche de ma famille élargie." },
  { theme: "famille", question: "Je pense que les grands-parents doivent jouer un rôle actif dans l'éducation des enfants." },
  { theme: "famille", question: "Je considère que l'avis de la famille compte dans les décisions importantes du couple." },
  { theme: "famille", question: "Je souhaite avoir plus de deux enfants." },
  { theme: "famille", question: "Je pense que l'un des deux parents devrait rester disponible les premières années des enfants." },
  { theme: "famille", question: "Je considère important d'organiser des réunions de famille régulières." },
  { theme: "famille", question: "Je pense que les enfants doivent connaître leurs cousins et leur famille élargie." },
  { theme: "famille", question: "Je souhaite transmettre une discipline claire mais bienveillante à mes enfants." },
  { theme: "famille", question: "Je pense que le foyer doit pouvoir accueillir ponctuellement d'autres membres de la famille." },
  { theme: "famille", question: "Je considère que les fêtes de famille doivent être une priorité dans l'agenda du couple." },
  { theme: "famille", question: "Je souhaite que mes enfants partagent la même spiritualité ou religion que moi." },
  { theme: "famille", question: "Je pense qu'il est important de soutenir financièrement sa famille élargie en cas de besoin." },
  { theme: "famille", question: "Je considère le rôle de parrain ou de marraine comme important dans la famille." },
  { theme: "famille", question: "Je souhaite célébrer des rites de passage traditionnels avec mes enfants." },
  { theme: "famille", question: "Je pense que les décisions concernant les enfants doivent toujours être prises à deux." },
  { theme: "famille", question: "Je considère important d'avoir des repas en famille réguliers." },
  { theme: "famille", question: "Je souhaite que mes enfants grandissent en étant bilingues au minimum." },
  { theme: "mode_vie", question: "Je préfère un rythme de vie calme à un rythme de vie trépidant." },
  { theme: "mode_vie", question: "Je considère le sport comme une priorité dans mon quotidien." },
  { theme: "mode_vie", question: "Je préfère voyager plutôt qu'épargner systématiquement." },
  { theme: "mode_vie", question: "Je pense que le couple doit avoir un budget commun." },
  { theme: "mode_vie", question: "Je préfère un intérieur sobre à un intérieur chargé." },
  { theme: "mode_vie", question: "Je considère important d'avoir des loisirs communs avec mon/ma partenaire." },
  { theme: "mode_vie", question: "Je pense que la carrière professionnelle peut primer sur la vie personnelle à certaines périodes." },
  { theme: "mode_vie", question: "Je préfère vivre en appartement plutôt qu'en maison." },
  { theme: "mode_vie", question: "Je considère important de prévoir une épargne pour les imprévus." },
  { theme: "mode_vie", question: "Je pense qu'il est important d'avoir des amis en dehors du couple." },
  { theme: "mode_vie", question: "Je préfère planifier à l'avance plutôt qu'improviser." },
  { theme: "mode_vie", question: "Je considère important de pratiquer une activité physique régulière en couple." },
  { theme: "mode_vie", question: "Je pense que les tâches ménagères doivent être partagées à parts égales." },
  { theme: "mode_vie", question: "Je préfère une alimentation saine stricte à une alimentation plus libre." },
  { theme: "mode_vie", question: "Je considère important de prendre des vacances chaque année." },
  { theme: "mode_vie", question: "Je pense qu'un animal de compagnie a sa place dans un foyer." },
  { theme: "mode_vie", question: "Je préfère rester proche de ma ville natale plutôt que déménager loin." },
  { theme: "communication", question: "Je préfère aborder un sujet sensible en personne plutôt que par message." },
  { theme: "communication", question: "Je considère important de prendre du recul avant de répondre à chaud." },
  { theme: "communication", question: "Je pense qu'il faut toujours dire ce que l'on pense, même si ça peut parfois blesser." },
  { theme: "communication", question: "Je préfère exprimer mes émotions ouvertement plutôt que les garder pour moi." },
  { theme: "communication", question: "Je considère que le silence peut parfois être une bonne réponse temporaire à un conflit." },
  { theme: "communication", question: "Je pense qu'il est important de complimenter régulièrement mon/ma partenaire." },
  { theme: "communication", question: "Je préfère résoudre un désaccord le jour même plutôt que d'attendre." },
  { theme: "communication", question: "Je considère important d'exprimer mes besoins clairement plutôt que d'attendre qu'on les devine." },
  { theme: "communication", question: "Je pense que l'humour aide à désamorcer les tensions dans un couple." },
  { theme: "communication", question: "Je préfère écouter activement avant de donner mon avis." },
  { theme: "communication", question: "Je considère important de reconnaître mes torts rapidement." },
  { theme: "communication", question: "Je pense qu'il faut éviter de se disputer devant les enfants." },
  { theme: "communication", question: "Je préfère les discussions calmes aux débats passionnés." },
  { theme: "communication", question: "Je considère important de se dire bonjour et au revoir avec affection chaque jour." },
  { theme: "communication", question: "Je pense que la communication non-verbale est tout aussi importante que les mots." },
  { theme: "communication", question: "Je préfère aborder les finances du couple ouvertement dès le début de la relation." },
  { theme: "communication", question: "Je considère que demander pardon est un signe de force, pas de faiblesse." },
];

/**
 * Charge les deux banques de questions dans Firestore — jusqu'ici
 * rédigées en Markdown mais jamais importées, ce qui empêchait tout
 * test réel du filtrage et de la compatibilité (docs/suivi-developpement.md).
 * Idempotent : réimporter ne crée jamais de doublon (identifiants
 * déterministes), donc rejouable sans risque si le contenu évolue.
 */
export const adminSeedQuestionBanks = onCall({ region: REGION, enforceAppCheck: ENFORCE_APP_CHECK }, async (request) => {
  const adminUid = requireAdmin(request);
  const db = getFirestore();

  const filtrageBatch = db.batch();
  FILTRAGE_QUESTIONS.forEach((q, i) => {
    const ref = db.collection("filtrage_question_bank").doc(`seed_${i}`);
    filtrageBatch.set(ref, { ...q, active: true });
  });
  await filtrageBatch.commit();

  const compatBatch = db.batch();
  COMPAT_QUESTIONS.forEach((q, i) => {
    const ref = db.collection("compat_question_bank").doc(`seed_${i}`);
    compatBatch.set(ref, { ...q, active: true });
  });
  await compatBatch.commit();

  await logAdminAction(db, {
    adminUid,
    action: "question_banks_seeded",
    details: { filtrageCount: FILTRAGE_QUESTIONS.length, compatCount: COMPAT_QUESTIONS.length },
  });

  return {
    ok: true,
    filtrageCount: FILTRAGE_QUESTIONS.length,
    compatCount: COMPAT_QUESTIONS.length,
  };
});
