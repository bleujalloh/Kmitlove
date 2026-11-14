import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/providers/firebase_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/age.dart';
import '../../../../core/widgets/settings_action.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../../../admin/presentation/admin_controller.dart';
import '../../../admin/presentation/screens/admin_screen.dart';
import '../../../communaute/presentation/communaute_controller.dart';
import '../../../communaute/presentation/screens/create_post_screen.dart';
import '../../../communaute/presentation/screens/my_participations_screen.dart';
import '../../../communaute/presentation/screens/organizer_dashboard_screen.dart';
import '../../../communaute/presentation/screens/organizer_request_screen.dart';
import '../../../compatibilite/presentation/compat_controller.dart';
import '../../../compatibilite/presentation/screens/compat_screen.dart';
import '../../../identite/presentation/screens/identite_screen.dart';
import '../../../premium/presentation/screens/premium_screen.dart';
import '../../domain/profil_photo.dart';
import '../photo_controller.dart';
import '../profil_controller.dart';
import 'photo_viewer_screen.dart';
import 'photos_section.dart';
import 'profil_detail_screen.dart';
import 'profil_edit_screen.dart';

/// Onglet « Profil » — présentation inspirée d'un profil de réseau social
/// moderne (demande du propriétaire, 14/11/2026, capture d'un profil
/// Instagram) : photo et chiffres en haut, nom, ville et description, puces
/// de la fiche, deux boutons côte à côte (Modifier / Partager), rangée de
/// photos, puis les raccourcis du compte. Les éléments qui n'existent pas
/// dans MERUT (abonnés, publications, onglets de contenu, notifications de
/// réseau) ne sont pas reproduits ; « Partager le profil » est implanté.
class MonProfilScreen extends ConsumerWidget {
  const MonProfilScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profilAsync = ref.watch(profilProvider);
    final isAdmin = ref.watch(isAdminProvider).value ?? false;
    final status = ref.watch(userStatusProvider).value;
    final isVerified = status?['isVerified'] == true;
    final organizerStatus = ref.watch(myOrganizerStatusProvider).value;
    final myPhotos = ref.watch(myPhotosProvider).value ?? const <ProfilPhoto>[];
    final approvedPhotos = myPhotos.where((p) => p.status == 'approved');
    // Photo de l'avatar : la première photo validée, à défaut ma première
    // photo même en attente ou refusée (je suis le seul à voir cet avatar ;
    // les autres ne voient que les photos validées).
    final avatarPhoto = approvedPhotos.isNotEmpty ? approvedPhotos.first : (myPhotos.isNotEmpty ? myPhotos.first : null);
    final avatarUrl = avatarPhoto == null ? null : ref.watch(photoDownloadUrlProvider(avatarPhoto.storagePath)).value;

    // Les compteurs reflètent exactement ce que le serveur a calculé
    // (functions/src/premium/useJeton.ts, activateBoost.ts) — jamais de règle
    // de disponibilité recalculée côté client.
    final jetons = (status?['jetons'] as num?)?.toInt() ?? 0;
    final isPremium = status?['isPremium'] == true;
    final boostedUntil = status?['boostedUntil'];
    final isBoostedNow = boostedUntil is Timestamp && boostedUntil.toDate().isAfter(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: context.l10n.createPostTooltip,
          icon: const Icon(Icons.add, size: 28),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CreatePostScreen()),
          ),
        ),
        title: Text(profilAsync.value?.displayName ?? context.l10n.navProfile),
        actions: [buildSettingsAction(context)],
      ),
      body: profilAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text(context.l10n.unexpectedError(e.toString()))),
        data: (profil) {
          if (profil == null) return const SizedBox.shrink();
          // Calculé côté serveur (functions/src/profil/getProfileCompletion.ts),
          // même règle que celle qui influence le classement dans Découvrir.
          final completionPercent = ref.watch(profileCompletionPercentProvider).value ?? 0;
          void edit() => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => ProfilEditScreen(existing: profil)),
              );

          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _Avatar(
                      url: avatarUrl,
                      completion: completionPercent / 100,
                      onTap: avatarPhoto == null
                          ? () => showAddPhotoSheet(context, ref)
                          : () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => PhotoViewerScreen(
                                    photos: myPhotos,
                                    initialIndex: myPhotos.indexOf(avatarPhoto),
                                  ),
                                ),
                              ),
                      onAdd: myPhotos.length >= 6 ? null : () => showAddPhotoSheet(context, ref),
                    ),
                    const SizedBox(width: 22),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _Stat(value: '$jetons', label: context.l10n.jetonsCounterLabel),
                          _Stat(
                            value: isBoostedNow ? '1' : (isPremium ? context.l10n.boostCounterIncluded : '0'),
                            label: context.l10n.boostCounterLabel,
                          ),
                          _Stat(value: '$completionPercent %', label: context.l10n.profileStatProfile, onTap: edit),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        '${profil.displayName}, ${ageFromBirthDate(profil.birthDate)}',
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isVerified) ...[
                      const SizedBox(width: 6),
                      Icon(Icons.verified, color: AppColors.accent, size: 18),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text('${profil.city}, ${profil.country}', style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 8),
                Text(
                  profil.bio.trim().isEmpty ? context.l10n.profileCompletionHint : profil.bio,
                  style: const TextStyle(fontSize: 14.5, height: 1.4),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if ((profil.profession ?? '').trim().isNotEmpty) _Chip(label: profil.profession!.trim()),
                    for (final interest in profil.interests.take(3)) _Chip(label: interest),
                    _Chip(label: context.l10n.profileAddChip, add: true, onTap: edit),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(onPressed: edit, child: Text(context.l10n.editMyProfile)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => SharePlus.instance.share(
                          ShareParams(
                            text: context.l10n.shareProfileMessage(profil.displayName, profil.city),
                          ),
                        ),
                        child: Text(context.l10n.shareProfileButton),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                _PhotosRow(photos: myPhotos, onAdd: () => showAddPhotoSheet(context, ref)),
                const SizedBox(height: 18),
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
                _ProfilActionTile(
                  icon: Icons.favorite_border,
                  title: context.l10n.navCompatTest,
                  trailing: Text(
                    (ref.watch(myCompatAnswersProvider).value?.isNotEmpty ?? false)
                        ? context.l10n.compatTestDoneBadge
                        : context.l10n.compatTestTodoBadge,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CompatScreen()),
                  ),
                ),
                _ProfilActionTile(
                  icon: Icons.event_available_outlined,
                  title: context.l10n.myParticipationsTitle,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const MyParticipationsScreen()),
                  ),
                ),
                _ProfilActionTile(
                  icon: Icons.campaign_outlined,
                  title: organizerStatus == 'approved'
                      ? context.l10n.organizerDashboardTitle
                      : context.l10n.becomeOrganizerTitle,
                  trailing: organizerStatus == 'pending' ? Icon(Icons.hourglass_top, color: AppColors.ink) : null,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => organizerStatus == 'approved'
                          ? const OrganizerDashboardScreen()
                          : const OrganizerRequestScreen(),
                    ),
                  ),
                ),
                _ProfilActionTile(
                  icon: Icons.workspace_premium_outlined,
                  title: context.l10n.navPremium,
                  highlight: true,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PremiumScreen()),
                  ),
                ),
                if (isAdmin)
                  _ProfilActionTile(
                    icon: Icons.admin_panel_settings_outlined,
                    title: context.l10n.navAdmin,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AdminScreen()),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Avatar rond avec l'anneau de complétion du profil et le « + » d'ajout de
