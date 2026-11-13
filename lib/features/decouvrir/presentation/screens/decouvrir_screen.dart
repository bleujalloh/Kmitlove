import 'dart:async';

import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/firebase_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/block_action.dart';
import '../../../../core/widgets/boost_action.dart';
import '../../../../core/widgets/country_field.dart';
import '../../../../core/widgets/profile_fact_sheet.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../../../compatibilite/presentation/compat_controller.dart';
import '../../../profil/domain/profil.dart';
import '../../../profil/presentation/profil_controller.dart';
import '../../domain/candidate.dart';
import '../decouvrir_controller.dart';
import '../detected_place_provider.dart';

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
    // Position réellement enregistrée côté serveur (user_status, lisible
    // par son seul propriétaire, écrite par updateMyLocation.ts) — jamais
    // supposée : c'est elle, pas l'interrupteur seul, qui décide si la
    // distance peut s'appliquer.
    final hasSavedLocation =
        ref.watch(userStatusProvider).value?['locationLat'] is num;
    // Lieu correspondant à la position active, affiché dans les pilules
    // Pays/Ville tant qu'aucun filtre explicite ne les remplace — jamais
    // appliqué comme filtre (voir detected_place_provider.dart).
    final detected = filters.useMyLocation && hasSavedLocation
        ? ref.watch(detectedPlaceProvider).value
        : null;
    // Le filtre de genre n'a de sens que pour un membre qui cherche LES DEUX
    // genres : sinon le choix a déjà été fait à l'inscription (audit du
    // 13/11/2026, accepté par le propriétaire) et la pilule serait inutile.
    final seeking = ref.watch(profilProvider).value?.seekingGenders;
    final showGenderPill = seeking != null && seeking.length > 1;
    // Distance : montrée seulement quand elle s'applique réellement (position
    // enregistrée et utilisée, pas de pays choisi) — plus estompée.
    final showDistancePill =
        filters.country == null && filters.useMyLocation && hasSavedLocation;
    // « Activer ma position » : seulement tant que la position n'est pas
    // accordée (ou si le membre l'a coupée pour cette recherche).
    final showLocationSwitch = !hasSavedLocation || !filters.useMyLocation;
    final detectedCountry = filters.country == null ? detected?.country : null;
    final detectedCity = filters.country == null ? detected?.city : null;

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
                  // Deux rangées de pilules, toutes fonctionnelles (maquette
                  // visuelle validée le 12/11/2026, demande explicite : "il
                  // faut que le filtrage marche sur toutes les options") —
                  // chacune relie une vraie action à discoverFiltersProvider,
                  // jamais un élément décoratif. Toujours visibles (pas de
                  // masquage conditionnel comme avant) ; quand un réglage
                  // n'a pas encore de valeur explicite, la pilule affiche un
                  // libellé neutre plutôt qu'une valeur inventée (ex. "Âge"
                  // plutôt qu'une plage par défaut que le client ne connaît
                  // pas réellement, calculée côté serveur).
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _FilterPill(
                          icon: Icons.tune,
                          label: context.l10n.filtersPillLabel,
                          filled: true,
                          onTap: () => _openFiltersSheet(context),
                        ),
                        const SizedBox(width: 8),
                        if (showGenderPill) ...[
                          _FilterPill(
                            icon: Icons.wc_outlined,
                            label: _genderPillLabel(context, filters.gender),
                            chevron: true,
                            onTap: () => _openGenderSheet(context, ref),
                          ),
                          const SizedBox(width: 8),
                        ],
                        _FilterPill(
                          icon: Icons.calendar_today_outlined,
                          label:
                              filters.minAge != null && filters.maxAge != null
                              ? context.l10n.ageRangePill(
                                  filters.minAge!,
                                  filters.maxAge!,
                                )
                              : context.l10n.agePillPlaceholder,
                          chevron: true,
                          onTap: () => _openFiltersSheet(context),
                        ),
                        if (showDistancePill) ...[
                          const SizedBox(width: 8),
                          _FilterPill(
                            icon: Icons.place_outlined,
                            label: context.l10n.maxDistancePill(
                              filters.maxDistanceKm,
                            ),
                            chevron: true,
                            onTap: () => _openFiltersSheet(context),
                          ),
                        ],
                        const SizedBox(width: 8),
                        if (showLocationSwitch) ...[
                          _LocationSwitchPill(hasSavedLocation: hasSavedLocation),
                          const SizedBox(width: 8),
                        ],
                        _FilterPill(
                          icon: detectedCountry != null
                              ? Icons.my_location
                              : Icons.public_outlined,
                          label:
                              filters.country ??
                              detectedCountry ??
                              context.l10n.countryLabel,
                          chevron: true,
                          detected: detectedCountry != null,
                          onTap: () => _openCountryPill(context, ref),
                        ),
                        const SizedBox(width: 8),
                        _FilterPill(
                          icon: filters.city == null && detectedCity != null
                              ? Icons.my_location
                              : Icons.location_city_outlined,
                          label:
                              filters.city ??
                              detectedCity ??
                              context.l10n.cityLabel,
                          chevron: true,
                          detected: filters.city == null && detectedCity != null,
                          dimmed: filters.country == null,
                          onTap: () => _openCitySheet(context, ref),
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
                            if (data.lastPassed != null)
                              TextButton.icon(
                                onPressed: () => ref
                                    .read(decouvrirControllerProvider.notifier)
                                    .undoLastPass(),
                                icon: const Icon(Icons.arrow_back, size: 18),
                                label: Text(context.l10n.undoLastPassButton),
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
                            const SizedBox(width: 12),
                            // « Retour » (prototype) : annule le dernier
                            // passage, Premium (undoLastSwipe.ts) ; grisé
                            // tant qu'il n'y a rien à annuler.
                            Opacity(
                              opacity: data.lastPassed != null ? 1 : 0.35,
                              child: _RoundButton(
                                icon: Icons.arrow_back,
                                color: AppColors.muted,
                                size: 40,
                                onTap: () => ref
                                    .read(decouvrirControllerProvider.notifier)
                                    .undoLastPass(),
                              ),
                            ),
                            const SizedBox(width: 12),
                            _RoundButton(
                              icon: Icons.favorite,
                              color: AppColors.noirProfond,
                              background: AppColors.accent,
                              size: 62,
                              onTap: () => ref
                                  .read(decouvrirControllerProvider.notifier)
                                  .swipe('like'),
                            ),
                            const SizedBox(width: 12),
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
                            const SizedBox(width: 12),
                            // Éclair du prototype : Boost du profil (même
                            // mécanisme que l'onglet Profil et Likes,
                            // activateBoost.ts : Premium, une fois par
                            // semaine).
                            _RoundButton(
                              icon: Icons.bolt,
                              color: AppColors.accent,
                              size: 40,
                              onTap: () => activateProfileBoost(context, ref),
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
                                color: AppColors.online,
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
                              onBlocked: () => ref
                                  .read(decouvrirControllerProvider.notifier)
                                  .removeCandidate(candidate.uid),
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

void _openFiltersSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => const _FiltersSheet(),
  );
}

String _genderPillLabel(BuildContext context, String? gender) {
  switch (gender) {
    case Gender.homme:
      return context.l10n.genderFilterMenPlural;
    case Gender.femme:
      return context.l10n.genderFilterWomenPlural;
    default:
      return context.l10n.genderFilterAll;
  }
}

/// Filtre rapide "Tous/Hommes/Femmes" (maquette visuelle validée le
/// 12/11/2026) — restreint ponctuellement la recherche à un seul genre
/// PARMI ceux que le profil recherche déjà (`seekingGenders`), jamais en
/// dehors : getCandidates.ts applique la même intersection côté serveur,
/// donc un choix hors préférence est proposé désactivé ici plutôt que de
/// laisser choisir une option qui ne renverrait jamais personne.
void _openGenderSheet(BuildContext context, WidgetRef ref) {
  final current = ref.read(discoverFiltersProvider).gender;
  // Profil pas encore chargé : on ne grise rien (le serveur applique de
  // toute façon l'intersection avec seekingGenders).
  final profilSeeking = ref.read(profilProvider).value?.seekingGenders;
  bool allowed(String g) => profilSeeking == null || profilSeeking.contains(g);

  void select(BuildContext sheetContext, String? gender) {
    final filters = ref.read(discoverFiltersProvider);
    ref.read(discoverFiltersProvider.notifier).state = filters.copyWith(
      gender: gender,
      clearGender: gender == null,
    );
    Navigator.of(sheetContext).pop();
  }

  showModalBottomSheet(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _GenderOptionTile(
            label: context.l10n.genderFilterAll,
            selected: current == null,
            onTap: () => select(sheetContext, null),
          ),
          _GenderOptionTile(
            label: context.l10n.genderFilterWomenPlural,
            selected: current == Gender.femme,
            onTap: allowed(Gender.femme)
                ? () => select(sheetContext, Gender.femme)
                : null,
          ),
          _GenderOptionTile(
            label: context.l10n.genderFilterMenPlural,
            selected: current == Gender.homme,
            onTap: allowed(Gender.homme)
                ? () => select(sheetContext, Gender.homme)
                : null,
          ),
        ],
      ),
    ),
  );
}

