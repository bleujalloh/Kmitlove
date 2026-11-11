import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Tout passe par des Cloud Functions qui vérifient elles-mêmes le rôle
/// admin (custom claim) côté serveur — jamais une confiance aveugle au
/// fait que l'écran admin soit affiché ou non côté client.
class AdminRepository {
  AdminRepository(this._functions, this._auth);

  final FirebaseFunctions _functions;
  final FirebaseAuth _auth;

  Future<bool> isCurrentUserAdmin() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    final result = await user.getIdTokenResult(true);
    return result.claims?['admin'] == true;
  }

  /// Ne fonctionne qu'une seule fois pour tout le projet — voir
  /// functions/src/admin/bootstrapFirstAdmin.ts.
  Future<void> bootstrapFirstAdmin() async {
    await _functions.httpsCallable('bootstrapFirstAdmin').call();
    await _auth.currentUser?.getIdTokenResult(true);
  }

  Future<List<Map<String, dynamic>>> listModerationRequests() async {
    final result = await _functions.httpsCallable('adminListModerationRequests').call();
    final data = result.data as Map<Object?, Object?>;
    return (data['requests'] as List)
        .map((r) => Map<String, dynamic>.from(r as Map))
        .toList();
  }

  Future<void> resolveModerationRequest(String requestId, String action) {
    return _functions
        .httpsCallable('adminResolveModerationRequest')
        .call({'requestId': requestId, 'action': action});
  }

  Future<void> resolveFiltrageReview(String requestId, bool approve) {
    return _functions
        .httpsCallable('resolveFiltrageReview')
        .call({'requestId': requestId, 'approve': approve});
  }

  Future<List<Map<String, dynamic>>> listPendingCommunityPosts() async {
    final result = await _functions.httpsCallable('adminListPendingCommunityPosts').call();
    final data = result.data as Map<Object?, Object?>;
    return (data['posts'] as List).map((p) => Map<String, dynamic>.from(p as Map)).toList();
  }

  Future<void> reviewCommunityPost(String postId, bool approve) {
    return _functions
        .httpsCallable('adminReviewCommunityPost')
        .call({'postId': postId, 'approve': approve});
  }

  Future<List<Map<String, dynamic>>> listOrganizerRequests() async {
    final result = await _functions.httpsCallable('adminListOrganizerRequests').call();
    final data = result.data as Map<Object?, Object?>;
    return (data['requests'] as List).map((r) => Map<String, dynamic>.from(r as Map)).toList();
  }

  Future<void> reviewOrganizerRequest(String uid, bool approve) {
    return _functions
        .httpsCallable('adminReviewOrganizerRequest')
        .call({'uid': uid, 'approve': approve});
  }

  Future<void> suspendOrganizer(String uid) {
    return _functions.httpsCallable('adminSuspendOrganizer').call({'uid': uid});
  }

  Future<List<Map<String, dynamic>>> listPendingPhotos() async {
    final result = await _functions.httpsCallable('adminListPendingPhotos').call();
    final data = result.data as Map<Object?, Object?>;
    return (data['photos'] as List).map((p) => Map<String, dynamic>.from(p as Map)).toList();
  }

  Future<void> reviewPhoto(String userId, String photoId, bool approve) {
    return _functions
        .httpsCallable('adminReviewPhoto')
        .call({'userId': userId, 'photoId': photoId, 'approve': approve});
  }

  Future<List<Map<String, dynamic>>> listIdentityVerifications() async {
    final result = await _functions.httpsCallable('adminListIdentityVerifications').call();
    final data = result.data as Map<Object?, Object?>;
    return (data['verifications'] as List)
        .map((v) => Map<String, dynamic>.from(v as Map))
        .toList();
  }

  Future<void> reviewIdentityVerification(String uid, bool approve) {
    return _functions
        .httpsCallable('adminReviewIdentityVerification')
        .call({'uid': uid, 'approve': approve});
  }

  Future<List<Map<String, dynamic>>> listUsers({String? query}) async {
    final result = await _functions.httpsCallable('adminListUsers').call({'query': query});
    final data = result.data as Map<Object?, Object?>;
    return (data['users'] as List).map((u) => Map<String, dynamic>.from(u as Map)).toList();
  }

  Future<void> setSuspension(String uid, bool suspend) {
    return _functions.httpsCallable('adminSetSuspension').call({'uid': uid, 'suspend': suspend});
  }

  Future<void> resolveSanctionAppeal(String requestId, bool approve) {
    return _functions
        .httpsCallable('resolveSanctionAppeal')
        .call({'requestId': requestId, 'approve': approve});
  }

  Future<List<Map<String, dynamic>>> listActionLogs() async {
    final result = await _functions.httpsCallable('adminListActionLogs').call();
    final data = result.data as Map<Object?, Object?>;
    return (data['logs'] as List).map((l) => Map<String, dynamic>.from(l as Map)).toList();
  }
}
