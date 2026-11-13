import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/providers/firebase_providers.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/sanction_appeal_button.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../../compatibilite/presentation/compat_controller.dart';
import '../../../decouvrir/presentation/decouvrir_controller.dart';
import '../../../messages/presentation/messages_controller.dart';
import '../../../notifications/push_controller.dart';
import '../../../messages/presentation/screens/blocked_profiles_screen.dart';

/// Espace Paramètres : réglages purs (langue, confidentialité, export
/// RGPD, déconnexion, suppression de compte) — modifier le profil,
/// Premium, le test de compatibilité, la vérification d'identité et
/// l'administration vivent désormais sur l'onglet Profil
/// (lib/features/profil/presentation/screens/mon_profil_screen.dart).
class ParametresScreen extends ConsumerStatefulWidget {
  const ParametresScreen({super.key});

  @override
  ConsumerState<ParametresScreen> createState() => _ParametresScreenState();
}

/// Nom d'une langue dans elle-même (convention universelle : "Français"
/// reste "Français" même en UI anglaise, et inversement) — seule source
/// pour le sous-titre et le dialogue de choix, pour qu'ils ne puissent
/// jamais diverger.
String _languageDisplayName(String code) => code == 'fr' ? 'Français' : 'English';

class _ParametresScreenState extends ConsumerState<ParametresScreen> {
  bool _exporting = false;
  bool _deleting = false;

