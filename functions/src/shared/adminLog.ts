import { FieldValue } from "firebase-admin/firestore";
import type { Firestore } from "firebase-admin/firestore";

/**
 * Journalise une action admin (section 4.8 — journalisation des actions
 * admin). Écriture seule depuis les Cloud Functions admin : jamais
 * modifiable ni lisible depuis le client (firestore.rules, défaut-refus),
 * seule adminListActionLogs y accède via l'Admin SDK.
 */
export async function logAdminAction(
  db: Firestore,
  params: { adminUid: string; action: string; targetUid?: string | null; details?: Record<string, unknown> },
): Promise<void> {
  await db.collection("admin_action_logs").add({
    adminUid: params.adminUid,
    action: params.action,
    targetUid: params.targetUid ?? null,
    details: params.details ?? null,
    at: FieldValue.serverTimestamp(),
  });
}
