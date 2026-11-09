import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore } from "firebase-admin/firestore";

import {
  REGION,
  DISCOVER_CANDIDATE_POOL_SIZE,
  DISCOVER_CANDIDATES_RETURNED,
  INACTIVE_ACCOUNT_DAYS,
} from "../config";

function computeAge(birthDateIso: string): number {
  const birth = new Date(birthDateIso);
  const now = new Date();
  let age = now.getFullYear() - birth.getFullYear();
  if (
    now.getMonth() < birth.getMonth() ||
    (now.getMonth() === birth.getMonth() && now.getDate() < birth.getDate())
  ) {
    age -= 1;
  }
  return age;
}

/**
 * Génère un paquet de candidats pour l'écran Découvrir (cahier des
 * charges section 4.4). Filtrage réciproque des préférences, exclusion
 * des profils déjà swipés et des comptes non activés — jamais côté
 * client (docs/architecture-technique.md section 4).
 */
export const getDiscoverCandidates = onCall({ region: REGION }, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Connexion requise.");
  }
  const uid = request.auth.uid;
  const db = getFirestore();

  const mySnap = await db.collection("users").doc(uid).get();
  const myProfil = mySnap.data();
  if (!myProfil) {
    throw new HttpsError("failed-precondition", "Profil manquant.");
  }
  const mySeekingGenders: string[] = myProfil.seekingGenders ?? [];
  const myGender: string = myProfil.gender;
  if (mySeekingGenders.length === 0) {
    return { candidates: [] };
  }

  const mySwipesSnap = await db.collection("swipes").where("fromUid", "==", uid).get();
  const alreadySwiped = new Set(mySwipesSnap.docs.map((doc) => doc.data().toUid as string));

  const poolSnap = await db
    .collection("users")
    .where("gender", "in", mySeekingGenders.slice(0, 10))
    .limit(DISCOVER_CANDIDATE_POOL_SIZE)
    .get();

  // Pré-filtrage sans lecture supplémentaire (self, déjà swipé,
  // préférence réciproque), pour ne lire le statut que des profils
  // potentiellement éligibles — en un seul lot plutôt qu'un par un.
  const preFiltered = poolSnap.docs.filter((doc) => {
    if (doc.id === uid) return false;
    if (alreadySwiped.has(doc.id)) return false;
    const candidateSeekingGenders: string[] = doc.data().seekingGenders ?? [];
    return candidateSeekingGenders.includes(myGender);
  });

  const statusSnaps = preFiltered.length > 0
    ? await db.getAll(...preFiltered.map((doc) => db.collection("user_status").doc(doc.id)))
    : [];

  const inactiveCutoff = Date.now() - INACTIVE_ACCOUNT_DAYS * 24 * 60 * 60 * 1000;
  const candidates: Record<string, unknown>[] = [];

  for (let i = 0; i < preFiltered.length; i += 1) {
    if (candidates.length >= DISCOVER_CANDIDATES_RETURNED) break;
    const doc = preFiltered[i];
    const status = statusSnaps[i].data();
    if (status?.filtrageStatus !== "active") continue;

    // Masquage des comptes inactifs (docs/regles-complementaires-concurrents.md
    // section 3). lastActiveAt n'est pas encore alimenté par l'app (pas de
    // suivi de connexion), donc en son absence on n'exclut personne — à
    // revoir une fois ce suivi ajouté, voir docs/suivi-developpement.md.
    const lastActiveAt = status?.lastActiveAt?.toMillis?.();
    if (lastActiveAt && lastActiveAt < inactiveCutoff) continue;

    const data = doc.data();
    candidates.push({
      uid: doc.id,
      displayName: data.displayName,
      age: computeAge(data.birthDate),
      city: data.city,
      country: data.country,
      bio: data.bio,
      interests: data.interests ?? [],
      relationshipIntent: data.relationshipIntent,
    });
  }

  return { candidates };
});
