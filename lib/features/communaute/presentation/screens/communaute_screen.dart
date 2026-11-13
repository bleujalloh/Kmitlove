import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/tab_pill.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../../domain/community_post.dart';
import '../communaute_controller.dart';
import 'create_post_screen.dart';
import 'events_tab.dart';
import 'post_detail_screen.dart';
import 'post_interactions.dart';

const _annonceTypes = ['annonce_publique', 'annonce_privee', 'annonce_libre'];

/// Communauté — 4 espaces en pilules (référence visuelle validée par le
/// propriétaire, 11/11/2026) : Communauté (fil social), Événements
/// (découverte, spec section 1/10), Actualités (annonces), Conseils.
class CommunauteScreen extends ConsumerWidget {
  const CommunauteScreen({super.key});

  static const _screens = [_FeedTab(), EventsTab(), _NewsTab(), _TipsTab()];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(communauteTabProvider);
    void setTab(int i) => ref.read(communauteTabProvider.notifier).state = i;

    return Scaffold(
      // Communauté n'est plus un onglet de la barre du bas (demande
      // confirmée du propriétaire, 12/11/2026) — toujours atteint
      // maintenant via Navigator.push (pilule de l'AppBar Messages),
      // donc a besoin d'une vraie AppBar avec retour : sans elle, cet
      // écran aurait été un cul-de-sac complet sur une plateforme sans
      // geste "retour" matériel.
      appBar: AppBar(title: Text(context.l10n.navCommunity)),
      body: SafeArea(
        child: Column(
          children: [
            _CommunautePillBar(tab: tab, onSelect: setTab),
            Expanded(child: IndexedStack(index: tab, children: _screens)),
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
    void open() => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => PostDetailScreen(post: post)),
        );
    // Publication du fil : carte du prototype (auteur, texte, j'aime et
    // réponses) ; les annonces et événements gardent leur carte actuelle.
    if (post.type == 'publication') {
      return Card(
        margin: const EdgeInsets.only(bottom: 14),
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: AppColors.border),
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: open,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PostAuthorLine(post: post),
                const SizedBox(height: 12),
                Text(post.text, style: const TextStyle(fontSize: 14, height: 1.4)),
                const SizedBox(height: 10),
                PostInteractionsRow(post: post, onRepliesTap: open),
              ],
            ),
          ),
        ),
      );
    }
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

/// Rangée de pilules de Communauté : l'onglet actif est ramené au centre
/// de l'écran (demande du propriétaire, 13/11/2026 : sur « Actualités » ou
/// « Conseils », la pilule choisie était coupée sur le bord).
class _CommunautePillBar extends StatefulWidget {
  const _CommunautePillBar({required this.tab, required this.onSelect});

  final int tab;
  final ValueChanged<int> onSelect;

  @override
  State<_CommunautePillBar> createState() => _CommunautePillBarState();
}

class _CommunautePillBarState extends State<_CommunautePillBar> {
  final _keys = List.generate(4, (_) => GlobalKey());

  @override
  void initState() {
    super.initState();
    _centerSelected(animate: false);
  }

  @override
  void didUpdateWidget(covariant _CommunautePillBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tab != widget.tab) _centerSelected(animate: true);
  }

  void _centerSelected({required bool animate}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _keys[widget.tab].currentContext;
      if (ctx == null) return;
      Scrollable.ensureVisible(
        ctx,
        alignment: 0.5,
        duration: animate ? const Duration(milliseconds: 250) : Duration.zero,
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.groups_outlined, context.l10n.navCommunity),
      (Icons.event_outlined, context.l10n.navEvents),
      (Icons.campaign_outlined, context.l10n.navNews),
      (Icons.star_outline, context.l10n.navTips),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              KeyedSubtree(
                key: _keys[i],
                child: TabPill(
                  icon: items[i].$1,
                  label: items[i].$2,
                  selected: widget.tab == i,
                  onTap: () => widget.onSelect(i),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
