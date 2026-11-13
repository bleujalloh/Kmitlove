/** Les deux genres possibles (profil et préférence de recherche) — liste
 * fermée partagée pour éviter que deux copies divergent silencieusement
 * (saveProfil.ts pour l'enregistrement, getCandidates.ts pour le filtre
 * rapide "Tous/Hommes/Femmes" de Découvrir, 12/11/2026).
 */
export const GENDERS: string[] = ["Femme", "Homme"];
