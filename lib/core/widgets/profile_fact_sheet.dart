import 'package:flutter/material.dart';

import '../../features/compatibilite/domain/compat_question.dart';
import '../../features/compatibilite/domain/compat_result.dart';
import '../../features/profil/domain/profil.dart';
import '../../l10n/l10n_extensions.dart';
import '../theme/app_theme.dart';
import 'image_viewer.dart';

/// Contenu complet d'une fiche profil — partagé TEL QUEL par la carte
/// Découvrir (révélation au défilement) et par la page de détail
/// (ProfilDetailScreen) : une seule mise en page, jamais deux copies.
///
/// Ordre voulu par le propriétaire (14/11/2026, d'après ce que font les
/// autres sites de rencontre : le plus engageant d'abord) :
/// 1. l'intention, en étiquette ; 2. la compatibilité expliquée ;
/// 3. la présentation ; 4. ce qu'on recherche chez l'autre et les valeurs,
/// en citations ; 5. les qualités et centres d'intérêt ; 6. « En bref »
/// (taille, études, métier, langues, enfants, tabac et alcool) ; 7. les
/// origines culturelles. Les photos supplémentaires s'intercalent entre ces
/// blocs quand elles sont fournies (la carte Découvrir n'affiche que la
/// première en tête).
///
/// Chaque bloc n'apparaît que s'il est réellement renseigné : jamais une
/// valeur inventée pour remplir la page, jamais un titre sans contenu.
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
    this.values,
    this.lookingFor,
    this.qualities = const [],
    this.languages = const [],
    this.culturalOrigins = const [],
    this.compatThemes = const [],
    this.extraPhotoUrls = const [],
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
  final String? values;
  final String? lookingFor;
  final List<String> qualities;
  final List<String> languages;
  final List<String> culturalOrigins;

  /// Thèmes sur lesquels le membre connecté et cette personne s'accordent le
  /// plus (déjà filtrés : `CompatResult.strongest`).
  final List<CompatThemeScore> compatThemes;

  /// Photos à intercaler entre les blocs (la première photo est ailleurs).
  final List<String> extraPhotoUrls;

  static bool _filled(String? s) => s != null && s.trim().isNotEmpty;

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
        (Icons.straighten, l10n.factHeightLabel, '${(heightCm! / 100).toStringAsFixed(2)} m'),
      if (_filled(educationLevel)) (Icons.school_outlined, l10n.factEducationLabel, educationLevel!),
      if (_filled(profession)) (Icons.work_outline, l10n.factProfessionLabel, profession!),
      if (languages.isNotEmpty) (Icons.translate, l10n.factLanguagesLabel, languages.join(', ')),
      if (childrenStatus != null)
        (Icons.family_restroom_outlined, l10n.factChildrenLabel, ChildrenStatus.label(childrenStatus!, l10n)),
      if (smokingDrinking.isNotEmpty) (Icons.wine_bar_outlined, l10n.factSmokingDrinkingLabel, smokingDrinking),
    ];

    // Photos supplémentaires, distribuées entre les blocs : une après les
    // citations, une après « En bref », le reste à la fin.
    var nextPhoto = 0;
    Widget? takePhoto() {
      if (nextPhoto >= extraPhotoUrls.length) return null;
      final i = nextPhoto++;
      return _SheetPhoto(urls: extraPhotoUrls, index: i);
    }

    final blocks = <Widget>[];
    void add(Widget? w) {
      if (w != null) blocks.add(w);
    }

    if (relationshipIntent != null) {
      add(
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(AppRadii.sm)),
            child: Text(
              '${l10n.factLookingForLabel} : ${RelationshipIntent.label(relationshipIntent!, l10n)}',
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.accent),
            ),
          ),
        ),
      );
    }
    if (compatThemes.isNotEmpty) {
      add(
        Text(
          l10n.compatAlignedOn(compatThemes.map((t) => compatThemeLabel(t.theme, l10n)).join(', ')),
          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, height: 1.4),
        ),
      );
    }
    if (_filled(bio)) {
      add(_Section(title: l10n.aboutMeSectionTitle, child: Text(bio, style: const TextStyle(fontSize: 15.5, height: 1.55))));
    }
    if (_filled(lookingFor)) add(_QuoteCard(title: l10n.profileSectionLookingFor, text: lookingFor!));
    if (_filled(values)) add(_QuoteCard(title: l10n.profileSectionValues, text: values!));
    add(takePhoto());
    if (qualities.isNotEmpty) {
      add(_Section(title: l10n.profileSectionQualities, child: _Chips(items: qualities, accent: false)));
    }
    if (interests.isNotEmpty) {
      add(_Section(title: l10n.profileSectionInterests, child: _Chips(items: interests, accent: true)));
    }
    add(
      _Section(
        title: l10n.profileSectionFacts,
        child: GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 3.2,
          mainAxisSpacing: 6,
          children: facts.map((f) => _FactCell(icon: f.$1, label: f.$2, value: f.$3)).toList(),
        ),
      ),
    );
    add(takePhoto());
    if (culturalOrigins.isNotEmpty) {
      add(_Section(title: l10n.profileSectionOrigins, child: _Chips(items: culturalOrigins, accent: false)));
    }
    for (Widget? w = takePhoto(); w != null; w = takePhoto()) {
      add(w);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < blocks.length; i++) ...[
          if (i > 0) const SizedBox(height: 22),
          blocks[i],
        ],
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: -0.2)),
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}

/// Citation : ce que la personne a écrit pour se présenter, en grand, dans
/// une carte « verre » (même langage que le reste de l'appli, sans trait).
class _QuoteCard extends StatelessWidget {
  const _QuoteCard({required this.title, required this.text});

  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: AppColors.backgroundSoft, borderRadius: BorderRadius.circular(AppRadii.lg)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.accent)),
          const SizedBox(height: 8),
          Text(text, style: AppTypography.tagline(fontSize: 17).copyWith(height: 1.45)),
        ],
      ),
    );
  }
}

/// Pastilles de texte : en or pour les centres d'intérêt, en verre pour les
/// qualités et les origines. Aucune icône décorative.
class _Chips extends StatelessWidget {
  const _Chips({required this.items, required this.accent});

  final List<String> items;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final item in items)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: accent ? AppColors.accentSoft : AppColors.backgroundSoft,
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
            child: Text(
              item,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: accent ? AppColors.accent : AppColors.ink,
              ),
            ),
          ),
      ],
    );
  }
}

class _SheetPhoto extends StatelessWidget {
  const _SheetPhoto({required this.urls, required this.index});

  final List<String> urls;
  final int index;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => openImageViewer(context, urls, index: index),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        child: AspectRatio(
          aspectRatio: 4 / 5,
          child: ColoredBox(
            color: AppColors.placeholder,
            child: Image.network(urls[index], fit: BoxFit.cover, width: double.infinity),
          ),
        ),
      ),
    );
  }
}

class _FactCell extends StatelessWidget {
  const _FactCell({required this.icon, required this.label, required this.value});

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
              Text(label, style: TextStyle(fontSize: 11, color: AppColors.muted), maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(
                value,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink),
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
