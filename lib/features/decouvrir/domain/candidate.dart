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
      );
}

class DiscoverFilters {
  const DiscoverFilters({this.minAge, this.maxAge, this.maxDistanceKm = 100});

  final int? minAge;
  final int? maxAge;
  final int maxDistanceKm;

  Map<String, dynamic> toMap() => {
        if (minAge != null) 'minAge': minAge,
        if (maxAge != null) 'maxAge': maxAge,
        'maxDistanceKm': maxDistanceKm,
      };

  DiscoverFilters copyWith({int? minAge, int? maxAge, int? maxDistanceKm}) => DiscoverFilters(
        minAge: minAge ?? this.minAge,
        maxAge: maxAge ?? this.maxAge,
        maxDistanceKm: maxDistanceKm ?? this.maxDistanceKm,
      );
}
