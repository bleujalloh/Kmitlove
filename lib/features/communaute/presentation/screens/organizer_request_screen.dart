import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../communaute_controller.dart';

/// Demande du statut organisateur (spec Communauté section 3,
/// 11/11/2026) — simplifiée sur demande explicite du propriétaire : pas
/// d'abonnement, mais un contrôle humain (validation admin) reste
/// obligatoire avant toute première publication d'événement.
class OrganizerRequestScreen extends ConsumerStatefulWidget {
  const OrganizerRequestScreen({super.key});

  @override
  ConsumerState<OrganizerRequestScreen> createState() => _OrganizerRequestScreenState();
}

class _OrganizerRequestScreenState extends ConsumerState<OrganizerRequestScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_nameController.text.trim().isEmpty || _descriptionController.text.trim().isEmpty) return;
    setState(() => _sending = true);
    try {
      await ref
          .read(communauteControllerProvider)
          .requestOrganizerStatus(_nameController.text.trim(), _descriptionController.text.trim());
      if (mounted) {
        await showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(context.l10n.organizerRequestSentTitle),
            content: Text(context.l10n.organizerRequestSentBody),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(context.l10n.cancelButton),
              ),
            ],
          ),
        );
        if (mounted) Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.l10n.organizerRequestFailed)));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(myOrganizerStatusProvider).value;

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.becomeOrganizerTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            if (status == 'pending' || status == 'rejected' || status == 'suspended') ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.accentSoft,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  status == 'pending'
                      ? context.l10n.organizerStatusPending
                      : status == 'suspended'
                          ? context.l10n.organizerStatusSuspended
                          : context.l10n.organizerStatusRejected,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 20),
            ],
            if (status != 'pending' && status != 'approved') ...[
              Text(
                context.l10n.becomeOrganizerIntro,
                style: TextStyle(color: AppColors.muted, fontSize: 13.5, height: 1.4),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(labelText: context.l10n.organizerNameLabel),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: InputDecoration(labelText: context.l10n.organizerDescriptionLabel),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _sending ? null : _submit,
                child: _sending
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.noirProfond),
                      )
                    : Text(context.l10n.organizerRequestSubmitButton),
              ),
            ] else if (status == 'approved')
              Text(context.l10n.organizerStatusApproved, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
