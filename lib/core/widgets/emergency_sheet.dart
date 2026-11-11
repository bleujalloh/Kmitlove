import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/auth_controller.dart';
import '../../features/profil/presentation/profil_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_extensions.dart';
import '../theme/app_theme.dart';

/// Numéros d'urgence connus avec certitude seulement — mieux vaut un
/// repli honnête (112, qui fonctionne via la plupart des réseaux mobiles)
/// qu'un numéro précis mais non vérifié pour un pays qu'on ne maîtrise
/// pas, vu ce qui est en jeu (docs/regles-complementaires-concurrents.md
/// section 1). Les clés restent les noms de pays tels que stockés dans le
/// profil (saisis en français) ; seul le libellé affiché est traduit.
Map<String, String> _knownEmergencyNumbers(AppLocalizations l10n) => {
      'France': l10n.emergencyNumbersFrance,
      'Belgique': l10n.emergencyNumbersBelgium,
    };

/// Bouton "Signaler un danger immédiat" + numéros d'urgence toujours
/// visibles, indépendamment de tout signalement (docs/regles-
/// complementaires-concurrents.md section 1). N'appelle jamais les
/// secours automatiquement — alerte la modération en priorité absolue.
void showEmergencySheet(BuildContext context, WidgetRef ref, {String? eventPostId, String? matchId}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => _EmergencySheetContent(eventPostId: eventPostId, matchId: matchId),
  );
}

class _EmergencySheetContent extends ConsumerStatefulWidget {
  const _EmergencySheetContent({this.eventPostId, this.matchId});

  final String? eventPostId;
  final String? matchId;

  @override
  ConsumerState<_EmergencySheetContent> createState() => _EmergencySheetContentState();
}

class _EmergencySheetContentState extends ConsumerState<_EmergencySheetContent> {
  bool _sending = false;
  bool _sent = false;

  Future<void> _send() async {
    setState(() => _sending = true);
    try {
      await ref.read(cloudFunctionsProvider).httpsCallable('triggerEmergencyAlert').call({
        'eventPostId': widget.eventPostId,
        'matchId': widget.matchId,
      });
      if (mounted) setState(() => _sent = true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.emergencySendFailed)),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final country = ref.watch(profilProvider).value?.country;
    final knownNumbers = _knownEmergencyNumbers(context.l10n);
    final numbers = (country != null ? knownNumbers[country] : null) ?? context.l10n.emergencyNumbersFallback;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: AppColors.accent),
                const SizedBox(width: 10),
                Text(context.l10n.safetyTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 14),
            Text(context.l10n.emergencyNumbersTitle, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 6),
            Text(numbers, style: const TextStyle(color: AppColors.muted, fontSize: 13.5, height: 1.4)),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),
            Text(
              context.l10n.emergencySheetDisclaimer,
              style: const TextStyle(fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _sending || _sent ? null : _send,
                icon: _sending
                    ? const SizedBox(
                        width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.noirProfond))
                    : Icon(_sent ? Icons.check : Icons.campaign_outlined),
                label: Text(_sent ? context.l10n.moderationNotified : context.l10n.reportImmediateDanger),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
