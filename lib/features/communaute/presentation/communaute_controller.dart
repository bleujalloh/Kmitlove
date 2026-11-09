import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/firebase_providers.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/communaute_repository.dart';
import '../domain/community_post.dart';

final communauteRepositoryProvider = Provider<CommunauteRepository>((ref) {
  return CommunauteRepository(ref.watch(firestoreProvider), ref.watch(cloudFunctionsProvider));
});

final communityFeedProvider = StreamProvider<List<CommunityPost>>((ref) {
  return ref.watch(communauteRepositoryProvider).watchFeed();
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

class CommunauteController {
  CommunauteController(this.ref);
  final Ref ref;

  Future<String> createPost({
    required String type,
    required String text,
    String? title,
    DateTime? eventDate,
    int? capacity,
    String? preciseLocation,
  }) {
    return ref.read(communauteRepositoryProvider).createPost(
          type: type,
          text: text,
          title: title,
          eventDate: eventDate,
          capacity: capacity,
          preciseLocation: preciseLocation,
        );
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
}

final communauteControllerProvider = Provider((ref) => CommunauteController(ref));
