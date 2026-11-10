import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore } from "firebase-admin/firestore";

import { REGION } from "../config";
import { requireAdmin } from "../shared/requireAdmin";

interface SearchData {
  query?: string; // recherche par préfixe de displayName
}

/**
 * Liste/recherche des membres pour l'espace admin (cahier des charges
 * section 6 : "consulter les utilisateurs"). Renvoie le profil public
 * ET le statut (filtrage, Premium, suspension) croisés, jamais
 * accessible depuis le client autrement.
 */
export const adminListUsers = onCall({ region: REGION }, async (request) => {
  requireAdmin(request);
  const { query } = (request.data ?? {}) as SearchData;
  const db = getFirestore();

  let usersQuery = db.collection("users").orderBy("displayName").limit(50) as FirebaseFirestore.Query;
  if (query?.trim()) {
    const trimmed = query.trim();
    usersQuery = db
      .collection("users")
      .orderBy("displayName")
      .startAt(trimmed)
      .endAt(`${trimmed}`)
      .limit(50);
  }

  const usersSnap = await usersQuery.get();
  if (usersSnap.empty) return { users: [] };

  const statusSnaps = await db.getAll(
    ...usersSnap.docs.map((d) => db.collection("user_status").doc(d.id)),
  );

  const users = usersSnap.docs.map((doc, i) => {
    const data = doc.data();
    const status = statusSnaps[i].data();
    return {
      uid: doc.id,
      displayName: data.displayName,
      city: data.city,
      country: data.country,
      filtrageStatus: status?.filtrageStatus ?? null,
      isPremium: status?.isPremium === true,
      isVerified: status?.isVerified === true,
    };
  });

  return { users };
});

interface SuspendData {
  uid: string;
  suspend: boolean;
}

/** Suspendre/réactiver un compte directement (section 6 : "gérer les suspensions"). */
export const adminSetSuspension = onCall({ region: REGION }, async (request) => {
  const adminUid = requireAdmin(request);
  const { uid, suspend } = request.data as SuspendData;
  if (!uid) {
    throw new HttpsError("invalid-argument", "uid manquant.");
  }

  const db = getFirestore();
  const statusRef = db.collection("user_status").doc(uid);

  if (suspend) {
    // On garde en mémoire le statut réel d'avant la suspension (actif,
    // en attente de révision...) pour ne jamais le perdre — la
    // réactivation doit le restaurer, pas supposer que tout le monde
    // était "active" avant d'être suspendu.
    const snap = await statusRef.get();
    const previousStatus = snap.data()?.filtrageStatus ?? "active";
    await statusRef.set(
      { filtrageStatus: "suspended", preSuspensionStatus: previousStatus, suspendedBy: adminUid },
      { merge: true },
    );
  } else {
    const snap = await statusRef.get();
    const restoredStatus = snap.data()?.preSuspensionStatus ?? "active";
    await statusRef.set(
      { filtrageStatus: restoredStatus, preSuspensionStatus: null, suspendedBy: null },
      { merge: true },
    );
  }

  return { ok: true };
});
