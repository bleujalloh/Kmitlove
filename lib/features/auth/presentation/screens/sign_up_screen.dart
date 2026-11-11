import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/google_mark.dart';
import '../../../../core/widgets/kamite_motif.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../auth_controller.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key, required this.onGoToSignIn});

  final VoidCallback onGoToSignIn;

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isAdult = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_isAdult) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.mustConfirmAdult)),
      );
      return;
    }
    await ref.read(authControllerProvider.notifier).signUp(
          _emailController.text.trim(),
          _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(28, 8, 28, 28),
          children: [
            const KamiteMotif(height: 110, compact: true),
            const SizedBox(height: 8),
            Text(
              context.l10n.signUpTitle,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.ink),
            ),
            const SizedBox(height: 4),
            Text(
              context.l10n.signUpSubtitle,
              style: const TextStyle(fontSize: 13, color: AppColors.muted),
            ),
            const SizedBox(height: 24),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(labelText: context.l10n.emailLabel),
                    validator: (v) =>
                        (v == null || !v.contains('@')) ? context.l10n.invalidEmail : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(labelText: context.l10n.passwordLabel),
                    validator: (v) =>
                        (v == null || v.length < 8) ? context.l10n.passwordMinLength : null,
                  ),
                  const SizedBox(height: 14),
                  CheckboxListTile(
                    value: _isAdult,
                    onChanged: (v) => setState(() => _isAdult = v ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    activeColor: AppColors.accent,
                    title: Text(
                      context.l10n.confirmAdult,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  if (authState.hasError) ...[
                    const SizedBox(height: 8),
                    Text(
                      readableAuthError(authState.error!, context.l10n),
                      style: const TextStyle(color: AppColors.accent, fontSize: 13),
                    ),
                  ],
                  const SizedBox(height: 18),
                  ElevatedButton(
                    onPressed: (authState.isLoading || !_isAdult) ? null : _submit,
                    child: authState.isLoading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.noirProfond),
                          )
                        : Text(context.l10n.signUp),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      const Expanded(child: Divider(color: AppColors.border)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(context.l10n.orSeparator,
                            style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                      ),
                      const Expanded(child: Divider(color: AppColors.border)),
                    ],
                  ),
                  const SizedBox(height: 18),
                  OutlinedButton.icon(
                    // La case à cocher doit bloquer l'inscription par
                    // Google au même titre que par e-mail (signalé par le
                    // propriétaire le 11/11/2026) — jusqu'ici seul le
                    // bouton "S'inscrire" en tenait compte.
                    onPressed: (authState.isLoading || !_isAdult)
                        ? null
                        : () => ref.read(authControllerProvider.notifier).signInWithGoogle(),
                    icon: const GoogleMark(),
                    label: Text(context.l10n.continueWithGoogle),
                  ),
                  const SizedBox(height: 14),
                  TextButton(
                    onPressed: widget.onGoToSignIn,
                    child: Text(context.l10n.alreadyHaveAccount),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
