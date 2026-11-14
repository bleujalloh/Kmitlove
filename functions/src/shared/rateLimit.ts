import { HttpsError } from "firebase-functions/v2/https";
import { getFirestore, Timestamp } from "firebase-admin/firestore";

/**
 * Limite de fréquence par membre, appliquée côté serveur (jamais côté
 * client seulement) : un script qui appellerait directement les fonctions ne
 * peut donc pas inonder la messagerie ni la file de modération.
 *
 * Principe : un compteur par (membre, règle) dans `rate_limits/{uid}_{clé}`,
 * sur fenêtre fixe. Document inaccessible aux clients (firestore.rules :
 * « tout le reste est refusé »), supprimé avec le compte (eraseAccount).
 * Toutes les règles d'un même appel sont vérifiées puis incrémentées dans
 * UNE transaction : un appel refusé ne consomme aucun quota.
 */
export interface RateLimitRule {
  /** Identifiant court et stable de la règle, ex. « msg_min ». */
  key: string;
  limit: number;
  windowSeconds: number;
}

export async function enforceRateLimit(uid: string, rules: RateLimitRule[]): Promise<void> {
  const db = getFirestore();
  const now = Date.now();
  await db.runTransaction(async (tx) => {
    const refs = rules.map((r) => db.collection("rate_limits").doc(`${uid}_${r.key}`));
    const snaps = await Promise.all(refs.map((ref) => tx.get(ref)));

    const next: { start: number; count: number }[] = [];
    for (let i = 0; i < rules.length; i += 1) {
      const rule = rules[i];
      const windowMs = rule.windowSeconds * 1000;
      const data = snaps[i].data();
      let start = (data?.windowStart as Timestamp | undefined)?.toMillis() ?? 0;
      let count = (data?.count as number | undefined) ?? 0;
      if (now - start >= windowMs) {
        start = now;
        count = 0;
      }
      if (count >= rule.limit) {
        const retryAfterSeconds = Math.max(1, Math.ceil((start + windowMs - now) / 1000));
        throw new HttpsError("resource-exhausted", "Trop de demandes, réessaie un peu plus tard.", {
          retryAfterSeconds,
        });
      }
      next.push({ start, count: count + 1 });
    }

    refs.forEach((ref, i) => {
      tx.set(ref, { uid, windowStart: Timestamp.fromMillis(next[i].start), count: next[i].count });
    });
  });
}
