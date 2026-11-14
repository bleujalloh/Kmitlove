import { HttpsError } from "firebase-functions/v2/https";
import { getFirestore } from "firebase-admin/firestore";

import { REGION } from "../config";
import { ENFORCE_APP_CHECK } from "../shared/appCheck";
import { onCall } from "../shared/callable";
import { hasValidConsent } from "../shared/consent";
import { enforceRateLimit } from "../shared/rateLimit";
import { requireApprovedOrganizer } from "../shared/requireApprovedOrganizer";

const MIN_QUERY_LENGTH = 3;
const MAX_QUERY_LENGTH = 40;
const MAX_RESULTS = 10;
// Une recherche par prénom ne doit pas permettre de parcourir toute la base
// de membres : débit limité (shared/rateLimit.ts) et résultats plafonnés.
const SEARCH_RATE_LIMITS = [{ key: "invite_search_min", limit: 20, windowSeconds: 60 }];

function capitalized(text: string): string {
  return text.charAt(0).toUpperCase() + text.slice(1).toLowerCase();
}

/**
 * Recherche d'un membre PAR PRÉNOM, pour qu'un organisateur invite quelqu'un à
 * un événement sur invitation. Avant, l'organisateur devait saisir à la main
 * l'identifiant technique du membre — inutilisable en pratique (constaté le
 * 14/11/2026).
 *
 * Réservée aux organisateurs approuvés. Ne renvoie que des membres que
 * l'organisateur pourrait déjà croiser dans l'appli : compte actif,
 * consentement valide, profil non masqué, aucun blocage dans un sens ou dans
 * l'autre — et seulement prénom, âge et ville, jamais un identifiant autre que
 * celui nécessaire pour inviter.
 */
export const searchMembersToInvite = onCall({ region: REGION, enforceAppCheck: ENFORCE_APP_CHECK }, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Connexion requise.");
  }
  const uid = request.auth.uid;
  const { query } = request.data as { query?: unknown };
  const text = typeof query === "string" ? query.trim() : "";
  if (text.length < MIN_QUERY_LENGTH || text.length > MAX_QUERY_LENGTH) {
    throw new HttpsError("invalid-argument", `Tape au moins ${MIN_QUERY_LENGTH} lettres du prénom.`);
  }

  const db = getFirestore();
  await requireApprovedOrganizer(db, uid);
  await enforceRateLimit(uid, SEARCH_RATE_LIMITS);

  // Recherche par début de prénom, sensible à la casse côté Firestore : on
  // essaie la saisie telle quelle, avec majuscule initiale, en minuscules et
  // en majuscules.
  const variants = [...new Set([text, capitalized(text), text.toLowerCase(), text.toUpperCase()])];
  const found = new Map<string, FirebaseFirestore.DocumentData>();
  for (const variant of variants) {
    const snap = await db
      .collection("users")
      .where("displayName", ">=", variant)
      .where("displayName", "<=", `${variant}`)
      .limit(MAX_RESULTS * 2)
      .get();
    for (const doc of snap.docs) {
      if (doc.id !== uid) found.set(doc.id, doc.data());
    }
  }
  const ids = [...found.keys()];
  if (ids.length === 0) return { members: [] };

  const [statusSnaps, blockSnaps] = await Promise.all([
    db.getAll(...ids.map((id) => db.collection("user_status").doc(id))),
    db.getAll(...ids.map((id) => db.collection("blocks").doc([uid, id].sort().join("_")))),
  ]);

  const members: { uid: string; displayName: string; age: number | null; city: string | null }[] = [];
  ids.forEach((id, i) => {
    const status = statusSnaps[i].data();
    if (status?.filtrageStatus !== "active") return;
    if (!hasValidConsent(status)) return;
    if (status.profileHidden === true) return;
    if (blockSnaps[i].exists) return;
    const data = found.get(id)!;
    members.push({
      uid: id,
      displayName: String(data.displayName ?? ""),
      age: typeof data.age === "number" ? data.age : null,
      city: typeof data.city === "string" ? data.city : null,
    });
  });
  members.sort((a, b) => a.displayName.localeCompare(b.displayName));
  return { members: members.slice(0, MAX_RESULTS) };
});
