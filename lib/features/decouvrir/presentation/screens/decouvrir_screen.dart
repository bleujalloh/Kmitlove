import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/block_action.dart';
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      }
      final matched = next.value?.justMatchedWith;
      if (matched != null && matched != previous?.value?.justMatchedWith) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(context.l10n.itsAMatch),
            content: Text(context.l10n.mutualLikeWith(matched.displayName)),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(context.l10n.great)),
            ],
          ),
        );
      }
    });

    return Scaffold(
      // Sans AppBar, ni bouton retour automatique ni titre cohérent avec
      // le reste de l'app — seul écran dans ce cas, bug remonté sur
      // appareil réel le 11/11.
      appBar: AppBar(
        title: Text(context.l10n.navDiscover),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (_) => const _FiltersSheet(),
            ),
          ),
        ],
      ),
      body: SafeArea(
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
                    onPressed: () => ref.read(decouvrirControllerProvider.notifier).refresh(),
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
                        onPressed: () => ref.read(decouvrirControllerProvider.notifier).refresh(),
                        child: Text(context.l10n.refreshButton),
                      ),
                    ],
                  ),
                ),
              );
            }

            final candidate = data.candidates.first;
            return Column(
              children: [
                const SizedBox(height: 10),
                Expanded(child: _CandidateCard(candidate: candidate)),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _RoundButton(
                        icon: Icons.close,
                        color: AppColors.muted,
                        onTap: () => ref.read(decouvrirControllerProvider.notifier).swipe('pass'),
                      ),
                      const SizedBox(width: 18),
                      _RoundButton(
                        icon: Icons.favorite,
                        color: Colors.white,
                        background: AppColors.accent,
                        size: 62,
                        onTap: () => ref.read(decouvrirControllerProvider.notifier).swipe('like'),
                      ),
                      const SizedBox(width: 18),
                      _RoundButton(
                        icon: Icons.star,
                        color: AppColors.accent,
                        onTap: () => ref.read(decouvrirControllerProvider.notifier).swipe('super_like'),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CandidateCard extends ConsumerWidget {
  const _CandidateCard({required this.candidate});

  final Candidate candidate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final compatScore = ref.watch(compatScoreWithProvider(candidate.uid)).value;
    final photoUrl = ref.watch(candidateFirstPhotoUrlProvider(candidate.uid)).value;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border, width: 1.5),
          borderRadius: BorderRadius.circular(20),
        ),
        clipBehavior: Clip.antiAlias,
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
                      ? Image.network(photoUrl, fit: BoxFit.cover, width: double.infinity, height: 340)
                      : const Icon(Icons.person_outline, size: 46, color: Color(0xFFC9C0B2)),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Material(
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
                ),
                // Nom/âge/localisation sur la photo (comme sur les
                // applications de rencontre courantes), via un dégradé
                // plutôt qu'un fond uni, pour rester lisible sur
                // n'importe quelle photo — remarqué le 11/11 : ces
                // informations existaient déjà mais noyées sous la photo
                // au lieu d'être mises en avant dessus.
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(18, 40, 18, 16),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Color(0xCC000000)],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      '${candidate.displayName}, ${candidate.age}',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (candidate.isVerified) ...[
                                    const SizedBox(width: 6),
                                    const Icon(Icons.verified, color: Colors.white, size: 19),
                                  ],
                                ],
                              ),
                            ),
                            if (compatScore != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: AppColors.accent,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  context.l10n.compatScoreBadge(compatScore),
                                  style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w700),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.place_outlined, size: 15, color: Colors.white70),
                            const SizedBox(width: 4),
                            Text(
                              candidate.distanceKm != null
                                  ? context.l10n.cityCountryWithDistance(candidate.city, candidate.country, candidate.distanceKm!)
                                  : context.l10n.cityCountry(candidate.city, candidate.country),
                              style: const TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(candidate.bio, style: const TextStyle(fontSize: 13.5, color: Color(0xFF4A4038))),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: candidate.interests
                        .map((i) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppColors.accentSoft,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                i,
                                style: const TextStyle(fontSize: 11.5, color: AppColors.accent, fontWeight: FontWeight.w600),
                              ),
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),
          ],
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
      padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.l10n.filtersTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 18),
          Text(context.l10n.ageRangeLabel(_ageRange.start.round(), _ageRange.end.round()),
              style: const TextStyle(fontWeight: FontWeight.w600)),
          RangeSlider(
            values: _ageRange,
            min: 18,
            max: 80,
            divisions: 62,
            activeColor: AppColors.accent,
            onChanged: (v) => setState(() => _ageRange = v),
          ),
          const SizedBox(height: 10),
          Text(context.l10n.maxDistanceLabel(_distance.round()), style: const TextStyle(fontWeight: FontWeight.w600)),
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
                    final ok = await ref.read(locationServiceProvider).updateMyLocation();
                    if (mounted) setState(() => _requestingLocation = false);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(ok
                              ? context.l10n.locationUpdated
                              : context.l10n.locationUnavailable),
                        ),
                      );
                    }
                  },
            icon: const Icon(Icons.my_location),
            label: Text(_requestingLocation ? context.l10n.locatingEllipsis : context.l10n.updateMyLocation),
          ),
          const Divider(height: 28),
          Text(context.l10n.locationFilterTitle, style: const TextStyle(fontWeight: FontWeight.w600)),
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
              ref.read(discoverFiltersProvider.notifier).state = DiscoverFilters(
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
    this.background = Colors.white,
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
          border: background == Colors.white ? Border.all(color: AppColors.border) : null,
        ),
        child: Icon(icon, color: color, size: size * 0.4),
      ),
    );
  }
}
