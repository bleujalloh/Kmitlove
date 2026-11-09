import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../domain/message.dart';

/// La messagerie elle-même (envoi, lecture, blocage) passe en écriture
/// directe Firestore — les règles de sécurité garantissent déjà
/// l'appartenance au match et l'absence de blocage
/// (docs/regles-messagerie-securite.md). Seul le signalement, qui doit
/// rester anonyme pour la personne signalée, passe par une Cloud Function.
class MessagesRepository {
  MessagesRepository(this._firestore, this._functions);

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  Stream<List<MatchSummary>> watchMatches(String uid) {
    return _firestore
        .collection('matches')
        .where('members', arrayContains: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((snap) async {
      // Un seul lot de lectures de profils en parallèle, plutôt qu'une
      // par une : sinon chaque nouveau message dans N'IMPORTE quel match
      // réémet toute la requête et refait N lectures séquentielles.
      final futures = snap.docs.map((doc) async {
        final data = doc.data();
        final members = List<String>.from(data['members'] as List);
        final otherUid = members.firstWhere((m) => m != uid, orElse: () => '');
        if (otherUid.isEmpty) return null;
        final profileDoc = await _firestore.collection('users').doc(otherUid).get();
        final displayName = profileDoc.data()?['displayName'] as String? ?? 'Membre';
        final lastMessageAt = (data['lastMessageAt'] as Timestamp?)?.toDate();
        return MatchSummary(
          matchId: doc.id,
          otherUid: otherUid,
          otherDisplayName: displayName,
          lastMessagePreview: data['lastMessagePreview'] as String?,
          lastMessageAt: lastMessageAt,
        );
      });
      final results = await Future.wait(futures);
      return results.whereType<MatchSummary>().toList();
    });
  }

  Stream<List<ChatMessage>> watchMessages(String matchId) {
    return _firestore
        .collection('matches')
        .doc(matchId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(ChatMessage.fromDoc).toList());
  }

  Future<void> sendMessage(String matchId, String fromUid, String text) {
    return _firestore.collection('matches').doc(matchId).collection('messages').add({
      'fromUid': fromUid,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
      'readBy': [fromUid],
    });
  }

  Future<void> markManyRead(String matchId, List<String> messageIds, String uid) async {
    if (messageIds.isEmpty) return;
    final batch = _firestore.batch();
    final messagesRef = _firestore.collection('matches').doc(matchId).collection('messages');
    for (final id in messageIds) {
      batch.update(messagesRef.doc(id), {'readBy': FieldValue.arrayUnion([uid])});
    }
    await batch.commit();
  }

  Stream<bool> watchIsBlocked(String matchId) {
    return _firestore.collection('blocks').doc(matchId).snapshots().map((s) => s.exists);
  }

  Future<void> block(String matchId, String uid) {
    return _firestore.collection('blocks').doc(matchId).set({
      'blockerUid': uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> unblock(String matchId) {
    return _firestore.collection('blocks').doc(matchId).delete();
  }

  Future<void> setShowReadReceipts(String uid, bool value) {
    return _firestore.collection('users').doc(uid).set(
      {'showReadReceipts': value},
      SetOptions(merge: true),
    );
  }

  Stream<bool> watchShowReadReceipts(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((s) => s.data()?['showReadReceipts'] as bool? ?? true);
  }

  Future<void> reportUser({
    required String targetUid,
    required String reason,
    String? details,
    String? matchId,
  }) {
    return _functions.httpsCallable('reportUser').call({
      'targetUid': targetUid,
      'reason': reason,
      'details': details,
      'matchId': matchId,
    });
  }
}
