import { HttpsError } from "firebase-functions/v2/https";
import type { Firestore } from "firebase-admin/firestore";

/**
 * Un organisateur suspendu ne doit plus pouvoir gérer SES événements
 * déjà créés, pas seulement être empêché d'en créer de nouveaux (spec
 * Communauté section 3/8, 11/11/2026 — adminSuspendOrganizer.ts).
 * Partagé entre toutes les actions de gestion d'un événement (inviter,
 * accepter/refuser, valider l'entrée, changer le statut), trouvé
 * manquant par une revue de code.
 */
export async function requireApprovedOrganizer(db: Firestore, uid: string): Promise<void> {
  const statusSnap = await db.collection("user_status").doc(uid).get();
  if (statusSnap.data()?.organizerStatus !== "approved") {
    throw new HttpsError("permission-denied", "Statut organisateur non valide ou suspendu.");
  }
}
