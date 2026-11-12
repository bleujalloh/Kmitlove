class Candidate {
  const Candidate({
    required this.uid,
    required this.displayName,
    required this.age,
    required this.city,
    required this.country,
    required this.bio,
    required this.interests,
    required this.relationshipIntent,
    this.distanceKm,
    this.isVerified = false,
    this.isOnline = false,
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
  final String relationshipIntent;
  final int? distanceKm;
  final bool isVerified;
  // Fiche profil étendue (révélation complète au scroll sur la carte
  // Découvrir, maquette visuelle validée le 12/11/2026) — `null` quand
  // le membre ne l'a pas renseigné, jamais une valeur inventée côté client.
  final bool isOnline;
  final String? profession;
  final int? heightCm;
  final String? educationLevel;
  final String? childrenStatus;
  final String? smokingHabit;
  final String? drinkingHabit;

  factory Candidate.fromMap(Map<String, dynamic> map) => Candidate(
    uid: map['uid'] as String,
    displayName: map['displayName'] as String,
    age: (map['age'] as num).toInt(),
    city: map['city'] as String,
    country: map['country'] as String,
    bio: map['bio'] as String,
    interests: List<String>.from(map['interests'] as List? ?? []),
    relationshipIntent: map['relationshipIntent'] as String,
    distanceKm: (map['distanceKm'] as num?)?.toInt(),
    isVerified: map['isVerified'] as bool? ?? false,
    isOnline: map['isOnline'] as bool? ?? false,
    profession: map['profession'] as String?,
    heightCm: (map['heightCm'] as num?)?.toInt(),
    educationLevel: map['educationLevel'] as String?,
    childrenStatus: map['childrenStatus'] as String?,
    smokingHabit: map['smokingHabit'] as String?,
    drinkingHabit: map['drinkingHabit'] as String?,
  );
}

class DiscoverFilters {
  const DiscoverFilters({
    this.minAge,
    this.maxAge,
    this.maxDistanceKm = 100,
    this.country,
    this.city,
  });

  final int? minAge;
  final int? maxAge;
  final int maxDistanceKm;

  /// Filtre pays/ville — quand renseigné, remplace le filtre de distance
  /// côté serveur plutôt que de s'y ajouter (voir getCandidates.ts) :
  /// utile pour une communauté répartie sur plusieurs pays, pas limitée
  /// au rayon GPS (docs/suivi-developpement.md section du 11/11/2026).
  final String? country;
  final String? city;

  Map<String, dynamic> toMap() => {
    if (minAge != null) 'minAge': minAge,
    if (maxAge != null) 'maxAge': maxAge,
    'maxDistanceKm': maxDistanceKm,
    if (country != null && country!.trim().isNotEmpty)
      'country': country!.trim(),
    if (city != null && city!.trim().isNotEmpty) 'city': city!.trim(),
  };

  DiscoverFilters copyWith({
    int? minAge,
    int? maxAge,
    int? maxDistanceKm,
    String? country,
    String? city,
    bool clearLocation = false,
  }) => DiscoverFilters(
    minAge: minAge ?? this.minAge,
    maxAge: maxAge ?? this.maxAge,
    maxDistanceKm: maxDistanceKm ?? this.maxDistanceKm,
    country: clearLocation ? null : (country ?? this.country),
    city: clearLocation ? null : (city ?? this.city),
  );
}
