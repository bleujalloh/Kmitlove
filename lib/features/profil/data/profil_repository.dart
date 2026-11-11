import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../domain/profil.dart';

/// Lit le profil directement dans `users` (lecture ouverte à tous les
/// membres connectés, voir firestore.rules), mais l'écrit uniquement via
/// la Cloud Function `saveProfil` : les choix fermés (genre, intention
/// relationnelle, habitudes de vie, qualités) et l'âge minimum doivent
/// être vérifiés côté serveur, pas seulement par les écrans Flutter —
/// firestore.rules refuse désormais toute écriture directe du client sur
/// cette collection. Aucune donnée sensible (filtrage, Premium...) ne
/// passe jamais par ici — voir user_status, géré uniquement par les
/// Cloud Functions.
class ProfilRepository {
  ProfilRepository(this._firestore, this._functions);

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  Stream<Profil?> watchProfil(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map(
          (snap) => snap.data() == null ? null : Profil.fromMap(snap.data()!),
        );
  }

  Future<void> saveProfil(String uid, Profil profil) {
    return _functions.httpsCallable('saveProfil').call(profil.toMap());
  }
}
