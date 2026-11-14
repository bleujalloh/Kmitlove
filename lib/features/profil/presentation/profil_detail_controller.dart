import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/firebase_providers.dart';
import 'photo_controller.dart';

class TargetProfile {
  const TargetProfile({
    required this.uid,
    required this.displayName,
    required this.age,
    required this.city,
    required this.country,
    required this.bio,
    required this.interests,
    this.relationshipIntent,
    this.profession,
    this.heightCm,
    this.educationLevel,
    this.childrenStatus,
    this.smokingHabit,
    this.drinkingHabit,
    this.values,
    this.lookingFor,
    this.qualities = const [],
    this.languages = const [],
    this.culturalOrigins = const [],
  });

  final String uid;
  final String displayName;
  final int age;
  final String city;
  final String country;
  final String bio;
  final List<String> interests;
  // Fiche profil étendue (maquette visuelle validée le 12/11/2026) —
  // mêmes champs publics que Candidate (decouvrir/domain/candidate.dart),
  // lus directement sur le même document public `users/{uid}`.
  final String? relationshipIntent;
  final String? profession;
  final int? heightCm;
  final String? educationLevel;
  final String? childrenStatus;
  final String? smokingHabit;
  final String? drinkingHabit;
  final String? values;
  final String? lookingFor;
  final List<String> qualities;
  final List<String> languages;
  final List<String> culturalOrigins;
}

/// Détail d'un profil tiers (fiche "Détail du profil" — demande du
/// propriétaire le 11/11/2026 : taper sur une carte de profil déjà likée
/// ne faisait rien, nulle part). Lecture directe Firestore : `users/{uid}`
/// est publiquement lisible par tout membre connecté (firestore.rules),
/// même raisonnement que candidateFirstPhotoUrlProvider.ts
/// (decouvrir_controller.dart) — pas besoin d'une Cloud Function dédiée.
///
/// `age` (jamais `birthDate`, qui ne vit plus que dans `user_status/{uid}`
/// depuis le 12/11/2026 — règlement permanent section 17, la date de
/// naissance exacte d'un AUTRE membre ne doit jamais être lisible) est
/// déjà calculé et stocké sur le document public par saveProfil.ts —
/// jamais recalculé ici à partir d'une donnée qui n'existe plus.
final targetProfileProvider = FutureProvider.autoDispose
    .family<TargetProfile?, String>((ref, uid) async {
      final doc = await ref
          .watch(firestoreProvider)
          .collection('users')
          .doc(uid)
          .get();
      final data = doc.data();
      if (data == null) return null;
      // `age` absent (profil pas encore resauvegardé depuis le passage à
      // un champ public calculé, 12/11/2026) doit échouer bruyamment,
      // pas s'afficher comme si la personne venait de naître — même
      // choix que `DateTime.parse` sur `birthDate` avant ce correctif
      // (trouvé par revue de code : un `?? 0` ici aurait justement
      // réintroduit l'anti-motif que ce choix évitait).
      if (data['age'] is! num) {
        throw StateError('Profil incomplet : age manquant pour $uid.');
      }
      return TargetProfile(
        uid: uid,
        displayName: data['displayName'] as String? ?? '',
        age: (data['age'] as num).toInt(),
        city: data['city'] as String? ?? '',
        country: data['country'] as String? ?? '',
        bio: data['bio'] as String? ?? '',
        interests: List<String>.from(data['interests'] as List? ?? const []),
        relationshipIntent: data['relationshipIntent'] as String?,
        profession: data['profession'] as String?,
        heightCm: (data['heightCm'] as num?)?.toInt(),
        educationLevel: data['educationLevel'] as String?,
        childrenStatus: data['childrenStatus'] as String?,
        smokingHabit: data['smokingHabit'] as String?,
        drinkingHabit: data['drinkingHabit'] as String?,
        values: data['values'] as String?,
        lookingFor: data['lookingFor'] as String?,
        qualities: List<String>.from(data['qualities'] as List? ?? const []),
        languages: List<String>.from(data['languages'] as List? ?? const []),
        culturalOrigins: List<String>.from(data['culturalOrigins'] as List? ?? const []),
      );
    });

/// Toutes les photos APPROUVÉES d'un profil tiers (pas seulement la
/// première, contrairement à candidateFirstPhotoUrlProvider — la fiche
/// détail montre un vrai carrousel). Requête partagée avec
/// candidateFirstPhotoUrlProvider via PhotoRepository (trouvé dupliqué
/// par revue de code). `isVerified` (user_status) n'est jamais relu ici :
/// réservé à son propriétaire côté règles (firestore.rules), l'appelant
/// doit le fournir quand il le connaît déjà (ex. MiniProfile.isVerified,
/// déjà renvoyé par getLikes.ts).
final targetProfilePhotoUrlsProvider = FutureProvider.autoDispose
    .family<List<String>, String>((ref, uid) async {
      final repo = ref.watch(photoRepositoryProvider);
      final paths = await repo.getApprovedPhotoStoragePaths(uid);
      // Chaque photo résolue indépendamment : si l'une échoue (fichier
      // Storage orphelin après un nettoyage qui n'a pas touché le document
      // Firestore, ou un échec réseau qui survit aux tentatives de
      // getDownloadUrl), les autres doivent quand même s'afficher plutôt que
      // de faire échouer tout le carrousel d'un coup (trouvé par revue de
      // code : un Future.wait strict aurait propagé l'échec d'une seule
      // photo à toutes les autres).
      final urls = await Future.wait(
        paths.map((path) async {
          try {
            return await repo.getDownloadUrl(path);
          } catch (_) {
            return null;
          }
        }),
      );
      return urls.whereType<String>().toList();
    });
