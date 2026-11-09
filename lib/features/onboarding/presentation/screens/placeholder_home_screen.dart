import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/auth_controller.dart';

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
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            "Compte connecté et e-mail vérifié.\nProchaine étape : le questionnaire de filtrage.",
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
