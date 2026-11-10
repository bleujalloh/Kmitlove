import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/auth_controller.dart';
import '../../features/profil/presentation/profil_controller.dart';
import '../theme/app_theme.dart';

/// Numéros d'urgence connus avec certitude seulement — mieux vaut un
/// repli honnête (112, qui fonctionne via la plupart des réseaux mobiles)
/// qu'un numéro précis mais non vérifié pour un pays qu'on ne maîtrise
/// pas, vu ce qui est en jeu (docs/regles-complementaires-concurrents.md
/// section 1).
const Map<String, String> _knownEmergencyNumbers = {
  'France': '17 (Police/Gendarmerie) · 112 (urgences Europe)',
  'Belgique': '101 (Police) · 112 (urgences Europe)',
};
const String _fallbackEmergencyNumbers =
    '112 (fonctionne dans la plupart des pays via un réseau mobile) — vérifie aussi le numéro d\'urgence local de ton pays de résidence';

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
          const SnackBar(content: Text("Échec de l'envoi, réessaie — ou appelle directement un numéro ci-dessous.")),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final country = ref.watch(profilProvider).value?.country;
    final numbers = (country != null ? _knownEmergencyNumbers[country] : null) ?? _fallbackEmergencyNumbers;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.warning_amber_rounded, color: AppColors.accent),
                SizedBox(width: 10),
                Text('Sécurité', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 14),
            Text('Numéros d\'urgence', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 6),
            Text(numbers, style: const TextStyle(color: AppColors.muted, fontSize: 13.5, height: 1.4)),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),
            const Text(
              'Si quelqu\'un te met en danger immédiat, préviens la modération en priorité absolue. '
              'Ce bouton n\'appelle jamais les secours à ta place — compose un numéro ci-dessus si tu es en danger maintenant.',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _sending || _sent ? null : _send,
                icon: _sending
                    ? const SizedBox(
                        width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Icon(_sent ? Icons.check : Icons.campaign_outlined),
                label: Text(_sent ? 'Modération prévenue' : 'Signaler un danger immédiat'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
