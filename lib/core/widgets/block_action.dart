import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/messages/presentation/messages_controller.dart';
import '../../l10n/l10n_extensions.dart';

/// Bloquer un profil AVANT tout match (depuis Découvrir ou Likes) — le
/// blocage n'était jusqu'ici possible que depuis une conversation déjà
/// matchée (docs/suivi-developpement.md section du 11/11/2026).
Future<void> showBlockProfileSheet(
  BuildContext context,
  WidgetRef ref, {
  required String targetUid,
  required String displayName,
  // Appelé seulement après un blocage réussi — chaque écran (Découvrir,
  // Likes) y retire le profil bloqué de son propre état local/provider
  // mis en cache, que ce fichier ne connaît pas (trouvé par audit : sans
  // ça, le profil bloqué restait visible/swipable sur la carte déjà
  // affichée jusqu'à ce que l'écran soit quitté puis rouvert).
  VoidCallback? onBlocked,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(context.l10n.blockProfileConfirmTitle),
      content: Text(context.l10n.blockProfileConfirmBody(displayName)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(context.l10n.cancelButton),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(context.l10n.blockButton),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;

  try {
    await ref.read(messagesControllerProvider).block(targetUid);
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.l10n.blockProfileFailed)));
    }
    return;
  }

  // Le blocage serveur a réussi à partir d'ici — `onBlocked` ne doit
  // jamais pouvoir transformer ce succès en message d'échec. Trouvé par
  // revue de code : le premier essai appelait `onBlocked` DANS le même
  // try/catch que l'appel réseau, donc une erreur locale (ex. `ref` déjà
  // disposé parce que l'utilisateur a quitté l'écran pendant l'attente)
  // affichait "blocage échoué" alors que la personne était déjà bloquée.
  try {
    onBlocked?.call();
  } catch (_) {
    // Ignoré volontairement : le blocage réel a déjà réussi, seul le
    // retrait visuel immédiat de l'écran appelant a échoué.
  }
  if (context.mounted) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(context.l10n.blockProfileSuccess)));
  }
}
