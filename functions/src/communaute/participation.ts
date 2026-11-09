import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import * as crypto from "crypto";

import { REGION } from "../config";

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

  const participationRef = postRef.collection("participations").doc(uid);
  const existing = await participationRef.get();
  if (existing.exists) {
    throw new HttpsError("already-exists", "Demande déjà envoyée.");
  }

  await participationRef.set({
    uid,
    status: "pending",
    requestedAt: FieldValue.serverTimestamp(),
    checkedIn: false,
  });

  return { ok: true };
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
  const participation = participationSnap.data();
  if (!participation || participation.status !== "accepted" || participation.checkinCode !== code) {
    throw new HttpsError("invalid-argument", "Code invalide.");
  }

  await participationRef.update({ checkedIn: true, checkedInAt: FieldValue.serverTimestamp() });
  return { ok: true };
});
