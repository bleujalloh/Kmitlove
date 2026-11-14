import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../features/auth/presentation/screens/reset_password_screen.dart';
import '../../features/auth/presentation/screens/sensitive_consent_screen.dart';
import '../../features/auth/presentation/screens/sign_in_screen.dart';
import '../../features/auth/presentation/screens/sign_up_screen.dart';
import '../../features/auth/presentation/screens/verify_email_screen.dart';
import '../../features/filtrage/presentation/filtrage_controller.dart';
import '../../features/filtrage/presentation/screens/filtrage_pending_screen.dart';
import '../../features/filtrage/presentation/screens/filtrage_result_screen.dart';
import '../../features/filtrage/presentation/screens/filtrage_screen.dart';
import '../../features/filtrage/presentation/screens/sanction_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/parametres/settings_controller.dart';
import '../../features/profil/presentation/profil_controller.dart';
import '../../features/profil/presentation/screens/profil_wizard_screen.dart';
import '../../l10n/l10n_extensions.dart';
import '../providers/firebase_providers.dart';
import 'main_shell.dart';

enum _LoggedOutView { onboarding, signUp, signIn, resetPassword }

final _loggedOutViewProvider = StateProvider<_LoggedOutView>((ref) => _LoggedOutView.onboarding);

/// Point d'entrée de toute la navigation : décide quel écran afficher
/// selon l'état de connexion, sans dépendre d'URL/deep-link pour l'instant
/// (go_router sera branché pour la navigation interne à l'app une fois
/// connecté — Découvrir/Likes/Messages/Communauté).
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, st) => Scaffold(body: Center(child: Text(context.l10n.unexpectedError(e.toString())))),
      data: (user) {
        if (user == null) {
          final view = ref.watch(_loggedOutViewProvider);
          switch (view) {
            case _LoggedOutView.onboarding:
              return OnboardingScreen(
                onAccepted: () =>
                    ref.read(_loggedOutViewProvider.notifier).state = _LoggedOutView.signUp,
              );
            case _LoggedOutView.signUp:
              return SignUpScreen(
                onGoToSignIn: () =>
                    ref.read(_loggedOutViewProvider.notifier).state = _LoggedOutView.signIn,
              );
            case _LoggedOutView.signIn:
              return SignInScreen(
                onGoToSignUp: () =>
                    ref.read(_loggedOutViewProvider.notifier).state = _LoggedOutView.signUp,
                onGoToResetPassword: () => ref.read(_loggedOutViewProvider.notifier).state =
                    _LoggedOutView.resetPassword,
              );
            case _LoggedOutView.resetPassword:
              return const ResetPasswordScreen();
          }
        }

        if (!user.emailVerified) {
          return VerifyEmailScreen(
            onVerified: () => ref.invalidate(authStateProvider),
          );
        }

        final statusAsync = ref.watch(userStatusProvider);
        return statusAsync.when(
          loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (e, st) => Scaffold(body: Center(child: Text(context.l10n.unexpectedError(e.toString())))),
          data: (status) {
            // Consentement explicite aux données sensibles (RGPD art. 9) : TOUT
            // en premier, avant même le questionnaire de filtrage (qui révèle
            // l'appartenance à la communauté), pour un compte neuf comme pour
            // un compte existant ou après un retrait (Paramètres). Le serveur
            // l'exige de toute façon pour chaque fonction de membre
            // (functions/src/shared/callable.ts).
            if (!hasSensitiveConsent(status)) return const SensitiveConsentScreen();
            final filtrageStatus = status?['filtrageStatus'] as String?;
            if (filtrageStatus == 'active') {
              // Le serveur a déjà activé le compte au moment où il répond
              // à submitFiltrageAttempt, mais le résultat local (écran de
              // bienvenue) peut ne pas encore avoir été affiché — on laisse
              // la priorité à l'écran de résultat pendant qu'il existe.
              final pendingResult = ref.watch(filtrageControllerProvider).value?.result;
              if (pendingResult != null && pendingResult.$1) {
                return const FiltrageResultScreen();
              }

              final profilAsync = ref.watch(profilProvider);
              return profilAsync.when(
                loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
                error: (e, st) =>
                    Scaffold(body: Center(child: Text(context.l10n.unexpectedError(e.toString())))),
                data: (profil) {
                  if (profil == null) return const ProfilWizardScreen();
                  return const MainShell();
                },
              );
            }
            if (filtrageStatus == 'rejected_pending_retry' || filtrageStatus == 'review_requested') {
              return FiltragePendingScreen(status: status!);
            }
            if (filtrageStatus == 'suspended') {
              // Compte sanctionné (docs/regles-messagerie-securite.md
              // section 3) — jamais d'accès à Découvrir/messagerie/
              // communauté tant que ce n'est pas levé ou contesté avec
              // succès (resolveSanctionAppeal).
              return SanctionScreen(status: status!);
            }
            // Pas encore de statut, ou tentative en cours : le questionnaire
            // gère lui-même son propre état interne (intro → questions →
            // résultat), voir filtrage_controller.dart.
            return const FiltrageScreen();
          },
        );
      },
    );
  }
}
