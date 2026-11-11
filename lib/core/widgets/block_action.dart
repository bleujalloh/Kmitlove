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
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.l10n.blockProfileSuccess)));
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.l10n.blockProfileFailed)));
    }
  }
}
