import 'package:cloud_functions/cloud_functions.dart';

import '../domain/mini_profile.dart';

class LikesData {
  const LikesData({
    required this.likesReceivedCount,
    required this.likesReceived,
    required this.myLikes,
    required this.isPremium,
  });

  final int likesReceivedCount;
  final List<MiniProfile> likesReceived;
  final List<MiniProfile> myLikes;
  final bool isPremium;
}

/// Jamais de lecture directe des swipes côté client (firestore.rules) —
/// tout passe par getLikes/retractLike (docs/regles-du-projet.md section 2).
class LikesRepository {
  LikesRepository(this._functions);

  final FirebaseFunctions _functions;

  Future<LikesData> getLikes() async {
    final result = await _functions.httpsCallable('getLikes').call();
    final data = result.data as Map<Object?, Object?>;
    List<MiniProfile> parseList(Object? raw) => (raw as List)
        .map((m) => MiniProfile.fromMap(Map<String, dynamic>.from(m as Map)))
        .toList();
    return LikesData(
      likesReceivedCount: (data['likesReceivedCount'] as num).toInt(),
      likesReceived: parseList(data['likesReceived']),
      myLikes: parseList(data['myLikes']),
      isPremium: data['isPremium'] as bool,
    );
  }

  Future<void> retractLike(String targetUid) {
    return _functions.httpsCallable('retractLike').call({'targetUid': targetUid});
  }
}
