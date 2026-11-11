import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/firebase_providers.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/profil_repository.dart';
import '../domain/profil.dart';
import 'photo_controller.dart';

final profilRepositoryProvider = Provider<ProfilRepository>((ref) {
  return ProfilRepository(ref.watch(firestoreProvider), ref.watch(cloudFunctionsProvider));
});

/// Profil du membre connecté (null si pas encore créé). Sert de garde de
/// navigation dans AuthGate, comme userStatusProvider.
final profilProvider = StreamProvider<Profil?>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return const Stream.empty();
  return ref.watch(profilRepositoryProvider).watchProfil(user.uid);
});

/// Pourcentage de complétion du profil — calculé côté serveur
/// (getProfileCompletion, functions/src/shared/profileCompletion.ts) pour
/// rester exactement la même règle que celle qui influence le classement
/// dans Découvrir (getDiscoverCandidates.ts) : jamais un second calcul
/// Dart qui pourrait diverger. Redemandé automatiquement dès que le
/// profil, les photos ou le statut (vérification) changent.
final profileCompletionPercentProvider = FutureProvider.autoDispose<int>((ref) async {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return 0;
  ref.watch(profilProvider);
  ref.watch(myPhotosProvider);
  ref.watch(userStatusProvider);
  final result = await ref.read(cloudFunctionsProvider).httpsCallable('getProfileCompletion').call();
  final data = result.data as Map<Object?, Object?>;
  return data['percent'] as int;
});

class ProfilController extends AsyncNotifier<void> {
  @override
  void build() {}

  Future<bool> save(Profil profil) async {
    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user == null) return false;
    state = const AsyncLoading();
    try {
      await ref.read(profilRepositoryProvider).saveProfil(user.uid, profil);
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}

final profilControllerProvider = AsyncNotifierProvider<ProfilController, void>(
  ProfilController.new,
);
