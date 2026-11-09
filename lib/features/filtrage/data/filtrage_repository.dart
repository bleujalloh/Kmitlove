import 'package:cloud_functions/cloud_functions.dart';

import '../domain/filtrage_question.dart';

/// Appelle uniquement les Cloud Functions — jamais de correction ni de
/// seuil côté client (docs/regles-du-projet.md section 1).
class FiltrageRepository {
  FiltrageRepository(this._functions);

  final FirebaseFunctions _functions;

  Future<(String attemptId, List<FiltrageQuestion> questions)> startAttempt() async {
    final result = await _functions.httpsCallable('startFiltrageAttempt').call();
    final data = result.data as Map<Object?, Object?>;
    final attemptId = data['attemptId'] as String;
    final questions = (data['questions'] as List)
        .map((q) => FiltrageQuestion.fromMap(Map<String, dynamic>.from(q as Map)))
        .toList();
    return (attemptId, questions);
  }

  Future<(bool passed, double score)> submitAttempt({
    required String attemptId,
    required Map<String, int> answers,
  }) async {
    final result = await _functions.httpsCallable('submitFiltrageAttempt').call({
      'attemptId': attemptId,
      'answers': answers,
    });
    final data = result.data as Map<Object?, Object?>;
    return (data['passed'] as bool, (data['score'] as num).toDouble());
  }

  Future<void> requestReview() async {
    await _functions.httpsCallable('requestFiltrageReview').call();
  }
}
