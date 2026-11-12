import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/empty_state_cards.dart';
import '../../../../core/widgets/tab_pill.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../../../communaute/presentation/screens/communaute_screen.dart';
import '../messages_controller.dart';
import 'chat_screen.dart';

/// Écran Messages — fidèle au prototype visuel validé (artifact
/// MERUT, Messages.dc.html).
class MatchesListScreen extends ConsumerWidget {
  const MatchesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchesAsync = ref.watch(matchesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.navMessages, overflow: TextOverflow.ellipsis),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              // Communauté n'est plus un onglet de la barre du bas (demande
              // confirmée du propriétaire, capture d'écran annotée,
              // 12/11/2026) — accessible depuis cette pilule, même style
              // que les pilules déjà en place ailleurs (filtres Découvrir,
              // onglets Likes), réutilisée telle quelle (TabPill).
              child: TabPill(
                icon: Icons.groups_outlined,
                label: context.l10n.navCommunity,
                selected: false,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CommunauteScreen()),
                ),
              ),
            ),
          ),
        ],
      ),
      body: matchesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text(context.l10n.conversationsLoadFailed)),
        data: (matches) {
          if (matches.isEmpty) {
            return Center(
              child: EmptyStateCards(
                icon: Icons.chat_bubble_outline,
                title: context.l10n.noMatchesYet,
                subtitle: context.l10n.noMatchesYetHint,
              ),
            );
          }
          return ListView.separated(
            itemCount: matches.length,
            separatorBuilder: (_, _) => const Divider(height: 1, color: AppColors.border),
            itemBuilder: (context, i) {
              final m = matches[i];
              return ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.placeholder,
                  child: Icon(Icons.person_outline, color: AppColors.placeholderIcon),
                ),
                title: Text(m.otherDisplayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                  m.lastMessagePreview?.isNotEmpty == true
                      ? m.lastMessagePreview!
                      : context.l10n.sayHelloPreview,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      matchId: m.matchId,
                      otherUid: m.otherUid,
                      otherDisplayName: m.otherDisplayName,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
