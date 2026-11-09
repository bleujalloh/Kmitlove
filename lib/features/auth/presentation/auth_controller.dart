import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/firebase_providers.dart';
import '../data/auth_repository.dart';

final cloudFunctionsProvider = Provider<FirebaseFunctions>(
  (ref) => FirebaseFunctions.instance,
);

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(firebaseAuthProvider),
    ref.watch(cloudFunctionsProvider),
  );
});

/// Message d'erreur simple et compréhensible, jamais le message technique
/// brut de Firebase (le propriétaire du projet n'est pas développeur).
String readableAuthError(Object error) {
  final code = error is Exception ? error.toString() : '';
  if (code.contains('email-already-in-use')) {
    return 'Cette adresse e-mail est déjà utilisée.';
  }
  if (code.contains('invalid-email')) {
    return 'Adresse e-mail invalide.';
  }
  if (code.contains('weak-password')) {
    return 'Mot de passe trop faible (8 caractères minimum).';
  }
  if (code.contains('user-not-found') || code.contains('wrong-password') || code.contains('invalid-credential')) {
    return 'E-mail ou mot de passe incorrect.';
  }
  if (code.contains('too-many-requests')) {
    return 'Trop de tentatives, réessaie dans quelques minutes.';
  }
  return 'Une erreur est survenue, réessaie.';
}

class AuthController extends AsyncNotifier<void> {
  @override
  void build() {}

  Future<bool> signUp(String email, String password) async {
    state = const AsyncLoading();
    try {
      await ref.read(authRepositoryProvider).signUpWithEmail(email: email, password: password);
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> signIn(String email, String password) async {
    state = const AsyncLoading();
    try {
      await ref.read(authRepositoryProvider).signInWithEmail(email: email, password: password);
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    state = const AsyncLoading();
    try {
      await ref.read(authRepositoryProvider).signInWithGoogle();
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> signInWithApple() async {
    state = const AsyncLoading();
    try {
      await ref.read(authRepositoryProvider).signInWithApple();
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> sendPasswordReset(String email) async {
    state = const AsyncLoading();
    try {
      await ref.read(authRepositoryProvider).sendPasswordResetEmail(email);
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<void> signOut() => ref.read(authRepositoryProvider).signOut();
}

final authControllerProvider = AsyncNotifierProvider<AuthController, void>(
  AuthController.new,
);
