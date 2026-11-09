import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../auth/presentation/auth_controller.dart';
import '../data/premium_repository.dart';

final premiumRepositoryProvider = Provider<PremiumRepository>((ref) {
  return PremiumRepository(ref.watch(cloudFunctionsProvider));
});

final productsProvider = FutureProvider<List<ProductDetails>>((ref) {
  return ref.read(premiumRepositoryProvider).loadProducts();
});

/// Écoute en continu les achats en cours (démarrés dans l'app ou
/// restaurés par le magasin) et les fait vérifier côté serveur avant de
/// les finaliser.
class PurchaseListener {
  PurchaseListener(this.ref) {
    _sub = ref.read(premiumRepositoryProvider).purchaseStream.listen(_onPurchases);
  }

  final Ref ref;
  StreamSubscription<List<PurchaseDetails>>? _sub;

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    final repo = ref.read(premiumRepositoryProvider);
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.purchased || purchase.status == PurchaseStatus.restored) {
        try {
          await repo.verifyPurchase(purchase);
          // Vérifié et crédité avec succès : on peut accuser réception.
          await repo.completePurchase(purchase);
        } on FirebaseFunctionsException catch (e) {
          // "Achat non valide" est une réponse définitive du magasin
          // (via verifyPurchase) : inutile de garder l'achat en attente,
          // il ne deviendra jamais valide. Toute autre erreur (config
          // serveur manquante, réseau...) est transitoire : on NE
          // termine PAS l'achat, pour que le flux d'achats le
          // représente à nouveau (relance de l'app, "Restaurer mes
          // achats") plutôt que de perdre un paiement réel sans crédit.
          if (e.code == 'failed-precondition' && e.message == 'Achat non valide.') {
            await repo.completePurchase(purchase);
          }
        }
      } else if (purchase.status == PurchaseStatus.error) {
        await repo.completePurchase(purchase);
      }
    }
  }

  void dispose() => _sub?.cancel();
}

final purchaseListenerProvider = Provider<PurchaseListener>((ref) {
  final listener = PurchaseListener(ref);
  ref.onDispose(listener.dispose);
  return listener;
});
