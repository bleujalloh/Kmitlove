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
  });

  final String uid;
  final String displayName;
  final int age;
  final String city;
  final String country;
  final String bio;
  final List<String> interests;
  final String relationshipIntent;

  factory Candidate.fromMap(Map<String, dynamic> map) => Candidate(
        uid: map['uid'] as String,
        displayName: map['displayName'] as String,
        age: (map['age'] as num).toInt(),
        city: map['city'] as String,
        country: map['country'] as String,
        bio: map['bio'] as String,
        interests: List<String>.from(map['interests'] as List? ?? []),
        relationshipIntent: map['relationshipIntent'] as String,
      );
}
