import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../../data/likes_repository.dart';
import '../../domain/mini_profile.dart';
import '../likes_controller.dart';

/// Écran Likes — fidèle au prototype visuel validé (artifact MERUT,
/// Likes.dc.html). "Qui m'a liké" en détail est réservé à Premium (pas
/// encore construit, voir docs/suivi-developpement.md) : en attendant,
/// seul le nombre est affiché avec un teaser.
class LikesScreen extends ConsumerStatefulWidget {
  const LikesScreen({super.key});

  @override
  ConsumerState<LikesScreen> createState() => _LikesScreenState();
}

class _LikesScreenState extends ConsumerState<LikesScreen> {
  int _tab = 0; // 0 = "T'ont liké", 1 = "Mes likes"

  @override
  Widget build(BuildContext context) {
    final likesAsync = ref.watch(likesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.navLikes)),
      body: likesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text(context.l10n.likesLoadFailed)),
        data: (likes) {
          return SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.backgroundSoft,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        _TabButton(
                          label: context.l10n.likedYouTab(likes.likesReceivedCount),
                          selected: _tab == 0,
                          onTap: () => setState(() => _tab = 0),
                        ),
                        _TabButton(
                          label: context.l10n.myLikesTab,
                          selected: _tab == 1,
                          onTap: () => setState(() => _tab = 1),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: _tab == 0
                      ? _ReceivedTab(likes: likes)
                      : _MyLikesTab(profiles: likes.myLikes),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.ink : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : AppColors.muted,
            ),
          ),
        ),
      ),
    );
  }
}

class _ReceivedTab extends StatelessWidget {
  const _ReceivedTab({required this.likes});

  final LikesData likes;

  @override
  Widget build(BuildContext context) {
    if (likes.likesReceivedCount == 0) {
      return Center(child: Text(context.l10n.noOneLikedYouYet));
    }
    if (likes.isPremium) {
      return _ProfileGrid(profiles: likes.likesReceived, onLongPress: null);
    }
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: likes.likesReceivedCount,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.8,
          ),
          itemBuilder: (context, i) => Container(
            decoration: BoxDecoration(
              color: AppColors.placeholder,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Icon(Icons.lock_outline, color: Color(0xFFB8AE9D)),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(16)),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.l10n.seeWhoLikedYou, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      context.l10n.unlockProfilesWithPremium(likes.likesReceivedCount),
                      style: const TextStyle(fontSize: 12, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(999)),
                child: Text(context.l10n.premiumTeaserPrice, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MyLikesTab extends ConsumerWidget {
  const _MyLikesTab({required this.profiles});

  final List<MiniProfile> profiles;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (profiles.isEmpty) {
      return Center(child: Text(context.l10n.noPendingLikesYet));
    }
    return _ProfileGrid(
      profiles: profiles,
      onLongPress: (p) => _confirmRetract(context, ref, p),
    );
  }

  void _confirmRetract(BuildContext context, WidgetRef ref, MiniProfile p) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.retractLikeConfirmTitle),
        content: Text(context.l10n.retractLikeConfirmBody(p.displayName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(context.l10n.cancelButton),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              try {
                await ref.read(likesControllerProvider).retract(p.uid);
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(context.l10n.retractLikeFailed)),
                  );
                }
              }
            },
            child: Text(context.l10n.retractButton),
          ),
        ],
      ),
    );
  }
}

class _ProfileGrid extends StatelessWidget {
  const _ProfileGrid({required this.profiles, required this.onLongPress});

  final List<MiniProfile> profiles;
  final void Function(MiniProfile)? onLongPress;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: profiles.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemBuilder: (context, i) {
        final p = profiles[i];
        return InkWell(
          onLongPress: onLongPress == null ? null : () => onLongPress!(p),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(16),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    width: double.infinity,
                    color: AppColors.placeholder,
                    child: const Icon(Icons.person_outline, color: Color(0xFFC9C0B2)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${p.displayName}, ${p.age}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                      Text(p.city, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
