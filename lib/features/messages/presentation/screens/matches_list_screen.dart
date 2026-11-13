import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/message_time.dart';
import '../../../../core/widgets/empty_state_cards.dart';
import '../../../../core/widgets/tab_pill.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../../../communaute/presentation/screens/communaute_screen.dart';
import '../../../../core/providers/firebase_providers.dart';
import '../../../decouvrir/presentation/decouvrir_controller.dart';
import '../../domain/message.dart';
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
                profiles: ref.watch(suggestedProfilesProvider),
              ),
            );
          }
          final myUid = ref.watch(authStateProvider).value?.uid ?? '';
          return Column(
            children: [
              // Rangée de ronds du prototype (Messages.dc.html) : photo et
              // prénom de chaque match, contour accent quand il y a du
              // nouveau (non lu, ou match encore sans message).
              SizedBox(
                height: 96,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
                  itemCount: matches.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 14),
                  itemBuilder: (context, i) => _MatchBubble(match: matches[i], myUid: myUid),
                ),
              ),
              Divider(height: 1, color: AppColors.border),
              Expanded(
                child: ListView.separated(
                  itemCount: matches.length,
                  separatorBuilder: (_, _) => Divider(height: 1, color: AppColors.border),
                  itemBuilder: (context, i) => _ConversationRow(match: matches[i], myUid: myUid),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Il y a du nouveau dans cette conversation : dernier message reçu et pas
/// encore lu par moi (jamais pour un message que j'ai moi-même envoyé).
bool _hasUnread(ChatMessage? last, String myUid) {
  return last != null && last.fromUid != myUid && !last.readBy.contains(myUid);
}

void _openChat(BuildContext context, MatchSummary m) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => ChatScreen(
        matchId: m.matchId,
        otherUid: m.otherUid,
        otherDisplayName: m.otherDisplayName,
      ),
    ),
  );
}

/// Photo approuvée du membre (même source que Découvrir et Likes :
/// candidateFirstPhotoUrlProvider), silhouette tant qu'il n'en a pas.
class _MemberAvatar extends ConsumerWidget {
  const _MemberAvatar({required this.uid, required this.size});

  final String uid;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final url = ref.watch(candidateFirstPhotoUrlProvider(uid)).value;
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: AppColors.placeholder, shape: BoxShape.circle),
      child: url != null
          ? Image.network(url, fit: BoxFit.cover)
          : Icon(Icons.person_outline, size: size * 0.42, color: AppColors.placeholderIcon),
    );
  }
}

class _MatchBubble extends ConsumerWidget {
  const _MatchBubble({required this.match, required this.myUid});

  final MatchSummary match;
  final String myUid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final last = ref.watch(lastMessageProvider(match.matchId)).value;
    final lastLoaded = ref.watch(lastMessageProvider(match.matchId)).hasValue;
    final fresh = lastLoaded && (last == null || _hasUnread(last, myUid));
    return InkWell(
      onTap: () => _openChat(context, match),
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 62,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: fresh ? AppColors.accent : AppColors.border, width: 2),
              ),
              child: _MemberAvatar(uid: match.otherUid, size: 50),
            ),
            const SizedBox(height: 6),
            Text(
              match.otherDisplayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConversationRow extends ConsumerWidget {
  const _ConversationRow({required this.match, required this.myUid});

  final MatchSummary match;
  final String myUid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final last = ref.watch(lastMessageProvider(match.matchId)).value;
    final unread = _hasUnread(last, myUid);
    final at = match.lastMessageAt;
    final time = at == null
        ? null
        : formatMessageTime(
            at,
            DateTime.now(),
            locale: Localizations.localeOf(context).toLanguageTag(),
            yesterdayLabel: context.l10n.messageTimeYesterday,
          );
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: _MemberAvatar(uid: match.otherUid, size: 52),
      title: Row(
        children: [
          Expanded(
            child: Text(
              match.otherDisplayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          if (time != null)
            Text(time, style: TextStyle(fontSize: 11, color: AppColors.muted)),
        ],
      ),
      subtitle: Text(
        match.lastMessagePreview?.isNotEmpty == true
            ? match.lastMessagePreview!
            : context.l10n.sayHelloPreview,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: unread ? FontWeight.w600 : FontWeight.normal,
          color: unread ? null : AppColors.muted,
        ),
      ),
      trailing: unread
          ? Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
            )
          : null,
      onTap: () => _openChat(context, match),
    );
  }
}
