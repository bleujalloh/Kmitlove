import { HttpsError } from "firebase-functions/v2/https";
import { onCall } from "../shared/callable";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import { getStorage } from "firebase-admin/storage";

import { REGION } from "../config";
import { ENFORCE_APP_CHECK } from "../shared/appCheck";
import { requireAdmin } from "../shared/requireAdmin";
import { downloadLinkFor } from "../shared/storageLinks";
import { logAdminAction } from "../shared/adminLog";

/**
 * Liste les demandes de vérification d'identité en attente, avec une
 * URL signée temporaire (10 minutes) vers le selfie — jamais une URL
 * publique, Storage refuse la lecture à qui n'est pas le propriétaire
 * (storage.rules), donc seul l'Admin SDK peut générer ce lien ici.
 */
export const adminListIdentityVerifications = onCall({ region: REGION, enforceAppCheck: ENFORCE_APP_CHECK }, async (request) => {
  requireAdmin(request);
  const db = getFirestore();
  const snap = await db
    .collection("user_status")
    .where("identityVerificationStatus", "==", "pending")
    .limit(50)
    .get();

  // Chemin écrit par le serveur seul (submitIdentityVerification : préfixe
  // identity_verifications/{uid}/ vérifié). Lien : shared/storageLinks.ts.
  const results = await Promise.all(
    snap.docs.map(async (doc) => {
      const path = doc.data().identityVerificationStoragePath as string | undefined;
      return { uid: doc.id, url: path ? await downloadLinkFor(path) : null };
    }),
  );

  return { verifications: results };
});

interface ReviewData {
  uid: string;
  approve: boolean;
}

export const adminReviewIdentityVerification = onCall({ region: REGION, enforceAppCheck: ENFORCE_APP_CHECK }, async (request) => {
  const adminUid = requireAdmin(request);
  const { uid, approve } = request.data as ReviewData;
  if (!uid || typeof uid !== "string" || typeof approve !== "boolean") {
    throw new HttpsError("invalid-argument", "Paramètres invalides.");
  }

  const db = getFirestore();
  const statusRef = db.collection("user_status").doc(uid);

  // Minimisation (RGPD, docs/rgpd-registre-des-traitements.md §7) : le selfie
  // n'a plus aucune utilité une fois la décision prise — seul le résultat
  // (`isVerified`, statut, date, décideur) est conservé. Fichier d'abord : si
  // sa suppression échoue, la décision n'est pas enregistrée et le modérateur
  // peut réessayer, au lieu de laisser un selfie sans plus aucune référence.
  const currentStatus = (await statusRef.get()).data();
  if (currentStatus?.identityVerificationStatus !== "pending") {
    throw new HttpsError("failed-precondition", "Aucune vérification en attente pour ce membre.");
  }
  // Tout le dossier du membre, pas seulement le fichier référencé : il peut en
  // avoir déposé d'autres (storage.rules n'impose aucun nom de fichier).
  await getStorage().bucket().deleteFiles({ prefix: `identity_verifications/${uid}/` });

  await statusRef.set(
    {
      identityVerificationStatus: approve ? "verified" : "rejected",
      isVerified: approve,
      identityVerificationReviewedAt: FieldValue.serverTimestamp(),
      identityVerificationReviewedBy: adminUid,
      identityVerificationStoragePath: FieldValue.delete(),
    },
    { merge: true },
  );

  await logAdminAction(db, {
    adminUid,
    action: approve ? "identity_verified" : "identity_rejected",
    targetUid: uid,
  });

  return { ok: true };
});
