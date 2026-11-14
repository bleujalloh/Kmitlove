/// Score de compatibilité par thème (jamais le détail des réponses) : sert à
/// dire sur quoi deux membres s'accordent.
class CompatThemeScore {
  const CompatThemeScore({required this.theme, required this.score});

  /// Identifiant stable du thème (functions/src/config.ts : COMPAT_THEME_WEIGHTS),
  /// affiché via `compatThemeLabel`.
  final String theme;

  /// Pourcentage de ressemblance des réponses sur ce thème, de 0 à 100.
  final int score;
}

/// Résultat de `computeCompatibility` : score global (null tant qu'il n'est
/// pas calculable) et score de chaque thème retenu.
class CompatResult {
  const CompatResult({required this.score, this.themes = const []});

  final int? score;
  final List<CompatThemeScore> themes;

  factory CompatResult.fromMap(Map<Object?, Object?> data) {
    final rawThemes = data['themes'];
    return CompatResult(
      score: (data['score'] as num?)?.toInt(),
      themes: [
        if (rawThemes is List)
          for (final t in rawThemes)
            if (t is Map && t['theme'] is String && t['score'] is num)
              CompatThemeScore(theme: t['theme'] as String, score: (t['score'] as num).toInt()),
      ],
    );
  }

  /// Les thèmes où l'accord est le plus net (au moins `minScore` %), du
  /// meilleur au moins bon, au plus `max`.
  List<CompatThemeScore> strongest({int minScore = 70, int max = 2}) {
    final sorted = [...themes.where((t) => t.score >= minScore)]..sort((a, b) => b.score.compareTo(a.score));
    return sorted.take(max).toList();
  }
}
