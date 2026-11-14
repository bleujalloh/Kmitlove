import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/action_feedback.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../messages_controller.dart';

/// "Mes blocages" — jusqu'ici, le blocage n'était visible/gérable que
/// depuis une conversation déjà matchée (bouton "Bloquer" dans
/// chat_screen.dart), sans aucun moyen de voir qui on a bloqué ni de
/// débloquer quelqu'un une fois la conversation quittée
/// (docs/suivi-developpement.md section du 11/11/2026).
class BlockedProfilesScreen extends ConsumerWidget {
  const BlockedProfilesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blocksAsync = ref.watch(myBlocksProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.blockedProfilesTitle)),
      body: blocksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text(context.l10n.genericError)),
        data: (blocks) {
          if (blocks.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  context.l10n.noBlockedProfiles,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.muted),
                ),
              ),
            );
          }
          return ListView.separated(
            itemCount: blocks.length,
            separatorBuilder: (_, _) => const SizedBox(height: 6),
            itemBuilder: (context, i) {
              final b = blocks[i];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.placeholder,
                  child: Icon(Icons.person_outline, color: AppColors.placeholderIcon),
                ),
                title: Text(b.displayName),
                trailing: TextButton(
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        title: Text(context.l10n.unblockConfirmTitle),
                        content: Text(context.l10n.unblockConfirmBody(b.displayName)),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(dialogContext).pop(false),
                            child: Text(context.l10n.cancelButton),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(dialogContext).pop(true),
                            child: Text(context.l10n.unblockButton),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true && context.mounted) {
                      await runWithFeedback(context, () => ref.read(messagesControllerProvider).unblock(b.uid));
                    }
                  },
                  child: Text(context.l10n.unblockButton),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
