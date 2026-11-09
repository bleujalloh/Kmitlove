import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../domain/community_post.dart';

/// Le fil se lit directement en Firestore (filtré par les règles de
/// sécurité : publié, ou propre publication en attente). Toute création
/// ou action de modération passe par des Cloud Functions, jamais une
/// écriture directe (firestore.rules, docs/regles-annonces-evenements.md).
class CommunauteRepository {
  CommunauteRepository(this._firestore, this._functions);

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  Stream<List<CommunityPost>> watchFeed() {
    return _firestore
        .collection('community_posts')
        .where('status', isEqualTo: 'published')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs.map(CommunityPost.fromDoc).toList());
  }

  Future<String> createPost({
    required String type,
    required String text,
    String? title,
    DateTime? eventDate,
    int? capacity,
    String? preciseLocation,
  }) async {
    final result = await _functions.httpsCallable('createCommunityPost').call({
      'type': type,
      'text': text,
      'title': title,
      'eventDate': eventDate?.toIso8601String(),
      'capacity': capacity,
      'preciseLocation': preciseLocation,
    });
    final data = result.data as Map<Object?, Object?>;
    return data['status'] as String;
  }

  Future<void> requestParticipation(String postId) {
    return _functions.httpsCallable('requestParticipation').call({'postId': postId});
  }

  Future<void> respondToParticipation(String postId, String targetUid, bool accept) {
    return _functions.httpsCallable('respondToParticipation').call({
      'postId': postId,
      'targetUid': targetUid,
      'accept': accept,
    });
  }

  Future<void> checkIn(String postId, String targetUid, String code) {
    return _functions.httpsCallable('checkInParticipant').call({
      'postId': postId,
      'targetUid': targetUid,
      'code': code,
    });
  }

  Future<String?> getPreciseLocation(String postId) async {
    final result = await _functions.httpsCallable('getEventLocation').call({'postId': postId});
    final data = result.data as Map<Object?, Object?>;
    return data['preciseLocation'] as String?;
  }

  Future<void> report(String postId, String reason, {String? details}) {
    return _functions
        .httpsCallable('reportCommunityPost')
        .call({'postId': postId, 'reason': reason, 'details': details});
  }

  Stream<List<Map<String, dynamic>>> watchParticipations(String postId) {
    return _firestore
        .collection('community_posts')
        .doc(postId)
        .collection('participations')
        .snapshots()
        .map((snap) => snap.docs.map((d) => {'uid': d.id, ...d.data()}).toList());
  }

  Stream<Map<String, dynamic>?> watchMyParticipation(String postId, String uid) {
    return _firestore
        .collection('community_posts')
        .doc(postId)
        .collection('participations')
        .doc(uid)
        .snapshots()
        .map((s) => s.data());
  }
}
