import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

import '../domain/message.dart';

/// Lecture et blocage passent en accès direct Firestore (les règles de
/// sécurité garantissent l'appartenance au match et l'absence de blocage,
/// docs/regles-messagerie-securite.md). L'ENVOI des messages et le
/// signalement passent par des Cloud Functions : limite de fréquence côté
/// serveur pour l'un, anonymat de la personne signalée pour l'autre.
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

  /// Dernier message d'une conversation seulement (pas tout l'historique) —
  /// sert à la liste Messages pour savoir s'il reste du non lu.
  Stream<ChatMessage?> watchLastMessage(String matchId) {
    return _firestore
        .collection('matches')
        .doc(matchId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .map((snap) => snap.docs.isEmpty ? null : ChatMessage.fromDoc(snap.docs.first));
  }

  Future<void> sendMessage(String matchId, String text) {
    return _functions.httpsCallable('sendMessage').call({'matchId': matchId, 'text': text});
  }

  /// Photo envoyée en conversation : floutée par défaut côté affichage
  /// tant qu'elle n'a pas été révélée (chat_screen.dart) —
  /// docs/regles-messagerie-securite.md section 2. Le fichier est déposé
  /// dans Storage, puis `sendMessage` crée le message qui le référence.
  Future<void> sendImageMessage(String matchId, String uid, File file) async {
    final storagePath = 'chat_photos/$matchId/${const Uuid().v4()}.jpg';
    final ref = _storage.ref(storagePath);
    await ref.putFile(
      file,
      SettableMetadata(contentType: 'image/jpeg', customMetadata: {'uploaderUid': uid}),
    );
    try {
      await _functions.httpsCallable('sendMessage').call({
        'matchId': matchId,
        'imageStoragePath': storagePath,
      });
    } catch (_) {
      // Envoi refusé (limite, blocage, réseau) : la photo n'a jamais été
      // publiée, on la retire pour ne pas la laisser orpheline dans Storage.
      try {
        await ref.delete();
      } catch (_) {}
      rethrow;
    }
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
