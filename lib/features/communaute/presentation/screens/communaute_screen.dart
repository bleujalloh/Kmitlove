import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../../domain/community_post.dart';
import '../communaute_controller.dart';
import 'create_post_screen.dart';
import 'post_detail_screen.dart';

/// Écran Communauté — fidèle au prototype visuel validé (artifact
/// MERUT, Communaute.dc.html).
class CommunauteScreen extends ConsumerWidget {
  const CommunauteScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedAsync = ref.watch(communityFeedProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.navCommunity)),
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
            itemBuilder: (context, i) {
              final post = posts[i];
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
            },
          );
        },
      ),
    );
  }
}
