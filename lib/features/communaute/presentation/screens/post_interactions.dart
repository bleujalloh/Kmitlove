import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/firebase_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/message_time.dart';
import '../../../../core/widgets/report_reasons.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../../domain/community_post.dart';
import '../communaute_controller.dart';

/// J'aime (♥ + compteur) et nombre de réponses d'une publication du fil —
/// ligne du bas de la carte du prototype Communaute.dc.html. Les j'aime
/// passent par togglePostLike (serveur), les compteurs sont lus en
/// Firestore.
class PostInteractionsRow extends ConsumerWidget {
  const PostInteractionsRow({super.key, required this.post, this.onRepliesTap});

  final CommunityPost post;
  final VoidCallback? onRepliesTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liked = ref.watch(postMyLikeProvider(post.id)).value ?? false;
    final likeCount = ref.watch(postLikeCountProvider(post.id)).value ?? 0;
    final replyCount = ref.watch(postReplyCountProvider(post.id)).value ?? 0;

    return Row(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () async {
            try {
              await ref.read(communauteControllerProvider).toggleLike(post.id);
            } catch (_) {
              if (context.mounted) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(context.l10n.likeFailed)));
              }
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
            child: Row(
              children: [
                Icon(
                  liked ? Icons.favorite : Icons.favorite_border,
                  size: 18,
                  color: liked ? AppColors.accent : AppColors.muted,
                ),
                const SizedBox(width: 6),
                Text('$likeCount', style: TextStyle(fontSize: 13, color: AppColors.muted)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 18),
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onRepliesTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
            child: Row(
              children: [
                Icon(Icons.chat_bubble_outline, size: 17, color: AppColors.muted),
                const SizedBox(width: 6),
                Text(
                  context.l10n.postRepliesCount(replyCount),
                  style: TextStyle(fontSize: 13, color: AppColors.muted),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// En-tête d'une publication du fil : auteur et ancienneté (« Fatou —
/// Publication communautaire · 3h » dans le prototype).
class PostAuthorLine extends ConsumerWidget {
  const PostAuthorLine({super.key, required this.post});

  final CommunityPost post;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(memberDisplayNameProvider(post.authorUid)).value;
    final at = post.createdAt;
    final when = at == null
        ? null
        : formatMessageTime(
            at,
            DateTime.now(),
            locale: Localizations.localeOf(context).toLanguageTag(),
            yesterdayLabel: context.l10n.messageTimeYesterday,
          );
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(color: AppColors.placeholder, shape: BoxShape.circle),
          child: Icon(Icons.person_outline, size: 16, color: AppColors.placeholderIcon),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name ?? '…', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
              Text(
                [context.l10n.publicationByMember, ?when].join(' · '),
                style: TextStyle(fontSize: 11, color: AppColors.muted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Liste des réponses et champ d'envoi, en bas du détail d'une
/// publication.
class PostRepliesSection extends ConsumerStatefulWidget {
  const PostRepliesSection({super.key, required this.post});

  final CommunityPost post;

  @override
  ConsumerState<PostRepliesSection> createState() => _PostRepliesSectionState();
}

class _PostRepliesSectionState extends ConsumerState<PostRepliesSection> {
  final _controller = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await ref.read(communauteControllerProvider).reply(widget.post.id, text);
      _controller.clear();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.l10n.replySendFailed)));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final repliesAsync = ref.watch(postRepliesProvider(widget.post.id));
    final myUid = ref.watch(firebaseAuthProvider).currentUser?.uid;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.l10n.repliesTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 10),
        repliesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => Text(context.l10n.feedLoadFailed),
          data: (replies) => Column(
            children: [
              for (final r in replies)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(r.authorName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  subtitle: Text(r.text, style: const TextStyle(fontSize: 13.5, height: 1.35)),
                  trailing: r.authorUid == myUid
                      ? null
                      : PopupMenuButton<String>(
                          icon: Icon(Icons.flag_outlined, size: 18, color: AppColors.muted),
                          onSelected: (reason) async {
                            await ref
                                .read(communauteControllerProvider)
                                .report(widget.post.id, reason, replyId: r.id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(content: Text(context.l10n.reportSent)));
                            }
                          },
                          itemBuilder: (_) => reportReasonLabels(context.l10n)
                              .entries
                              .map((e) => PopupMenuItem(
                                    value: e.key,
                                    child: Text(context.l10n.reportWithReason(e.value)),
                                  ))
                              .toList(),
                        ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                maxLength: 500,
                minLines: 1,
                maxLines: 4,
                decoration: InputDecoration(hintText: context.l10n.replyHint, counterText: ''),
              ),
            ),
            IconButton(
              icon: _sending
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : Icon(Icons.send, color: AppColors.accent),
              onPressed: _sending ? null : _send,
            ),
          ],
        ),
      ],
    );
  }
}
