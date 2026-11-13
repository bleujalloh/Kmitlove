import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/providers/firebase_providers.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/sanction_appeal_button.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../../compatibilite/presentation/compat_controller.dart';
import '../../../decouvrir/presentation/decouvrir_controller.dart';
import '../../../messages/presentation/messages_controller.dart';
import '../../legal_texts.dart';
import '../../settings_controller.dart';
import 'settings_subscreens.dart';
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
                if (current == null) Icon(Icons.check, color: AppColors.accent),
              ],
            ),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.of(dialogContext).pop('fr'),
            child: Row(
              children: [
                Expanded(child: Text(_languageDisplayName('fr'))),
                if (current?.languageCode == 'fr') Icon(Icons.check, color: AppColors.accent),
              ],
            ),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.of(dialogContext).pop('en'),
            child: Row(
              children: [
                Expanded(child: Text(_languageDisplayName('en'))),
                if (current?.languageCode == 'en') Icon(Icons.check, color: AppColors.accent),
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

  String _themeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return context.l10n.themeLight;
      case ThemeMode.dark:
        return context.l10n.themeDark;
      case ThemeMode.system:
        return context.l10n.themeSystem;
    }
  }

  Future<void> _pickTheme() async {
    final current = ref.read(themeModeProvider);
    final choice = await showDialog<ThemeMode>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text(context.l10n.appearance),
        children: [
          for (final mode in ThemeMode.values)
            SimpleDialogOption(
              onPressed: () => Navigator.of(dialogContext).pop(mode),
              child: Row(
                children: [
                  Expanded(child: Text(_themeLabel(mode))),
                  if (current == mode) Icon(Icons.check, color: AppColors.accent),
                ],
              ),
            ),
        ],
      ),
    );
    if (choice != null) await ref.read(themeModeProvider.notifier).setMode(choice);
  }

  void _open(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
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
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.warningBannerTitle,
                      style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.accent),
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
              leading: const Icon(Icons.brightness_6_outlined),
              title: Text(context.l10n.appearance),
              subtitle: Text(_themeLabel(ref.watch(themeModeProvider))),
              trailing: const Icon(Icons.chevron_right),
              onTap: _pickTheme,
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
            ListTile(
              leading: const Icon(Icons.notifications_none),
              title: Text(context.l10n.settingsNotificationsTitle),
              subtitle: Text(context.l10n.settingsNotificationsRowSubtitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _open(const NotificationsSettingsScreen()),
            ),
            ListTile(
              leading: const Icon(Icons.tune),
              title: Text(context.l10n.datingPrefsTitle),
              subtitle: Text(context.l10n.datingPrefsRowSubtitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _open(const DatingPreferencesScreen()),
            ),
            _SectionLabel(context.l10n.privacySectionTitle),
            ListTile(
              leading: const Icon(Icons.visibility_outlined),
              title: Text(context.l10n.profileVisibilityTitle),
              subtitle: Text(
                ref.watch(profileHiddenProvider)
                    ? context.l10n.visibilityHidden
                    : context.l10n.profileVisibilityRowSubtitle,
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _open(const ProfileVisibilityScreen()),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.my_location_outlined),
              title: Text(context.l10n.settingsLocationTitle),
              subtitle: Text(context.l10n.settingsLocationHint),
              value: status?['locationLat'] is num,
              onChanged: _togglingLocation ? null : _toggleLocation,
            ),
            SwitchListTile(
              secondary: const Icon(Icons.done_all),
              title: Text(context.l10n.showReadReceiptsTitle),
              subtitle: Text(context.l10n.showReadReceiptsHint),
              value: ref.watch(showReadReceiptsProvider(myUid)).value ?? true,
              onChanged: (v) => ref.read(messagesControllerProvider).toggleReadReceipts(v),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.people_outline),
              title: Text(context.l10n.compatVisibilityTitle),
              subtitle: Text(context.l10n.compatVisibilityHint),
              value: ref.watch(compatAnswersVisibleProvider).value ?? true,
              onChanged: (v) => ref.read(compatControllerProvider.notifier).setAnswersVisible(v),
            ),
            ListTile(
              leading: const Icon(Icons.block_outlined),
              title: Text(context.l10n.blockedProfilesTitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _open(const BlockedProfilesScreen()),
            ),
            ListTile(
              leading: const Icon(Icons.flag_outlined),
              title: Text(context.l10n.myReportsTitle),
              subtitle: Text(context.l10n.myReportsRowSubtitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _open(const MyReportsScreen()),
            ),
            _SectionLabel(context.l10n.settingsDataSection),
            ListTile(
              leading: _exporting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.download_outlined),
              title: Text(context.l10n.exportMyData),
              subtitle: Text(context.l10n.gdprPortabilityRight),
              trailing: const Icon(Icons.chevron_right),
              onTap: _exporting ? null : _exportData,
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: Text(context.l10n.signOut),
              trailing: const Icon(Icons.chevron_right),
              // Désinscription du jeton push + réinitialisation de l'état de
              // session déplacées dans AuthController.signOut() (12/11/2026).
              onTap: () => ref.read(authControllerProvider.notifier).signOut(),
            ),
            ListTile(
              leading: _deleting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Icon(Icons.delete_outline, color: AppColors.accent),
              title: Text(context.l10n.deleteMyAccount, style: TextStyle(color: AppColors.accent)),
              onTap: _deleting ? null : _confirmDeleteAccount,
            ),
            _SectionLabel(context.l10n.settingsInfoSection),
            ListTile(
              title: Text(context.l10n.legalTerms),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _open(LegalScreen(title: context.l10n.legalTerms, kind: LegalKind.terms)),
            ),
            ListTile(
              title: Text(context.l10n.legalPrivacy),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _open(LegalScreen(title: context.l10n.legalPrivacy, kind: LegalKind.privacy)),
            ),
            ListTile(
              title: Text(context.l10n.legalNotice),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _open(LegalScreen(title: context.l10n.legalNotice, kind: LegalKind.notice)),
            ),
            ListTile(
              title: Text(context.l10n.aboutTitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _open(const AboutScreen()),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 6),
      child: Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.muted)),
    );
  }
}
