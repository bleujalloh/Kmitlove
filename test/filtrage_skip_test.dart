import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:merut/features/filtrage/data/filtrage_repository.dart';
import 'package:merut/features/filtrage/domain/filtrage_question.dart';
import 'package:merut/features/filtrage/presentation/filtrage_controller.dart';

class _FakeRepo implements FiltrageRepository {
  Map<String, int>? submitted;

  @override
  Future<(String, List<FiltrageQuestion>)> startAttempt() async => (
        'a1',
        const [
          FiltrageQuestion(id: 'q1', theme: 'Histoire', question: 'Q1', options: ['a', 'b']),
          FiltrageQuestion(id: 'q2', theme: 'Histoire', question: 'Q2', options: ['a', 'b']),
        ],
      );

  @override
  Future<(bool, double)> submitAttempt({
    required String attemptId,
    required Map<String, int> answers,
  }) async {
    submitted = answers;
    return (false, 0.0);
  }

  @override
  Future<void> requestReview() async {}
}

void main() {
  test('« Je ne sais pas » et « Passer » ne sont jamais envoyés comme réponses', () async {
    final repo = _FakeRepo();
    final container = ProviderContainer(
      overrides: [filtrageRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    final controller = container.read(filtrageControllerProvider.notifier);

    await controller.startAttempt();
    controller.selectAnswer(FiltrageController.unknownAnswer); // q1 : je ne sais pas
    controller.goToNextQuestion();
    controller.selectAnswer(1); // q2 : réponse choisie…
    await controller.skipQuestion(); // …puis passée sur la dernière question → soumission

    expect(repo.submitted, isEmpty);
    expect(container.read(filtrageControllerProvider).value?.result, isNotNull);
  });

  test('une vraie réponse est bien envoyée', () async {
    final repo = _FakeRepo();
    final container = ProviderContainer(
      overrides: [filtrageRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    final controller = container.read(filtrageControllerProvider.notifier);

    await controller.startAttempt();
    controller.selectAnswer(0);
    controller.goToNextQuestion();
    controller.selectAnswer(FiltrageController.unknownAnswer);
    await controller.submit();

    expect(repo.submitted, {'q1': 0});
  });
}
