import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_controller.dart';
import '../data/filtrage_repository.dart';
import '../domain/filtrage_question.dart';

final filtrageRepositoryProvider = Provider<FiltrageRepository>((ref) {
  return FiltrageRepository(ref.watch(cloudFunctionsProvider));
});

class FiltrageAttemptState {
  const FiltrageAttemptState({
    required this.attemptId,
    required this.questions,
    required this.currentIndex,
    required this.answers,
    this.result,
  });

  final String attemptId;
  final List<FiltrageQuestion> questions;
  final int currentIndex;
  final Map<String, int> answers;
  final (bool passed, double score)? result;

  FiltrageQuestion get currentQuestion => questions[currentIndex];
  bool get isLastQuestion => currentIndex == questions.length - 1;
  double get progress => (currentIndex + 1) / questions.length;

  FiltrageAttemptState copyWith({
    int? currentIndex,
    Map<String, int>? answers,
    (bool, double)? result,
  }) {
    return FiltrageAttemptState(
      attemptId: attemptId,
      questions: questions,
      currentIndex: currentIndex ?? this.currentIndex,
      answers: answers ?? this.answers,
      result: result ?? this.result,
    );
  }
}

class FiltrageController extends AsyncNotifier<FiltrageAttemptState?> {
  @override
  Future<FiltrageAttemptState?> build() async => null;

  Future<void> startAttempt() async {
    state = const AsyncLoading();
    try {
      final (attemptId, questions) = await ref.read(filtrageRepositoryProvider).startAttempt();
      state = AsyncData(
        FiltrageAttemptState(
          attemptId: attemptId,
          questions: questions,
          currentIndex: 0,
          answers: const {},
        ),
      );
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  void selectAnswer(int optionIndex) {
    final current = state.value;
    if (current == null) return;
    final updatedAnswers = Map<String, int>.from(current.answers)
      ..[current.currentQuestion.id] = optionIndex;
    state = AsyncData(current.copyWith(answers: updatedAnswers));
  }

  /// Valeur de `answers` pour « Je ne sais pas » (option du prototype
  /// Questionnaire.dc.html) : jamais envoyée au serveur, une question non
  /// répondue compte comme une mauvaise réponse
  /// (docs/regles-du-projet.md, section 1) — submitAttempt.ts le gère déjà.
  static const unknownAnswer = -1;

  /// « Passer » : on avance sans répondre (une éventuelle réponse déjà
  /// choisie sur cette question est retirée). À la dernière question,
  /// on termine le questionnaire.
  Future<void> skipQuestion() async {
    final current = state.value;
    if (current == null) return;
    final updated = Map<String, int>.from(current.answers)
      ..remove(current.currentQuestion.id);
    state = AsyncData(current.copyWith(answers: updated));
    if (current.isLastQuestion) {
      await submit();
    } else {
      goToNextQuestion();
    }
  }

  void goToNextQuestion() {
    final current = state.value;
    if (current == null || current.isLastQuestion) return;
    state = AsyncData(current.copyWith(currentIndex: current.currentIndex + 1));
  }

  Future<void> submit() async {
    final current = state.value;
    if (current == null) return;
    state = const AsyncLoading();
    try {
      final result = await ref.read(filtrageRepositoryProvider).submitAttempt(
            attemptId: current.attemptId,
            answers: {
              for (final e in current.answers.entries)
                if (e.value != unknownAnswer) e.key: e.value,
            },
          );
      state = AsyncData(current.copyWith(result: result));
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  void reset() {
    state = const AsyncData(null);
  }
}

final filtrageControllerProvider =
    AsyncNotifierProvider<FiltrageController, FiltrageAttemptState?>(
  FiltrageController.new,
);
