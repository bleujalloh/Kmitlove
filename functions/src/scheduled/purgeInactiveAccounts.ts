import { onSchedule } from "firebase-functions/v2/scheduler";
import { getFirestore, Timestamp, FieldValue } from "firebase-admin/firestore";
import { getAuth } from "firebase-admin/auth";

import {
  REGION,
  INACTIVE_ACCOUNT_WARNING_MONTHS,
  INACTIVE_ACCOUNT_GRACE_DAYS,
  INACTIVE_PURGE_MAX_PER_RUN,
} from "../config";
import { eraseAccount } from "../shared/eraseAccount";
import { sendPushToUser } from "../shared/push";

/**
 * Minimisation des données (RGPD, docs/rgpd-registre-des-traitements.md §7) :
 * un compte sans aucune activité depuis ~24 mois n'a plus de raison d'être
 * conservé. En deux temps, jamais de suppression par surprise :
 *   1. après INACTIVE_ACCOUNT_WARNING_MONTHS mois d'inactivité, le membre est
 *      prévenu par notification ; `inactivityWarnedAt` n'est posé que si la
 *      notification a RÉELLEMENT atteint au moins un appareil — sans appareil
 *      joignable (jeton retiré à la déconnexion, jeton périmé), le compte
 *      n'est PAS supprimé : il reste masqué des autres membres et attend un
 *      canal d'avertissement fiable (e-mail, décision du propriétaire) ;
 *   2. si, INACTIVE_ACCOUNT_GRACE_DAYS jours plus tard, il n'est toujours pas
 *      revenu (`lastActiveAt` inchangé), le compte est supprimé comme à sa
 *      demande (shared/eraseAccount.ts).
 * Garde-fous : plafond par exécution ; état du compte RELU juste avant toute
 * action (un membre revenu entre-temps n'est jamais touché) ; comptes
 * administrateur jamais purgés (et, si le compte d'authentification ne peut
 * pas être lu, le compte est ignoré plutôt que traité) ; parcours par pages
 * pour ne pas rester bloqué sur les mêmes comptes.
 *
 * La date d'activité (`lastActiveAt`) est écrite par recordActivity.ts à
 * chaque session ; un compte qui n'en a aucune (abandonné avant d'arriver à
 * l'écran principal) n'est pas couvert par cette purge.
 */
const DAY_MS = 24 * 60 * 60 * 1000;
const PAGE_SIZE = 100;
const MAX_PAGES = 10;

export const purgeInactiveAccounts = onSchedule(
  { schedule: "every 24 hours", region: REGION, timeoutSeconds: 540 },
  async () => {
    const db = getFirestore();
    const now = Date.now();
    const warnCutoff = now - INACTIVE_ACCOUNT_WARNING_MONTHS * 30.44 * DAY_MS;

    let handled = 0;
    let last: FirebaseFirestore.QueryDocumentSnapshot | undefined;
    for (let page = 0; page < MAX_PAGES && handled < INACTIVE_PURGE_MAX_PER_RUN; page += 1) {
      let query = db
        .collection("user_status")
        .where("lastActiveAt", "<=", Timestamp.fromMillis(warnCutoff))
        .orderBy("lastActiveAt", "asc")
        .limit(PAGE_SIZE);
      if (last) query = query.startAfter(last);
      const snap = await query.get();
      if (snap.empty) break;
      last = snap.docs[snap.docs.length - 1];

      for (const doc of snap.docs) {
        if (handled >= INACTIVE_PURGE_MAX_PER_RUN) break;
        try {
          handled += await processAccount(doc.id, now, warnCutoff);
        } catch (err) {
          // eslint-disable-next-line no-console
          console.error("purgeInactiveAccounts: traitement impossible, retenté demain", { uid: doc.id, err });
        }
      }
      if (snap.size < PAGE_SIZE) break;
    }
  },
);

/** Traite un compte ; renvoie 1 si une action (avertissement ou suppression) a été faite. */
async function processAccount(uid: string, now: number, warnCutoff: number): Promise<number> {
  const db = getFirestore();
  const statusRef = db.collection("user_status").doc(uid);

  // Compte administrateur : jamais purgé. Seule l'absence du compte
  // d'authentification est tolérée ; toute autre erreur (réseau, quota) fait
  // ignorer le compte aujourd'hui plutôt que de risquer de purger un admin.
  let authUser: Awaited<ReturnType<ReturnType<typeof getAuth>["getUser"]>> | null = null;
  try {
    authUser = await getAuth().getUser(uid);
  } catch (err) {
    if ((err as { code?: string }).code !== "auth/user-not-found") throw err;
  }
  if (authUser?.customClaims?.admin === true) return 0;

  // État relu à l'instant : l'instantané de la requête peut dater de
  // plusieurs minutes, or une suppression est irréversible.
  const fresh = (await statusRef.get()).data();
  const lastActiveMs = (fresh?.lastActiveAt as Timestamp | undefined)?.toMillis();
  if (lastActiveMs === undefined || lastActiveMs > warnCutoff) return 0; // revenu entre-temps

  let warnedAt = (fresh?.inactivityWarnedAt as Timestamp | undefined)?.toMillis();
  // Un avertissement antérieur à la dernière activité est périmé.
  if (warnedAt !== undefined && warnedAt < lastActiveMs) warnedAt = undefined;

  // Donnée orpheline (plus aucun compte d'authentification) : personne à
  // prévenir, on la supprime.
  if (authUser === null) {
    await eraseAccount(uid);
    return 1;
  }

  if (warnedAt === undefined) {
    const delivered = await sendPushToUser(
      uid,
      {
        title: "Ton compte MERUT est inactif",
        body: `Sans connexion de ta part d'ici ${INACTIVE_ACCOUNT_GRACE_DAYS} jours, ton compte et tes données seront supprimés.`,
      },
      { type: "inactivity_warning" },
    );
    if (delivered > 0) {
      await statusRef.update({ inactivityWarnedAt: FieldValue.serverTimestamp() });
      return 1;
    }
    // Aucun appareil atteint : pas de compte à rebours, donc pas de suppression.
    await statusRef.update({ inactivityWarnUndeliveredAt: FieldValue.serverTimestamp() });
    return 0;
  }

  if (now - warnedAt >= INACTIVE_ACCOUNT_GRACE_DAYS * DAY_MS) {
    await eraseAccount(uid);
    return 1;
  }
  return 0;
}
