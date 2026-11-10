import { FieldValue, Timestamp } from "firebase-admin/firestore";

import { SANCTION_SUSPENSION_DAYS, PRIORITY_REVIEW_REPORT_THRESHOLD } from "../config";

export type SanctionAction = "warn" | "suspend" | "ban";

type SanctionLevel = "none" | "warned" | "suspended" | "banned";

const ACTION_LEVEL: Record<SanctionAction, SanctionLevel> = {
  warn: "warned",
  suspend: "suspended",
  ban: "banned",
};
const LEVEL_RANK: Record<SanctionLevel, number> = { none: 0, warned: 1, suspended: 2, banned: 3 };
const KNOWN_LEVELS = new Set<SanctionLevel>(["none", "warned", "suspended", "banned"]);

/**
 * Calcule la mise à jour de `user_status` pour une sanction confirmée —
 * fonction pure, sans accès Firestore, pour pouvoir être composée dans la
 * transaction plus large de admin/moderationRequests.ts (lecture du
 * signalement + du statut cible + écritures, toutes atomiques ensemble :
 * sans ça, un double clic/retry pourrait faire avancer confirmedReportCount
 * deux fois pour un seul signalement confirmé).
 *
 * `filtrageStatus` (déjà utilisé partout pour masquer un compte) reste
 * la seule source de vérité pour "ce compte est actuellement caché", mais
 * `sanctionLevel` est tenu synchronisé avec lui par TOUS les points
 * d'écriture (ici, et admin/listUsers.ts pour la suspension manuelle, et
 * admin/resolveSanctionAppeal.ts pour la levée d'un recours) : aucun des
 * deux ne doit jamais changer sans l'autre, sinon cette fonction ne peut
 * plus savoir de façon fiable si un compte est déjà sanctionné.
 *
 * L'échelle ne redescend JAMAIS toute seule : si un second signalement
 * contre le même compte est traité avec une action plus faible que son
 * niveau actuel (ex. "avertir" un compte déjà suspendu — l'admin peut très
 * bien ne pas revérifier l'état actuel avant de cliquer), le niveau le
 * plus sévère des deux l'emporte.
 */
export function computeSanctionUpdate(
  current: Record<string, unknown>,
  action: SanctionAction,
): { update: Record<string, unknown>; confirmedReportCount: number; priorityReview: boolean } {
  // Même repli défensif que pour sanctionLevel plus bas : une valeur
  // stockée non numérique ferait dériver vers une concaténation de
  // chaînes ("5" + 1 → "51") plutôt qu'un vrai incrément, et corromprait
  // durablement le champ.
  const rawCount = current.confirmedReportCount;
  const previousCount = typeof rawCount === "number" && Number.isFinite(rawCount) ? rawCount : 0;
  const confirmedReportCount = previousCount + 1;
  const priorityReview = confirmedReportCount >= PRIORITY_REVIEW_REPORT_THRESHOLD;

  const update: Record<string, unknown> = {
    confirmedReportCount,
    priorityReview,
    lastSanctionAt: FieldValue.serverTimestamp(),
  };

  // Repli défensif sur "none" si la valeur stockée n'est pas l'une des
  // quatre connues (migration future, édition manuelle en console...) :
  // sans lui, LEVEL_RANK[currentLevel] vaudrait undefined et la
  // comparaison ci-dessous ne serait plus jamais vraie, désactivant
  // silencieusement toute escalade pour ce compte en particulier.
  const rawLevel = current.sanctionLevel as string | undefined;
  const currentLevel: SanctionLevel =
    rawLevel != null && KNOWN_LEVELS.has(rawLevel as SanctionLevel) ? (rawLevel as SanctionLevel) : "none";
  const requestedLevel = ACTION_LEVEL[action];

  if (LEVEL_RANK[requestedLevel] > LEVEL_RANK[currentLevel]) {
    // Une sanction plus sévère que la précédente est un évènement NOUVEAU
    // et distinct — ni un éventuel délai d'attente venant du refus d'un
    // recours contre l'ANCIENNE sanction, ni un recours encore en attente
    // contre elle (account/requestSanctionAppeal.ts bloquerait sinon tout
    // nouveau recours tant que l'admin n'a pas traité l'ancien, devenu
    // sans objet) ne doivent bloquer un recours contre celle-ci.
    update.appealNextRetryAt = null;
    update.appealPending = false;
    if (requestedLevel === "warned") {
      update.sanctionLevel = "warned";
    } else {
      // "suspended" et "banned" partent tous deux du même statut
      // d'origine à mémoriser pour une éventuelle restauration par
      // resolveSanctionAppeal — sans ça, un recours accepté
      // restaurerait "active" par défaut même si le compte était par
      // exemple "review_requested" avant la sanction.
      update.preSuspensionStatus = current.preSuspensionStatus ?? current.filtrageStatus ?? "active";
      update.filtrageStatus = "suspended";
      update.sanctionLevel = requestedLevel;
      if (requestedLevel === "suspended") {
        // Atteindre cette branche exige currentLevel < "suspended", donc
        // "none" ou "warned" — et puisque sanctionLevel/filtrageStatus
        // sont tenus synchronisés partout (voir doc ci-dessus), le compte
        // n'est jamais déjà suspendu en entrant ici : poser un délai de
        // 30 jours est toujours sûr.
        update.suspendedUntil = Timestamp.fromMillis(Date.now() + SANCTION_SUSPENSION_DAYS * 24 * 60 * 60 * 1000);
      } else {
        update.suspendedUntil = null; // "banned" : jamais levée automatiquement par liftExpiredSuspensions
      }
    }
  }
  // Sinon (action plus faible ou égale au niveau déjà atteint) : seuls
  // les compteurs ci-dessus avancent, le niveau de sanction reste
  // inchangé — le signalement est quand même marqué résolu avec
  // l'action choisie par l'admin (moderationRequests.ts), seule la
  // conséquence sur le compte n'est pas une régression.

  return { update, confirmedReportCount, priorityReview };
}
