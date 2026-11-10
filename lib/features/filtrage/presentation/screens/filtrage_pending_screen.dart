import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../filtrage_controller.dart';

/// Affiché quand le compte attend un nouvel essai ou une révision humaine
/// (docs/regles-du-projet.md section 1), en dehors du flux immédiat du
/// questionnaire.
class FiltragePendingScreen extends ConsumerWidget {
  const FiltragePendingScreen({super.key, required this.status});

  final Map<String, dynamic> status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewRequested = status['filtrageStatus'] == 'review_requested';
    final nextRetryAt = status['filtrageNextRetryAt'] as Timestamp?;
    final canRetryNow = nextRetryAt == null || nextRetryAt.toDate().isBefore(DateTime.now());

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  reviewRequested ? Icons.hourglass_top_outlined : Icons.schedule_outlined,
                  size: 56,
                  color: AppColors.accent,
                ),
                const SizedBox(height: 18),
                Text(
                  reviewRequested ? context.l10n.reviewInProgressTitle : context.l10n.nextAttemptSoonTitle,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.ink),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  reviewRequested
                      ? context.l10n.reviewInProgressBody
                      : canRetryNow
                          ? context.l10n.canRetryNow
                          : context.l10n.canRetryFrom(_formatDate(nextRetryAt.toDate())),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.muted, height: 1.5),
                ),
                const SizedBox(height: 28),
                if (!reviewRequested && canRetryNow)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => ref.read(filtrageControllerProvider.notifier).startAttempt(),
                      child: Text(context.l10n.retryFiltrageButton),
                    ),
                  ),
                // Sans ça, un compte qui attend encore son délai de
                // nouvel essai n'avait aucune option affichée du tout —
                // ni retenter, ni demander une révision, ni se
                // déconnecter (bug remonté sur appareil réel le 11/11).
                if (!reviewRequested) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => ref.read(filtrageRepositoryProvider).requestReview(),
                      child: Text(context.l10n.requestHumanReview),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
                  child: Text(context.l10n.signOut),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
