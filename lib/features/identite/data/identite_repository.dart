import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// Ouverte à tout membre volontaire, pas réservée aux organisateurs
/// d'événements (docs/regles-complementaires-concurrents.md section 1).
/// Le fichier est déposé directement dans Storage (règles : propriétaire
/// uniquement, jamais lisible par un autre membre), puis déclaré via une
/// Cloud Function pour que l'admin soit prévenu.
class IdentiteRepository {
  IdentiteRepository(this._storage, this._functions);

  final FirebaseStorage _storage;
  final FirebaseFunctions _functions;

  Future<void> submitSelfie(String uid, File file) async {
    final storagePath = 'identity_verifications/$uid/selfie.jpg';
    await _storage.ref(storagePath).putFile(file);
    await _functions.httpsCallable('submitIdentityVerification').call({'storagePath': storagePath});
  }
}
