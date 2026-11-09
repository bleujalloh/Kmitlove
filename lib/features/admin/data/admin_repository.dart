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
}
