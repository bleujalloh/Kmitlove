import '../../l10n/app_localizations.dart';

/// Motifs de signalement partagés entre la messagerie (chat_screen.dart)
/// et la communauté (post_detail_screen.dart) — les clés sont les codes
/// stables envoyés au serveur (functions/src/shared/reportReasons.ts),
/// seul le libellé affiché est traduit ici.
Map<String, String> reportReasonLabels(AppLocalizations l10n) => {
      'faux_profil': l10n.reportReasonFakeProfile,
      'comportement_abusif': l10n.reportReasonAbusiveBehavior,
      'contenu_inapproprie': l10n.reportReasonInappropriateContent,
      'arnaque': l10n.reportReasonScam,
      'autre': l10n.reportReasonOther,
    };