/// photo.
class _Avatar extends StatelessWidget {
  const _Avatar({required this.url, required this.completion, required this.onTap, required this.onAdd});

  final String? url;
  final double completion;
  final VoidCallback onTap;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 98,
      height: 98,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 98,
            height: 98,
            child: CircularProgressIndicator(value: completion.clamp(0.0, 1.0), strokeWidth: 3),
          ),
          GestureDetector(
            onTap: onTap,
            child: Container(
              width: 84,
              height: 84,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.placeholder),
              child: url != null
                  ? Image.network(url!, fit: BoxFit.cover)
                  : Icon(Icons.person, size: 40, color: AppColors.placeholderIcon),
            ),
          ),
          if (onAdd != null)
            Positioned(
              right: 0,
              bottom: 2,
              child: GestureDetector(
                onTap: onAdd,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
                  child: const Icon(Icons.add, size: 18, color: AppColors.noirProfond),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Chiffre au-dessus de son libellé (jetons, boost, profil).
class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, this.onTap});

  final String value;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

/// Puce de la fiche (profession, centre d'intérêt) ou puce d'ajout.
class _Chip extends StatelessWidget {
  const _Chip({required this.label, this.add = false, this.onTap});

  final String label;
  final bool add;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.sm),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.backgroundSoft,
          borderRadius: BorderRadius.circular(AppRadii.sm),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (add) ...[
              Icon(Icons.add, size: 16, color: AppColors.accent),
              const SizedBox(width: 4),
            ],
            Text(label, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

/// Rangée de photos : tuile « Nouveau » puis chaque photo avec son état
/// (touche = ouvre la visionneuse, où l'on peut aussi la supprimer).
class _PhotosRow extends ConsumerWidget {
  const _PhotosRow({required this.photos, required this.onAdd});

  final List<ProfilPhoto> photos;
  final VoidCallback onAdd;

  String _status(BuildContext context, String status) {
    switch (status) {
      case 'approved':
        return context.l10n.photoApproved;
      case 'rejected':
        return context.l10n.photoRejected;
      default:
        return context.l10n.photoPending;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 118,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          if (photos.length < 6)
            _Thumb(
              label: context.l10n.photosNewTile,
              onTap: onAdd,
              child: Icon(Icons.add, size: 30, color: AppColors.ink),
            ),
          for (var i = 0; i < photos.length; i++)
            _Thumb(
              label: _status(context, photos[i].status),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => PhotoViewerScreen(photos: photos, initialIndex: i)),
              ),
              child: ref.watch(photoDownloadUrlProvider(photos[i].storagePath)).when(
                    data: (u) => Image.network(u, fit: BoxFit.cover, width: 84, height: 84),
                    loading: () => const SizedBox.shrink(),
                    error: (e, st) => Icon(Icons.person_outline, color: AppColors.ink),
                  ),
            ),
        ],
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.label, required this.onTap, required this.child});

  final String label;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        child: SizedBox(
          width: 84,
          child: Column(
            children: [
              Container(
                width: 84,
                height: 84,
                clipBehavior: Clip.antiAlias,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.backgroundSoft,
                  borderRadius: BorderRadius.circular(AppRadii.lg),
                ),
                child: child,
              ),
              const SizedBox(height: 6),
              Text(label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
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
    this.highlight = false,
  });

  final IconData icon;
  final String title;
  final VoidCallback? onTap;
  final Widget? trailing;

  /// Mise en avant (Premium) : fond doré léger, sans bandeau sombre.
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: highlight ? AppColors.accentSoft : null,
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.accent),
            const SizedBox(width: 14),
            Expanded(
              child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            ),
            trailing ?? Icon(Icons.chevron_right, color: AppColors.ink),
          ],
        ),
      ),
    );
  }
}
