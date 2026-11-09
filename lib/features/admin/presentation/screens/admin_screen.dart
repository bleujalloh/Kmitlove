import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../admin_controller.dart';

/// Espace admin minimal (cahier des charges section 6) : traitement des
/// signalements/révisions de filtrage et des annonces/événements en
/// attente. Ne couvre pas tout (pas de gestion des utilisateurs, des
/// abonnements, ni de statistiques) — voir docs/suivi-developpement.md.
class AdminScreen extends ConsumerWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Administration'),
          bottom: const TabBar(
            tabs: [Tab(text: 'Signalements'), Tab(text: 'Publications en attente')],
          ),
        ),
        body: const TabBarView(
          children: [_ModerationTab(), _PendingPostsTab()],
        ),
      ),
    );
  }
}

class _ModerationTab extends ConsumerWidget {
  const _ModerationTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(moderationRequestsProvider);
    return requestsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => const Center(child: Text('Impossible de charger les signalements.')),
      data: (requests) {
        if (requests.isEmpty) return const Center(child: Text('Rien en attente.'));
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          separatorBuilder: (_, _) => const Divider(),
          itemBuilder: (context, i) {
            final r = requests[i];
            final isFiltrageReview = r['type'] == 'filtrage_review';
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r['type'] as String? ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                  if (r['reason'] != null) Text('Motif : ${r['reason']}'),
                  if (r['uid'] != null) Text('Membre : ${r['uid']}'),
                  if (r['targetUid'] != null) Text('Visé : ${r['targetUid']}'),
                  if (r['lastScore'] != null) Text('Score filtrage : ${r['lastScore']}'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: isFiltrageReview
                        ? [
                            TextButton(
                              onPressed: () => ref
                                  .read(adminRepositoryProvider)
                                  .resolveFiltrageReview(r['id'] as String, true)
                                  .then((_) => ref.invalidate(moderationRequestsProvider)),
                              child: const Text('Activer le compte'),
                            ),
                            TextButton(
                              onPressed: () => ref
                                  .read(adminRepositoryProvider)
                                  .resolveFiltrageReview(r['id'] as String, false)
                                  .then((_) => ref.invalidate(moderationRequestsProvider)),
                              child: const Text('Maintenir le refus'),
                            ),
                          ]
                        : [
                            TextButton(
                              onPressed: () => ref
                                  .read(adminRepositoryProvider)
                                  .resolveModerationRequest(r['id'] as String, 'dismiss')
                                  .then((_) => ref.invalidate(moderationRequestsProvider)),
                              child: const Text('Classer sans suite'),
                            ),
                            TextButton(
                              onPressed: () => ref
                                  .read(adminRepositoryProvider)
                                  .resolveModerationRequest(r['id'] as String, 'warn')
                                  .then((_) => ref.invalidate(moderationRequestsProvider)),
                              child: const Text('Avertir'),
                            ),
                            TextButton(
                              onPressed: () => ref
                                  .read(adminRepositoryProvider)
                                  .resolveModerationRequest(r['id'] as String, 'suspend')
                                  .then((_) => ref.invalidate(moderationRequestsProvider)),
                              style: TextButton.styleFrom(foregroundColor: AppColors.accent),
                              child: const Text('Suspendre'),
                            ),
                          ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _PendingPostsTab extends ConsumerWidget {
  const _PendingPostsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(pendingCommunityPostsProvider);
    return postsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => const Center(child: Text('Impossible de charger les publications.')),
      data: (posts) {
        if (posts.isEmpty) return const Center(child: Text('Rien en attente.'));
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: posts.length,
          separatorBuilder: (_, _) => const Divider(),
          itemBuilder: (context, i) {
            final p = posts[i];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p['title'] as String? ?? p['type'] as String? ?? '',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(p['text'] as String? ?? ''),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      TextButton(
                        onPressed: () => ref
                            .read(adminRepositoryProvider)
                            .reviewCommunityPost(p['id'] as String, true)
                            .then((_) => ref.invalidate(pendingCommunityPostsProvider)),
                        child: const Text('Valider'),
                      ),
                      TextButton(
                        onPressed: () => ref
                            .read(adminRepositoryProvider)
                            .reviewCommunityPost(p['id'] as String, false)
                            .then((_) => ref.invalidate(pendingCommunityPostsProvider)),
                        style: TextButton.styleFrom(foregroundColor: AppColors.accent),
                        child: const Text('Refuser'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
