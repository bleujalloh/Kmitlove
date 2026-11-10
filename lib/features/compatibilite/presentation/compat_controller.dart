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

/// Score de compatibilité avec un autre membre (carte Découvrir) — `null`
/// tant que l'un des deux n'a pas assez répondu au test pour un thème
/// commun, ou que la cible a désactivé sa visibilité (jamais affiché
/// comme un faux 0 % dans ce cas, voir compat_screen.dart et
/// computeCompatibility.ts).
///
/// `autoDispose` : sans lui, une session de swipe prolongée garderait en
/// mémoire un Future par profil jamais revu entre-temps, pour toute la
/// durée de l'app. Limite assumée et non corrigée ici : chaque carte
/// affichée déclenche quand même un appel serveur complet (4 lectures
/// Firestore dont un balayage de toute la banque de questions), même pour
/// un profil passé en moins d'une seconde — un vrai correctif demanderait
/// de mettre en cache la banque côté serveur ou de décaler l'appel,
/// disproportionné pour un simple badge d'affichage au stade actuel.
final compatScoreWithProvider = FutureProvider.autoDispose.family<int?, String>((ref, targetUid) {
  return ref.read(compatRepositoryProvider).computeCompatibilityWith(targetUid);
});

final compatAnswersVisibleProvider = StreamProvider<bool>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return const Stream.empty();
  return ref.watch(compatRepositoryProvider).watchAnswersVisible(user.uid);
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

  Future<void> setAnswersVisible(bool visible) async {
    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user == null) return;
    await ref.read(compatRepositoryProvider).setAnswersVisible(user.uid, visible);
  }
}

final compatControllerProvider = AsyncNotifierProvider<CompatController, void>(
  CompatController.new,
);
