import { onSchedule } from "firebase-functions/v2/scheduler";
import { getFirestore, FieldValue } from "firebase-admin/firestore";

import { REGION, EVENT_REMINDER_HOURS_BEFORE } from "../config";
import { sendPushToUser } from "../shared/push";

/**
 * Rappel automatique avant un événement réservé (spec Communauté section
 * 9 — "ne pas oublier un événement réservé"). Tourne toutes les heures
 * et couvre toute la fenêtre [maintenant, maintenant + 24h] plutôt qu'une
 * heure précise exacte : si une exécution est manquée, la suivante
 * retrouve le même événement et envoie quand même le rappel — la marque
 * `reminderSentAt` sur chaque participation (jamais sur l'événement, qui
 * a plusieurs participants) garantit qu'un même participant ne reçoit le
 * rappel qu'une seule fois.
 */
export const sendEventReminders = onSchedule(
  { schedule: "every 1 hours", region: REGION },
  async () => {
    const db = getFirestore();
    const now = new Date();
    // `eventDate` est écrit par le client en heure locale sans décalage
    // UTC explicite (create_post_screen.dart), alors que `now` ici est un
    // vrai instant UTC — une comparaison exacte serait décalée de
    // quelques heures selon le fuseau de l'organisateur (trouvé par revue
    // de code ; corriger ça pour de bon demanderait de stocker un vrai
    // fuseau, absent de tout le modèle de données du projet). Une marge
    // de sécurité ici absorbe ce décalage sans jamais rater la fenêtre de
    // rappel : la marque `reminderSentAt` par participation (plus bas)
    // reste la seule garantie d'un rappel envoyé une seule fois.
    const marginMs = 4 * 60 * 60 * 1000;
    const windowStart = new Date(now.getTime() - marginMs);
    const windowEnd = new Date(now.getTime() + EVENT_REMINDER_HOURS_BEFORE * 60 * 60 * 1000 + marginMs);

    const eventsSnap = await db
      .collection("community_posts")
      .where("type", "in", ["evenement_public", "evenement_prive"])
      .where("eventDate", ">=", windowStart.toISOString())
      .where("eventDate", "<=", windowEnd.toISOString())
      .get();

    for (const eventDoc of eventsSnap.docs) {
      const post = eventDoc.data();
      if (post.eventState === "annule" || post.eventState === "termine") {
        continue;
      }

      const participationsSnap = await eventDoc.ref
        .collection("participations")
        .where("status", "==", "accepted")
        .get();

      for (const participationDoc of participationsSnap.docs) {
        if (participationDoc.data().reminderSentAt) {
          continue;
        }
        await sendPushToUser(participationDoc.id, {
          title: "Rappel d'événement",
          body: `« ${post.title ?? "Ton événement"} » a lieu bientôt.`,
        });
        await participationDoc.ref.update({ reminderSentAt: FieldValue.serverTimestamp() });
      }
    }
  },
);
