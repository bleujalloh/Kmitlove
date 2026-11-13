import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/google_mark.dart';
import '../../../../core/widgets/kamite_motif.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../auth_controller.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({
    super.key,
    required this.onGoToSignUp,
    required this.onGoToResetPassword,
  });

  final VoidCallback onGoToSignUp;
  final VoidCallback onGoToResetPassword;

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authControllerProvider.notifier).signIn(
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
              context.l10n.signInTitle,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.ink),
            ),
            const SizedBox(height: 4),
            Text(
              context.l10n.signInSubtitle,
              style: TextStyle(fontSize: 13, color: AppColors.muted),
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
                    validator: (v) => (v == null || v.isEmpty) ? context.l10n.passwordRequired : null,
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: widget.onGoToResetPassword,
                      child: Text(context.l10n.forgotPassword),
                    ),
                  ),
                  if (authState.hasError) ...[
                    const SizedBox(height: 4),
                    Text(
                      readableAuthError(authState.error!, context.l10n),
                      style: TextStyle(color: AppColors.accent, fontSize: 13),
                    ),
                  ],
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: authState.isLoading ? null : _submit,
                    child: authState.isLoading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.noirProfond),
                          )
                        : Text(context.l10n.signIn),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(child: Divider(color: AppColors.border)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(context.l10n.orSeparator,
                            style: TextStyle(color: AppColors.muted, fontSize: 12)),
                      ),
                      Expanded(child: Divider(color: AppColors.border)),
                    ],
                  ),
                  const SizedBox(height: 18),
                  OutlinedButton.icon(
                    onPressed: authState.isLoading
                        ? null
                        : () => ref
                            .read(authControllerProvider.notifier)
                            .signInWithGoogle(allowAccountCreation: false),
                    icon: const GoogleMark(),
                    label: Text(context.l10n.continueWithGoogle),
                  ),
                  // Connexion Apple volontairement masquée : le compte
                  // Apple Developer n'est pas encore ouvert, le bouton ne
                  // ferait qu'échouer (docs/suivi-developpement.md).
                  const SizedBox(height: 14),
                  TextButton(
                    onPressed: widget.onGoToSignUp,
                    child: Text(context.l10n.noAccountYet),
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
