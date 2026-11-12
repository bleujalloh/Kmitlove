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

  /// Chemins Storage des photos APPROUVÉES d'un membre — partagé entre
  /// `candidateFirstPhotoUrlProvider` (decouvrir_controller.dart, une
  /// seule photo pour la carte) et `targetProfilePhotoUrlsProvider`
  /// (profil_detail_controller.dart, toutes les photos pour le
  /// carrousel), plutôt que deux requêtes réimplémentées séparément
  /// (trouvé par revue de code).
  // Les deux méthodes ci-dessous ordonnent désormais par `uploadedAt`
  // CROISSANT (la plus ancienne en premier) — même définition de "photo
  // principale" des deux côtés : la première jamais approuvée, stable
  // tant qu'elle n'est pas supprimée, plutôt qu'une photo qui changerait
  // silencieusement à chaque nouvel ajout. Avant ce correctif,
  // `getApprovedPhotoStoragePaths` n'avait aucun tri (ordre Firestore non
  // garanti) tandis que `watchPhotos` triait par le plus récent — deux
  // membres pouvaient donc voir une "première photo" différente de celle
  // affichée à son propriétaire sur son propre onglet Profil (trouvé par
  // revue de code).
  Future<List<String>> getApprovedPhotoStoragePaths(String uid, {int? limit}) async {
    Query<Map<String, dynamic>> query = _firestore
        .collection('users')
        .doc(uid)
        .collection('photos')
        .where('status', isEqualTo: 'approved')
        .orderBy('uploadedAt');
    if (limit != null) query = query.limit(limit);
    final snap = await query.get();
    return snap.docs.map((d) => d.data()['storagePath'] as String?).whereType<String>().toList();
  }

  Stream<List<ProfilPhoto>> watchPhotos(String uid) {
    // Tri refait côté client plutôt que confié à `orderBy('uploadedAt')`
    // Firestore (gardé sans tri ici, contrairement à
    // `getApprovedPhotoStoragePaths` ci-dessus) : `uploadPhoto` écrit
    // `uploadedAt` avec `FieldValue.serverTimestamp()`, donc l'écho local
    // immédiat de ce listener (avant confirmation serveur) voit ce champ
    // `null` un court instant — trié en ASCENDING, Firestore place les
    // valeurs `null` EN PREMIER, ce qui aurait fait sauter une photo tout
    // juste ajoutée en tête de la galerie pendant une fraction de
    // seconde avant qu'elle ne reprenne sa vraie place une fois
    // l'horodatage résolu (trouvé par revue de code). Un tri manuel qui
    // place toujours `null` en DERNIER (jamais avant les autres, quel
    // que soit le sens) évite ce sursaut visuel.
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('photos')
        .snapshots()
        .map((snap) {
          final photos = snap.docs.map(ProfilPhoto.fromDoc).toList();
          photos.sort((a, b) {
            if (a.uploadedAt == null && b.uploadedAt == null) return 0;
            if (a.uploadedAt == null) return 1;
            if (b.uploadedAt == null) return -1;
            return a.uploadedAt!.compareTo(b.uploadedAt!);
          });
          return photos;
        });
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
