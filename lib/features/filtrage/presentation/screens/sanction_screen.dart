import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/sanction_appeal_button.dart';
import '../../../auth/presentation/auth_controller.dart';

/// Affiché à la place de tout le reste de l'app quand le compte est
/// suspendu temporairement ou banni (docs/regles-messagerie-securite.md
/// section 3) — un compte sanctionné ne doit jamais pouvoir atteindre
/// Découvrir, la messagerie ou la communauté, donc ce n'est pas un simple
/// bandeau dans Paramètres (qu'il n'atteint jamais, voir
/// core/router/auth_gate.dart) mais l'écran entier affiché par AuthGate.
class SanctionScreen extends ConsumerWidget {
  const SanctionScreen({super.key, required this.status});

  final Map<String, dynamic> status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final banned = status['sanctionLevel'] == 'banned';
    final suspendedUntil = status['suspendedUntil'] as Timestamp?;
    final appealPending = status['appealPending'] == true;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.block, size: 56, color: AppColors.accent),
                const SizedBox(height: 18),
                Text(
                  banned ? 'Compte suspendu définitivement' : 'Compte suspendu temporairement',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.ink),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  !banned && suspendedUntil != null
                      ? "Ton compte redevient actif à partir du ${_formatDate(suspendedUntil.toDate())}."
                      : "Cette décision fait suite à un ou plusieurs signalements confirmés.",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.muted, height: 1.5),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Si tu penses que c'est une erreur, tu peux demander qu'un modérateur réexamine cette décision.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.muted, height: 1.5),
                ),
                const SizedBox(height: 24),
                SanctionAppealButton(appealPending: appealPending),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
                  child: const Text('Se déconnecter'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
