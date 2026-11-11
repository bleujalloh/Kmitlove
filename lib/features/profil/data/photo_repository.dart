import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

import '../../../core/utils/retry.dart';
import '../domain/profil_photo.dart';

/// Upload direct vers Storage (règles : propriétaire uniquement, 10 Mo
/// max) puis création du document de suivi en base, toujours "pending"
/// à la création — jamais "approved" directement par le client, voir
/// firestore.rules (docs/regles-messagerie-securite.md section 1).
class PhotoRepository {
  PhotoRepository(this._storage, this._firestore);

  final FirebaseStorage _storage;
  final FirebaseFirestore _firestore;

  Stream<List<ProfilPhoto>> watchPhotos(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('photos')
        .orderBy('uploadedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(ProfilPhoto.fromDoc).toList());
  }

  Future<void> uploadPhoto(String uid, File file) async {
    final photoId = const Uuid().v4();
    final storagePath = 'profile_photos/$uid/$photoId.jpg';
    await _storage.ref(storagePath).putFile(file);
    await _firestore.collection('users').doc(uid).collection('photos').doc(photoId).set({
      'storagePath': storagePath,
      'status': 'pending',
      'uploadedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<String> getDownloadUrl(String storagePath) {
    return retryAsync(() => _storage.ref(storagePath).getDownloadURL());
  }

  Future<void> deletePhoto(String uid, ProfilPhoto photo) async {
    // Le document Firestore part en premier : s'il ne reste que le
    // fichier Storage à supprimer après coup, c'est un objet orphelin
    // inoffensif (plus jamais référencé) plutôt qu'une vignette cassée
    // affichée indéfiniment dans l'app si l'ordre inverse échouait à
    // mi-chemin.
    await _firestore.collection('users').doc(uid).collection('photos').doc(photo.id).delete();
    await _storage.ref(photo.storagePath).delete();
  }
}
