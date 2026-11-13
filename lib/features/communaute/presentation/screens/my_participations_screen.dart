import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/firebase_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../../domain/community_post.dart';
import '../communaute_controller.dart';
import 'post_detail_screen.dart';

/// "Mes participations" (spec Communauté section 10) — demandes
/// envoyées, invitations reçues, événements confirmés, tous posts
/// confondus (requête de groupe de collections, voir
/// communaute_repository.dart). N'existait pas côté client jusqu'ici,
/// alors que l'index Firestore nécessaire était déjà déclaré.
class MyParticipationsScreen extends ConsumerWidget {
  const MyParticipationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final participationsAsync = ref.watch(myParticipationsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.myParticipationsTitle)),
      body: participationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text(context.l10n.genericError)),
        data: (participations) {
          if (participations.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  context.l10n.noParticipationsYet,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.muted),
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: participations.length,
            separatorBuilder: (_, _) => Divider(height: 1, color: AppColors.border),
            itemBuilder: (context, i) => _ParticipationTile(participation: participations[i]),
          );
        },
      ),
    );
  }
}

class _ParticipationTile extends ConsumerWidget {
  const _ParticipationTile({required this.participation});
  final Map<String, dynamic> participation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postId = participation['postId'] as String;
    final status = participation['status'] as String? ?? 'pending';
    final postSnap = ref.watch(_postByIdProvider(postId));

    return postSnap.when(
      loading: () => const ListTile(title: Text('…')),
      error: (e, st) => const SizedBox.shrink(),
      data: (post) {
        if (post == null) return const SizedBox.shrink();
        return ListTile(
          title: Text(post.title ?? post.text, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(context.l10n.statusLabel(status)),
          trailing: Icon(Icons.chevron_right, color: AppColors.muted),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => PostDetailScreen(post: post)),
          ),
        );
      },
    );
  }
}

final _postByIdProvider = StreamProvider.family<CommunityPost?, String>((ref, postId) {
  return ref.watch(firestoreProvider).collection('community_posts').doc(postId).snapshots().map(
        (snap) => snap.data() == null ? null : CommunityPost.fromDoc(snap),
      );
});
