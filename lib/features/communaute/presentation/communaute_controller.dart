import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/firebase_providers.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../profil/presentation/photo_controller.dart';
import '../data/communaute_repository.dart';
import '../domain/community_post.dart';

final communauteRepositoryProvider = Provider<CommunauteRepository>((ref) {
  return CommunauteRepository(
    ref.watch(firestoreProvider),
    ref.watch(cloudFunctionsProvider),
    ref.watch(firebaseStorageProvider),
  );
});

final communityFeedProvider = StreamProvider<List<CommunityPost>>((ref) {
  return ref.watch(communauteRepositoryProvider).watchFeed();
});

final allPublishedEventsProvider = StreamProvider<List<CommunityPost>>((ref) {
  return ref.watch(communauteRepositoryProvider).watchAllPublishedEvents();
});

final participationsProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>((ref, postId) {
  return ref.watch(communauteRepositoryProvider).watchParticipations(postId);
});

final myParticipationProvider =
    StreamProvider.family<Map<String, dynamic>?, String>((ref, postId) {
  final uid = ref.watch(firebaseAuthProvider).currentUser?.uid;
  if (uid == null) return const Stream.empty();
  return ref.watch(communauteRepositoryProvider).watchMyParticipation(postId, uid);
});

/// "Mes participations" (spec Communauté section 10).
final myParticipationsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final uid = ref.watch(firebaseAuthProvider).currentUser?.uid;
  if (uid == null) return const Stream.empty();
  return ref.watch(communauteRepositoryProvider).watchMyParticipations(uid);
});

/// Statut organisateur du membre courant (spec section 3) — none/pending/
/// approved/rejected/suspended, lu depuis user_status (jamais modifiable
/// depuis le client, voir firestore.rules).
final myOrganizerStatusProvider = StreamProvider<String?>((ref) {
  final status = ref.watch(userStatusProvider);
  return status.when(
    data: (s) => Stream.value(s?['organizerStatus'] as String?),
    loading: () => const Stream.empty(),
    error: (e, st) => Stream.error(e, st),
  );
});

/// Mes événements en tant qu'organisateur (espace organisateur, section 8).
final myOrganizedEventsProvider = StreamProvider<List<CommunityPost>>((ref) {
  final uid = ref.watch(firebaseAuthProvider).currentUser?.uid;
  if (uid == null) return const Stream.empty();
  return ref.watch(communauteRepositoryProvider).watchMyEvents(uid);
});

final favoriteIdsProvider = StreamProvider<Set<String>>((ref) {
  final uid = ref.watch(firebaseAuthProvider).currentUser?.uid;
  if (uid == null) return const Stream.empty();
  return ref.watch(communauteRepositoryProvider).watchFavoriteIds(uid);
});

final linkedEventsProvider = StreamProvider.family<List<CommunityPost>, String>((ref, parentEventId) {
  return ref.watch(communauteRepositoryProvider).watchLinkedEvents(parentEventId);
});

final eventReviewsProvider = StreamProvider.family<List<Map<String, dynamic>>, String>((ref, postId) {
  return ref.watch(communauteRepositoryProvider).watchReviews(postId);
});

/// Affiche d'un événement (URL de téléchargement depuis son chemin
/// Storage) — même raisonnement de mise en cache par chemin que les
/// autres photos de l'app (profil/presentation/photo_controller.dart).
final eventPosterUrlProvider = FutureProvider.family<String, String>((ref, storagePath) {
  return ref.watch(communauteRepositoryProvider).getPosterDownloadUrl(storagePath);
});

class CommunauteController {
  CommunauteController(this.ref);
  final Ref ref;

  Future<String> createPost({
    required String type,
    required String text,
    String? title,
    DateTime? eventDate,
    DateTime? eventEndDate,
    int? capacity,
    String? preciseLocation,
    String? category,
    String? format,
    String? city,
    String? country,
    int? ageMinimum,
    String? conditions,
    String? contactChannel,
    String? posterStoragePath,
    String? accessMode,
    String? parentEventId,
  }) {
    return ref.read(communauteRepositoryProvider).createPost(
          type: type,
          text: text,
          title: title,
          eventDate: eventDate,
          eventEndDate: eventEndDate,
          capacity: capacity,
          preciseLocation: preciseLocation,
          category: category,
          format: format,
          city: city,
          country: country,
          ageMinimum: ageMinimum,
          conditions: conditions,
          contactChannel: contactChannel,
          posterStoragePath: posterStoragePath,
          accessMode: accessMode,
          parentEventId: parentEventId,
        );
  }

  Future<String> uploadEventPoster(File file) async {
    final uid = ref.read(firebaseAuthProvider).currentUser!.uid;
    return ref.read(communauteRepositoryProvider).uploadEventPoster(uid, file);
  }

  Future<void> deleteEventPoster(String storagePath) {
    return ref.read(communauteRepositoryProvider).deleteEventPoster(storagePath);
  }

  Future<void> requestParticipation(String postId) {
    return ref.read(communauteRepositoryProvider).requestParticipation(postId);
  }

  Future<void> respond(String postId, String targetUid, bool accept) {
    return ref.read(communauteRepositoryProvider).respondToParticipation(postId, targetUid, accept);
  }

  Future<void> checkIn(String postId, String targetUid, String code) {
    return ref.read(communauteRepositoryProvider).checkIn(postId, targetUid, code);
  }

  Future<String?> getPreciseLocation(String postId) {
    return ref.read(communauteRepositoryProvider).getPreciseLocation(postId);
  }

  Future<void> report(String postId, String reason) {
    return ref.read(communauteRepositoryProvider).report(postId, reason);
  }

  Future<void> requestOrganizerStatus(String name, String description) {
    return ref.read(communauteRepositoryProvider).requestOrganizerStatus(name, description);
  }

  Future<void> inviteToEvent(String postId, String targetUid) {
    return ref.read(communauteRepositoryProvider).inviteToEvent(postId, targetUid);
  }

  Future<void> updateEventState(String postId, String eventState) {
    return ref.read(communauteRepositoryProvider).updateEventState(postId, eventState);
  }

  Future<void> toggleFavorite(String postId, bool favorite) {
    final uid = ref.read(firebaseAuthProvider).currentUser!.uid;
    return ref.read(communauteRepositoryProvider).setFavorite(uid, postId, favorite);
  }

  Future<void> submitReview(String postId, int rating, {String? comment}) {
    return ref.read(communauteRepositoryProvider).submitReview(postId, rating, comment: comment);
  }
}

final communauteControllerProvider = Provider((ref) => CommunauteController(ref));
