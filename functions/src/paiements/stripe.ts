import { onCall, onRequest, HttpsError } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import Stripe from "stripe";

import { REGION, PREMIUM_SUBSCRIPTION_PRODUCT_ID, JETON_PACK_PRODUCTS } from "../config";

/**
 * Infrastructure Stripe — prête pour un futur site web ou une
 * distribution hors Play Store, mais JAMAIS exposée dans l'app Android
 * tant qu'elle reste distribuée via le Play Store : Google interdit un
 * moyen de paiement alternatif pour des abonnements/biens numériques
 * DANS l'app, sous peine de bannissement (docs/suivi-developpement.md,
 * décision du 2026-11-10). Non branchée à un bouton app pour l'instant.
 */
const stripeSecretKey = defineSecret("STRIPE_SECRET_KEY");
const stripeWebhookSecret = defineSecret("STRIPE_WEBHOOK_SECRET");

function getStripeClient(key: string): Stripe {
  return new Stripe(key);
}

interface CreateCheckoutData {
  productId: string; // doit correspondre à PREMIUM_SUBSCRIPTION_PRODUCT_ID ou JETON_PACK_PRODUCTS
  successUrl: string;
  cancelUrl: string;
}

/** Crée une session Stripe Checkout — pensée pour un usage web. */
export const createStripeCheckoutSession = onCall(
  { region: REGION, secrets: [stripeSecretKey] },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Connexion requise.");
    }
    const key = stripeSecretKey.value();
    if (!key || key === "NOT_CONFIGURED") {
      throw new HttpsError("failed-precondition", "Stripe non configuré côté serveur.");
    }

    const { productId, successUrl, cancelUrl } = request.data as CreateCheckoutData;
    const isSubscription = productId === PREMIUM_SUBSCRIPTION_PRODUCT_ID;
    const isJetonPack = productId in JETON_PACK_PRODUCTS;
    if (!isSubscription && !isJetonPack) {
      throw new HttpsError("invalid-argument", "Produit inconnu.");
    }

    // Les prix réels (price_xxx) doivent être créés dans le tableau de
    // bord Stripe et mappés ici une fois le compte configuré — en
    // attendant, cette fonction répond "non configuré" plutôt que de
    // deviner un identifiant de prix. `successUrl`/`cancelUrl` seront
    // utilisés dès que ce mapping existera.
    void getStripeClient(key);
    void successUrl;
    void cancelUrl;
    throw new HttpsError(
      "failed-precondition",
      "Les identifiants de prix Stripe ne sont pas encore associés aux produits Kamalove.",
    );
  },
);

/**
 * Webhook Stripe (signature vérifiée) : crédite Premium/jetons une fois
 * le paiement confirmé, avec le même registre anti-fraude que Google
 * Play (functions/src/premium/verifyPurchase.ts) pour ne jamais créditer
 * deux fois le même événement.
 */
export const stripeWebhook = onRequest(
  { region: REGION, secrets: [stripeSecretKey, stripeWebhookSecret] },
  async (req, res) => {
    const key = stripeSecretKey.value();
    const webhookSecret = stripeWebhookSecret.value();
    if (!key || key === "NOT_CONFIGURED" || !webhookSecret || webhookSecret === "NOT_CONFIGURED") {
      res.status(503).send("Stripe non configuré.");
      return;
    }

    const stripe = getStripeClient(key);
    const signature = req.headers["stripe-signature"];
    let event: Stripe.Event;
    try {
      event = stripe.webhooks.constructEvent(req.rawBody, signature as string, webhookSecret);
    } catch {
      res.status(400).send("Signature invalide.");
      return;
    }

    if (event.type !== "checkout.session.completed") {
      res.status(200).send("ignoré");
      return;
    }

    const session = event.data.object as Stripe.Checkout.Session;
    const uid = session.client_reference_id;
    const productId = session.metadata?.productId;
    if (!uid || !productId) {
      res.status(200).send("métadonnées manquantes, ignoré");
      return;
    }

    const db = getFirestore();
    const tokenRef = db.collection("used_purchase_tokens").doc(`stripe_${event.id}`);
    await db.runTransaction(async (tx) => {
      const existing = await tx.get(tokenRef);
      if (existing.exists) return;
      tx.set(tokenRef, { uid, productId, creditedAt: FieldValue.serverTimestamp(), source: "stripe" });

      const statusRef = db.collection("user_status").doc(uid);
      if (productId === PREMIUM_SUBSCRIPTION_PRODUCT_ID) {
        tx.set(statusRef, { isPremium: true }, { merge: true });
      } else if (productId in JETON_PACK_PRODUCTS) {
        tx.set(statusRef, { jetons: FieldValue.increment(JETON_PACK_PRODUCTS[productId]) }, { merge: true });
      }
    });

    res.status(200).send("ok");
  },
);
