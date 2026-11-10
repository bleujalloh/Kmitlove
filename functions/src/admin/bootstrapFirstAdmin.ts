import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getAuth } from "firebase-admin/auth";
import { getFirestore, FieldValue } from "firebase-admin/firestore";

import { REGION } from "../config";
import { logAdminAction } from "../shared/adminLog";

/**
 * Permet au tout premier appelant de devenir administrateur — ensuite
 * définitivement verrouillée dès qu'un admin existe, pour qu'on ne
 * puisse jamais "s'auto-nommer admin" après coup (docs/suivi-developpement.md,
 * cahier des charges section 6 : rôles et permissions distincts).
 * Les admins suivants sont ajoutés manuellement par un admin existant
 * (hors de cette fonction, volontairement — pas encore d'écran pour ça).
 *
 * Le verrou est posé via une transaction Firestore (pas une simple
 * lecture puis écriture) : sans ça, deux appels simultanés pourraient
 * tous les deux constater qu'aucun admin n'existe encore et devenir
 * admin tous les deux, cassant l'invariant "un seul premier admin"
 * (même raisonnement que functions/src/premium/useJeton.ts).
 */
export const bootstrapFirstAdmin = onCall({ region: REGION }, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Connexion requise.");
  }
  const uid = request.auth.uid;
  const db = getFirestore();
  const lockRef = db.collection("app_config").doc("admin_bootstrap");

  const wonRace = await db.runTransaction(async (tx) => {
    const snap = await tx.get(lockRef);
    if (snap.exists) return false;
    tx.set(lockRef, { claimedBy: uid, claimedAt: FieldValue.serverTimestamp() });
    return true;
  });

  if (!wonRace) {
    throw new HttpsError(
      "already-exists",
      "Un administrateur existe déjà, impossible de prendre ce rôle automatiquement.",
    );
  }

  try {
    await getAuth().setCustomUserClaims(uid, { admin: true });
  } catch (error) {
    // Si la pose du rôle échoue après que le verrou a été posé, on le
    // retire : sinon plus personne ne pourrait jamais devenir admin,
    // puisque le projet resterait bloqué avec un verrou pris mais aucun
    // admin réel.
    await lockRef.delete();
    throw new HttpsError("internal", "Impossible d'attribuer le rôle admin, réessaie.");
  }

  // Événement de sécurité à toujours garder trace de : qui est devenu
  // admin et quand (section 4.8 — journalisation des actions admin).
  await logAdminAction(db, { adminUid: uid, action: "first_admin_bootstrapped", targetUid: uid });

  return { ok: true };
});
