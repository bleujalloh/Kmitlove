import { onCall } from "firebase-functions/v2/https";
import { getFirestore } from "firebase-admin/firestore";

import { REGION } from "../config";
import { ENFORCE_APP_CHECK } from "../shared/appCheck";
import { requireAdmin } from "../shared/requireAdmin";

/** Journal des actions admin (section 4.8 — journalisation). Lecture seule,
 * les 100 dernières actions tous admins confondus, les plus récentes en premier. */
export const adminListActionLogs = onCall({ region: REGION, enforceAppCheck: ENFORCE_APP_CHECK }, async (request) => {
  requireAdmin(request);
  const db = getFirestore();
  const snap = await db.collection("admin_action_logs").orderBy("at", "desc").limit(100).get();
  return { logs: snap.docs.map((d) => ({ id: d.id, ...d.data() })) };
});
