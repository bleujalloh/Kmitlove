import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/firebase_providers.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/messages_repository.dart';
import '../domain/message.dart';

final messagesRepositoryProvider = Provider<MessagesRepository>((ref) {
  return MessagesRepository(
    ref.watch(firestoreProvider),
    ref.watch(cloudFunctionsProvider),
    FirebaseStorage.instance,
  );
});

/// Mise en cache de l'URL de téléchargement d'une photo de message, par
/// chemin Storage — même raisonnement que pour les photos de profil
/// (profil/presentation/photo_controller.dart).
final messageImageUrlProvider = FutureProvider.family<String, String>((ref, storagePath) {
  return ref.watch(messagesRepositoryProvider).getImageDownloadUrl(storagePath);
});

final matchesProvider = StreamProvider<List<MatchSummary>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return const Stream.empty();
  return ref.watch(messagesRepositoryProvider).watchMatches(user.uid);
});

final chatMessagesProvider =
    StreamProvider.family<List<ChatMessage>, String>((ref, matchId) {
  return ref.watch(messagesRepositoryProvider).watchMessages(matchId);
});

final isBlockedProvider = StreamProvider.family<bool, String>((ref, matchId) {
  return ref.watch(messagesRepositoryProvider).watchIsBlocked(matchId);
});

/// Préférence d'indicateur de lecture d'un membre donné (soi-même ou
/// l'autre personne d'une conversation) — réciprocité : voir
/// docs/regles-messagerie-securite.md section 2.
final showReadReceiptsProvider = StreamProvider.family<bool, String>((ref, uid) {
  return ref.watch(messagesRepositoryProvider).watchShowReadReceipts(uid);
});

class MessagesController {
  MessagesController(this.ref);
  final Ref ref;

  Future<void> send(String matchId, String text) async {
    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user == null || text.trim().isEmpty) return;
    await ref.read(messagesRepositoryProvider).sendMessage(matchId, user.uid, text.trim());
  }

  Future<void> sendImage(String matchId, File file) async {
    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user == null) return;
    await ref.read(messagesRepositoryProvider).sendImageMessage(matchId, user.uid, file);
  }

  Future<void> markManyRead(String matchId, List<String> messageIds) async {
    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user == null) return;
    await ref.read(messagesRepositoryProvider).markManyRead(matchId, messageIds, user.uid);
  }

  Future<void> block(String matchId) async {
    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user == null) return;
    await ref.read(messagesRepositoryProvider).block(matchId, user.uid);
  }

  Future<void> toggleReadReceipts(bool value) async {
    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user == null) return;
    await ref.read(messagesRepositoryProvider).setShowReadReceipts(user.uid, value);
  }

  Future<void> report({
    required String targetUid,
    required String reason,
    String? details,
    String? matchId,
    String? messageId,
  }) {
    return ref.read(messagesRepositoryProvider).reportUser(
          targetUid: targetUid,
          reason: reason,
          details: details,
          matchId: matchId,
          messageId: messageId,
        );
  }
}

final messagesControllerProvider = Provider((ref) => MessagesController(ref));
