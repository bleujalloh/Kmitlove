import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
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
        const SnackBar(content: Text('Tu dois confirmer avoir 18 ans ou plus.')),
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
      appBar: AppBar(title: const Text('Créer un compte')),
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
                    validator: (v) =>
                        (v == null || v.length < 8) ? '8 caractères minimum' : null,
                  ),
                  const SizedBox(height: 14),
                  CheckboxListTile(
                    value: _isAdult,
                    onChanged: (v) => setState(() => _isAdult = v ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    activeColor: AppColors.accent,
                    title: const Text(
                      "Je confirme avoir 18 ans ou plus.",
                      style: TextStyle(fontSize: 13),
                    ),
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
                        : const Text("S'inscrire"),
                  ),
                  const SizedBox(height: 14),
                  TextButton(
                    onPressed: widget.onGoToSignIn,
                    child: const Text('Déjà un compte ? Se connecter'),
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
