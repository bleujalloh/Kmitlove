import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../domain/compat_question.dart';

/// La banque de questions et les réponses de l'utilisateur sont lues/
/// écrites directement en base (pas de "bonne réponse" à cacher ici,
/// contrairement au filtrage) — mais le score de compatibilité entre
/// deux membres est toujours calculé côté serveur, jamais côté client
/// (docs/regles-economie-et-compatibilite.md section 2).
class CompatRepository {
  CompatRepository(this._firestore, this._functions);

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  Future<List<CompatQuestion>> loadQuestionBank() async {
    final snap = await _firestore
        .collection('compat_question_bank')
        .where('active', isEqualTo: true)
        .get();
    return snap.docs
        .map((doc) => CompatQuestion.fromFirestore(doc.id, doc.data()))
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

  Future<int?> computeCompatibilityWith(String targetUid) async {
    final result =
        await _functions.httpsCallable('computeCompatibility').call({'targetUid': targetUid});
    final data = result.data as Map<Object?, Object?>;
    return data['score'] as int?;
  }
}
