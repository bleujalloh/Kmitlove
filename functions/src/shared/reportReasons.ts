/** Motifs de signalement partagés entre reportUser et reportCommunityPost
 * (docs/regles-economie-et-compatibilite.md section 3) — une seule liste
 * pour que les deux flux ne divergent jamais silencieusement.
 */
export const REPORT_REASONS = [
  "faux_profil",
  "comportement_abusif",
  "contenu_inapproprie",
  "arnaque",
  "autre",
] as const;
