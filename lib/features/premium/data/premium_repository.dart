import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../domain/premium_products.dart';

/// L'achat passe par Google Play / App Store (obligatoire pour un
/// abonnement sur mobile), mais le crédit (Premium actif, jetons) n'est
/// jamais accordé sur la seule confirmation du magasin côté client —
/// toujours vérifié côté serveur avant d'être crédité
/// (docs/regles-du-projet.md section 2, functions/src/premium/verifyPurchase.ts).
class PremiumRepository {
  PremiumRepository(this._functions);

  final FirebaseFunctions _functions;
  final InAppPurchase _iap = InAppPurchase.instance;

  Future<bool> get isAvailable => _iap.isAvailable();

  Future<List<ProductDetails>> loadProducts() async {
    final response = await _iap.queryProductDetails(kAllProductIds);
    return response.productDetails;
  }

  Stream<List<PurchaseDetails>> get purchaseStream => _iap.purchaseStream;

  Future<void> buy(ProductDetails product) {
    final param = PurchaseParam(productDetails: product);
    if (product.id == kPremiumSubscriptionId) {
      return _iap.buyNonConsumable(purchaseParam: param);
    }
    return _iap.buyConsumable(purchaseParam: param);
  }

  Future<void> completePurchase(PurchaseDetails purchase) {
    return _iap.completePurchase(purchase);
  }

  Future<bool> verifyPurchase(PurchaseDetails purchase) async {
    final result = await _functions.httpsCallable('verifyPurchase').call({
      'platform': Platform.isIOS ? 'ios' : 'android',
      'productId': purchase.productID,
      'purchaseToken': purchase.verificationData.serverVerificationData,
    });
    final data = result.data as Map<Object?, Object?>;
    return data['ok'] == true;
  }

  Future<void> useJetonToResurface(String targetUid) {
    return _functions.httpsCallable('useJetonToResurface').call({'targetUid': targetUid});
  }
}
