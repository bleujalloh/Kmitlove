import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/providers/firebase_providers.dart';
import '../data/photo_repository.dart';
import '../domain/profil_photo.dart';

final firebaseStorageProvider = Provider<FirebaseStorage>((ref) => FirebaseStorage.instance);

final photoRepositoryProvider = Provider<PhotoRepository>((ref) {
  return PhotoRepository(ref.watch(firebaseStorageProvider), ref.watch(firestoreProvider));
});

/// Mise en cache de l'URL de téléchargement par chemin Storage : sans
/// ça, chaque reconstruction du widget (ex. un setState ailleurs dans
/// l'écran de profil) referait l'appel réseau pour chaque photo.
final photoDownloadUrlProvider = FutureProvider.family<String, String>((ref, storagePath) {
  return ref.watch(photoRepositoryProvider).getDownloadUrl(storagePath);
});

final myPhotosProvider = StreamProvider<List<ProfilPhoto>>((ref) {
  final uid = ref.watch(authStateProvider).value?.uid;
  if (uid == null) return const Stream.empty();
  return ref.watch(photoRepositoryProvider).watchPhotos(uid);
});

class PhotoController {
  PhotoController(this.ref);
  final Ref ref;

  Future<bool> pickAndUpload({required bool fromCamera}) async {
    final uid = ref.read(firebaseAuthProvider).currentUser?.uid;
    if (uid == null) return false;
    final picked = await ImagePicker().pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1600,
    );
    if (picked == null) return false;
    await ref.read(photoRepositoryProvider).uploadPhoto(uid, File(picked.path));
    return true;
  }

  Future<void> delete(ProfilPhoto photo) async {
    final uid = ref.read(firebaseAuthProvider).currentUser?.uid;
    if (uid == null) return;
    await ref.read(photoRepositoryProvider).deletePhoto(uid, photo);
  }
}

final photoControllerProvider = Provider((ref) => PhotoController(ref));
