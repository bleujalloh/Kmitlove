import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import * as crypto from "crypto";

import { REGION } from "../config";
import { requireApprovedOrganizer } from "../shared/requireApprovedOrganizer";

/**
 * Demande de participation à un événement ou à une annonce privée
 * (cahier des charges section 4.7). L'adresse exacte reste masquée
 * jusqu'à acceptation (docs/regles-annonces-evenements.md section 2).
 */
export const requestParticipation = onCall({ region: REGION }, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Connexion requise.");
  }
  const uid = request.auth.uid;
  const { postId } = request.data as { postId: string };
  if (!postId) {
    throw new HttpsError("invalid-argument", "postId manquant.");
  }

  const db = getFirestore();
  const postRef = db.collection("community_posts").doc(postId);
  const postSnap = await postRef.get();
  const post = postSnap.data();
  if (!post || post.status !== "published") {
    throw new HttpsError("not-found", "Publication introuvable.");
  }
  const typesWithRequest = ["evenement_public", "evenement_prive", "annonce_privee"];
  if (!typesWithRequest.includes(post.type)) {
    throw new HttpsError(
      "invalid-argument",
      "Cette publication ne nécessite pas de demande de participation.",
    );
  }
  if (post.authorUid === uid) {
    throw new HttpsError("invalid-argument", "Tu es l'organisateur de cette publication.");
  }
  // Spec Communauté section 2 : un événement "sur invitation" n'accepte
  // de demande que de la part d'un uid explicitement invité par
  // l'organisateur — jamais une simple vérification côté client. La
  // liste vit dans la sous-collection privée (jamais sur le document
  // public, voir createCommunityPost.ts), lue ici via l'Admin SDK.
  if (post.accessMode === "sur_invitation") {
    const invitationsSnap = await postRef.collection("private").doc("invitations").get();
    const invited: string[] = invitationsSnap.data()?.invitedUids ?? [];
    if (!invited.includes(uid)) {
      throw new HttpsError(
        "permission-denied",
        "Cet événement est sur invitation uniquement.",
      );
    }
  }
  if (post.eventState === "annule" || post.eventState === "termine") {
    throw new HttpsError("failed-precondition", "Cet événement n'accepte plus de demandes.");
  }

  const participationRef = postRef.collection("participations").doc(uid);

  // Spec Communauté section 4 : pour un événement public ou sur
  // invitation, les étapes de validation par l'organisateur peuvent être
  // supprimées — seule la capacité reste contrôlée. Seul "sur demande"
  // (et les annonces privées, qui n'ont pas de accessMode) passe
  // vraiment par une acceptation manuelle (respondToParticipation).
  const autoAccept = post.accessMode === "public" || post.accessMode === "sur_invitation";

  const result = await db.runTransaction(async (tx) => {
    const [freshPostSnap, existingSnap] = await Promise.all([tx.get(postRef), tx.get(participationRef)]);
    // Une participation annulée par le membre lui-même (cancelParticipation.ts)
    // ne doit pas bloquer une nouvelle demande pour le même événement —
    // sans cette exception, personne ne pourrait plus jamais revenir sur
    // un événement qu'il a quitté une fois (trouvé par revue de code).
    if (existingSnap.exists && existingSnap.data()?.status !== "cancelled") {
      throw new HttpsError("already-exists", "Demande déjà envoyée.");
    }
    const freshPost = freshPostSnap.data()!;
    // Relu fraîchement DANS la transaction, pas seulement avant (ligne
    // 54 plus haut) : un organisateur qui annule son événement pile
    // entre cette lecture précoce et la validation de la transaction ne
    // doit pas laisser passer une inscription quand même (trouvé par
    // revue de code, même raisonnement que le blocage dans recordSwipe.ts).
    if (freshPost.eventState === "annule" || freshPost.eventState === "termine") {
      throw new HttpsError("failed-precondition", "Cet événement n'accepte plus de demandes.");
    }

    if (!autoAccept) {
      tx.set(participationRef, {
        uid,
        status: "pending",
        requestedAt: FieldValue.serverTimestamp(),
        checkedIn: false,
      });
      return { status: "pending" as const };
    }

    const isFull = freshPost.capacity && freshPost.participantsCount >= freshPost.capacity;
    if (isFull) {
      tx.set(participationRef, {
        uid,
        status: "waitlisted",
        requestedAt: FieldValue.serverTimestamp(),
        checkedIn: false,
      });
      return { status: "waitlisted" as const };
    }

    const checkinCode = crypto.randomBytes(4).toString("hex").toUpperCase();
    tx.set(participationRef, {
      uid,
      status: "accepted",
      requestedAt: FieldValue.serverTimestamp(),
      respondedAt: FieldValue.serverTimestamp(),
      checkedIn: false,
      checkinCode,
    });
    tx.update(postRef, { participantsCount: FieldValue.increment(1) });
    return { status: "accepted" as const };
  });

  return { ok: true, status: result.status };
});

