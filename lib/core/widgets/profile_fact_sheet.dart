import 'package:flutter/material.dart';

import '../../features/profil/domain/profil.dart';
import '../../l10n/l10n_extensions.dart';
import '../theme/app_theme.dart';

/// Icône approximative par mot-clé pour un centre d'intérêt (texte libre,
/// aucune liste fermée côté serveur — saveProfil.ts) : une correspondance
/// raisonnable quand un mot-clé connu est trouvé, une icône générique
/// sinon (maquette visuelle validée le 12/11/2026) — jamais une
/// classification exacte garantie, purement décoratif, aucune règle
/// métier n'en dépend.
IconData interestIcon(String interest) {
  final lower = interest.toLowerCase();
  if (lower.contains('kamite') ||
      lower.contains('kemet') ||
      lower.contains('culture')) {
    return Icons.account_balance_outlined;
  }
  if (lower.contains('histoire')) return Icons.menu_book_outlined;
  if (lower.contains('spiritualit')) return Icons.self_improvement_outlined;
  if (lower.contains('bien') && lower.contains('tre')) {
    return Icons.fitness_center_outlined;
  }
  if (lower.contains('sport') || lower.contains('fitness')) {
    return Icons.fitness_center_outlined;
  }
  if (lower.contains('musique')) return Icons.music_note_outlined;
  if (lower.contains('cuisine') || lower.contains('cooking')) {
    return Icons.restaurant_outlined;
  }
  if (lower.contains('voyage') || lower.contains('travel')) {
    return Icons.flight_outlined;
  }
  if (lower.contains('lecture') ||
      lower.contains('livre') ||
      lower.contains('book')) {
    return Icons.book_outlined;
  }
  if (lower.contains('cinéma') ||
      lower.contains('cinema') ||
      lower.contains('film')) {
    return Icons.movie_outlined;
  }
  if (lower.contains('art') || lower.contains('peinture')) {
    return Icons.palette_outlined;
  }
  if (lower.contains('danse') || lower.contains('dance')) {
    return Icons.nightlife_outlined;
  }
  if (lower.contains('nature') || lower.contains('randonn')) {
    return Icons.park_outlined;
  }
  return Icons.local_offer_outlined;
}

/// Contenu complet d'une fiche profil (centres d'intérêt, "À propos de
/// moi", grille de faits étendue) — extrait de l'écran de détail
/// (ProfilDetailScreen) pour être réutilisé TEL QUEL dans la carte
/// Découvrir (révélation au scroll, demande explicite du propriétaire
/// le 12/11/2026) sans dupliquer la mise en page à deux endroits. Chaque
/// fait n'apparaît que si réellement renseigné : jamais une valeur
/// inventée pour remplir la grille de la maquette (ex. aucun champ
/// "mode de vie" n'existe dans le modèle de données — volontairement
/// omis plutôt que fabriqué).
class ProfileFactSheet extends StatelessWidget {
  const ProfileFactSheet({
    super.key,
    required this.bio,
    required this.interests,
    required this.age,
    this.heightCm,
    this.educationLevel,
    this.profession,
    this.relationshipIntent,
    this.childrenStatus,
    this.smokingHabit,
    this.drinkingHabit,
  });

  final String bio;
  final List<String> interests;
  final int age;
  final int? heightCm;
  final String? educationLevel;
  final String? profession;
  final String? relationshipIntent;
  final String? childrenStatus;
  final String? smokingHabit;
  final String? drinkingHabit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final smokingDrinking = [
      if (smokingHabit != null) LifestyleHabit.label(smokingHabit!, l10n),
      if (drinkingHabit != null) LifestyleHabit.label(drinkingHabit!, l10n),
    ].join(' / ');

    final facts = <(IconData, String, String)>[
      (Icons.cake_outlined, l10n.factAgeLabel, l10n.factAgeValue(age)),
      if (heightCm != null)
        (
          Icons.straighten,
          l10n.factHeightLabel,
          '${(heightCm! / 100).toStringAsFixed(2)} m',
        ),
      if (educationLevel?.trim().isNotEmpty == true)
        (Icons.school_outlined, l10n.factEducationLabel, educationLevel!),
      if (profession?.trim().isNotEmpty == true)
        (Icons.work_outline, l10n.factProfessionLabel, profession!),
      if (relationshipIntent != null)
        (
          Icons.favorite_border,
          l10n.factLookingForLabel,
          RelationshipIntent.label(relationshipIntent!, l10n),
        ),
      if (childrenStatus != null)
        (
          Icons.family_restroom_outlined,
          l10n.factChildrenLabel,
          ChildrenStatus.label(childrenStatus!, l10n),
        ),
      if (smokingDrinking.isNotEmpty)
        (
          Icons.wine_bar_outlined,
          l10n.factSmokingDrinkingLabel,
          smokingDrinking,
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (interests.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: interests
                .map(
                  (i) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accentSoft,
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          interestIcon(i),
                          size: 14,
                          color: AppColors.accent,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          i,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.accent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 20),
        ],
        if (bio.trim().isNotEmpty) ...[
          Row(
            children: [
              Icon(
                Icons.person_outline,
                size: 18,
                color: AppColors.accent,
              ),
              const SizedBox(width: 8),
              Text(
                l10n.aboutMeSectionTitle,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            bio,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.5,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 20),
        ],
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 3.2,
          mainAxisSpacing: 6,
          children: facts
              .map((f) => _FactCell(icon: f.$1, label: f.$2, value: f.$3))
              .toList(),
        ),
      ],
    );
  }
}

class _FactCell extends StatelessWidget {
  const _FactCell({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.accent),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 11, color: AppColors.muted),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
