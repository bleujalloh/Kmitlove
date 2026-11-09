import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/candidate.dart';
import '../decouvrir_controller.dart';

/// Écran Découvrir (swipe) — fidèle au prototype visuel validé (artifact
/// Kamalove, Decouvrir.dc.html). Le score de compatibilité par carte sera
/// branché une fois l'appel computeCompatibility relié ici (actuellement
/// construit mais pas encore affiché à cet endroit, voir suivi-developpement.md).
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
            title: const Text("C'est un match !"),
            content: Text('Toi et ${matched.displayName} vous êtes mutuellement likés.'),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Super')),
            ],
          ),
        );
      }
    });

    return Scaffold(
      body: SafeArea(
        child: state.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Impossible de charger les profils.'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => ref.read(decouvrirControllerProvider.notifier).refresh(),
                    child: const Text('Réessayer'),
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
                      const Text(
                        "Plus de profils pour l'instant, repasse plus tard.",
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => ref.read(decouvrirControllerProvider.notifier).refresh(),
                        child: const Text('Actualiser'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final candidate = data.candidates.first;
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Découvrir',
                        style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: AppColors.ink),
                      ),
                    ],
                  ),
                ),
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

class _CandidateCard extends StatelessWidget {
  const _CandidateCard({required this.candidate});

  final Candidate candidate;

  @override
  Widget build(BuildContext context) {
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
            Container(
              height: 220,
              width: double.infinity,
              color: AppColors.placeholder,
              child: const Icon(Icons.person_outline, size: 46, color: Color(0xFFC9C0B2)),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${candidate.displayName}, ${candidate.age}',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.ink),
                  ),
                  const SizedBox(height: 4),
                  Text('${candidate.city}, ${candidate.country}',
                      style: const TextStyle(color: AppColors.muted, fontSize: 13)),
                  const SizedBox(height: 12),
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
