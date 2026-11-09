import 'package:cloud_functions/cloud_functions.dart';

import '../domain/candidate.dart';

/// Tout passe par des Cloud Functions : génération des candidats et
/// enregistrement d'un swipe sont une logique métier sensible (limite de
/// likes, détection de match, exclusion des profils déjà vus) — jamais
/// côté client (docs/architecture-technique.md section 4).
class DecouvrirRepository {
  DecouvrirRepository(this._functions);

  final FirebaseFunctions _functions;

  Future<List<Candidate>> getCandidates() async {
    final result = await _functions.httpsCallable('getDiscoverCandidates').call();
    final data = result.data as Map<Object?, Object?>;
    final list = data['candidates'] as List;
    return list
        .map((c) => Candidate.fromMap(Map<String, dynamic>.from(c as Map)))
        .toList();
  }

  Future<bool> swipe(String targetUid, String action) async {
    final result = await _functions
        .httpsCallable('recordSwipe')
        .call({'targetUid': targetUid, 'action': action});
    final data = result.data as Map<Object?, Object?>;
    return data['matchCreated'] as bool;
  }
}
