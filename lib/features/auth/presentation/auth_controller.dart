import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../core/device_id.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../../l10n/app_localizations.dart';
import '../data/auth_repository.dart';

// Toutes les Cloud Functions sont déployées sur europe-west1 (voir
// functions/src/config.ts, REGION) — sans région explicite ici, le SDK
// appelle par défaut us-central1, où rien n'existe : chaque appel
// renvoyait silencieusement "not-found" (bug présent depuis la toute
// première version de ce fichier, découvert sur appareil réel le 11/11
// uniquement parce que startFiltrageAttempt affiche enfin un code
// technique en cas d'échec — l'ampleur réelle de son impact sur les
// autres fonctions appelables, jamais vérifiées une par une, est inconnue).
final cloudFunctionsProvider = Provider<FirebaseFunctions>(
  (ref) => FirebaseFunctions.instanceFor(region: 'europe-west1'),
);

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(firebaseAuthProvider),
    ref.watch(cloudFunctionsProvider),
  );
});

/// Message d'erreur simple et compréhensible, jamais le message technique
/// brut de Firebase (le propriétaire du projet n'est pas développeur).
String readableAuthError(Object error, AppLocalizations l10n) {
  final code = error is Exception ? error.toString() : '';
  if (code.contains('email-already-in-use')) {
    return l10n.authErrorEmailInUse;
  }
  if (code.contains('invalid-email')) {
    return l10n.authErrorInvalidEmail;
  }
  if (code.contains('weak-password')) {
    return l10n.authErrorWeakPassword;
  }
  if (code.contains('user-not-found') || code.contains('wrong-password') || code.contains('invalid-credential')) {
    return l10n.authErrorWrongCredentials;
  }
  if (code.contains('too-many-requests')) {
    return l10n.authErrorTooManyRequests;
  }
  if (code.contains('operation-not-allowed')) {
    return l10n.authErrorOperationNotAllowed;
  }
  if (code.contains('network-request-failed')) {
    return l10n.authErrorNetwork;
  }
  // Code technique ajouté entre parenthèses seulement ici (cas non reconnu)
  // pour qu'une simple capture d'écran suffise à diagnostiquer la suite,
  // sans avoir besoin d'un terminal/adb logcat.
  final shortCode = RegExp(r'firebase_auth/[a-z0-9-]+').stringMatch(code);
  return shortCode != null ? l10n.genericErrorWithCode(shortCode) : l10n.genericError;
}

/// Posé par signInWithGoogle/signInWithApple quand l'authentification
/// vient de créer un compte tout neuf (jamais lors d'une simple
/// reconnexion). AuthGate l'observe pour imposer un écran de confirmation
/// d'âge avant de laisser passer vers le reste de l'app : ces deux
/// méthodes n'ont pas de case à cocher avant l'appel contrairement à
/// l'inscription par e-mail, et un contrôle fait depuis l'écran
/// d'origine arrive trop tard — authStateProvider notifie AuthGate dès
/// que Firebase confirme la connexion, qui navigue immédiatement vers
/// l'écran suivant avant que l'écran d'origine ait eu la main pour
/// afficher quoi que ce soit (bug remonté sur appareil réel le 11/11 :
/// Google laissait passer sans jamais rien demander, confirmé par
/// capture d'écran).
final pendingAdultConfirmationProvider = StateProvider<bool>((ref) => false);

class AuthController extends AsyncNotifier<void> {
  @override
  void build() {}

  Future<bool> signUp(String email, String password) async {
    state = const AsyncLoading();
    try {
      final credential =
          await ref.read(authRepositoryProvider).signUpWithEmail(email: email, password: password);
      unawaited(_reportDeviceSignalIfNew(credential));
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  /// Signal anti-abus best-effort (limite de comptes par appareil,
  /// docs/suivi-developpement.md) : jamais sur une simple reconnexion,
  /// et jamais bloquant pour l'inscription elle-même si l'appel échoue.
  Future<void> _reportDeviceSignalIfNew(UserCredential credential) async {
    if (credential.additionalUserInfo?.isNewUser != true) return;
    try {
      final deviceId = await getDeviceSignalId();
      await ref
          .read(cloudFunctionsProvider)
          .httpsCallable('registerDeviceSignal')
          .call({'deviceId': deviceId});
    } catch (_) {
      // Signal best-effort : une erreur réseau ici ne doit jamais empêcher
      // l'inscription de se terminer normalement.
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
      final credential = await ref.read(authRepositoryProvider).signInWithGoogle();
      if (credential.additionalUserInfo?.isNewUser == true) {
        ref.read(pendingAdultConfirmationProvider.notifier).state = true;
      }
      unawaited(_reportDeviceSignalIfNew(credential));
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
      final credential = await ref.read(authRepositoryProvider).signInWithApple();
      if (credential.additionalUserInfo?.isNewUser == true) {
        ref.read(pendingAdultConfirmationProvider.notifier).state = true;
      }
      unawaited(_reportDeviceSignalIfNew(credential));
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

/// Déclenche une seule fois par session l'enregistrement de
/// "dernière activité" (docs/regles-complementaires-concurrents.md
/// section 3 — masquage des comptes inactifs). Observé (watch) depuis
/// l'accueil pour s'exécuter dès qu'un membre atteint l'app.
final activityHeartbeatProvider = FutureProvider<void>((ref) async {
  await ref.read(cloudFunctionsProvider).httpsCallable('recordActivity').call();
});

final authControllerProvider = AsyncNotifierProvider<AuthController, void>(
  AuthController.new,
);
