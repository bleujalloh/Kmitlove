import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/providers/firebase_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/sanction_appeal_button.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../../profil/presentation/profil_controller.dart';
import '../../../profil/presentation/screens/profil_edit_screen.dart';

/// Espace Paramètres : seul point d'accès pour modifier son profil une
/// fois créé, exporter ses données (RGPD) et supprimer son compte —
/// jusqu'ici absent de l'app (docs/suivi-developpement.md).
class ParametresScreen extends ConsumerStatefulWidget {
  const ParametresScreen({super.key});

  @override
  ConsumerState<ParametresScreen> createState() => _ParametresScreenState();
}

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
            .showSnackBar(const SnackBar(content: Text("Impossible d'exporter, réessaie.")));
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _confirmDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Supprimer définitivement ton compte ?'),
        content: const Text(
          'Ton profil, tes photos, tes messages, tes matchs, tes annonces et tes réponses sont supprimés sans retour possible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.accent),
            child: const Text('Supprimer définitivement'),
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
          const SnackBar(content: Text('Impossible de supprimer le compte, réessaie.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profilAsync = ref.watch(profilProvider);
    // Un compte suspendu/banni n'atteint jamais cet écran (voir
    // core/router/auth_gate.dart → SanctionScreen) — seul un simple
    // avertissement laisse le compte actif et donc visible ici.
    final status = ref.watch(userStatusProvider).value;
    final warned = status?['sanctionLevel'] == 'warned';
    final appealPending = status?['appealPending'] == true;

    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres')),
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
                    const Text(
                      'Ton compte a reçu un avertissement suite à un signalement confirmé.',
                      style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.accent),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Si tu penses que c\'est une erreur, tu peux demander qu\'un modérateur réexamine cette décision.',
                      style: TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 10),
                    SanctionAppealButton(appealPending: appealPending),
                  ],
                ),
              ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Modifier mon profil'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                final profil = profilAsync.value;
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => ProfilEditScreen(existing: profil)),
                );
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: _exporting
                  ? const SizedBox(
                      width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.download_outlined),
              title: const Text('Exporter mes données'),
              subtitle: const Text('Droit RGPD à la portabilité'),
              onTap: _exporting ? null : _exportData,
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Se déconnecter'),
              onTap: () => ref.read(authControllerProvider.notifier).signOut(),
            ),
            const Divider(height: 1),
            ListTile(
              leading: _deleting
                  ? const SizedBox(
                      width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.delete_outline, color: AppColors.accent),
              title: const Text('Supprimer mon compte', style: TextStyle(color: AppColors.accent)),
              onTap: _deleting ? null : _confirmDeleteAccount,
            ),
          ],
        ),
      ),
    );
  }
}
