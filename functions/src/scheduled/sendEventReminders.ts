import { onSchedule } from "firebase-functions/v2/scheduler";
import { getFirestore, FieldValue } from "firebase-admin/firestore";

import { REGION, EVENT_REMINDER_HOURS_BEFORE } from "../config";
import { sendPushToUser } from "../shared/push";
import { zonedWallTimeToUtcMillis } from "../shared/timezone";

// Marge utilisée UNIQUEMENT pour élargir la requête Firestore (`eventDate`
// y est comparé comme une simple chaîne, sans connaître encore le fuseau
// de chaque événement) — jamais pour décider d'envoyer ou non un rappel.
// Cette décision précise est prise plus bas, un par un, à partir du vrai
// fuseau stocké sur chaque événement (createCommunityPost.ts). Les
// fuseaux réels vont au plus de UTC-12 à UTC+14 ; une marge de 16h des
// deux côtés couvre tous les cas sans jamais exclure un événement qui
// devrait être examiné.
const QUERY_MARGIN_MS = 16 * 60 * 60 * 1000;

/**
 * Rappel automatique avant un événement réservé (spec Communauté section
 * 9 — "ne pas oublier un événement réservé"). Tourne toutes les heures ;
 * si une exécution est manquée, la suivante retrouve le même événement
 * et envoie quand même le rappel — la marque `reminderSentAt` sur chaque
 * participation (jamais sur l'événement, qui a plusieurs participants)
 * garantit qu'un même participant ne reçoit le rappel qu'une seule fois.
 */
export const sendEventReminders = onSchedule(
  { schedule: "every 1 hours", region: REGION },
  async () => {
    const db = getFirestore();
    const now = new Date();
    const windowStart = new Date(now.getTime() - QUERY_MARGIN_MS);
    const windowEnd = new Date(
      now.getTime() + EVENT_REMINDER_HOURS_BEFORE * 60 * 60 * 1000 + QUERY_MARGIN_MS,
    );

    const eventsSnap = await db
      .collection("community_posts")
      .where("type", "in", ["evenement_public", "evenement_prive"])
      .where("eventDate", ">=", windowStart.toISOString())
      .where("eventDate", "<=", windowEnd.toISOString())
      .get();

    for (const eventDoc of eventsSnap.docs) {
      try {
        const post = eventDoc.data();
        if (post.eventState === "annule" || post.eventState === "termine" || !post.eventDate) {
          continue;
        }

        // Calcul précis à partir du vrai fuseau de l'organisateur — les
        // événements créés avant ce correctif n'ont pas de `timezone` ;
        // UTC n'est utilisé que pour ce lot historique, jamais pour un
        // nouvel événement (createCommunityPost.ts l'exige désormais).
        const eventUtcMillis = zonedWallTimeToUtcMillis(post.eventDate, post.timezone ?? "UTC");
        const reminderTriggerMillis = eventUtcMillis - EVENT_REMINDER_HOURS_BEFORE * 60 * 60 * 1000;
        const nowMillis = now.getTime();
        if (nowMillis < reminderTriggerMillis || nowMillis >= eventUtcMillis) {
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
      } catch (err) {
        // Un événement isolé invalide (date/fuseau corrompu...) ne doit
        // jamais interrompre l'exécution entière et priver tous les
        // autres événements de leur rappel cette heure-ci (trouvé par
        // revue de code).
        // eslint-disable-next-line no-console
        console.error("sendEventReminders: échec sur un événement", { postId: eventDoc.id, err });
      }
    }
  },
);
