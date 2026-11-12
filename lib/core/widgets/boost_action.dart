import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/auth_controller.dart';
import '../../l10n/l10n_extensions.dart';

/// Active le boost gratuit déjà existant (functions/src/premium/activateBoost.ts,
/// jetons) — extrait de PremiumScreen pour être réutilisé tel quel par le
/// bouton "Booste ton profil" de l'écran Likes (demande explicite du
/// propriétaire, 12/11/2026 : jamais une nouvelle fonctionnalité inventée
/// ni un achat, exactement le même mécanisme gratuit que l'onglet Profil).
Future<void> activateProfileBoost(BuildContext context, WidgetRef ref) async {
  try {
    await ref.read(cloudFunctionsProvider).httpsCallable('activateBoost').call();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.boostActivated)),
      );
    }
  } on FirebaseFunctionsException catch (e) {
    if (context.mounted) {
      final message = e.code == 'permission-denied'
          ? context.l10n.boostPremiumOnly
          : e.code == 'resource-exhausted'
              ? context.l10n.boostAlreadyUsed
              : context.l10n.boostActivateFailed;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }
}
