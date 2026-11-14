import { hasValidConsent, requireConsent } from "../shared/consent";
import { HttpsError } from "firebase-functions/v2/https";
import { onCall } from "../shared/callable";
import { getFirestore } from "firebase-admin/firestore";

import { REGION } from "../config";
import { ENFORCE_APP_CHECK } from "../shared/appCheck";

/**
 * Qui m'a liké / mes likes (cahier des charges section 4.5). "Qui m'a
 * liké" en détail est une fonctionnalité Premium (section 5) — tant que
 * Premium n'est pas construit, personne n'y a accès, seul le nombre est
 * communiqué (docs/suivi-developpement.md).
 */
export const getLikes = onCall({ region: REGION, enforceAppCheck: ENFORCE_APP_CHECK }, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Connexion requise.");
  }
  const uid = request.auth.uid;
  const db = getFirestore();

  const [receivedSnap, sentSnap, statusSnap] = await Promise.all([
    db.collection("swipes").where("toUid", "==", uid).get(),
    db.collection("swipes").where("fromUid", "==", uid).get(),
    db.collection("user_status").doc(uid).get(),
  ]);

  const isLike = (action: string) => action === "like" || action === "super_like";

  const likersUids = new Set<string>();
  for (const doc of receivedSnap.docs) {
    const data = doc.data();
    if (isLike(data.action)) likersUids.add(data.fromUid);
  }
  const myLikeUids: string[] = [];
  for (const doc of sentSnap.docs) {
    const data = doc.data();
    if (isLike(data.action)) myLikeUids.push(data.toUid);
  }

  // Un like devenu match n'a plus sa place dans "Likes" — il vit dans
  // Messages (docs/regles-du-projet.md, section matchs/messagerie).
  // Un blocage (dans un sens ou dans l'autre) exclut totalement la paire
  // des deux listes (docs/suivi-developpement.md section du 11/11/2026).
  // Un seul lot de lectures plutôt qu'une par une.
  const allTargets = [...new Set([...likersUids, ...myLikeUids])];
  const matchedUids = new Set<string>();
  const blockedUids = new Set<string>();
  if (allTargets.length > 0) {
    const pairIds = allTargets.map((target) => [uid, target].sort().join("_"));
    const [matchSnaps, blockSnaps] = await Promise.all([
      db.getAll(...pairIds.map((id) => db.collection("matches").doc(id))),
      db.getAll(...pairIds.map((id) => db.collection("blocks").doc(id))),
    ]);
    matchSnaps.forEach((snap, i) => {
      if (snap.exists) matchedUids.add(allTargets[i]);
    });
    blockSnaps.forEach((snap, i) => {
      if (snap.exists) blockedUids.add(allTargets[i]);
    });
  }

  const likersWithoutMatch = [...likersUids].filter((u) => !matchedUids.has(u) && !blockedUids.has(u));
  const myLikesWithoutMatch = myLikeUids.filter((u) => !matchedUids.has(u) && !blockedUids.has(u));
  requireConsent(statusSnap.data());
  const isPremium = statusSnap.data()?.isPremium === true;

  // Les deux listes sont indépendantes l'une de l'autre : on les
  // récupère en parallèle plutôt que l'une après l'autre.
  const [likesReceived, myLikes] = await Promise.all([
    isPremium ? fetchMiniProfiles(db, likersWithoutMatch) : Promise.resolve([]),
    fetchMiniProfiles(db, myLikesWithoutMatch),
  ]);

  return {
    likesReceivedCount: likersWithoutMatch.length,
    likesReceived,
    myLikes,
    isPremium,
  };
});

async function fetchMiniProfiles(db: ReturnType<typeof getFirestore>, uids: string[]) {
  if (uids.length === 0) return [];

  const [profileSnaps, statusSnaps] = await Promise.all([
    db.getAll(...uids.map((id) => db.collection("users").doc(id))),
    db.getAll(...uids.map((id) => db.collection("user_status").doc(id))),
  ]);

  const result: { uid: string; displayName: string; age: number; city: string; isVerified: boolean }[] = [];
  for (let i = 0; i < profileSnaps.length; i += 1) {
    const profileSnap = profileSnaps[i];
    if (!profileSnap.exists) continue;
    // Un profil suspendu/rejeté depuis ne doit plus apparaître dans les
    // likes d'un autre membre, même si le swipe existe toujours en base
    // (même règle que Découvrir, docs/architecture-technique.md).
    if (statusSnaps[i].data()?.filtrageStatus !== "active") continue;
    // Sans consentement art. 9 valide, le membre n'est montré à personne.
    if (!hasValidConsent(statusSnaps[i].data())) continue;

    const data = profileSnap.data()!;
    // `age` est calculé une fois par saveProfil.ts (règlement permanent
    // section 17, 12/11/2026 : birthDate n'est plus jamais publique) —
    // un profil qui n'a jamais encore resauvegardé après ce correctif
    // n'en aurait pas ; ignoré plutôt que planté/affiché avec un âge
    // inventé côté client (même raisonnement que pour les comptes
    // suspendus juste au-dessus).
    if (typeof data.age !== "number") continue;
    result.push({
      uid: profileSnap.id,
      displayName: data.displayName,
      age: data.age,
      city: data.city,
      isVerified: statusSnaps[i].data()?.isVerified === true,
    });
  }
  return result;
}
