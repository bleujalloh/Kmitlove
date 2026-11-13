import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../../domain/community_post.dart';
import '../communaute_controller.dart';
import 'create_post_screen.dart';
import 'post_detail_screen.dart';

/// Espace organisateur (spec Communauté section 8, 11/11/2026) — séparé
/// de la page Communauté des membres : créer/gérer ses événements,
/// consulter ses statistiques. Gestion des demandes/invitations/QR se
/// fait depuis la fiche de chaque événement (post_detail_screen.dart),
/// réservée à l'organisateur de ce post précis.
class OrganizerDashboardScreen extends ConsumerWidget {
  const OrganizerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(myOrganizedEventsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.organizerDashboardTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CreatePostScreen(organizerMode: true)),
            ),
          ),
        ],
      ),
      body: eventsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text(context.l10n.genericError)),
        data: (events) {
          final onlyEvents = events.where((p) => p.isEvent).toList();
          if (onlyEvents.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      context.l10n.myEventsEmpty,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.muted),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const CreatePostScreen(organizerMode: true)),
                      ),
                      child: Text(context.l10n.createEventButton),
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: onlyEvents.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final post = onlyEvents[i];
              return _OrganizerEventCard(post: post);
            },
          );
        },
      ),
    );
  }
}

class _OrganizerEventCard extends StatelessWidget {
  const _OrganizerEventCard({required this.post});

  final CommunityPost post;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => PostDetailScreen(post: post)),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    post.title?.isNotEmpty == true ? post.title! : post.text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.accentSoft,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    post.status == 'pending_review' ? '…' : eventStateLabel(post.eventState ?? 'prevu', context.l10n),
                    style: TextStyle(fontSize: 11, color: AppColors.accent, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${post.participantsCount}${post.capacity != null ? '/${post.capacity}' : ''} participants',
              style: TextStyle(color: AppColors.muted, fontSize: 12.5),
            ),
          ],
        ),
      ),
    );
  }
}
