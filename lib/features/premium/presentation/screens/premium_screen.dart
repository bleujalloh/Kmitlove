import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/boost_action.dart';
import '../../../../core/providers/firebase_providers.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../premium_controller.dart';

/// Écran Premium / jetons (cahier des charges section 5). Les produits
/// n'apparaîtront que lorsque les fiches seront créées dans Google Play
/// Console / App Store Connect (pas encore fait — docs/suivi-developpement.md) :
/// écran fonctionnel mais vide tant que ce n'est pas configuré, ce n'est
/// pas un bug.
class PremiumScreen extends ConsumerWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(purchaseListenerProvider); // démarre l'écoute des achats
    final productsAsync = ref.watch(productsProvider);
    final isPremium = ref.watch(userStatusProvider).value?['isPremium'] == true;

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.navPremium)),
      body: Column(
        children: [
          if (isPremium)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Icon(Icons.workspace_premium, color: AppColors.accent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      context.l10n.youArePremium,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.accentSoft,
                borderRadius: BorderRadius.circular(AppRadii.lg),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(context.l10n.boostTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text(
                          context.l10n.boostDescription,
                          style: TextStyle(fontSize: 12, color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                  if (isPremium)
                    ElevatedButton(
                      onPressed: () => activateProfileBoost(context, ref),
                      child: Text(context.l10n.activateButton),
                    ),
                ],
              ),
            ),
          ),
          if (isPremium)
            const Spacer()
          else
          Expanded(
            child: productsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text(context.l10n.shopUnavailable)),
              data: (products) {
                if (products.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        context.l10n.noSubscriptionOffersYet,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.muted),
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: products.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final product = products[i];
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(AppRadii.lg),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(product.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text(product.description,
                                    style: TextStyle(fontSize: 12, color: AppColors.muted)),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () => ref.read(premiumRepositoryProvider).buy(product),
                            child: Text(product.price),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
