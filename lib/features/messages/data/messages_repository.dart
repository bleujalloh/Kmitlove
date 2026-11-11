import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

import '../domain/message.dart';

/// La messagerie elle-même (envoi, lecture, blocage) passe en écriture
/// directe Firestore — les règles de sécurité garantissent déjà
/// l'appartenance au match et l'absence de blocage
/// (docs/regles-messagerie-securite.md). Seul le signalement, qui doit
/// rester anonyme pour la personne signalée, passe par une Cloud Function.
class MessagesRepository {
  MessagesRepository(this._firestore, this._functions, this._storage);

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;
  final FirebaseStorage _storage;

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

  /// Photo envoyée en conversation : floutée par défaut côté affichage
  /// tant qu'elle n'a pas été révélée (chat_screen.dart) —
  /// docs/regles-messagerie-securite.md section 2.
  Future<void> sendImageMessage(String matchId, String fromUid, File file) async {
    final storagePath = 'chat_photos/$matchId/${const Uuid().v4()}.jpg';
    await _storage.ref(storagePath).putFile(file);
    await _firestore.collection('matches').doc(matchId).collection('messages').add({
      'fromUid': fromUid,
      'text': '',
      'imageStoragePath': storagePath,
      'createdAt': FieldValue.serverTimestamp(),
      'readBy': [fromUid],
    });
  }

  Future<String> getImageDownloadUrl(String storagePath) {
    return _storage.ref(storagePath).getDownloadURL();
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

  /// Identifiant d'une paire de membres — toujours [uid1, uid2] triés et
  /// joints par "_", que la paire soit déjà matchée ou non (même
  /// convention que l'identifiant de match côté serveur, recordSwipe.ts).
  String _pairId(String uidA, String uidB) => ([uidA, uidB]..sort()).join('_');

  Stream<bool> watchIsBlocked(String myUid, String otherUid) {
    return _firestore
        .collection('blocks')
        .doc(_pairId(myUid, otherUid))
        .snapshots()
        .map((s) => s.exists);
  }

  /// Blocage d'un membre — utilisable avant tout match (depuis Découvrir/
  /// Likes) ou depuis une conversation existante, voir firestore.rules.
  Future<void> block(String myUid, String targetUid) {
    return _firestore.collection('blocks').doc(_pairId(myUid, targetUid)).set({
      'blockerUid': myUid,
      'blockedUid': targetUid,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> unblock(String myUid, String targetUid) {
    return _firestore.collection('blocks').doc(_pairId(myUid, targetUid)).delete();
  }

  /// Liste des membres que JE bloque (pas l'inverse) — pour l'écran "Mes
  /// blocages" (Paramètres).
  Stream<List<BlockedProfile>> watchMyBlocks(String myUid) {
    return _firestore
        .collection('blocks')
        .where('blockerUid', isEqualTo: myUid)
        .snapshots()
        .asyncMap((snap) async {
      final futures = snap.docs.map((doc) async {
        final blockedUid = doc.data()['blockedUid'] as String?;
        if (blockedUid == null) return null;
        final profileDoc = await _firestore.collection('users').doc(blockedUid).get();
        final displayName = profileDoc.data()?['displayName'] as String? ?? 'Membre';
        return BlockedProfile(uid: blockedUid, displayName: displayName);
      });
      final results = await Future.wait(futures);
      return results.whereType<BlockedProfile>().toList();
    });
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
    String? messageId,
  }) {
    return _functions.httpsCallable('reportUser').call({
      'targetUid': targetUid,
      'reason': reason,
      'details': details,
      'matchId': matchId,
      'messageId': messageId,
    });
  }
}
