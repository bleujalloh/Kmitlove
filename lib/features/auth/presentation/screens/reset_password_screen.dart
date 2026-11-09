import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../auth_controller.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await ref
        .read(authControllerProvider.notifier)
        .sendPasswordReset(_emailController.text.trim());
    if (ok) setState(() => _sent = true);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Réinitialiser le mot de passe')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: _sent
              ? const Text(
                  "Si cette adresse existe, un e-mail de réinitialisation vient d'être envoyé. Pense à vérifier tes spams.",
                  style: TextStyle(fontSize: 14, height: 1.5),
                )
              : Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Indique ton adresse e-mail, on t\'envoie un lien pour choisir un nouveau mot de passe.',
                        style: TextStyle(fontSize: 14, color: AppColors.muted),
                      ),
                      const SizedBox(height: 18),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(labelText: 'Adresse e-mail'),
                        validator: (v) =>
                            (v == null || !v.contains('@')) ? 'E-mail invalide' : null,
                      ),
                      if (authState.hasError) ...[
                        const SizedBox(height: 8),
                        Text(
                          readableAuthError(authState.error!),
                          style: const TextStyle(color: AppColors.accent, fontSize: 13),
                        ),
                      ],
                      const SizedBox(height: 18),
                      ElevatedButton(
                        onPressed: authState.isLoading ? null : _submit,
                        child: authState.isLoading
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Envoyer le lien'),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
