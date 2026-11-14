import { HttpsError } from "firebase-functions/v2/https";
import { onCall } from "../shared/callable";
import { defineSecret } from "firebase-functions/params";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import { google } from "googleapis";

import { REGION, ANDROID_PACKAGE_NAME, PREMIUM_SUBSCRIPTION_PRODUCT_ID, JETON_PACK_PRODUCTS } from "../config";
import { ENFORCE_APP_CHECK } from "../shared/appCheck";

/**
 * Clé de compte de service Google Play Console (JSON), à créer dans
 * Google Play Console > Configuration de l'API > Comptes de service,
 * puis à enregistrer avec `firebase functions:secrets:set
 * GOOGLE_PLAY_SERVICE_ACCOUNT_JSON`. Jamais commitée dans le dépôt
 * (docs/regles-du-projet.md section 2).
 */
const googlePlayServiceAccountJson = defineSecret("GOOGLE_PLAY_SERVICE_ACCOUNT_JSON");

interface VerifyData {
  platform: "android" | "ios";
  productId: string;
  purchaseToken: string; // Android : jeton de la bibliothèque in_app_purchase
}

async function verifyAndroidPurchase(productId: string, purchaseToken: string, keyJson: string) {
  const credentials = JSON.parse(keyJson);
  const auth = new google.auth.GoogleAuth({
    credentials,
    scopes: ["https://www.googleapis.com/auth/androidpublisher"],
  });
  const publisher = google.androidpublisher({ version: "v3", auth });

  const isSubscription = productId === PREMIUM_SUBSCRIPTION_PRODUCT_ID;
  if (isSubscription) {
    // API Subscriptions v2 (l'ancienne purchases.subscriptions.get est
    // dépréciée côté Google Play).
    const res = await publisher.purchases.subscriptionsv2.get({
      packageName: ANDROID_PACKAGE_NAME,
      token: purchaseToken,
    });
    const validStates = ["SUBSCRIPTION_STATE_ACTIVE", "SUBSCRIPTION_STATE_IN_GRACE_PERIOD"];
    const valid = validStates.includes(res.data.subscriptionState ?? "");
    return { valid, isSubscription: true };
  }

  const res = await publisher.purchases.products.get({
    packageName: ANDROID_PACKAGE_NAME,
    productId,
    token: purchaseToken,
  });
  // purchaseState 0 = achat effectué.
  const valid = res.data.purchaseState === 0;
  // Un achat consommable doit être marqué "consommé" côté Play pour ne
  // jamais pouvoir être revérifié/recrédité deux fois.
  if (valid) {
    await publisher.purchases.products.consume({
      packageName: ANDROID_PACKAGE_NAME,
      productId,
      token: purchaseToken,
    });
  }
  return { valid, isSubscription: false };
}

/**
 * Vérifie un achat (abonnement Premium ou pack de jetons) auprès du
 * magasin avant de créditer quoi que ce soit — jamais sur la seule
 * déclaration du client (docs/regles-du-projet.md section 2).
 *
 * iOS/App Store Server API : pas encore implémenté, le compte Apple
 * Developer n'est pas encore ouvert (docs/suivi-developpement.md). La
 * structure ci-dessous est prévue pour recevoir cette vérification de
 * la même façon une fois les identifiants disponibles — ne jamais
 * créditer un achat iOS sans elle en attendant.
 */
export const verifyPurchase = onCall(
  { region: REGION, enforceAppCheck: ENFORCE_APP_CHECK, secrets: [googlePlayServiceAccountJson] },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Connexion requise.");
    }
    const uid = request.auth.uid;
    const { platform, productId, purchaseToken } = request.data as VerifyData;

    const isKnownProduct =
      productId === PREMIUM_SUBSCRIPTION_PRODUCT_ID || productId in JETON_PACK_PRODUCTS;
    if (!isKnownProduct || !purchaseToken) {
      throw new HttpsError("invalid-argument", "Achat inconnu.");
    }

    if (platform !== "android") {
      throw new HttpsError(
        "unimplemented",
        "La vérification des achats iOS n'est pas encore disponible.",
      );
    }

    const keyJson = googlePlayServiceAccountJson.value();
    if (!keyJson || keyJson === "NOT_CONFIGURED") {
      throw new HttpsError(
        "failed-precondition",
        "Vérification des achats non configurée côté serveur.",
      );
    }

    const { valid, isSubscription } = await verifyAndroidPurchase(productId, purchaseToken, keyJson);
    if (!valid) {
      throw new HttpsError("failed-precondition", "Achat non valide.");
    }

    const db = getFirestore();
    const statusRef = db.collection("user_status").doc(uid);

    // Registre global des jetons de paiement déjà traités : sans ça, un
    // même jeton (fuité, partagé entre comptes de test...) pourrait être
    // vérifié avec succès par plusieurs comptes différents et créditer
    // Premium/jetons à chacun pour un seul paiement réel. L'écriture
    // transactionnelle garantit qu'un seul appel gagne la course même en
    // cas de redélivrance de l'événement d'achat par le magasin.
    const tokenRef = db.collection("used_purchase_tokens").doc(purchaseToken);
    const alreadyCredited = await db.runTransaction(async (tx) => {
      const tokenSnap = await tx.get(tokenRef);
      if (tokenSnap.exists) {
        return true;
      }
      tx.set(tokenRef, {
        uid,
        productId,
        creditedAt: FieldValue.serverTimestamp(),
      });
      if (isSubscription) {
        tx.set(statusRef, { isPremium: true }, { merge: true });
      } else {
        const amount = JETON_PACK_PRODUCTS[productId];
        tx.set(statusRef, { jetons: FieldValue.increment(amount) }, { merge: true });
      }
      return false;
    });

    if (alreadyCredited) {
      // Pas une erreur côté utilisateur : le magasin redélivre parfois le
      // même événement (ex. app relancée avant l'accusé de réception).
      // On confirme simplement que l'achat est bien pris en compte, sans
      // créditer une seconde fois.
      return { ok: true, isSubscription, alreadyCredited: true };
    }

    return { ok: true, isSubscription };
  },
);
