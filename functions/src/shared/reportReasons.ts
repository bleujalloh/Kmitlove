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

/** Motifs jugés plus graves d'emblée (contenu dangereux/frauduleux) —
 * ces signalements remontent en premier dans la file d'attente admin,
 * docs/regles-complementaires-concurrents.md section 1 ("priorité selon
 * gravité"), sans avoir besoin d'un second champ de tri numérique. */
export const HIGH_SEVERITY_REASONS: ReadonlySet<string> = new Set(["contenu_inapproprie", "arnaque"]);
