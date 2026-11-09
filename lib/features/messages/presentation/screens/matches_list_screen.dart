import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../messages_controller.dart';
import 'chat_screen.dart';

/// Écran Messages — fidèle au prototype visuel validé (artifact
/// Kamalove, Messages.dc.html).
class MatchesListScreen extends ConsumerWidget {
  const MatchesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchesAsync = ref.watch(matchesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: matchesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => const Center(child: Text('Impossible de charger les conversations.')),
        data: (matches) {
          if (matches.isEmpty) {
            return const Center(child: Text('Pas encore de match — va faire un tour sur Découvrir.'));
          }
          return ListView.separated(
            itemCount: matches.length,
            separatorBuilder: (_, _) => const Divider(height: 1, color: AppColors.border),
            itemBuilder: (context, i) {
              final m = matches[i];
              return ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.placeholder,
                  child: Icon(Icons.person_outline, color: Color(0xFFC9C0B2)),
                ),
                title: Text(m.otherDisplayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                  m.lastMessagePreview?.isNotEmpty == true
                      ? m.lastMessagePreview!
                      : 'Dites bonjour 👋',
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
