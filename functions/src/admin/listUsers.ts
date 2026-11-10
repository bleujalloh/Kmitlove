import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore } from "firebase-admin/firestore";

import { REGION } from "../config";
import { requireAdmin } from "../shared/requireAdmin";
import { logAdminAction } from "../shared/adminLog";

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
      // Distingue une suspension temporaire d'un bannissement définitif —
      // sans ça, le bouton "Réactiver" de l'espace admin aurait l'air
      // d'annuler la même chose dans les deux cas, alors qu'un
      // bannissement est une décision bien plus lourde.
      sanctionLevel: status?.sanctionLevel ?? "none",
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

  // Lecture-vérification-écriture dans une transaction, même raisonnement
  // que admin/resolveSanctionAppeal.ts et admin/moderationRequests.ts :
  // sans elle, un double clic (suspendre puis réactiver juste après, ou
  // l'inverse) pourrait lire le même état obsolète deux fois et laisser
  // le compte dans l'état contraire à la dernière action voulue par
  // l'admin.
  const changed = await db.runTransaction<boolean>(async (tx) => {
    const snap = await tx.get(statusRef);
    const existing = snap.data();
    const alreadySuspended = existing?.filtrageStatus === "suspended";
    // Appel sans effet si l'état demandé est déjà l'état actuel — jamais
    // réécrire preSuspensionStatus/sanctionLevel dans ce cas (ça
    // écraserait preSuspensionStatus par "suspended" lui-même, ou
    // rétrograderait un "banned" en simple "suspended").
    if (suspend === alreadySuspended) {
      return false;
    }

    if (suspend) {
      // On garde en mémoire le statut réel d'avant la suspension (actif,
      // en attente de révision...) pour ne jamais le perdre — la
      // réactivation doit le restaurer, pas supposer que tout le monde
      // était "active" avant d'être suspendu.
      tx.set(
        statusRef,
        {
          filtrageStatus: "suspended",
          preSuspensionStatus: existing?.filtrageStatus ?? "active",
          suspendedBy: adminUid,
          // sanctionLevel/suspendedUntil tenus synchronisés avec
          // filtrageStatus dès cette écriture (plutôt que dérivés plus
          // tard par shared/sanctions.ts) : une suspension manuelle est
          // indéfinie (suspendedUntil=null), jamais levée par
          // liftExpiredSuspensions.ts, et reste cohérente si un
          // signalement est ensuite confirmé sur ce même compte.
          sanctionLevel: "suspended",
          suspendedUntil: null,
          // Nouvelle sanction = nouvel évènement, voir shared/sanctions.ts :
          // un délai venant du refus d'un recours contre une sanction
          // précédente ne doit pas bloquer un recours contre celle-ci.
          appealNextRetryAt: null,
        },
        { merge: true },
      );
    } else {
      const restoredStatus = existing?.preSuspensionStatus ?? "active";
      tx.set(
        statusRef,
        {
          filtrageStatus: restoredStatus,
          preSuspensionStatus: null,
          suspendedBy: null,
          // Réactiver doit effacer TOUTE trace de sanction, pas seulement
          // filtrageStatus — même raisonnement que l'approbation d'un
          // recours (admin/resolveSanctionAppeal.ts) : sinon sanctionLevel
          // resterait "suspended" sur un compte redevenu actif, bloquant
          // silencieusement toute future re-suspension (voir shared/
          // sanctions.ts) et laissant croire à tort que le compte peut
          // encore faire un recours.
          sanctionLevel: "none",
          suspendedUntil: null,
          appealPending: false,
          appealNextRetryAt: null,
        },
        { merge: true },
      );
    }

    return true;
  });

  if (changed) {
    await logAdminAction(db, { adminUid, action: suspend ? "user_suspended" : "user_reactivated", targetUid: uid });
  }

  return { ok: true };
});
