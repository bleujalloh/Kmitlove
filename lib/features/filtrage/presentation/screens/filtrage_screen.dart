import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../filtrage_controller.dart';
import 'filtrage_intro_screen.dart';
import 'filtrage_result_screen.dart';

/// Code technique court ajouté au message d'erreur générique (jamais le
/// message brut) — même raisonnement que readableAuthError, pour qu'une
/// simple capture d'écran suffise à diagnostiquer sans terminal.
String _shortDiagnosticCode(Object e) {
  if (e is FirebaseFunctionsException) return e.code;
  final text = e.toString();
  return text.length > 60 ? text.substring(0, 60) : text;
}

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
                Text(
                  context.l10n.filtrageStartFailedWithCode(_shortDiagnosticCode(e)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => ref.read(filtrageControllerProvider.notifier).startAttempt(),
                  child: Text(context.l10n.retryButton),
                ),
                const SizedBox(height: 12),
                // Sans ça, un échec persistant (ex. banque de questions
                // vide côté serveur) enfermait le membre sur cet écran
                // sans aucune issue — ni retour, ni déconnexion possible
                // (bug remonté sur appareil réel le 11/11).
                TextButton(
                  onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
                  child: Text(context.l10n.signOut),
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
                      Text(
                        context.l10n.filtrageHeaderTitle,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.muted,
                          letterSpacing: 0.4,
                        ),
                      ),
                      Text(
                        context.l10n.questionCounter(attempt.currentIndex + 1, attempt.questions.length),
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
                  ...List.generate(
                    question.options.length,
                    (i) => _AnswerOption(
                      label: question.options[i],
                      isSelected: selected == i,
                      onTap: () => controller.selectAnswer(i),
                    ),
                  ),
                  _AnswerOption(
                    label: context.l10n.dontKnowOption,
                    isSelected: selected == FiltrageController.unknownAnswer,
                    onTap: () => controller.selectAnswer(FiltrageController.unknownAnswer),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundSoft,
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      context.l10n.filtrageDisclaimer,
                      style: const TextStyle(fontSize: 12, height: 1.5, color: AppColors.muted),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 16, 28, 28),
              child: Row(
                children: [
                  OutlinedButton(
                    onPressed: controller.skipQuestion,
                    child: Text(context.l10n.skipQuestion),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
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
                      child: Text(attempt.isLastQuestion ? context.l10n.finishButton : context.l10n.nextQuestion),
                    ),
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

/// Une réponse proposée (même rendu pour les vraies options et pour
/// « Je ne sais pas »).
class _AnswerOption extends StatelessWidget {
  const _AnswerOption({required this.label, required this.isSelected, required this.onTap});

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.accentSoft : AppColors.background,
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
                  label,
                  style: TextStyle(
                    fontSize: 14.5,
                    color: AppColors.ink,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                  ),
                ),
              ),
              if (isSelected) const Icon(Icons.check, size: 18, color: AppColors.accent),
            ],
          ),
        ),
      ),
    );
  }
}
