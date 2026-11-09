import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_controller.dart';
import '../data/likes_repository.dart';

final likesRepositoryProvider = Provider<LikesRepository>((ref) {
  return LikesRepository(ref.watch(cloudFunctionsProvider));
});

final likesProvider = FutureProvider.autoDispose<LikesData>((ref) {
  return ref.read(likesRepositoryProvider).getLikes();
});

class LikesController {
  LikesController(this.ref);
  final Ref ref;

  Future<void> retract(String targetUid) async {
    await ref.read(likesRepositoryProvider).retractLike(targetUid);
    ref.invalidate(likesProvider);
  }
}

final likesControllerProvider = Provider((ref) => LikesController(ref));
