import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);

final firestoreProvider = Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

/// Flux de l'utilisateur connecté (null si déconnecté). Sert de base aux
/// gardes de navigation (core/router/auth_gate.dart).
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

/// Statut d'activation du compte (filtrage, suspension...), jamais
/// modifiable depuis le client — voir firestore.rules et
/// docs/regles-du-projet.md section 1.
final userStatusProvider = StreamProvider<Map<String, dynamic>?>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return const Stream.empty();
  return ref
      .watch(firestoreProvider)
      .collection('user_status')
      .doc(user.uid)
      .snapshots()
      .map((snap) => snap.data());
});
