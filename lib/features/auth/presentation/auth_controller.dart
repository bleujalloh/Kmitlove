import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../core/device_id.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../../l10n/app_localizations.dart';
import '../../communaute/presentation/communaute_controller.dart';
import '../../decouvrir/presentation/decouvrir_controller.dart';
import '../../notifications/push_controller.dart';
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
  if (code.contains('user-not-found') ||
      code.contains('wrong-password') ||
      code.contains('invalid-credential')) {
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
  if (code.contains('no-account-for-social-sign-in')) {
    return l10n.authErrorNoAccountForSocialSignIn;
  }
  // Code technique ajouté entre parenthèses seulement ici (cas non reconnu)
  // pour qu'une simple capture d'écran suffise à diagnostiquer la suite,
  // sans avoir besoin d'un terminal/adb logcat.
  final shortCode = RegExp(r'firebase_auth/[a-z0-9-]+').stringMatch(code);
  return shortCode != null
      ? l10n.genericErrorWithCode(shortCode)
      : l10n.genericError;
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
      final credential = await ref
          .read(authRepositoryProvider)
          .signUpWithEmail(email: email, password: password);
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
      await ref
          .read(authRepositoryProvider)
          .signInWithEmail(email: email, password: password);
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  /// [allowAccountCreation] doit rester `false` sur l'écran "Se connecter"
  /// (signalé par le propriétaire le 11/11/2026 : "on peut s'inscrire en
  /// cliquant sur se connecter") — Firebase ne distingue pas nativement
  /// connexion et inscription pour un fournisseur fédéré (Google/Apple),
  /// `signInWithCredential` crée silencieusement un nouveau compte si
  /// celui-ci n'existait pas encore. Le compte tout juste créé est donc
  /// supprimé immédiatement si l'appelant ne voulait qu'une connexion.
  Future<bool> signInWithGoogle({bool allowAccountCreation = true}) async {
    state = const AsyncLoading();
    try {
      final credential = await ref
          .read(authRepositoryProvider)
          .signInWithGoogle();
      final isNewUser = credential.additionalUserInfo?.isNewUser == true;
      if (isNewUser && !allowAccountCreation) {
        await ref.read(authRepositoryProvider).deleteJustCreatedAccount();
        state = AsyncError(
          Exception('no-account-for-social-sign-in'),
          StackTrace.current,
        );
        return false;
      }
      if (isNewUser) {
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

  /// Voir [signInWithGoogle] pour la raison d'être de [allowAccountCreation].
  Future<bool> signInWithApple({bool allowAccountCreation = true}) async {
    state = const AsyncLoading();
    try {
      final credential = await ref
          .read(authRepositoryProvider)
          .signInWithApple();
      final isNewUser = credential.additionalUserInfo?.isNewUser == true;
      if (isNewUser && !allowAccountCreation) {
        await ref.read(authRepositoryProvider).deleteJustCreatedAccount();
        state = AsyncError(
          Exception('no-account-for-social-sign-in'),
          StackTrace.current,
        );
        return false;
      }
      if (isNewUser) {
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

  /// Réinitialise tout l'état de session qui vivait dans des
  /// `StateProvider` (ou équivalent) avant de déconnecter réellement le
  /// compte — demande explicite du propriétaire, 12/11/2026 (règlement
  /// permanent section 17, "la plus stricte gagne") : sur un appareil
  /// partagé entre plusieurs comptes l'un après l'autre, aucun de ces
  /// providers n'est réinitialisé par la simple fermeture de l'app (ils
  /// vivent tant que le `ProviderScope` entier vit, pas tant qu'un
  /// widget précis reste monté), donc le compte suivant héritait
  /// silencieusement des filtres/choix du précédent. Centralisé ICI
  /// plutôt que dans l'écran Paramètres : signOut() a quatre points
  /// d'entrée réels (Paramètres, SanctionScreen, FiltrageScreen,
  /// FiltragePendingScreen, trouvé en cherchant tous les appels de
  /// authControllerProvider.notifier.signOut()) et seul celui de
  /// Paramètres désinscrivait jusqu'ici le jeton de notifications push —
  /// un compte suspendu ou encore en vérification qui se déconnectait
  /// depuis l'un des trois autres écrans continuait donc à recevoir des
  /// notifications poussées après sa déconnexion.
  Future<void> signOut() async {
    await unregisterCurrentPushToken(ref);
    ref.invalidate(discoverFiltersProvider);
    ref.invalidate(communauteTabProvider);
    ref.invalidate(eventFiltersProvider);
    ref.invalidate(pendingAdultConfirmationProvider);
    // Sans ce invalidate, le compte SUIVANT sur le même appareil (même
    // session d'app, pas de redémarrage) n'aurait jamais son jeton push
    // enregistré : `pushRegistrationProvider` n'est pas `.autoDispose`,
    // donc un `ref.watch` dans MainShell après la reconnexion ne ferait
    // que relire le Future déjà résolu du compte précédent plutôt que de
    // rejouer `registerFcmToken` — le symétrique, côté enregistrement,
    // du problème de désinscription déjà corrigé juste au-dessus (trouvé
    // par revue de code).
    ref.invalidate(pushRegistrationProvider);
    await ref.read(authRepositoryProvider).signOut();
  }
}

/// "Dernière activité" (docs/regles-complementaires-concurrents.md
/// section 3 — masquage des comptes inactifs) — maintenant répétée
/// toutes les 5 minutes tant que l'app reste ouverte, pas seulement une
/// fois par session : réutilisée depuis le 12/11/2026 pour calculer le
/// badge "En ligne" sur la carte Découvrir (getCandidates.ts), qui a
/// besoin d'un signal réellement frais (fenêtre de 10 minutes,
/// ONLINE_THRESHOLD_MINUTES) — un seul appel au lancement aurait laissé
/// quelqu'un apparaître "en ligne" seulement les 10 premières minutes
/// de sa session, puis "hors ligne" alors qu'il utilise encore l'app
/// (trouvé par revue de code). Le minuteur s'arrête automatiquement si
/// ce provider est disposé (plus d'observateur, ex. déconnexion).
final activityHeartbeatProvider = Provider.autoDispose<void>((ref) {
  // `.autoDispose` : un Provider classique ne serait jamais réellement
  // disposé tant que le ProviderScope entier vit, donc le minuteur aurait
  // continué à tourner même après une déconnexion (main_shell.dart est
  // démonté, mais ce n'est pas lui qui "possède" ce provider) — appelant
  // recordActivity sans session, qui échoue en boucle, pour toujours
  // (trouvé par revue de code). Avec `.autoDispose`, dès qu'il n'a plus
  // aucun observateur (MainShell démonté), Riverpod le dispose et annule
  // le minuteur.
  Future<void> ping() async {
    // Best-effort, comme sendPushToUser côté serveur : un échec ponctuel
    // (réseau, déconnexion pile entre deux coups de minuteur) ne doit
    // jamais remonter comme une exception non interceptée.
    try {
      await ref
          .read(cloudFunctionsProvider)
          .httpsCallable('recordActivity')
          .call();
    } catch (_) {}
  }

  ping();
  final timer = Timer.periodic(const Duration(minutes: 5), (_) => ping());
  ref.onDispose(timer.cancel);
});

final authControllerProvider = AsyncNotifierProvider<AuthController, void>(
  AuthController.new,
);
