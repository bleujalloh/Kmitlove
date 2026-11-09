import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/firebase_providers.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/compat_repository.dart';
import '../domain/compat_question.dart';

final compatRepositoryProvider = Provider<CompatRepository>((ref) {
  return CompatRepository(ref.watch(firestoreProvider), ref.watch(cloudFunctionsProvider));
});

final compatQuestionBankProvider = FutureProvider<List<CompatQuestion>>((ref) {
  return ref.read(compatRepositoryProvider).loadQuestionBank();
});

final myCompatAnswersProvider = StreamProvider<Map<String, int>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return const Stream.empty();
  return ref.watch(compatRepositoryProvider).watchMyAnswers(user.uid);
});

class CompatController extends AsyncNotifier<void> {
  @override
  void build() {}

  Future<bool> saveAnswers(Map<String, int> answers) async {
    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user == null) return false;
    state = const AsyncLoading();
    try {
      await ref.read(compatRepositoryProvider).saveAnswers(user.uid, answers);
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}

final compatControllerProvider = AsyncNotifierProvider<CompatController, void>(
  CompatController.new,
);
