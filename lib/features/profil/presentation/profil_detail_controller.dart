import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/firebase_providers.dart';
import '../../../core/utils/age.dart';
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
}

/// Détail d'un profil tiers (fiche "Détail du profil" — demande du
/// propriétaire le 11/11/2026 : taper sur une carte de profil déjà likée
/// ne faisait rien, nulle part). Lecture directe Firestore : `users/{uid}`
/// est publiquement lisible par tout membre connecté (firestore.rules),
/// même raisonnement que candidateFirstPhotoUrlProvider.ts
/// (decouvrir_controller.dart) — pas besoin d'une Cloud Function dédiée.
/// `birthDate` est un champ obligatoire et validé à l'écriture
/// (saveProfil.ts) : `DateTime.parse` (qui lève une exception s'il est
/// absent ou corrompu) plutôt qu'un `tryParse` masqué par un âge par
/// défaut de 0 — même choix que Profil.fromMap (profil/domain/profil.dart),
/// une donnée invalide doit échouer bruyamment, pas s'afficher comme
/// si la personne venait de naître (trouvé par revue de code).
final targetProfileProvider = FutureProvider.autoDispose
    .family<TargetProfile?, String>((ref, uid) async {
      final doc = await ref
          .watch(firestoreProvider)
          .collection('users')
          .doc(uid)
          .get();
      final data = doc.data();
      if (data == null) return null;
      return TargetProfile(
        uid: uid,
        displayName: data['displayName'] as String? ?? '',
        age: ageFromBirthDate(DateTime.parse(data['birthDate'] as String)),
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
