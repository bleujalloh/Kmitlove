import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/firebase_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/block_action.dart';
import '../../../../core/widgets/profile_fact_sheet.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../../../compatibilite/presentation/compat_controller.dart';
import '../../domain/candidate.dart';
import '../decouvrir_controller.dart';

/// Écran Découvrir (swipe) — fidèle au prototype visuel validé (artifact
/// MERUT, Decouvrir.dc.html).
class DecouvrirScreen extends ConsumerWidget {
  const DecouvrirScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(decouvrirControllerProvider);

    ref.listen(decouvrirControllerProvider, (previous, next) {
      final error = next.value?.errorMessage;
      if (error != null && error != previous?.value?.errorMessage) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error)));
      }
      final matched = next.value?.justMatchedWith;
      if (matched != null && matched != previous?.value?.justMatchedWith) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(context.l10n.itsAMatch),
            content: Text(context.l10n.mutualLikeWith(matched.displayName)),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(context.l10n.great),
              ),
            ],
          ),
        );
      }
    });

    final filters = ref.watch(discoverFiltersProvider);

    return Scaffold(
      // Sans AppBar, ni bouton retour automatique ni titre cohérent avec
      // le reste de l'app — seul écran dans ce cas, bug remonté sur
      // appareil réel le 11/11.
      appBar: AppBar(title: Text(context.l10n.navDiscover)),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.discoverSubtitle,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _FilterPill(
                          icon: Icons.tune,
                          label: context.l10n.filtersPillLabel,
                          filled: true,
                          onTap: () => showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            builder: (_) => const _FiltersSheet(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Chaque pastille reflète l'état réel de
                        // discoverFiltersProvider, jamais une valeur figée
                        // (maquette visuelle validée le 12/11/2026) — l'âge
                        // n'est affiché que s'il a été réglé explicitement
                        // par le membre : tant qu'il reste absent, le
                        // serveur applique sa propre plage par défaut
                        // (±8 ans autour du sien, getCandidates.ts), que le
                        // client ne connaît pas et ne doit donc jamais
                        // prétendre afficher.
                        if (filters.minAge != null && filters.maxAge != null)
                          _FilterPill(
                            icon: Icons.calendar_today_outlined,
                            label: context.l10n.ageRangePill(
                              filters.minAge!,
                              filters.maxAge!,
                            ),
                          ),
                        if (filters.minAge != null && filters.maxAge != null)
                          const SizedBox(width: 8),
                        if (filters.country != null)
                          _FilterPill(
                            icon: Icons.place_outlined,
                            label: filters.city ?? filters.country!,
                          )
                        else
                          _FilterPill(
                            icon: Icons.place_outlined,
                            label: context.l10n.maxDistancePill(
                              filters.maxDistanceKm,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: state.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(context.l10n.profilesLoadFailed),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () => ref
                              .read(decouvrirControllerProvider.notifier)
                              .refresh(),
                          child: Text(context.l10n.retryButton),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (data) {
                  if (data.candidates.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              context.l10n.noMoreProfiles,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: () => ref
                                  .read(decouvrirControllerProvider.notifier)
                                  .refresh(),
                              child: Text(context.l10n.refreshButton),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final candidate = data.candidates.first;
                  final status = ref.watch(userStatusProvider).value;
                  final isPremium = status?['isPremium'] == true;
                  final jetons = (status?['jetons'] as num?)?.toInt() ?? 0;
                  return Column(
                    children: [
                      const SizedBox(height: 10),
                      Expanded(
                        child: _CandidateCard(
                          key: ValueKey(candidate.uid),
                          candidate: candidate,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _RoundButton(
                              icon: Icons.close,
                              color: AppColors.muted,
                              onTap: () => ref
                                  .read(decouvrirControllerProvider.notifier)
                                  .swipe('pass'),
                            ),
                            const SizedBox(width: 18),
                            _RoundButton(
                              icon: Icons.favorite,
                              color: AppColors.noirProfond,
                              background: AppColors.accent,
                              size: 62,
                              onTap: () => ref
                                  .read(decouvrirControllerProvider.notifier)
                                  .swipe('like'),
                            ),
                            const SizedBox(width: 18),
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                _RoundButton(
                                  icon: Icons.star,
                                  color: AppColors.accent,
                                  onTap: () => ref
                                      .read(
                                        decouvrirControllerProvider.notifier,
                                      )
                                      .swipe('super_like'),
                                ),
                                // Mirroir UX de la règle serveur (recordSwipe.ts :
                                // Premium gratuit, sinon 1 jeton) — jamais la
                                // seule vérification, juste pour que le coût soit
                                // visible avant de taper, pas seulement après un
                                // message d'erreur.
                                if (!isPremium)
                                  Positioned(
                                    top: -4,
                                    right: -4,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.noirProfond,
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                        border: Border.all(
                                          color: AppColors.accent,
                                          width: 1.2,
                                        ),
                                      ),
                                      child: Text(
                                        '$jetons',
                                        style: const TextStyle(
                                          color: AppColors.accent,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CandidateCard extends ConsumerWidget {
  const _CandidateCard({super.key, required this.candidate});

  final Candidate candidate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final compatScore = ref.watch(compatScoreWithProvider(candidate.uid)).value;
    final photoUrl = ref
        .watch(candidateFirstPhotoUrlProvider(candidate.uid))
        .value;

    return _DraggableCard(
      onSwipeLike: () =>
          ref.read(decouvrirControllerProvider.notifier).swipe('like'),
      onSwipePass: () =>
          ref.read(decouvrirControllerProvider.notifier).swipe('pass'),
      child: _CandidateCardContent(
        candidate: candidate,
        compatScore: compatScore,
        photoUrl: photoUrl,
      ),
    );
  }
}

class _DraggableCard extends StatefulWidget {
  const _DraggableCard({
    required this.onSwipeLike,
    required this.onSwipePass,
    required this.child,
  });

  final VoidCallback onSwipeLike;
  final VoidCallback onSwipePass;
  final Widget child;

  @override
  State<_DraggableCard> createState() => _DraggableCardState();
}

/// Carte swipable : glisser à droite = like, à gauche = passe — demandé
/// par le propriétaire le 11/11/2026, les boutons ronds en dessous
/// restaient jusqu'ici la SEULE façon d'agir sur une carte Découvrir,
/// ce qui "ne ressemble pas à une app de rencontres".
///
/// Séparé de `_CandidateCardContent` (trouvé par revue de code) : avant,
/// `setState` sur chaque pixel glissé reconstruisait toute la fiche
/// profil (grille de faits, icônes d'intérêt...) uniquement pour
/// repositionner la carte — ici, `widget.child` est construit une seule
/// fois par `_CandidateCard` et jamais reconstruit pendant un glissement,
/// seule cette coquille (translation/rotation/estampilles like-passe) se
/// redessine à chaque frame.
class _DraggableCardState extends State<_DraggableCard>
    with SingleTickerProviderStateMixin {
  static const _swipeThreshold = 110.0;

  late final AnimationController _snapBackController;
  Offset _dragOffset = Offset.zero;
  Offset _snapBackStart = Offset.zero;

  @override
  void initState() {
    super.initState();
    _snapBackController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 220),
        )..addListener(() {
          setState(() {
            _dragOffset = Offset.lerp(
              _snapBackStart,
              Offset.zero,
              _snapBackController.value,
            )!;
          });
        });
  }

  @override
  void dispose() {
    _snapBackController.dispose();
    super.dispose();
  }

  // `onHorizontalDrag*` (axe contraint), pas `onPan*` (toute direction) :
  // demande explicite du propriétaire le 12/11/2026 pour que le swipe
  // horizontal (like/passe) coexiste avec le défilement vertical qui
  // révèle le profil complet plus bas (ScrollView imbriqué) — deux
  // reconnaisseurs sur des axes orthogonaux se désambiguïsent nativement
  // dans l'arène de gestes Flutter, contrairement à un Pan (toute
  // direction) qui entrerait en conflit avec le défilement vertical.
  void _onHorizontalDragStart(DragStartDetails details) {
    _snapBackController.stop();
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    setState(() => _dragOffset += details.delta);
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (_dragOffset.dx > _swipeThreshold) {
      widget.onSwipeLike();
      return;
    }
    if (_dragOffset.dx < -_swipeThreshold) {
      widget.onSwipePass();
      return;
    }
    // Pas assez loin pour valider le swipe : retour au centre animé
    // plutôt qu'un saut brutal.
    _snapBackStart = _dragOffset;
    _snapBackController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final angle = (_dragOffset.dx / 1200).clamp(-0.25, 0.25);
    final likeOpacity = (_dragOffset.dx / _swipeThreshold).clamp(0.0, 1.0);
    final nopeOpacity = (-_dragOffset.dx / _swipeThreshold).clamp(0.0, 1.0);

    return GestureDetector(
      onHorizontalDragStart: _onHorizontalDragStart,
      onHorizontalDragUpdate: _onHorizontalDragUpdate,
      onHorizontalDragEnd: _onHorizontalDragEnd,
      child: Transform.translate(
        offset: _dragOffset,
        child: Transform.rotate(
          angle: angle,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border, width: 1.5),
                borderRadius: BorderRadius.circular(20),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  widget.child,
                  Positioned(
                    top: 24,
                    left: 20,
                    child: Opacity(
                      opacity: likeOpacity,
                      child: _SwipeStamp(
                        label: context.l10n.swipeLikeStamp,
                        color: AppColors.accent,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 24,
                    right: 20,
                    child: Opacity(
                      opacity: nopeOpacity,
                      child: _SwipeStamp(
                        label: context.l10n.swipePassStamp,
                        color: AppColors.muted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Révélation du profil complet au défilement vertical, comme
/// Hinge/Bumble (demande explicite du propriétaire, 12/11/2026) : la
/// photo défile avec le reste plutôt que de rester épinglée, un seul
/// ScrollView plutôt qu'une mise en page à deux zones séparées.
class _CandidateCardContent extends ConsumerWidget {
  const _CandidateCardContent({
    required this.candidate,
    required this.compatScore,
    required this.photoUrl,
  });

  final Candidate candidate;
  final int? compatScore;
  final String? photoUrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                height: 340,
                width: double.infinity,
                color: AppColors.placeholder,
                child: photoUrl != null
                    ? Image.network(
                        photoUrl!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: 340,
                      )
                    : const Icon(
                        Icons.person_outline,
                        size: 46,
                        color: AppColors.placeholderIcon,
                      ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Row(
                  // Sans ça, la Row (contraintes lâches du Stack, pas de
                  // `left` fixé) prend toute la largeur disponible et ses
                  // enfants se retrouvent alignés à GAUCHE de cette largeur
                  // au lieu de rester collés au bord droit — badge et menu
                  // se seraient retrouvés en haut à GAUCHE de la photo au
                  // lieu d'à droite (trouvé par revue de code).
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Badge "En ligne" (maquette visuelle validée le
                    // 12/11/2026) : réutilise lastActiveAt déjà écrit par
                    // recordActivity.ts (répété toutes les 5 minutes,
                    // auth_controller.dart), calculé côté serveur dans
                    // getCandidates.ts — jamais un nouveau système de
                    // présence temps réel.
                    if (candidate.isOnline)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.greenAccent,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              context.l10n.onlineBadgeLabel,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    Material(
                      color: Colors.black.withValues(alpha: 0.35),
                      shape: const CircleBorder(),
                      child: PopupMenuButton<void>(
                        icon: const Icon(Icons.more_vert, color: Colors.white),
                        onSelected: (_) {},
                        itemBuilder: (menuContext) => [
                          PopupMenuItem<void>(
                            onTap: () => showBlockProfileSheet(
                              context,
                              ref,
                              targetUid: candidate.uid,
                              displayName: candidate.displayName,
                            ),
                            child: Text(context.l10n.blockProfileAction),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        '${candidate.displayName}, ${candidate.age}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.ink,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (candidate.isVerified) ...[
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.verified,
                        color: AppColors.accent,
                        size: 19,
                      ),
                    ],
                    const Spacer(),
                    if (compatScore != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          context.l10n.compatScoreBadge(compatScore!),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.noirProfond,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.place_outlined,
                      size: 15,
                      color: AppColors.muted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      candidate.distanceKm != null
                          ? context.l10n.cityCountryWithDistance(
                              candidate.city,
                              candidate.country,
                              candidate.distanceKm!,
                            )
                          : context.l10n.cityCountry(
                              candidate.city,
                              candidate.country,
                            ),
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                ProfileFactSheet(
                  bio: candidate.bio,
                  interests: candidate.interests,
                  age: candidate.age,
                  heightCm: candidate.heightCm,
                  educationLevel: candidate.educationLevel,
                  profession: candidate.profession,
                  relationshipIntent: candidate.relationshipIntent,
                  childrenStatus: candidate.childrenStatus,
                  smokingHabit: candidate.smokingHabit,
                  drinkingHabit: candidate.drinkingHabit,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.icon,
    required this.label,
    this.onTap,
    this.filled = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: filled ? AppColors.accent : AppColors.backgroundSoft,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: filled ? AppColors.accent : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: filled ? AppColors.noirProfond : AppColors.accent,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: filled ? AppColors.noirProfond : AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SwipeStamp extends StatelessWidget {
  const _SwipeStamp({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.25,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 3),
          borderRadius: BorderRadius.circular(8),
          color: AppColors.noirProfond.withValues(alpha: 0.25),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w900,
            fontSize: 22,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }
}

class _FiltersSheet extends ConsumerStatefulWidget {
  const _FiltersSheet();

  @override
  ConsumerState<_FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends ConsumerState<_FiltersSheet> {
  late RangeValues _ageRange;
  late double _distance;
  late final TextEditingController _countryController;
  late final TextEditingController _cityController;
  bool _requestingLocation = false;

  @override
  void initState() {
    super.initState();
    final current = ref.read(discoverFiltersProvider);
    _ageRange = RangeValues(
      (current.minAge ?? 18).toDouble(),
      (current.maxAge ?? 60).toDouble(),
    );
    _distance = current.maxDistanceKm.toDouble();
    _countryController = TextEditingController(text: current.country ?? '');
    _cityController = TextEditingController(text: current.city ?? '');
  }

  @override
  void dispose() {
    _countryController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.filtersTitle,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 18),
          Text(
            context.l10n.ageRangeLabel(
              _ageRange.start.round(),
              _ageRange.end.round(),
            ),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          RangeSlider(
            values: _ageRange,
            min: 18,
            max: 80,
            divisions: 62,
            activeColor: AppColors.accent,
            onChanged: (v) => setState(() => _ageRange = v),
          ),
          const SizedBox(height: 10),
          Text(
            context.l10n.maxDistanceLabel(_distance.round()),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          Slider(
            value: _distance,
            min: 5,
            max: 100,
            divisions: 19,
            activeColor: AppColors.accent,
            onChanged: (v) => setState(() => _distance = v),
          ),
          const SizedBox(height: 6),
          OutlinedButton.icon(
            onPressed: _requestingLocation
                ? null
                : () async {
                    setState(() => _requestingLocation = true);
                    final ok = await ref
                        .read(locationServiceProvider)
                        .updateMyLocation();
                    if (mounted) setState(() => _requestingLocation = false);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            ok
                                ? context.l10n.locationUpdated
                                : context.l10n.locationUnavailable,
                          ),
                        ),
                      );
                    }
                  },
            icon: const Icon(Icons.my_location),
            label: Text(
              _requestingLocation
                  ? context.l10n.locatingEllipsis
                  : context.l10n.updateMyLocation,
            ),
          ),
          const Divider(height: 28),
          Text(
            context.l10n.locationFilterTitle,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            context.l10n.locationFilterHint,
            style: const TextStyle(fontSize: 12.5, color: AppColors.muted),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _countryController,
            decoration: InputDecoration(labelText: context.l10n.countryLabel),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _cityController,
            decoration: InputDecoration(labelText: context.l10n.cityLabel),
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: () {
              final country = _countryController.text.trim();
              final city = _cityController.text.trim();
              ref
                  .read(discoverFiltersProvider.notifier)
                  .state = DiscoverFilters(
                minAge: _ageRange.start.round(),
                maxAge: _ageRange.end.round(),
                maxDistanceKm: _distance.round(),
                country: country.isEmpty ? null : country,
                city: city.isEmpty ? null : city,
              );
              Navigator.of(context).pop();
            },
            child: Text(context.l10n.applyButton),
          ),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.color,
    required this.onTap,
    this.background = AppColors.background,
    this.size = 48,
  });

  final IconData icon;
  final Color color;
  final Color background;
  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: background,
          shape: BoxShape.circle,
          border: background == AppColors.background
              ? Border.all(color: AppColors.border)
              : null,
        ),
        child: Icon(icon, color: color, size: size * 0.4),
      ),
    );
  }
}
