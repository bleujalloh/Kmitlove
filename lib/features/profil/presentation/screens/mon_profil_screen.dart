import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/firebase_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/age.dart';
import '../../../../core/widgets/settings_action.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../../../admin/presentation/admin_controller.dart';
import '../../../admin/presentation/screens/admin_screen.dart';
import '../../../communaute/presentation/communaute_controller.dart';
import '../../../communaute/presentation/screens/my_participations_screen.dart';
import '../../../communaute/presentation/screens/organizer_dashboard_screen.dart';
import '../../../communaute/presentation/screens/organizer_request_screen.dart';
import '../../../compatibilite/presentation/compat_controller.dart';
import '../../../compatibilite/presentation/screens/compat_screen.dart';
import '../../../identite/presentation/screens/identite_screen.dart';
import '../../../premium/presentation/screens/premium_screen.dart';
import '../photo_controller.dart';
import '../profil_controller.dart';
import 'photo_viewer_screen.dart';
import 'photos_section.dart';
import 'profil_detail_screen.dart';
import 'profil_edit_screen.dart';

/// Onglet "Profil" — ta propre fiche telle que tu peux la revoir et la
/// compléter, dernier des 4 onglets de la barre du bas (Découvrir/Likes/
/// Messages/Profil — Communauté n'en fait plus partie depuis le
/// 12/11/2026, accessible depuis une pilule dans l'AppBar de Messages).
/// N'existait pas avant (remarqué le 11/11) : les réglages secondaires
/// étaient atteignables depuis n'importe quel onglet via une icône
/// engrenage, mais rien ne montrait jamais la fiche elle-même d'un coup
/// d'œil.
class MonProfilScreen extends ConsumerWidget {
  const MonProfilScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profilAsync = ref.watch(profilProvider);
    final isAdmin = ref.watch(isAdminProvider).value ?? false;
    final status = ref.watch(userStatusProvider).value;
    final isVerified = status?['isVerified'] == true;
    final organizerStatus = ref.watch(myOrganizerStatusProvider).value;
    // Avatar dérivé de `myPhotosProvider` (un Stream, déjà utilisé par
    // PhotosSection juste en dessous) plutôt que de
    // `candidateFirstPhotoUrlProvider` (pensé pour un profil TIERS, un
    // FutureProvider à usage unique jamais invalidé) — trouvé par audit :
    // ajouter/supprimer une photo mettait bien à jour la galerie du bas
    // mais jamais ce grand avatar, qui gardait l'ancienne photo pour le
    // reste de la session tant que l'onglet restait ouvert dans
    // l'IndexedStack de MainShell.
    final myPhotos = ref.watch(myPhotosProvider).value ?? const [];
    final approvedPhotos = myPhotos.where((p) => p.status == 'approved');
    // Photo affichée dans l'avatar : la première photo validée, à défaut ma
    // première photo même en attente ou refusée (je suis le seul à voir
    // cet avatar ; les autres, eux, ne voient que les photos validées).
    final firstApprovedPhoto = approvedPhotos.isNotEmpty
        ? approvedPhotos.first
        : (myPhotos.isNotEmpty ? myPhotos.first : null);
    final photoUrl = firstApprovedPhoto == null
        ? null
        : ref.watch(photoDownloadUrlProvider(firstApprovedPhoto.storagePath)).value;

