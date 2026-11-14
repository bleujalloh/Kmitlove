import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/action_feedback.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../filtrage_controller.dart';

class FiltrageResultScreen extends ConsumerWidget {
  const FiltrageResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attempt = ref.watch(filtrageControllerProvider).value;
    final result = attempt?.result;
    if (result == null) return const SizedBox.shrink();
    final (passed, score) = result;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  passed ? Icons.celebration_outlined : Icons.info_outline,
                  size: 56,
                  color: AppColors.accent,
                ),
                const SizedBox(height: 18),
                Text(
                  passed ? context.l10n.filtragePassedTitle : context.l10n.filtrageFailedTitle,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.ink),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  passed
                      ? context.l10n.filtragePassedBody
                      : context.l10n.filtrageFailedBody((score * 100).round()),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.muted, height: 1.5),
                ),
                const SizedBox(height: 28),
                if (passed)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => ref.read(filtrageControllerProvider.notifier).reset(),
                      child: Text(context.l10n.continueButton),
                    ),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () async {
                        // La suite (retour à l'écran de départ) n'a lieu que si
                        // la demande est bien partie ; sinon le membre voit
                        // l'échec et peut réessayer.
                        final sent = await runWithFeedback(
                          context,
                          () => ref.read(filtrageRepositoryProvider).requestReview(),
                        );
                        if (sent) ref.read(filtrageControllerProvider.notifier).reset();
                      },
                      child: Text(context.l10n.requestHumanReview),
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