  Future<void> _exportData() async {
    setState(() => _exporting = true);
    try {
      final functions = ref.read(cloudFunctionsProvider);
      final result = await functions.httpsCallable('exportMyData').call();
      final data = result.data;
      final jsonString = const JsonEncoder.withIndent('  ').convert(data);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/merut-mes-donnees.json');
      await file.writeAsString(jsonString);
      if (mounted) {
        await SharePlus.instance.share(
          ShareParams(files: [XFile(file.path)], text: 'Mes données MERUT'),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.l10n.exportFailed)));
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _confirmDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.deleteAccountConfirmTitle),
        content: Text(
          context.l10n.deleteAccountConfirmBody,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(context.l10n.cancelButton),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.accent),
            child: Text(context.l10n.deletePermanentlyButton),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _deleting = true);
    try {
      await ref.read(authRepositoryProvider).deleteAccount();
      // Pas de navigation manuelle : AuthGate réagit automatiquement à la
      // déconnexion déclenchée par deleteAccount().
    } catch (_) {
      if (mounted) {
        setState(() => _deleting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.deleteAccountFailed)),
        );
      }
    }
  }

  Future<void> _pickLanguage() async {
    final current = ref.read(localeControllerProvider);
    final choice = await showDialog<String>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text(context.l10n.chooseLanguage),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.of(dialogContext).pop('system'),
            child: Row(
              children: [
                Expanded(child: Text(context.l10n.systemLanguage)),
                if (current == null) const Icon(Icons.check, color: AppColors.accent),
              ],
            ),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.of(dialogContext).pop('fr'),
            child: Row(
              children: [
                Expanded(child: Text(_languageDisplayName('fr'))),
                if (current?.languageCode == 'fr') const Icon(Icons.check, color: AppColors.accent),
              ],
            ),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.of(dialogContext).pop('en'),
            child: Row(
              children: [
                Expanded(child: Text(_languageDisplayName('en'))),
                if (current?.languageCode == 'en') const Icon(Icons.check, color: AppColors.accent),
              ],
            ),
          ),
        ],
      ),
    );
    if (choice == null) return;
    await ref
        .read(localeControllerProvider.notifier)
        .setLocale(choice == 'system' ? null : Locale(choice));
  }

  bool _togglingLocation = false;

  /// Active (permission + enregistrement) ou retire (suppression de la
  /// position enregistrée) le consentement à la géolocalisation — même
  /// source de vérité que Découvrir : la position réellement enregistrée.
  Future<void> _toggleLocation(bool on) async {
    setState(() => _togglingLocation = true);
    final messenger = ScaffoldMessenger.of(context);
    final deniedText = context.l10n.settingsLocationDenied;
    final errorText = context.l10n.genericError;
    try {
      final service = ref.read(locationServiceProvider);
      if (on) {
        final ok = await service.updateMyLocation();
        if (!ok) messenger.showSnackBar(SnackBar(content: Text(deniedText)));
      } else {
        await service.clearMyLocation();
      }
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(errorText)));
    } finally {
      if (mounted) setState(() => _togglingLocation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Un compte suspendu/banni n'atteint jamais cet écran (voir
    // core/router/auth_gate.dart → SanctionScreen) — seul un simple
    // avertissement laisse le compte actif et donc visible ici.
    final status = ref.watch(userStatusProvider).value;
    final warned = status?['sanctionLevel'] == 'warned';
    final appealPending = status?['appealPending'] == true;

    final locale = ref.watch(localeControllerProvider);
    final myUid = ref.watch(firebaseAuthProvider).currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.settingsTitle)),
      body: SafeArea(
        child: ListView(
          children: [
            if (warned)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.backgroundSoft,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.warningBannerTitle,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.accent),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      context.l10n.sanctionAppealHint,
                      style: const TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 10),
                    SanctionAppealButton(appealPending: appealPending),
                  ],
                ),
              ),
            ListTile(
              leading: const Icon(Icons.language_outlined),
              title: Text(context.l10n.language),
              subtitle: Text(
                locale == null ? context.l10n.systemLanguage : _languageDisplayName(locale.languageCode),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: _pickLanguage,
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text(
                context.l10n.privacySectionTitle,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.muted, letterSpacing: 0.5),
              ),
            ),
            SwitchListTile(
              title: Text(context.l10n.settingsLocationTitle),
              subtitle: Text(context.l10n.settingsLocationHint),
              value: status?['locationLat'] is num,
              onChanged: _togglingLocation ? null : _toggleLocation,
            ),
            ListTile(
              title: Text(context.l10n.settingsNotificationsTitle),
              subtitle: Text(
                (ref.watch(notificationsEnabledProvider).value ?? true)
                    ? context.l10n.notificationsOn
                    : context.l10n.notificationsOff,
              ),
            ),
            SwitchListTile(
              title: Text(context.l10n.showReadReceiptsTitle),
              subtitle: Text(context.l10n.showReadReceiptsHint),
              value: ref.watch(showReadReceiptsProvider(myUid)).value ?? true,
              onChanged: (v) => ref.read(messagesControllerProvider).toggleReadReceipts(v),
            ),
            SwitchListTile(
              title: Text(context.l10n.compatVisibilityTitle),
              subtitle: Text(context.l10n.compatVisibilityHint),
              value: ref.watch(compatAnswersVisibleProvider).value ?? true,
              onChanged: (v) => ref.read(compatControllerProvider.notifier).setAnswersVisible(v),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.block_outlined),
              title: Text(context.l10n.blockedProfilesTitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const BlockedProfilesScreen()),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: _exporting
                  ? const SizedBox(
                      width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.download_outlined),
              title: Text(context.l10n.exportMyData),
              subtitle: Text(context.l10n.gdprPortabilityRight),
              onTap: _exporting ? null : _exportData,
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.logout),
              title: Text(context.l10n.signOut),
              // Désinscription du jeton push + réinitialisation de l'état de
              // session (filtres, sous-onglets) déplacées dans
              // AuthController.signOut() lui-même (12/11/2026) — ce bouton
              // n'était qu'un des quatre points d'entrée réels de la
              // déconnexion, les trois autres (SanctionScreen,
              // FiltrageScreen, FiltragePendingScreen) ne faisaient ni l'un
              // ni l'autre.
              onTap: () => ref.read(authControllerProvider.notifier).signOut(),
            ),
            const Divider(height: 1),
            ListTile(
              leading: _deleting
                  ? const SizedBox(
                      width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.delete_outline, color: AppColors.accent),
              title: Text(context.l10n.deleteMyAccount, style: const TextStyle(color: AppColors.accent)),
              onTap: _deleting ? null : _confirmDeleteAccount,
            ),
          ],
        ),
      ),
    );
  }
}