/// Sélecteur pays réel (liste ISO 3166-1 complète via `country_picker`,
/// même mécanisme que CountryField à l'inscription) — jamais un champ
/// texte libre, demande explicite du propriétaire le 12/11/2026. Choisir
/// un nouveau pays efface la ville déjà sélectionnée : une ville
/// retenue pour l'ancien pays n'a plus de sens pour le nouveau.
void _pickCountry(BuildContext context, WidgetRef ref) {
  showCountryPicker(
    context: context,
    showPhoneCode: false,
    onSelect: (country) {
      final name = frenchCountryName(country);
      final filters = ref.read(discoverFiltersProvider);
      ref.read(discoverFiltersProvider.notifier).state = filters.copyWith(
        country: name,
        clearCity: true,
      );
    },
  );
}

/// Pilule "Pays" : ouvre directement le sélecteur tant qu'aucun pays
/// n'est choisi ; une fois un pays actif, propose de le changer ou de
/// retirer le filtre (le sélecteur lui-même n'a pas d'entrée "aucun").
void _openCountryPill(BuildContext context, WidgetRef ref) {
  if (ref.read(discoverFiltersProvider).country == null) {
    _pickCountry(context, ref);
    return;
  }
  showModalBottomSheet(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.public_outlined),
            title: Text(context.l10n.changeCountryOption),
            onTap: () {
              Navigator.of(sheetContext).pop();
              _pickCountry(context, ref);
            },
          ),
          ListTile(
            leading: const Icon(Icons.close),
            title: Text(context.l10n.removeCountryFilterOption),
            onTap: () {
              final filters = ref.read(discoverFiltersProvider);
              ref.read(discoverFiltersProvider.notifier).state = filters
                  .copyWith(clearLocation: true);
              Navigator.of(sheetContext).pop();
            },
          ),
        ],
      ),
    ),
  );
}

