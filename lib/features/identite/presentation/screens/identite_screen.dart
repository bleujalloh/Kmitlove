import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/providers/firebase_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../../profil/presentation/photo_controller.dart';
import '../../data/identite_repository.dart';

final identiteRepositoryProvider = Provider((ref) {
  return IdentiteRepository(ref.watch(firebaseStorageProvider), ref.watch(cloudFunctionsProvider));
});

/// Vérification d'identité par selfie (cahier des charges section 4.8 et
/// docs/regles-complementaires-concurrents.md section 1) : donne le
/// badge visible et est requise pour organiser un événement physique.
/// Jamais obligatoire pour utiliser le reste de l'app.
class IdentiteScreen extends ConsumerStatefulWidget {
  const IdentiteScreen({super.key});

  @override
  ConsumerState<IdentiteScreen> createState() => _IdentiteScreenState();
}

class _IdentiteScreenState extends ConsumerState<IdentiteScreen> {
  bool _submitting = false;

  Future<void> _submit() async {
    final uid = ref.read(firebaseAuthProvider).currentUser?.uid;
    if (uid == null) return;
    final picked = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 85);
    if (picked == null) return;

    setState(() => _submitting = true);
    try {
      await ref.read(identiteRepositoryProvider).submitSelfie(uid, File(picked.path));
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.l10n.identitySubmitted)));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.l10n.identitySubmitFailed)));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.identityVerificationTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.verified_outlined, size: 56, color: AppColors.accent),
              const SizedBox(height: 18),
              Text(
                context.l10n.identityIntro,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted, height: 1.5),
              ),
              const SizedBox(height: 10),
              Text(
                context.l10n.identityPrivacyHint,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted, fontSize: 12, height: 1.5),
              ),
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.noirProfond),
                      )
                    : Text(context.l10n.takeASelfie),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
