import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
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
      appBar: AppBar(title: const Text('Se connecter')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(28),
          children: [
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Adresse e-mail'),
                    validator: (v) =>
                        (v == null || !v.contains('@')) ? 'E-mail invalide' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Mot de passe'),
                    validator: (v) => (v == null || v.isEmpty) ? 'Mot de passe requis' : null,
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: widget.onGoToResetPassword,
                      child: const Text('Mot de passe oublié ?'),
                    ),
                  ),
                  if (authState.hasError) ...[
                    const SizedBox(height: 4),
                    Text(
                      readableAuthError(authState.error!),
                      style: const TextStyle(color: AppColors.accent, fontSize: 13),
                    ),
                  ],
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: authState.isLoading ? null : _submit,
                    child: authState.isLoading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Se connecter'),
                  ),
                  const SizedBox(height: 18),
                  OutlinedButton.icon(
                    onPressed: authState.isLoading
                        ? null
                        : () => ref.read(authControllerProvider.notifier).signInWithGoogle(),
                    icon: const Icon(Icons.g_mobiledata),
                    label: const Text('Continuer avec Google'),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: authState.isLoading
                        ? null
                        : () => ref.read(authControllerProvider.notifier).signInWithApple(),
                    icon: const Icon(Icons.apple),
                    label: const Text('Continuer avec Apple'),
                  ),
                  const SizedBox(height: 14),
                  TextButton(
                    onPressed: widget.onGoToSignUp,
                    child: const Text('Pas encore de compte ? Créer un compte'),
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
