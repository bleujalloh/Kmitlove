import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/profil.dart';

/// Lit/écrit le profil dans la collection `users` (voir firestore.rules :
/// lecture par les membres connectés, écriture par le propriétaire
/// uniquement). Aucune donnée sensible (filtrage, Premium...) ne passe
/// jamais par ici — voir user_status, géré uniquement par les Cloud
/// Functions.
class ProfilRepository {
  ProfilRepository(this._firestore);

  final FirebaseFirestore _firestore;

  Stream<Profil?> watchProfil(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map(
          (snap) => snap.data() == null ? null : Profil.fromMap(snap.data()!),
        );
  }

  Future<void> saveProfil(String uid, Profil profil) {
    return _firestore.collection('users').doc(uid).set(profil.toMap());
  }
}
