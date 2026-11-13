import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../auth_controller.dart';

/// Affiché par AuthGate juste après une inscription via Google/Apple qui
/// vient de créer un compte tout neuf (pendingAdultConfirmationProvider,
/// voir auth_controller.dart) — ces deux méthodes n'ont pas de case à
/// cocher avant l'appel contrairement à l'inscription par e-mail. Un
/// écran dédié plutôt qu'une boîte de dialogue depuis l'écran d'origine :
/// AuthGate navigue déjà vers l'écran suivant dès que Firebase confirme
/// la connexion, avant que l'écran d'origine ait pu afficher quoi que ce
/// soit (bug remonté sur appareil réel le 11/11).
class AdultConfirmationScreen extends ConsumerStatefulWidget {
  const AdultConfirmationScreen({super.key});

  @override
  ConsumerState<AdultConfirmationScreen> createState() => _AdultConfirmationScreenState();
}

class _AdultConfirmationScreenState extends ConsumerState<AdultConfirmationScreen> {
  bool _declining = false;

  Future<void> _decline() async {
    setState(() => _declining = true);
    try {
      await ref.read(authRepositoryProvider).deleteAccount();
    } finally {
      // deleteAccount() se déconnecte dans tous les cas (voir
      // auth_repository.dart) — authStateProvider redeviendra null et
      // AuthGate repartira seul sur l'onboarding ; on efface quand même
      // le drapeau pour qu'une prochaine inscription ne reste pas bloquée
      // dessus par erreur.
      ref.read(pendingAdultConfirmationProvider.notifier).state = false;
    }
  }

  void _accept() {
    ref.read(pendingAdultConfirmationProvider.notifier).state = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.how_to_reg_outlined, size: 56, color: AppColors.accent),
                const SizedBox(height: 18),
                Text(
                  context.l10n.confirmAdultDialogTitle,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.ink),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  context.l10n.confirmAdultDialogBody,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.muted, height: 1.5),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _declining ? null : _accept,
                    child: Text(context.l10n.confirmAdultDialogAccept),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _declining ? null : _decline,
                    child: _declining
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(context.l10n.confirmAdultDialogDecline),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
