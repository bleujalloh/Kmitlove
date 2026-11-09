import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../premium_controller.dart';

/// Écran Premium / jetons (cahier des charges section 5). Les produits
/// n'apparaîtront que lorsque les fiches seront créées dans Google Play
/// Console / App Store Connect (pas encore fait, comptes développeur pas
/// ouverts — docs/suivi-developpement.md) : écran fonctionnel mais vide
/// tant que ce n'est pas configuré, ce n'est pas un bug.
class PremiumScreen extends ConsumerWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(purchaseListenerProvider); // démarre l'écoute des achats
    final productsAsync = ref.watch(productsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Premium & jetons')),
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => const Center(child: Text('Boutique indisponible pour le moment.')),
        data: (products) {
          if (products.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  "Aucune offre disponible pour l'instant.",
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
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(product.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text(product.description, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
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
    );
  }
}