void _openCitySheet(BuildContext context, WidgetRef ref) {
  if (ref.read(discoverFiltersProvider).country == null) {
    // La ville n'a d'effet côté serveur que combinée à un pays
    // (getCandidates.ts : cityFilter n'est appliqué que si countryFilter
    // est déjà actif) — prévenir plutôt que laisser une pilule "active"
    // en apparence mais sans aucun effet réel.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.selectCountryFirstHint)),
    );
    return;
  }
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => const _CitySheet(),
  );
}

class _GenderOptionTile extends StatelessWidget {
  const _GenderOptionTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      enabled: onTap != null,
      leading: Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        color: selected ? AppColors.accent : AppColors.muted,
      ),
      title: Text(label),
      onTap: onTap,
    );
  }
}

/// Feuille "Ville" — autocomplétion sur les suggestions réelles déjà
/// construites (core/data/major_cities.dart), saisie libre toujours
/// possible au-delà (même CityField qu'à l'inscription, aucune liste
/// exhaustive de villes n'existe pour ce projet). Valider un champ vide
/// retire le filtre ville.
class _CitySheet extends ConsumerStatefulWidget {
  const _CitySheet();

  @override
  ConsumerState<_CitySheet> createState() => _CitySheetState();
}

class _CitySheetState extends ConsumerState<_CitySheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: ref.read(discoverFiltersProvider).city ?? '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
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
            context.l10n.cityLabel,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 14),
          CityField(
            controller: _controller,
            country: ref.watch(discoverFiltersProvider).country,
            label: context.l10n.cityLabel,
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: () {
              final city = _controller.text.trim();
              final filters = ref.read(discoverFiltersProvider);
              ref.read(discoverFiltersProvider.notifier).state = filters
                  .copyWith(
                    city: city.isEmpty ? null : city,
                    clearCity: city.isEmpty,
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

/// Interrupteur "Ma position" (maquette visuelle validée le 12/11/2026) —
/// relie la logique GPS déjà existante (LocationService.updateMyLocation,
/// locationLat/locationLng dans user_status) à un contrôle visible et
/// basculable directement sur Découvrir. L'interrupteur n'apparaît activé
/// que si une position est RÉELLEMENT enregistrée côté serveur et que le
/// membre veut l'utiliser — jamais "activé" par défaut sans position.
/// Activer sans position connue déclenche une vraie demande GPS (même
/// action que le bouton "Mettre à jour ma position" de la feuille) ;
/// désactiver dit au serveur d'ignorer la distance sans effacer les
/// coordonnées (useMyLocation, getCandidates.ts).
class _LocationSwitchPill extends ConsumerStatefulWidget {
  const _LocationSwitchPill({required this.hasSavedLocation});

  final bool hasSavedLocation;

  @override
  ConsumerState<_LocationSwitchPill> createState() =>
      _LocationSwitchPillState();
}

class _LocationSwitchPillState extends ConsumerState<_LocationSwitchPill> {
  bool _requesting = false;

  bool _statusHasLocation() =>
      ref.read(userStatusProvider).value?['locationLat'] is num;

  /// Attend (6 s au plus) que le flux de statut reflète la position tout
  /// juste enregistrée. Jamais bloquant : au pire, le flux finit par
  /// arriver et l'écran se met à jour comme avant.
  Future<void> _waitForSavedLocation() async {
    if (_statusHasLocation()) return;
    final completer = Completer<void>();
    final subscription = ref.listenManual(userStatusProvider, (_, next) {
      if (next.value?['locationLat'] is num && !completer.isCompleted) {
        completer.complete();
      }
    });
    try {
      await completer.future.timeout(const Duration(seconds: 6));
    } on TimeoutException {
      // Pas de blocage : le flux mettra l'affichage à jour dès qu'il arrive.
    } finally {
      subscription.close();
    }
  }

  Future<void> _toggle(bool enabled) async {
    if (enabled && !widget.hasSavedLocation) {
      setState(() => _requesting = true);
      var ok = false;
      try {
        ok = await ref.read(locationServiceProvider).updateMyLocation();
      } catch (_) {
        ok = false;
      }
      if (!mounted) return;
      if (!ok) {
        setState(() => _requesting = false);
        // Position refusée/indisponible : l'interrupteur reste coupé,
        // jamais affiché "activé" sans position réellement obtenue.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.locationUnavailable)),
        );
        return;
      }
      // Signalé sur appareil réel le 13/11 : "en activant sa position, les
      // filtres position ne se mettent pas à jour". Le serveur a bien
      // enregistré la position, mais l'interrupteur et la pilule de
      // distance ne lisent QUE le statut synchronisé (hasSavedLocation) :
      // ils restaient sur "sans position" plusieurs secondes après la fin
      // du chargement. On garde donc le chargement affiché jusqu'à ce que
      // le statut confirme réellement la position, au lieu de la supposer.
      await _waitForSavedLocation();
      if (!mounted) return;
      setState(() => _requesting = false);
    }
    // Toujours une nouvelle instance : relance la recherche avec le
    // nouvel état (decouvrirControllerProvider observe ce provider).
    final filters = ref.read(discoverFiltersProvider);
    ref.read(discoverFiltersProvider.notifier).state = filters.copyWith(
      useMyLocation: enabled,
    );
  }

  @override
  Widget build(BuildContext context) {
    final useMyLocation = ref.watch(discoverFiltersProvider).useMyLocation;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.backgroundSoft,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.my_location, size: 15, color: AppColors.accent),
          const SizedBox(width: 6),
          Text(
            context.l10n.myLocationPillLabel,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 24,
            width: 40,
            child: _requesting
                ? const Center(
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : FittedBox(
                    child: Switch(
                      value: useMyLocation && widget.hasSavedLocation,
                      activeTrackColor: AppColors.accent,
                      onChanged: _toggle,
                    ),
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
    this.chevron = false,
    this.dimmed = false,
    this.detected = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool filled;
  final bool chevron;
  // Valeur déduite de la position GPS, affichée mais pas appliquée comme
  // filtre : en italique, avec l'icône de position, pour ne jamais se
  // confondre avec un filtre réellement choisi.
  final bool detected;
  // Réglage affiché mais sans effet réel dans l'état courant — reste
  // cliquable pour pouvoir le modifier.
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: dimmed ? 0.45 : 1,
      child: InkWell(
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
                  fontStyle: detected ? FontStyle.italic : FontStyle.normal,
                  color: filled ? AppColors.noirProfond : AppColors.ink,
                ),
              ),
              if (chevron) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.keyboard_arrow_down,
                  size: 16,
                  color: filled ? AppColors.noirProfond : AppColors.muted,
                ),
              ],
            ],
          ),
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
  late String? _country;
  bool _ageTouched = false;
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
    _country = current.country;
    _cityController = TextEditingController(text: current.city ?? '');
  }

  @override
  void dispose() {
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
            onChanged: (v) => setState(() {
              _ageRange = v;
              _ageTouched = true;
            }),
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
                    var ok = false;
                    try {
                      ok = await ref
                          .read(locationServiceProvider)
                          .updateMyLocation();
                    } catch (_) {
                      ok = false;
                    }
                    // Une position fraîchement enregistrée réactive aussi
                    // l'interrupteur "Ma position" : sinon le message
                    // "position mise à jour" s'afficherait alors que le
                    // serveur continue d'ignorer la distance.
                    if (ok) {
                      final f = ref.read(discoverFiltersProvider);
                      ref.read(discoverFiltersProvider.notifier).state = f
                          .copyWith(useMyLocation: true);
                    }
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
          // Sélecteurs réels (liste ISO 3166-1 / suggestions de villes déjà
          // construites), jamais des champs texte libres — même widgets
          // qu'à l'inscription (CountryField/CityField), demande explicite
          // du propriétaire le 12/11/2026.
          CountryField(
            value: _country,
            label: context.l10n.countryLabel,
            onChanged: (name) => setState(() {
              _country = name;
              _cityController.clear();
            }),
          ),
          const SizedBox(height: 10),
          // Clé liée au pays : CityField garde son propre champ interne,
          // qu'un simple `_cityController.clear()` ne vide pas à l'écran —
          // le recréer au changement de pays évite d'afficher encore la
          // ville de l'ancien pays alors qu'elle n'est plus retenue.
          CityField(
            key: ValueKey(_country),
            controller: _cityController,
            country: _country,
            label: context.l10n.cityLabel,
          ),
          if (_country != null)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => setState(() {
                  _country = null;
                  _cityController.clear();
                }),
                icon: const Icon(Icons.close, size: 16),
                label: Text(context.l10n.removeCountryFilterOption),
              ),
            ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: () {
              final city = _cityController.text.trim();
              final current = ref.read(discoverFiltersProvider);
              // Âge laissé tel quel si le curseur n'a pas été touché :
              // ouvrir la feuille pour régler autre chose (la pilule
              // distance y mène aussi) ne doit pas figer en douce une
              // plage 18-60 à la place de la plage par défaut du serveur.
              final keepAge = !_ageTouched;
              ref
                  .read(discoverFiltersProvider.notifier)
                  .state = DiscoverFilters(
                minAge: keepAge ? current.minAge : _ageRange.start.round(),
                maxAge: keepAge ? current.maxAge : _ageRange.end.round(),
                maxDistanceKm: _distance.round(),
                country: _country,
                // Une ville sans pays n'a aucun effet côté serveur.
                city: _country == null || city.isEmpty ? null : city,
                // Jamais réinitialisés par cette feuille : le genre et
                // l'interrupteur "Ma position" vivent maintenant sur les
                // pilules dédiées (trouvé en écrivant ce correctif —
                // reconstruire DiscoverFilters ici sans les reporter les
                // aurait silencieusement effacés à chaque "Appliquer").
                gender: current.gender,
                useMyLocation: current.useMyLocation,
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
