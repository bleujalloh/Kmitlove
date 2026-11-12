import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore } from "firebase-admin/firestore";

import {
  REGION,
  DISCOVER_CANDIDATE_POOL_SIZE,
  DISCOVER_CANDIDATES_RETURNED,
  INACTIVE_ACCOUNT_DAYS,
  MIN_APPROVED_PHOTOS_TO_BE_DISCOVERABLE,
  ONLINE_THRESHOLD_MINUTES,
} from "../config";
import { distanceKm } from "../shared/distance";
import { computeProfileCompletionPercent } from "../shared/profileCompletion";

interface DiscoverFilters {
  minAge?: number;
  maxAge?: number;
  maxDistanceKm?: number;
  // Filtre pays/ville (docs/suivi-developpement.md section du 11/11/2026) :
  // permet de voir des profils hors du rayon GPS, utile pour une
  // communauté répartie sur plusieurs pays — quand actif, remplace le
  // filtre de distance plutôt que de s'y ajouter (une distance en km
  // n'a pas de sens pour comparer deux pays différents).
  country?: string;
  city?: string;
}

const MAX_LOCATION_FILTER_LENGTH = 60;

/**
 * Génère un paquet de candidats pour l'écran Découvrir (cahier des
 * charges section 4.4). Filtrage réciproque des préférences, exclusion
 * des profils déjà swipés et des comptes non activés, filtres d'âge et
 * de distance (docs/regles-complementaires-concurrents.md section 3) —
 * jamais côté client (docs/architecture-technique.md section 4).
 */
