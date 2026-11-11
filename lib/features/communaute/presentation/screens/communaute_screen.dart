import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../../domain/community_post.dart';
import '../communaute_controller.dart';
import 'create_post_screen.dart';
import 'events_tab.dart';
import 'post_detail_screen.dart';

const _annonceTypes = ['annonce_publique', 'annonce_privee', 'annonce_libre'];

/// Communauté — 4 espaces en pilules (référence visuelle validée par le
/// propriétaire, 11/11/2026) : Communauté (fil social), Événements
/// (découverte, spec section 1/10), Actualités (annonces), Conseils.
class CommunauteScreen extends StatefulWidget {
  const CommunauteScreen({super.key});

  @override
  State<CommunauteScreen> createState() => _CommunauteScreenState();
}

class _CommunauteScreenState extends State<CommunauteScreen> {
  int _tab = 0;
  static const _screens = [_FeedTab(), EventsTab(), _NewsTab(), _TipsTab()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _TabPill(
                      icon: Icons.groups_outlined,
                      label: context.l10n.navCommunity,
                      selected: _tab == 0,
                      onTap: () => setState(() => _tab = 0),
                    ),
                    const SizedBox(width: 8),
                    _TabPill(
                      icon: Icons.event_outlined,
                      label: context.l10n.navEvents,
                      selected: _tab == 1,
                      onTap: () => setState(() => _tab = 1),
                    ),
                    const SizedBox(width: 8),
                    _TabPill(
                      icon: Icons.campaign_outlined,
                      label: context.l10n.navNews,
                      selected: _tab == 2,
                      onTap: () => setState(() => _tab = 2),
                    ),
                    const SizedBox(width: 8),
                    _TabPill(
                      icon: Icons.star_outline,
                      label: context.l10n.navTips,
                      selected: _tab == 3,
                      onTap: () => setState(() => _tab = 3),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(child: IndexedStack(index: _tab, children: _screens)),
          ],
        ),
      ),
    );
  }
}

class _TabPill extends StatelessWidget {
  const _TabPill({required this.icon, required this.label, required this.selected, required this.onTap});

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent : AppColors.backgroundSoft,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? AppColors.accent : AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: selected ? AppColors.noirProfond : AppColors.muted),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.noirProfond : AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedTab extends ConsumerWidget {
  const _FeedTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedAsync = ref.watch(communityFeedProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.accent,
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CreatePostScreen()),
        ),
        child: const Icon(Icons.add, color: AppColors.noirProfond),
      ),
      body: feedAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text(context.l10n.feedLoadFailed)),
        data: (posts) {
          if (posts.isEmpty) {
            return Center(child: Text(context.l10n.nothingToShowYet));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: posts.length,
            itemBuilder: (context, i) => _PostCard(post: posts[i]),
          );
        },
      ),
    );
  }
}

class _NewsTab extends ConsumerWidget {
  const _NewsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedAsync = ref.watch(communityFeedProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.accent,
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CreatePostScreen()),
        ),
        child: const Icon(Icons.add, color: AppColors.noirProfond),
      ),
      body: feedAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text(context.l10n.feedLoadFailed)),
        data: (posts) {
          final news = posts.where((p) => _annonceTypes.contains(p.type)).toList();
          if (news.isEmpty) {
            return Center(child: Text(context.l10n.nothingToShowYet));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: news.length,
            itemBuilder: (context, i) => _PostCard(post: news[i]),
          );
        },
      ),
    );
  }
}

/// Conseils — contenu éditorial rédigé par un administrateur
/// (adminCreateTip/manageTips.ts, 11/11/2026) : ni la spec ni la
/// référence visuelle ne définissaient le contenu au-delà du nom de
/// l'onglet, donc une rédaction humaine validée plutôt qu'un contenu
/// généré ou une liste figée côté client.
class _TipsTab extends ConsumerWidget {
  const _TipsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tipsAsync = ref.watch(communityTipsProvider);
    return Scaffold(
      body: tipsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text(context.l10n.feedLoadFailed)),
        data: (tips) {
          if (tips.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  context.l10n.noTipsYet,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.muted),
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: tips.length,
            itemBuilder: (context, i) => _TipCard(tip: tips[i]),
          );
        },
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  const _TipCard({required this.tip});
  final Map<String, dynamic> tip;

  @override
  Widget build(BuildContext context) {
    final category = tip['category'] as String?;
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppColors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (category != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(999)),
                child: Text(
                  tipCategoryLabel(category, context.l10n),
                  style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w600, fontSize: 11),
                ),
              ),
              const SizedBox(height: 8),
            ],
            Text(tip['title'] as String? ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 6),
            Text(tip['body'] as String? ?? '', style: const TextStyle(fontSize: 13.5, height: 1.4)),
          ],
        ),
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({required this.post});
  final CommunityPost post;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppColors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        title: Text(post.title ?? postTypeLabel(post.type, context.l10n), style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(post.text, maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: post.isEvent
            ? Text('${post.participantsCount}/${post.capacity ?? "-"}')
            : null,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => PostDetailScreen(post: post)),
        ),
      ),
    );
  }
}
