import { HttpsError } from "firebase-functions/v2/https";
import { onCall } from "../shared/callable";
import { defineSecret } from "firebase-functions/params";
import { getFirestore, FieldValue } from "firebase-admin/firestore";

import { REGION, PREMIUM_SUBSCRIPTION_PRODUCT_ID, JETON_PACK_PRODUCTS } from "../config";
import { ENFORCE_APP_CHECK } from "../shared/appCheck";

/**
 * Infrastructure PayPal — même logique et même réserve que Stripe (voir
 * functions/src/paiements/stripe.ts) : prête pour un futur site web,
 * jamais exposée dans l'app Android tant qu'elle reste sur le Play Store.
 */
const paypalClientId = defineSecret("PAYPAL_CLIENT_ID");
const paypalClientSecret = defineSecret("PAYPAL_CLIENT_SECRET");

// Sandbox par défaut — passer à "https://api-m.paypal.com" en production
// une fois les vraies identifiants configurés.
const PAYPAL_API_BASE = "https://api-m.sandbox.paypal.com";

async function getPaypalAccessToken(clientId: string, clientSecret: string): Promise<string> {
  const auth = Buffer.from(`${clientId}:${clientSecret}`).toString("base64");
  const res = await fetch(`${PAYPAL_API_BASE}/v1/oauth2/token`, {
    method: "POST",
    headers: {
      Authorization: `Basic ${auth}`,
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body: "grant_type=client_credentials",
  });
  if (!res.ok) {
    throw new Error(`Échec de l'authentification PayPal (${res.status}).`);
  }
  const data = (await res.json()) as { access_token: string };
  return data.access_token;
}

function priceForProduct(productId: string): string | null {
  if (productId === PREMIUM_SUBSCRIPTION_PRODUCT_ID) return "9.99";
  if (productId in JETON_PACK_PRODUCTS) {
    // Tarification indicative à ajuster avec le vrai modèle de prix —
    // voir docs/regles-economie-et-compatibilite.md section 1 (tarifs
    // précis "à fixer plus tard").
    return productId === "kamalove_jetons_5" ? "2.99" : "6.99";
  }
  return null;
}

interface CreateOrderData {
  productId: string;
}

/** Crée une commande PayPal — pensée pour un usage web, pas encore branchée à un bouton app. */
export const createPaypalOrder = onCall(
  { region: REGION, enforceAppCheck: ENFORCE_APP_CHECK, secrets: [paypalClientId, paypalClientSecret] },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Connexion requise.");
    }
    const clientId = paypalClientId.value();
    const clientSecret = paypalClientSecret.value();
    if (!clientId || clientId === "NOT_CONFIGURED" || !clientSecret || clientSecret === "NOT_CONFIGURED") {
      throw new HttpsError("failed-precondition", "PayPal non configuré côté serveur.");
    }

    const { productId } = request.data as CreateOrderData;
    const price = priceForProduct(productId);
    if (!price) {
      throw new HttpsError("invalid-argument", "Produit inconnu.");
    }

    const accessToken = await getPaypalAccessToken(clientId, clientSecret);
    const res = await fetch(`${PAYPAL_API_BASE}/v2/checkout/orders`, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${accessToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        intent: "CAPTURE",
        purchase_units: [
          {
            custom_id: `${request.auth.uid}:${productId}`,
            amount: { currency_code: "EUR", value: price },
          },
        ],
      }),
    });
    if (!res.ok) {
      throw new HttpsError("internal", "Impossible de créer la commande PayPal.");
    }
    const order = (await res.json()) as { id: string };
    return { orderId: order.id };
  },
);

interface CaptureOrderData {
  orderId: string;
}

/**
 * Capture une commande PayPal déjà approuvée par le payeur, puis
 * crédite Premium/jetons — anti-fraude par le même registre global que
 * Google Play/Stripe (une commande ne peut être créditée qu'une fois).
 */
export const capturePaypalOrder = onCall(
  { region: REGION, enforceAppCheck: ENFORCE_APP_CHECK, secrets: [paypalClientId, paypalClientSecret] },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Connexion requise.");
    }
    const uid = request.auth.uid;
    const clientId = paypalClientId.value();
    const clientSecret = paypalClientSecret.value();
    if (!clientId || clientId === "NOT_CONFIGURED" || !clientSecret || clientSecret === "NOT_CONFIGURED") {
      throw new HttpsError("failed-precondition", "PayPal non configuré côté serveur.");
    }

    const { orderId } = request.data as CaptureOrderData;
    if (!orderId) {
      throw new HttpsError("invalid-argument", "orderId manquant.");
    }

    const accessToken = await getPaypalAccessToken(clientId, clientSecret);
    const res = await fetch(`${PAYPAL_API_BASE}/v2/checkout/orders/${orderId}/capture`, {
      method: "POST",
      headers: { Authorization: `Bearer ${accessToken}`, "Content-Type": "application/json" },
    });
    if (!res.ok) {
      throw new HttpsError("internal", "Impossible de capturer le paiement PayPal.");
    }
    const captureResult = (await res.json()) as {
      status: string;
      purchase_units: { custom_id: string }[];
    };
    if (captureResult.status !== "COMPLETED") {
      throw new HttpsError("failed-precondition", "Paiement non complété.");
    }

    const customId = captureResult.purchase_units[0]?.custom_id ?? "";
    const [ownerUid, productId] = customId.split(":");
    if (ownerUid !== uid || !productId) {
      // Empêche un compte de capturer/créditer une commande créée par un
      // autre — le custom_id porte l'identité du créateur de la commande.
      throw new HttpsError("permission-denied", "Cette commande ne t'appartient pas.");
    }

    const db = getFirestore();
    const tokenRef = db.collection("used_purchase_tokens").doc(`paypal_${orderId}`);
    await db.runTransaction(async (tx) => {
      const existing = await tx.get(tokenRef);
      if (existing.exists) return;
      tx.set(tokenRef, { uid, productId, creditedAt: FieldValue.serverTimestamp(), source: "paypal" });

      const statusRef = db.collection("user_status").doc(uid);
      if (productId === PREMIUM_SUBSCRIPTION_PRODUCT_ID) {
        tx.set(statusRef, { isPremium: true }, { merge: true });
      } else if (productId in JETON_PACK_PRODUCTS) {
        tx.set(statusRef, { jetons: FieldValue.increment(JETON_PACK_PRODUCTS[productId]) }, { merge: true });
      }
    });

    return { ok: true };
  },
);
