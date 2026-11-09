import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/firebase_providers.dart';
import '../data/profil_repository.dart';
import '../domain/profil.dart';

final profilRepositoryProvider = Provider<ProfilRepository>((ref) {
  return ProfilRepository(ref.watch(firestoreProvider));
});

/// Profil du membre connecté (null si pas encore créé). Sert de garde de
/// navigation dans AuthGate, comme userStatusProvider.
final profilProvider = StreamProvider<Profil?>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return const Stream.empty();
  return ref.watch(profilRepositoryProvider).watchProfil(user.uid);
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
