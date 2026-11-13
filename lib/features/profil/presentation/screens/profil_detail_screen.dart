import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/image_viewer.dart';
import '../../../../core/widgets/profile_fact_sheet.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../../../compatibilite/presentation/compat_controller.dart';
import '../profil_detail_controller.dart';

/// Fiche détail d'un profil tiers — manquait entièrement avant (signalé
/// le 11/11/2026 : taper sur la carte d'un profil déjà liké ne faisait
/// rien, nulle part dans l'app ; seule la carte de swipe Découvrir
/// montrait bio/intérêts, et un seul candidat à la fois pendant le
/// swipe). Réutilisable partout où une mini-carte de profil est
/// affichée (likes_screen.dart : "Mes likes" et "T'ont liké" en Premium).
class ProfilDetailScreen extends ConsumerWidget {
  const ProfilDetailScreen({
    super.key,
    required this.uid,
    this.isVerified = false,
    this.isPreview = false,
  });

  final String uid;

  /// Aperçu de MON profil tel que les autres le voient (onglet Profil) :
  /// même fiche, mêmes données publiques (photos approuvées seulement),
  /// sans score de compatibilité avec soi-même, avec un bandeau
  /// explicatif.
  final bool isPreview;

  /// Fourni par l'appelant quand il le connaît déjà (ex.
  /// MiniProfile.isVerified, déjà renvoyé par getLikes.ts) : `user_status`
  /// (où vit ce champ) n'est lisible que par son propriétaire côté règles
  /// (firestore.rules) — jamais relu ici pour un profil tiers.
  final bool isVerified;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(targetProfileProvider(uid));
    final photoUrls =
        ref.watch(targetProfilePhotoUrlsProvider(uid)).value ??
        const <String>[];
    final compatScore = isPreview ? null : ref.watch(compatScoreWithProvider(uid)).value;

    return Scaffold(
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text(context.l10n.genericError)),
        data: (profile) {
          if (profile == null) {
            return Center(child: Text(context.l10n.genericError));
          }
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 380,
                pinned: true,
                backgroundColor: AppColors.background,
                foregroundColor: Colors.white,
                flexibleSpace: FlexibleSpaceBar(
                  background: photoUrls.isEmpty
                      ? Container(
                          color: AppColors.placeholder,
                          child: Icon(
                            Icons.person_outline,
                            size: 64,
                            color: AppColors.placeholderIcon,
                          ),
                        )
                      : _PhotoCarousel(photoUrls: photoUrls),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isPreview) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundSoft,
                            border: Border.all(color: AppColors.border),
                            borderRadius: BorderRadius.circular(AppRadii.md),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.visibility_outlined, size: 18, color: AppColors.accent),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  context.l10n.profilePreviewBanner,
                                  style: TextStyle(fontSize: 12.5, height: 1.4, color: AppColors.muted),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              '${profile.displayName}, ${profile.age}',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppColors.ink,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isVerified) ...[
                            const SizedBox(width: 6),
                            Icon(
                              Icons.verified,
                              color: AppColors.accent,
                              size: 20,
                            ),
                          ],
                          if (compatScore != null) ...[
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.accent,
                                borderRadius: BorderRadius.circular(AppRadii.sm),
                              ),
                              child: Text(
                                context.l10n.compatScoreBadge(compatScore),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.noirProfond,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.place_outlined,
                            size: 15,
                            color: AppColors.muted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            context.l10n.cityCountry(
                              profile.city,
                              profile.country,
                            ),
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      ProfileFactSheet(
                        bio: profile.bio,
                        interests: profile.interests,
                        age: profile.age,
                        heightCm: profile.heightCm,
                        educationLevel: profile.educationLevel,
                        profession: profile.profession,
                        relationshipIntent: profile.relationshipIntent,
                        childrenStatus: profile.childrenStatus,
                        smokingHabit: profile.smokingHabit,
                        drinkingHabit: profile.drinkingHabit,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PhotoCarousel extends StatefulWidget {
  const _PhotoCarousel({required this.photoUrls});
  final List<String> photoUrls;

  @override
  State<_PhotoCarousel> createState() => _PhotoCarouselState();
}

class _PhotoCarouselState extends State<_PhotoCarousel> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          itemCount: widget.photoUrls.length,
          onPageChanged: (i) => setState(() => _index = i),
          itemBuilder: (context, i) => GestureDetector(
            onTap: () => openImageViewer(context, widget.photoUrls, index: i),
            child: Image.network(widget.photoUrls[i], fit: BoxFit.cover),
          ),
        ),
        if (widget.photoUrls.length > 1)
          Positioned(
            // En bas de la photo plutôt qu'en haut : un positionnement
            // haut chevauchait la zone de tap de la flèche retour du
            // SliverAppBar sur un téléphone à barre de statut standard
            // (trouvé par revue de code).
            bottom: 16,
            left: 12,
            right: 12,
            child: Row(
              children: List.generate(
                widget.photoUrls.length,
                (i) => Expanded(
                  child: Container(
                    height: 3,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: i == _index ? AppColors.accent : Colors.white38,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
