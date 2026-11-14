import '../domain/compat_result.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../domain/compat_question.dart';

/// Les réponses de l'utilisateur sont lues/écrites directement en base
/// (pas de "bonne réponse" à cacher ici, contrairement au filtrage), mais
/// la banque de questions elle-même passe par getCompatQuestions (tirage
/// aléatoire côté serveur, docs/suivi-developpement.md section du
/// 11/11/2026) — le score de compatibilité entre deux membres reste lui
/// aussi toujours calculé côté serveur (docs/regles-economie-et-
/// compatibilite.md section 2).
class CompatRepository {
  CompatRepository(this._firestore, this._functions);

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  Future<List<CompatQuestion>> loadQuestionBank() async {
    final result = await _functions.httpsCallable('getCompatQuestions').call();
    final data = result.data as Map<Object?, Object?>;
    return (data['questions'] as List)
        .map((q) => CompatQuestion.fromMap(Map<String, dynamic>.from(q as Map)))
        .toList();
  }

  Stream<Map<String, int>> watchMyAnswers(String uid) {
    return _firestore.collection('compat_answers').doc(uid).snapshots().map(
          (snap) => Map<String, int>.from(snap.data()?['answers'] as Map? ?? {}),
        );
  }

  Future<void> saveAnswers(String uid, Map<String, int> answers) {
    return _firestore.collection('compat_answers').doc(uid).set({'answers': answers});
  }

  Future<CompatResult> computeCompatibilityWith(String targetUid) async {
    final result =
        await _functions.httpsCallable('computeCompatibility').call({'targetUid': targetUid});
    return CompatResult.fromMap(result.data as Map<Object?, Object?>);
  }

  /// Contrôle de visibilité (cahier des charges section 4.3) : stocké sur
  /// le profil public comme `showReadReceipts` (même raisonnement, voir
  /// messages_repository.dart) — visible par défaut, un membre peut
  /// choisir de ne plus jamais être comparé à personne (computeCompatibility.ts
  /// renvoie alors toujours `null` pour lui, jamais un faux score).
  Future<void> setAnswersVisible(String uid, bool visible) {
    return _firestore.collection('users').doc(uid).set(
      {'compatAnswersVisible': visible},
      SetOptions(merge: true),
    );
  }

  Stream<bool> watchAnswersVisible(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((s) => s.data()?['compatAnswersVisible'] as bool? ?? true);
  }
}
