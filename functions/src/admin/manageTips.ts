import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore, FieldValue } from "firebase-admin/firestore";

import { REGION } from "../config";
import { ENFORCE_APP_CHECK } from "../shared/appCheck";
import { requireAdmin } from "../shared/requireAdmin";
import { logAdminAction } from "../shared/adminLog";

const TIP_CATEGORIES = ["culture", "relation", "securite", "communaute"] as const;
const MAX_TITLE_LENGTH = 120;
const MAX_BODY_LENGTH = 2000;

interface CreateTipData {
  title: string;
  body: string;
  category: string;
}

/**
 * Contenu éditorial de l'onglet "Conseils" (maquette visuelle validée le
 * 11/11/2026) — rédigé exclusivement par un administrateur, jamais par
 * les membres : il n'y a pas de modération à faire sur du contenu que
 * seul un admin peut créer.
 */
export const adminCreateTip = onCall({ region: REGION, enforceAppCheck: ENFORCE_APP_CHECK }, async (request) => {
  const adminUid = requireAdmin(request);
  const { title, body, category } = request.data as CreateTipData;
  if (!title?.trim() || !body?.trim()) {
    throw new HttpsError("invalid-argument", "Titre et contenu requis.");
  }
  if (title.length > MAX_TITLE_LENGTH || body.length > MAX_BODY_LENGTH) {
    throw new HttpsError("invalid-argument", "Titre ou contenu trop long.");
  }
  if (!TIP_CATEGORIES.includes(category as never)) {
    throw new HttpsError("invalid-argument", "Catégorie invalide.");
  }

  const db = getFirestore();
  const tipRef = await db.collection("community_tips").add({
    title: title.trim(),
    body: body.trim(),
    category,
    createdAt: FieldValue.serverTimestamp(),
    createdBy: adminUid,
  });

  await logAdminAction(db, { adminUid, action: "tip_created", details: { tipId: tipRef.id } });
  return { ok: true, tipId: tipRef.id };
});

export const adminDeleteTip = onCall({ region: REGION, enforceAppCheck: ENFORCE_APP_CHECK }, async (request) => {
  const adminUid = requireAdmin(request);
  const { tipId } = request.data as { tipId: string };
  if (!tipId) {
    throw new HttpsError("invalid-argument", "tipId manquant.");
  }

  const db = getFirestore();
  await db.collection("community_tips").doc(tipId).delete();
  await logAdminAction(db, { adminUid, action: "tip_deleted", details: { tipId } });
  return { ok: true };
});
