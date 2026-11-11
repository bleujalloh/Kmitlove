import '../../../l10n/app_localizations.dart';

class CompatQuestion {
  const CompatQuestion({required this.id, required this.theme, required this.question});

  final String id;
  final String theme;
  final String question;

  factory CompatQuestion.fromMap(Map<String, dynamic> data) {
    return CompatQuestion(
      id: data['id'] as String,
      theme: data['theme'] as String,
      question: data['question'] as String,
    );
  }
}

String compatThemeLabel(String theme, AppLocalizations l10n) {
  switch (theme) {
    case 'vision_couple':
      return l10n.compatThemeVisionCouple;
    case 'valeurs_culture':
      return l10n.compatThemeValeursCulture;
    case 'famille':
      return l10n.compatThemeFamille;
    case 'mode_vie':
      return l10n.compatThemeModeVie;
    case 'communication':
      return l10n.compatThemeCommunication;
    default:
      return theme;
  }
}
