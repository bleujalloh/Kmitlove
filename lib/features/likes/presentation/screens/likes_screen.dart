import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/block_action.dart';
import '../../../../core/widgets/boost_action.dart';
import '../../../../core/widgets/empty_state_cards.dart';
import '../../../../core/widgets/tab_pill.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../../../premium/presentation/screens/premium_screen.dart';
import '../../../decouvrir/presentation/decouvrir_controller.dart';
import '../../../profil/presentation/screens/profil_detail_screen.dart';
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
      appBar: AppBar(
        title: Text(context.l10n.navLikes),
        actions: [
          IconButton(
            tooltip: context.l10n.refreshButton,
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(likesProvider),
          ),
        ],
      ),
      body: likesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text(context.l10n.likesLoadFailed)),
        data: (likes) {
          return SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                  child: Row(
                    children: [
                      TabPill(
                        label: context.l10n.likedYouTab(likes.likesReceivedCount),
                        selected: _tab == 0,
                        onTap: () => setState(() => _tab = 0),
                      ),
                      const SizedBox(width: 8),
                      TabPill(
                        label: context.l10n.myLikesTab,
                        selected: _tab == 1,
                        onTap: () => setState(() => _tab = 1),
                      ),
                    ],
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

class _ReceivedTab extends ConsumerWidget {
  const _ReceivedTab({required this.likes});

  final LikesData likes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (likes.likesReceivedCount == 0) {
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        child: Column(
          children: [
            EmptyStateCards(
              title: context.l10n.noOneLikedYouYet,
              subtitle: context.l10n.noOneLikedYouYetHint,
              profiles: ref.watch(suggestedProfilesProvider),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                // Boost gratuit déjà existant (jetons), jamais un nouvel
                // achat ni une fonctionnalité inventée — demande explicite
                // du propriétaire, 12/11/2026 : même mécanisme que
                // l'onglet Profil (activateProfileBoost, partagé avec
                // PremiumScreen).
                onPressed: () => activateProfileBoost(context, ref),
                icon: const Icon(Icons.bolt),
                label: Text(context.l10n.boostYourProfileButton),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.noirProfond,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                // Route vers l'écran Premium déjà existant, qui communique
                // déjà l'état réel sans bouton d'achat fonctionnel — les
                // paiements restent en pause (functions/src/index.ts),
                // jamais un achat réel ou simulé déclenché ici.
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PremiumScreen()),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.ink,
                  side: const BorderSide(color: AppColors.border),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                ),
                child: Text(context.l10n.upgradeToPremiumButton),
              ),
            ),
          ],
        ),
      );
    }
    if (likes.isPremium) {
      return _ProfileGrid(
        profiles: likes.likesReceived,
        onLongPress: (p) => showBlockProfileSheet(
          context,
          ref,
          targetUid: p.uid,
          displayName: p.displayName,
          onBlocked: () {
            ref.invalidate(likesProvider);
            // Le même profil peut aussi être en cache dans la pile
            // Découvrir (decouvrirControllerProvider n'est pas autoDispose
            // et MainShell garde cet onglet vivant dans un IndexedStack) —
            // sans ce retrait explicite, bloquer depuis Likes laissait la
            // personne swipable en revenant sur Découvrir (trouvé par
            // revue de code, même défaut que l'inverse déjà corrigé).
            ref.read(decouvrirControllerProvider.notifier).removeCandidate(p.uid);
          },
        ),
      );
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
              child: Icon(Icons.lock_outline, color: AppColors.placeholderIcon),
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
                decoration: BoxDecoration(color: AppColors.surfaceDark, borderRadius: BorderRadius.circular(999)),
                child: Text(
                  context.l10n.premiumTeaserPrice,
                  style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold),
                ),
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
      return Center(
        child: EmptyStateCards(
          icon: Icons.send_outlined,
          title: context.l10n.noPendingLikesYet,
          subtitle: context.l10n.noPendingLikesYetHint,
          profiles: ref.watch(suggestedProfilesProvider),
        ),
      );
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

class _ProfileGrid extends ConsumerWidget {
  const _ProfileGrid({required this.profiles, required this.onLongPress});

  final List<MiniProfile> profiles;
  final void Function(MiniProfile)? onLongPress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        final photoUrl = ref.watch(candidateFirstPhotoUrlProvider(p.uid)).value;
        return InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ProfilDetailScreen(uid: p.uid, isVerified: p.isVerified),
            ),
          ),
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
                    child: photoUrl != null
                        ? Image.network(photoUrl, fit: BoxFit.cover, width: double.infinity)
                        : const Icon(Icons.person_outline, color: AppColors.placeholderIcon),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              '${p.displayName}, ${p.age}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (p.isVerified) ...[
                            const SizedBox(width: 3),
                            const Icon(Icons.verified, color: AppColors.accent, size: 13),
                          ],
                        ],
                      ),
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
