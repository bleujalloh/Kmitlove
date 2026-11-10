import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../core/providers/firebase_providers.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/admin_repository.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository(ref.watch(cloudFunctionsProvider), ref.watch(firebaseAuthProvider));
});

/// Permet de n'afficher l'entrée "Administration" que si le compte a
/// réellement le rôle — purement pour l'ergonomie, la sécurité réelle
/// est côté serveur (requireAdmin dans chaque Cloud Function).
final isAdminProvider = FutureProvider<bool>((ref) {
  ref.watch(authStateProvider);
  return ref.read(adminRepositoryProvider).isCurrentUserAdmin();
});

final moderationRequestsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  return ref.read(adminRepositoryProvider).listModerationRequests();
});

final pendingCommunityPostsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  return ref.read(adminRepositoryProvider).listPendingCommunityPosts();
});

final pendingPhotosProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  return ref.read(adminRepositoryProvider).listPendingPhotos();
});

final pendingIdentityVerificationsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  return ref.read(adminRepositoryProvider).listIdentityVerifications();
});

final adminUserSearchProvider = StateProvider.autoDispose<String>((ref) => '');

final adminUsersProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final query = ref.watch(adminUserSearchProvider);
  return ref.read(adminRepositoryProvider).listUsers(query: query.isEmpty ? null : query);
});

final adminActionLogsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  return ref.read(adminRepositoryProvider).listActionLogs();
});
