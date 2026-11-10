import { onCall } from "firebase-functions/v2/https";
import { getFirestore } from "firebase-admin/firestore";

import { REGION } from "../config";
import { requireAdmin } from "../shared/requireAdmin";

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
];

/**
 * Charge les deux banques de questions dans Firestore — jusqu'ici
 * rédigées en Markdown mais jamais importées, ce qui empêchait tout
 * test réel du filtrage et de la compatibilité (docs/suivi-developpement.md).
 * Idempotent : réimporter ne crée jamais de doublon (identifiants
 * déterministes), donc rejouable sans risque si le contenu évolue.
 */
export const adminSeedQuestionBanks = onCall({ region: REGION }, async (request) => {
  requireAdmin(request);
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

  return {
    ok: true,
    filtrageCount: FILTRAGE_QUESTIONS.length,
    compatCount: COMPAT_QUESTIONS.length,
  };
});
