import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../../../parametres/legal_texts.dart';
import '../../../parametres/presentation/screens/settings_subscreens.dart';
import '../../../parametres/settings_controller.dart';
import '../auth_controller.dart';

/// Consentement explicite et séparé au traitement des données sensibles
/// (RGPD art. 9, docs/rgpd-registre-des-traitements.md §3). Affiché par
/// AuthGate tant que le membre n'a pas donné un consentement valide —
/// à l'inscription (avant l'assistant de profil) comme pour les comptes
/// existants, ou après un retrait depuis Paramètres. Le consentement est
/// enregistré côté serveur (`recordSensitiveConsent`) ; saveProfil refuse de
/// toute façon d'enregistrer le profil sans lui.
class SensitiveConsentScreen extends ConsumerStatefulWidget {
  const SensitiveConsentScreen({super.key});

  @override
  ConsumerState<SensitiveConsentScreen> createState() => _SensitiveConsentScreenState();
}

class _SensitiveConsentScreenState extends ConsumerState<SensitiveConsentScreen> {
  bool _checked = false;
  bool _busy = false;

  Future<void> _accept() async {
    setState(() => _busy = true);
    try {
      await ref.read(settingsControllerProvider).setSensitiveConsent(true);
      // AuthGate réagit tout seul au changement de statut.
    } catch (_) {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.consentSaveFailed)));
      }
    }
  }

  Future<void> _refuseAndDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.deleteAccountConfirmTitle),
        content: Text(context.l10n.deleteAccountConfirmBody),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: Text(context.l10n.cancelButton)),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(context.l10n.deletePermanentlyButton),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _busy = true);
    try {
      await ref.read(authRepositoryProvider).deleteAccount();
    } catch (_) {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.deleteAccountFailed)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          children: [
            Text(
              l10n.consentTitle,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5, height: 1.2),
            ),
            const SizedBox(height: 12),
            Text(l10n.consentIntro, style: const TextStyle(fontSize: 15, height: 1.5)),
            const SizedBox(height: 18),
            _Item(text: l10n.consentItemOrientation),
            _Item(text: l10n.consentItemCulture),
            _Item(text: l10n.consentItemPhotos),
            const SizedBox(height: 8),
            Text(l10n.consentWithdrawNote, style: const TextStyle(fontSize: 14, height: 1.5)),
            TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => LegalScreen(title: l10n.legalPrivacy, kind: LegalKind.privacy),
                ),
              ),
              style: TextButton.styleFrom(alignment: Alignment.centerLeft, padding: EdgeInsets.zero),
              child: Text(l10n.consentReadPrivacy),
            ),
            const SizedBox(height: 8),
            Material(
              color: AppColors.backgroundSoft,
              borderRadius: BorderRadius.circular(AppRadii.lg),
              child: CheckboxListTile(
                value: _checked,
                onChanged: _busy ? null : (v) => setState(() => _checked = v == true),
                controlAffinity: ListTileControlAffinity.leading,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.lg)),
                title: Text(l10n.consentCheckbox, style: const TextStyle(fontSize: 14.5, height: 1.4)),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: (_checked && !_busy) ? _accept : null,
              child: _busy
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.noirProfond),
                    )
                  : Text(l10n.consentContinue),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _busy ? null : _refuseAndDelete,
              child: Text(l10n.consentRefuseDelete),
            ),
            TextButton(
              onPressed: _busy ? null : () => ref.read(authControllerProvider.notifier).signOut(),
              child: Text(l10n.signOut),
            ),
          ],
        ),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 7, right: 12),
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
            ),
          ),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 15, height: 1.45))),
        ],
      ),
    );
  }
}
