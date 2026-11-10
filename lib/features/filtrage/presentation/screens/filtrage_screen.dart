import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../filtrage_controller.dart';
import 'filtrage_intro_screen.dart';
import 'filtrage_result_screen.dart';

/// Écran du questionnaire de filtrage — fidèle au prototype visuel validé
/// (artifact MERUT, Questionnaire.dc.html), étendu à plusieurs questions.
class FiltrageScreen extends ConsumerWidget {
  const FiltrageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(filtrageControllerProvider);

    return state.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, st) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Impossible de démarrer le questionnaire pour le moment.'),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => ref.read(filtrageControllerProvider.notifier).startAttempt(),
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (attempt) {
        if (attempt == null) return const FiltrageIntroScreen();
        if (attempt.result != null) return const FiltrageResultScreen();
        return _QuestionView(attempt: attempt);
      },
    );
  }
}

class _QuestionView extends ConsumerWidget {
  const _QuestionView({required this.attempt});

  final FiltrageAttemptState attempt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final question = attempt.currentQuestion;
    final selected = attempt.answers[question.id];
    final controller = ref.read(filtrageControllerProvider.notifier);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 22, 28, 16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "VÉRIFICATION D'ENGAGEMENT",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.muted,
                          letterSpacing: 0.4,
                        ),
                      ),
                      Text(
                        'Question ${attempt.currentIndex + 1}/${attempt.questions.length}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: attempt.progress,
                      minHeight: 6,
                      backgroundColor: AppColors.border,
                      color: AppColors.accent,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(28, 8, 28, 0),
                children: [
                  Text(
                    question.theme.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accent,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    question.question,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 22),
                  ...List.generate(question.options.length, (i) {
                    final isSelected = selected == i;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: InkWell(
                        onTap: () => controller.selectAnswer(i),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.accentSoft : Colors.white,
                            border: Border.all(
                              color: isSelected ? AppColors.accent : AppColors.border,
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  question.options[i],
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    color: AppColors.ink,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                const Icon(Icons.check, size: 18, color: AppColors.accent),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundSoft,
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      "Ce questionnaire porte uniquement sur la culture, l'histoire et les valeurs — jamais sur ton apparence ou ton origine. Un score minimum est requis pour activer ton compte ; en cas d'échec, tu peux demander une révision par un modérateur.",
                      style: TextStyle(fontSize: 12, height: 1.5, color: AppColors.muted),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 16, 28, 28),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: selected == null
                      ? null
                      : () {
                          if (attempt.isLastQuestion) {
                            controller.submit();
                          } else {
                            controller.goToNextQuestion();
                          }
                        },
                  child: Text(attempt.isLastQuestion ? 'Terminer' : 'Question suivante'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
