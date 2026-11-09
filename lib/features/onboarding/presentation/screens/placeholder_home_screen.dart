import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../admin/presentation/admin_controller.dart';
import '../../../admin/presentation/screens/admin_screen.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../../compatibilite/presentation/screens/compat_screen.dart';
import '../../../decouvrir/presentation/screens/decouvrir_screen.dart';
import '../../../likes/presentation/screens/likes_screen.dart';
import '../../../communaute/presentation/screens/communaute_screen.dart';
import '../../../identite/presentation/screens/identite_screen.dart';
import '../../../messages/presentation/screens/matches_list_screen.dart';
import '../../../premium/presentation/screens/premium_screen.dart';

/// Écran temporaire après connexion + vérification d'e-mail, en attendant
/// le questionnaire de filtrage (docs/suivi-developpement.md) et la vraie
/// navigation à 4 onglets (Likes/Messages/Découvrir/Communauté).
class PlaceholderHomeScreen extends ConsumerWidget {
  const PlaceholderHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kamalove'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Compte activé et profil créé.\nProchaine étape : Découvrir, Likes, Messages, Communauté.",
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const DecouvrirScreen()),
                ),
                child: const Text('Découvrir'),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LikesScreen()),
                ),
                child: const Text('Likes'),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const MatchesListScreen()),
                ),
                child: const Text('Messages'),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CommunauteScreen()),
                ),
                child: const Text('Communauté'),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PremiumScreen()),
                ),
                child: const Text('Premium & jetons'),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CompatScreen()),
                ),
                child: const Text('Faire le test de compatibilité'),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const IdentiteScreen()),
                ),
                child: const Text('Vérification d\'identité'),
              ),
              Consumer(
                builder: (context, ref, _) {
                  final isAdmin = ref.watch(isAdminProvider).value ?? false;
                  if (!isAdmin) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AdminScreen()),
                      ),
                      child: const Text('Administration'),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