    // Les deux compteurs reflètent exactement ce que le serveur a calculé
    // (functions/src/premium/useJeton.ts, activateBoost.ts) — jamais de
    // seuil ou de logique de disponibilité recalculée côté client, sinon
    // c'est exactement le genre de règle qui doit rester côté serveur.
    final jetons = (status?['jetons'] as num?)?.toInt() ?? 0;
    final isPremium = status?['isPremium'] == true;
    final boostedUntil = status?['boostedUntil'];
    final isBoostedNow =
        boostedUntil is Timestamp && boostedUntil.toDate().isAfter(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.navProfile),
        actions: [buildSettingsAction(context)],
      ),
      body: profilAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text(context.l10n.unexpectedError(e.toString()))),
        data: (profil) {
          if (profil == null) return const SizedBox.shrink();
          // Calculé côté serveur (functions/src/profil/getProfileCompletion.ts),
          // exactement la même règle que celle qui influence le classement
          // dans Découvrir — jamais un second calcul Dart qui pourrait
          // diverger. 0 pendant le premier chargement (pas d'anneau vide
          // trompeur au-delà de ça, la valeur arrive en général très vite).
          final completionPercent = ref.watch(profileCompletionPercentProvider).value ?? 0;
          final completion = completionPercent / 100;

          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Center(
                  child: Column(
                    children: [
                      SizedBox(
                        width: 132,
                        height: 132,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 132,
                              height: 132,
                              child: CircularProgressIndicator(
                                value: completion,
                                strokeWidth: 4,
                                backgroundColor: AppColors.border,
                                color: AppColors.accent,
                              ),
                            ),
                            GestureDetector(
                              onTap: firstApprovedPhoto == null
                                  ? null
                                  : () => Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => PhotoViewerScreen(
                                            photos: myPhotos,
                                            initialIndex: myPhotos.indexOf(firstApprovedPhoto),
                                          ),
                                        ),
                                      ),
                              child: Container(
                                width: 112,
                                height: 112,
                                clipBehavior: Clip.antiAlias,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.placeholder,
                                ),
                                child: photoUrl != null
                                    ? Image.network(photoUrl, fit: BoxFit.cover)
                                    : Icon(Icons.person, size: 48, color: AppColors.placeholderIcon),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => ProfilEditScreen(existing: profil)),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: AppColors.accentSoft,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                context.l10n.profileCompletionPercent(completionPercent),
                                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.accent, fontSize: 13),
                              ),
                              const SizedBox(width: 2),
                              Icon(Icons.chevron_right, size: 16, color: AppColors.accent),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              '${profil.displayName}, ${ageFromBirthDate(profil.birthDate)}',
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.ink),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isVerified) ...[
                            const SizedBox(width: 6),
                            Icon(Icons.verified, color: AppColors.accent, size: 19),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${profil.city}, ${profil.country}',
                        style: TextStyle(color: AppColors.muted, fontSize: 13),
                      ),
                      if (completion < 1) ...[
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            context.l10n.profileCompletionHint,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: AppColors.muted),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _CounterTile(
                        icon: Icons.bolt,
                        count: '$jetons',
                        label: context.l10n.jetonsCounterLabel,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const PremiumScreen()),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _CounterTile(
                        icon: Icons.rocket_launch_outlined,
                        count: isBoostedNow ? '1' : (isPremium ? context.l10n.boostCounterIncluded : '0'),
                        label: context.l10n.boostCounterLabel,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const PremiumScreen()),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const PhotosSection(),
                const SizedBox(height: 16),
                _ProfilActionTile(
                  icon: Icons.edit_outlined,
                  title: context.l10n.editMyProfile,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => ProfilEditScreen(existing: profil)),
                  ),
                ),
                const SizedBox(height: 10),
                _ProfilActionTile(
                  icon: Icons.visibility_outlined,
                  title: context.l10n.viewMyProfileAsOthers,
                  onTap: () {
                    final uid = ref.read(firebaseAuthProvider).currentUser?.uid;
                    if (uid == null) return;
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ProfilDetailScreen(uid: uid, isVerified: isVerified, isPreview: true),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                _ProfilActionTile(
                  icon: Icons.verified_outlined,
                  title: isVerified ? context.l10n.identityVerifiedTitle : context.l10n.navIdentityVerification,
                  trailing: isVerified ? Icon(Icons.check_circle, color: AppColors.accent) : null,
                  onTap: isVerified
                      ? null
                      : () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const IdentiteScreen()),
                          ),
                ),
                const SizedBox(height: 10),
                _ProfilActionTile(
                  icon: Icons.favorite_border,
                  title: context.l10n.navCompatTest,
                  trailing: Text(
                    (ref.watch(myCompatAnswersProvider).value?.isNotEmpty ?? false)
                        ? context.l10n.compatTestDoneBadge
                        : context.l10n.compatTestTodoBadge,
                    style: TextStyle(fontSize: 12, color: AppColors.muted),
                  ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CompatScreen()),
                  ),
                ),
                const SizedBox(height: 10),
                _ProfilActionTile(
                  icon: Icons.event_available_outlined,
                  title: context.l10n.myParticipationsTitle,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const MyParticipationsScreen()),
                  ),
                ),
                const SizedBox(height: 10),
                _ProfilActionTile(
                  icon: Icons.campaign_outlined,
                  title: organizerStatus == 'approved'
                      ? context.l10n.organizerDashboardTitle
                      : context.l10n.becomeOrganizerTitle,
                  trailing: organizerStatus == 'pending'
                      ? Icon(Icons.hourglass_top, color: AppColors.muted)
                      : null,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => organizerStatus == 'approved'
                          ? const OrganizerDashboardScreen()
                          : const OrganizerRequestScreen(),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDark,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.accent, width: 1),
                  ),
                  child: _ProfilActionTile(
                    icon: Icons.workspace_premium_outlined,
                    title: context.l10n.navPremium,
                    iconColor: AppColors.accent,
                    textColor: AppColors.onSurfaceDark,
                    trailingColor: AppColors.accent,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const PremiumScreen()),
                    ),
                  ),
                ),
                if (isAdmin) ...[
                  const SizedBox(height: 10),
                  _ProfilActionTile(
                    icon: Icons.admin_panel_settings_outlined,
                    title: context.l10n.navAdmin,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AdminScreen()),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ProfilActionTile extends StatelessWidget {
  const _ProfilActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.trailing,
    this.iconColor,
    this.textColor,
    this.trailingColor,
  });

  final IconData icon;
  final String title;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Color? iconColor;
  final Color? textColor;
  final Color? trailingColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: iconColor == null
              ? BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(16),
                )
              : null,
          child: Row(
            children: [
              Icon(icon, color: iconColor ?? AppColors.accent),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.w600, color: textColor ?? AppColors.ink),
                ),
              ),
              trailing ?? Icon(Icons.chevron_right, color: trailingColor ?? AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compteur façon "Boosts/Superlikes" des applications de rencontre
/// courantes, adapté aux avantages réellement gratuits de MERUT — jamais
/// de bouton d'achat ici, les paiements restent en pause
/// (functions/src/index.ts).
class _CounterTile extends StatelessWidget {
  const _CounterTile({
    required this.icon,
    required this.count,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String count;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.backgroundSoft,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: AppColors.accentSoft, shape: BoxShape.circle),
                child: Icon(icon, color: AppColors.accent, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(count, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    Text(label, style: TextStyle(fontSize: 11.5, color: AppColors.muted)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
