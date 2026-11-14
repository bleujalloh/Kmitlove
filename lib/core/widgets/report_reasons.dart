import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_extensions.dart';

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

/// Exécute l'envoi d'un signalement ET en annonce toujours le résultat :
/// confirmation, limite de fréquence atteinte, ou échec. Sans cela, un
/// signalement refusé (quota, réseau) fermait la feuille sans rien dire — un
/// membre qui signale un comportement dangereux croyait l'avoir fait.
Future<void> sendReportWithFeedback(BuildContext context, Future<void> Function() send) async {
  final messenger = ScaffoldMessenger.of(context);
  final l10n = context.l10n;
  try {
    await send();
    messenger.showSnackBar(SnackBar(content: Text(l10n.reportSent)));
  } catch (e) {
    final rateLimited = e is FirebaseFunctionsException && e.code == 'resource-exhausted';
    messenger.showSnackBar(SnackBar(content: Text(rateLimited ? l10n.reportRateLimited : l10n.reportFailed)));
  }
}