export const getDiscoverCandidates = onCall({ region: REGION }, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Connexion requise.");
  }
  const uid = request.auth.uid;
  const db = getFirestore();
  const filters = (request.data ?? {}) as DiscoverFilters;

  const [mySnap, myStatusSnap] = await Promise.all([
    db.collection("users").doc(uid).get(),
    db.collection("user_status").doc(uid).get(),
  ]);
  const myProfil = mySnap.data();
  if (!myProfil) {
    throw new HttpsError("failed-precondition", "Profil manquant.");
  }
  const mySeekingGenders: string[] = myProfil.seekingGenders ?? [];
  const myGender: string = myProfil.gender;
  if (mySeekingGenders.length === 0) {
    return { candidates: [] };
  }

  // `age` est désormais calculé une fois par saveProfil.ts et stocké
  // directement sur le document public (règlement permanent section 17,
  // 12/11/2026 : la date de naissance exacte n'est plus jamais exposée,
  // même sur son propre document) — jamais recalculé ici à partir d'un
  // `birthDate` qui n'existe plus sur `users/{uid}`. Échec explicite
  // plutôt qu'un NaN silencieux (minAge/maxAge deviendraient NaN, et
  // Découvrir renverrait toujours une liste vide sans jamais expliquer
  // pourquoi) si ce profil n'a jamais resauvegardé depuis ce correctif.
  if (typeof myProfil.age !== "number") {
    throw new HttpsError("failed-precondition", "Profil incomplet, réenregistre-le.");
  }
  const myAge = myProfil.age;
  // Par défaut ±8 ans autour de son âge (docs/regles-complementaires-concurrents.md
  // section 3), remplaçable par les filtres manuels envoyés par le client.
  const minAge = filters.minAge ?? myAge - 8;
  const maxAge = filters.maxAge ?? myAge + 8;
  const maxDistance = filters.maxDistanceKm ?? 100;

  const countryFilter = typeof filters.country === "string" && filters.country.trim().length > 0
    ? filters.country.trim().slice(0, MAX_LOCATION_FILTER_LENGTH).toLowerCase()
    : null;
  const cityFilter = typeof filters.city === "string" && filters.city.trim().length > 0
    ? filters.city.trim().slice(0, MAX_LOCATION_FILTER_LENGTH).toLowerCase()
    : null;
  const hasLocationFilter = countryFilter !== null;

  const myStatus = myStatusSnap.data();
  const myLat = myStatus?.locationLat as number | undefined;
  const myLng = myStatus?.locationLng as number | undefined;
  const hasMyLocation = !hasLocationFilter && typeof myLat === "number" && typeof myLng === "number";

  const mySwipesSnap = await db.collection("swipes").where("fromUid", "==", uid).get();
  const alreadySwiped = new Set(mySwipesSnap.docs.map((doc) => doc.data().toUid as string));

  let poolQuery = db
    .collection("users")
    .where("gender", "in", mySeekingGenders.slice(0, 10)) as FirebaseFirestore.Query;
  if (countryFilter !== null) {
    poolQuery = poolQuery.where("countryLower", "==", countryFilter);
    if (cityFilter !== null) {
      poolQuery = poolQuery.where("cityLower", "==", cityFilter);
    }
  }
  const poolSnap = await poolQuery.limit(DISCOVER_CANDIDATE_POOL_SIZE).get();

  // Pré-filtrage sans lecture supplémentaire (self, déjà swipé,
  // préférence réciproque, âge), pour ne lire le statut que des profils
  // potentiellement éligibles — en un seul lot plutôt qu'un par un.
  const preFiltered = poolSnap.docs.filter((doc) => {
    if (doc.id === uid) return false;
    if (alreadySwiped.has(doc.id)) return false;
    const data = doc.data();
    const candidateSeekingGenders: string[] = data.seekingGenders ?? [];
    if (!candidateSeekingGenders.includes(myGender)) return false;
    // Un profil qui n'a jamais resauvegardé depuis ce correctif n'aurait
    // pas encore `age` — exclu plutôt que planté/inclus avec un âge
    // inventé (même raisonnement que getLikes.ts).
    if (typeof data.age !== "number") return false;
    return data.age >= minAge && data.age <= maxAge;
  });

  const statusSnaps = preFiltered.length > 0
    ? await db.getAll(...preFiltered.map((doc) => db.collection("user_status").doc(doc.id)))
    : [];

  const inactiveCutoff = Date.now() - INACTIVE_ACCOUNT_DAYS * 24 * 60 * 60 * 1000;
  const now = Date.now();
  type StatusPassed = {
    doc: FirebaseFirestore.QueryDocumentSnapshot;
    status: FirebaseFirestore.DocumentData;
    distance: number | null;
  };
  const statusPassed: StatusPassed[] = [];

  // On évalue TOUS les profils pré-filtrés (pas de sortie anticipée dès
  // qu'on atteint le quota) pour pouvoir ensuite faire remonter les
  // profils boostés — sinon le Boost Premium n'aurait aucun effet
  // observable (cahier des charges section 5).
  for (let i = 0; i < preFiltered.length; i += 1) {
    const doc = preFiltered[i];
    const status = statusSnaps[i].data();
    if (status?.filtrageStatus !== "active") continue;

    // Masquage des comptes inactifs depuis 30 jours
    // (docs/regles-complementaires-concurrents.md section 3).
    const lastActiveAt = status?.lastActiveAt?.toMillis?.();
    if (lastActiveAt && lastActiveAt < inactiveCutoff) continue;

    let distance: number | null = null;
    if (hasMyLocation && typeof status?.locationLat === "number" && typeof status?.locationLng === "number") {
      distance = distanceKm(myLat!, myLng!, status.locationLat, status.locationLng);
      if (distance > maxDistance) continue;
    }

    statusPassed.push({ doc, status, distance });
  }

  // Nombre de photos APPROUVÉES de chaque candidat restant — jamais
  // déclaré par le candidat lui-même : ce compte vient de la sous-
  // collection photos, dont seul un admin (ou l'approbation automatique
  // planifiée) peut faire passer le statut à "approved" (firestore.rules).
  // En dessous du minimum, le profil est exclu de Découvrir, pas
  // seulement moins bien classé (docs/suivi-developpement.md, section du
  // 11/11/2026).
  //
  // Limite assumée et non corrigée ici : une requête d'agrégation par
  // candidat restant plutôt qu'un seul round-trip groupé (ex. collectionGroup
  // + dénormalisation du compte sur user_status) — raisonnable tant que
  // DISCOVER_CANDIDATE_POOL_SIZE reste borné, même raisonnement que le
  // commentaire équivalent sur compatScoreWithProvider côté client
  // (compat_controller.dart).
  //
  // Deux compteurs distincts dérivés d'UNE seule lecture par candidat
  // (demande explicite du propriétaire, 11/11/2026 ; une requête
  // d'agrégation séparée pour chacun aurait doublé le nombre de requêtes
  // Firestore de ce chemin déjà coûteux — trouvé par revue de code) : le
  // nombre total de photos approuvées reste utilisé pour le calcul de
  // complétion de profil (shared/profileCompletion.ts, inchangé) ; le
  // nombre de photos approuvées AVEC VISAGE DÉTECTÉ (`hasFace`,
  // moderatePhotoContent.ts) devient la vraie condition de visibilité
  // ci-dessous — un profil avec 2 photos approuvées mais sans aucun
  // visage détectable ne doit pas apparaître dans Découvrir. Le nombre
  // de photos par membre reste petit, donc lire les documents complets
  // plutôt qu'un simple compte n'ajoute pas de coût significatif.
  const approvedPhotoDocs = await Promise.all(
    statusPassed.map(({ doc }) =>
      db.collection("users").doc(doc.id).collection("photos").where("status", "==", "approved").get(),
    ),
  );

  // Un blocage (dans un sens ou dans l'autre, l'identifiant de paire ne
  // dépend pas de qui a bloqué qui) exclut totalement Découvrir, pas
  // seulement un badge — docs/suivi-developpement.md section du
  // 11/11/2026.
  // `Firestore.getAll()` exige au moins un argument — sans ce garde-fou,
  // Découvrir plante entièrement ("impossible de charger les profils")
  // dès que personne ne passe les filtres précédents, au lieu de
  // simplement renvoyer une liste vide (bug remonté sur appareil réel
  // le 11/11, confirmé par les logs Cloud Functions).
  const blockSnaps = statusPassed.length > 0
    ? await db.getAll(
        ...statusPassed.map(({ doc }) => db.collection("blocks").doc([uid, doc.id].sort().join("_"))),
      )
    : [];

  const eligible: (Record<string, unknown> & { _boosted: boolean; _completionPercent: number })[] = [];
  for (let i = 0; i < statusPassed.length; i += 1) {
    const { doc, status, distance } = statusPassed[i];
    if (blockSnaps[i].exists) continue;
    const approvedPhotoCount = approvedPhotoDocs[i].size;
    const approvedFacePhotoCount = approvedPhotoDocs[i].docs.filter((p) => p.data().hasFace === true).length;
    if (approvedFacePhotoCount < MIN_APPROVED_PHOTOS_TO_BE_DISCOVERABLE) continue;

    const boostedUntil = status?.boostedUntil?.toMillis?.() as number | undefined;
    const lastActiveAtMillis = status?.lastActiveAt?.toMillis?.() as number | undefined;
    const data = doc.data();
    eligible.push({
      uid: doc.id,
      displayName: data.displayName,
      age: data.age,
      city: data.city,
      country: data.country,
      bio: data.bio,
      interests: data.interests ?? [],
      relationshipIntent: data.relationshipIntent,
      // Fiche profil étendue (maquette visuelle validée le 12/11/2026,
      // révélation complète au scroll sur la carte Découvrir) — `null`
      // quand non renseigné, jamais une valeur inventée côté client.
      profession: data.profession ?? null,
      heightCm: data.heightCm ?? null,
      educationLevel: data.educationLevel ?? null,
      childrenStatus: data.childrenStatus ?? null,
      smokingHabit: data.smokingHabit ?? null,
      drinkingHabit: data.drinkingHabit ?? null,
      distanceKm: distance === null ? null : Math.round(distance),
      isVerified: status?.isVerified === true,
      isOnline:
        typeof lastActiveAtMillis === "number" &&
        now - lastActiveAtMillis <= ONLINE_THRESHOLD_MINUTES * 60 * 1000,
      _boosted: typeof boostedUntil === "number" && boostedUntil > now,
      // Les profils boostés passent toujours devant (cahier des charges
      // section 5) ; à boost égal, un profil plus complet (bio, centres
      // d'intérêt, photos, vérification...) remonte — même calcul que
      // l'onglet Profil (shared/profileCompletion.ts), jamais une note
      // recalculée différemment ici.
      _completionPercent: computeProfileCompletionPercent(data, approvedPhotoCount, status?.isVerified === true),
    });
  }

  eligible.sort((a, b) => {
    const boostDiff = Number(b._boosted) - Number(a._boosted);
    if (boostDiff !== 0) return boostDiff;
    return b._completionPercent - a._completionPercent;
  });
  const candidates = eligible
    .slice(0, DISCOVER_CANDIDATES_RETURNED)
    .map(({ _boosted, _completionPercent, ...rest }) => rest);

  return { candidates };
});
