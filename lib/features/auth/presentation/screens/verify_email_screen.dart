import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/firebase_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../auth_controller.dart';

/// Attente de la vérification d'e-mail (section 4.1 du cahier des charges).
/// Revérifie automatiquement toutes les 5 secondes pendant que l'utilisateur
/// a l'onglet ouvert, pour ne pas le bloquer sur un bouton "j'ai vérifié".
class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key, required this.onVerified});

  final VoidCallback onVerified;

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  Timer? _timer;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _check());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _check() async {
    final verified = await ref.read(authRepositoryProvider).checkEmailVerified();
    if (verified) {
      _timer?.cancel();
      widget.onVerified();
    }
  }

  Future<void> _resend() async {
    setState(() => _sending = true);
    await ref.read(authRepositoryProvider).resendEmailVerification();
    if (mounted) {
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("E-mail de vérification renvoyé.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = ref.read(firebaseAuthProviderForDisplay);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.mark_email_unread_outlined, size: 56, color: AppColors.accent),
                const SizedBox(height: 18),
                Text(
                  'Vérifie ta boîte mail',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  'Un lien de confirmation a été envoyé à $email. Clique sur le lien, cette page se met à jour automatiquement.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 22),
                TextButton(
                  onPressed: _sending ? null : _resend,
                  child: Text(_sending ? 'Envoi...' : "Je n'ai rien reçu, renvoyer l'e-mail"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final firebaseAuthProviderForDisplay = Provider<String>((ref) {
  return ref.watch(firebaseAuthProvider).currentUser?.email ?? 'ton adresse';
});
