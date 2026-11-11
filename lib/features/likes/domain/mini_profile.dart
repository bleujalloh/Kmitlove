class MiniProfile {
  const MiniProfile({
    required this.uid,
    required this.displayName,
    required this.age,
    required this.city,
    this.isVerified = false,
  });

  final String uid;
  final String displayName;
  final int age;
  final String city;
  final bool isVerified;

  factory MiniProfile.fromMap(Map<String, dynamic> map) => MiniProfile(
        uid: map['uid'] as String,
        displayName: map['displayName'] as String,
        age: (map['age'] as num).toInt(),
        city: map['city'] as String,
        isVerified: map['isVerified'] as bool? ?? false,
      );
}