interface RespondData {
  postId: string;
  targetUid: string;
  accept: boolean;
}

/**
 * Acceptation/refus par l'organisateur. Vérifie la capacité restante
 * pour les événements et génère un code de présence lors de
 * l'acceptation (simplifié : un code à saisir, pas un vrai QR scanné —
 * voir docs/suivi-developpement.md pour la limite assumée).
 */
export const respondToParticipation = onCall({ region: REGION }, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Connexion requise.");
  }
  const uid = request.auth.uid;
  const { postId, targetUid, accept } = request.data as RespondData;
  if (!postId || !targetUid) {
    throw new HttpsError("invalid-argument", "Paramètres manquants.");
  }

  const db = getFirestore();
  const postRef = db.collection("community_posts").doc(postId);
  const participationRef = postRef.collection("participations").doc(targetUid);

  await requireApprovedOrganizer(db, uid);

  await db.runTransaction(async (tx) => {
    const [postSnap, participationSnap] = await Promise.all([
      tx.get(postRef),
      tx.get(participationRef),
    ]);
    const post = postSnap.data();
    if (!post || post.authorUid !== uid) {
      throw new HttpsError("permission-denied", "Seul l'organisateur peut répondre.");
    }
    const participation = participationSnap.data();
    if (!participation || participation.status !== "pending") {
      throw new HttpsError("failed-precondition", "Aucune demande en attente pour ce membre.");
    }

    if (!accept) {
      tx.update(participationRef, { status: "rejected", respondedAt: FieldValue.serverTimestamp() });
      return;
    }

    if (post.capacity && post.participantsCount >= post.capacity) {
      tx.update(participationRef, {
        status: "waitlisted",
        respondedAt: FieldValue.serverTimestamp(),
      });
      return;
    }

    const checkinCode = crypto.randomBytes(4).toString("hex").toUpperCase();
    tx.update(participationRef, {
      status: "accepted",
      respondedAt: FieldValue.serverTimestamp(),
      checkinCode,
    });
    tx.update(postRef, { participantsCount: FieldValue.increment(1) });
  });

  return { ok: true };
});

interface CheckInData {
  postId: string;
  targetUid: string;
  code: string;
}

/** Vérification à l'entrée (section 4.7) via le code de présence. */
export const checkInParticipant = onCall({ region: REGION }, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Connexion requise.");
  }
  const uid = request.auth.uid;
  const { postId, targetUid, code } = request.data as CheckInData;

  const db = getFirestore();
  const postRef = db.collection("community_posts").doc(postId);
  const participationRef = postRef.collection("participations").doc(targetUid);

  const [postSnap, participationSnap] = await Promise.all([postRef.get(), participationRef.get()]);
  const post = postSnap.data();
  if (!post || post.authorUid !== uid) {
    throw new HttpsError("permission-denied", "Seul l'organisateur peut valider l'entrée.");
  }
  await requireApprovedOrganizer(db, uid);
  const participation = participationSnap.data();
  if (!participation || participation.status !== "accepted" || participation.checkinCode !== code) {
    throw new HttpsError("invalid-argument", "Code invalide.");
  }

  await participationRef.update({ checkedIn: true, checkedInAt: FieldValue.serverTimestamp() });
  return { ok: true };
});
