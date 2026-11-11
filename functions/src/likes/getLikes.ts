import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore } from "firebase-admin/firestore";

import { REGION } from "../config";
import { computeAge } from "../shared/age";

/**
 * Qui m'a liké / mes likes (cahier des charges section 4.5). "Qui m'a
 * liké" en détail est une fonctionnalité Premium (section 5) — tant que
 * Premium n'est pas construit, personne n'y a accès, seul le nombre est
 * communiqué (docs/suivi-developpement.md).
 */
export const getLikes = onCall({ region: REGION }, async (request) => {
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
  // Un seul lot de lectures plutôt qu'une par une.
  const allTargets = [...new Set([...likersUids, ...myLikeUids])];
  const matchedUids = new Set<string>();
  if (allTargets.length > 0) {
    const matchRefs = allTargets.map((target) =>
      db.collection("matches").doc([uid, target].sort().join("_")),
    );
    const matchSnaps = await db.getAll(...matchRefs);
    matchSnaps.forEach((snap, i) => {
      if (snap.exists) matchedUids.add(allTargets[i]);
    });
  }

  const likersWithoutMatch = [...likersUids].filter((u) => !matchedUids.has(u));
  const myLikesWithoutMatch = myLikeUids.filter((u) => !matchedUids.has(u));
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

    const data = profileSnap.data()!;
    result.push({
      uid: profileSnap.id,
      displayName: data.displayName,
      age: computeAge(data.birthDate),
      city: data.city,
      isVerified: statusSnaps[i].data()?.isVerified === true,
    });
  }
  return result;
}
