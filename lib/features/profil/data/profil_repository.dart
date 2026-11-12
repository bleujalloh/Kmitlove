import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../domain/profil.dart';

/// Lit le profil public directement dans `users` (lecture ouverte à tous
/// les membres connectés, voir firestore.rules), mais l'écrit uniquement
/// via la Cloud Function `saveProfil` : les choix fermés (genre, intention
/// relationnelle, habitudes de vie, qualités) et l'âge minimum doivent
/// être vérifiés côté serveur, pas seulement par les écrans Flutter —
/// firestore.rules refuse désormais toute écriture directe du client sur
/// cette collection.
///
/// `birthDate` (date de naissance EXACTE) ne vit plus sur ce document
/// public depuis le 12/11/2026 (règlement permanent section 17) — stockée
/// uniquement dans `user_status/{uid}`, lisible par son seul propriétaire,
/// donc recomposée ici en combinant les deux lectures pour reconstituer
/// un `Profil` complet (nécessaire pour pré-remplir le sélecteur de date
/// à l'édition). N'importe le propriétaire ne doit jamais relire la date
/// de naissance d'un AUTRE membre de cette façon — voir
/// profil_detail_controller.dart, qui lit `age` déjà calculé à la place.
class ProfilRepository {
  ProfilRepository(this._firestore, this._functions);

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  Stream<Profil?> watchProfil(String uid) {
    final usersStream = _firestore.collection('users').doc(uid).snapshots();
    final statusStream = _firestore.collection('user_status').doc(uid).snapshots();
    return usersStream.asyncMap((userSnap) async {
      final userData = userSnap.data();
      if (userData == null) return null;
      final statusSnap = await statusStream.first;
      final birthDate = statusSnap.data()?['birthDate'];
      final merged = {...userData};
      if (birthDate != null) merged['birthDate'] = birthDate;
      return Profil.fromMap(merged);
    });
  }

  Future<void> saveProfil(String uid, Profil profil) {
    return _functions.httpsCallable('saveProfil').call(profil.toMap());
  }
}
