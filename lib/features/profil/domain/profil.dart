/// Intentions relationnelles possibles (cahier des charges section 4.2).
class RelationshipIntent {
  static const serieuse = 'relation_serieuse';
  static const famille = 'relation_durable_famille';
  static const decouverte = 'decouverte_amoureuse';
  static const mariage = 'mariage';

  static const all = [serieuse, famille, decouverte, mariage];

  static String label(String value) {
    switch (value) {
      case serieuse:
        return 'Relation sérieuse';
      case famille:
        return 'Relation durable en vue d\'une famille';
      case decouverte:
        return 'Découverte amoureuse';
      case mariage:
        return 'Mariage';
      default:
        return value;
    }
  }
}

class Profil {
  const Profil({
    required this.displayName,
    required this.birthDate,
    required this.gender,
    required this.seekingGenders,
    required this.country,
    required this.city,
    required this.bio,
    required this.relationshipIntent,
    this.profession,
    this.languages = const [],
    this.interests = const [],
    this.culturalOrigins = const [],
    this.values,
  });

  final String displayName;
  final DateTime birthDate;
  final String gender;
  final List<String> seekingGenders;
  final String country;
  final String city;
  final String bio;
  final String relationshipIntent;
  final String? profession;
  final List<String> languages;
  final List<String> interests;
  final List<String> culturalOrigins;
  final String? values;

  Map<String, dynamic> toMap() => {
        'displayName': displayName,
        'birthDate': birthDate.toIso8601String(),
        'gender': gender,
        'seekingGenders': seekingGenders,
        'country': country,
        'city': city,
        'bio': bio,
        'relationshipIntent': relationshipIntent,
        'profession': profession,
        'languages': languages,
        'interests': interests,
        'culturalOrigins': culturalOrigins,
        'values': values,
      };

  factory Profil.fromMap(Map<String, dynamic> map) => Profil(
        displayName: map['displayName'] as String,
        birthDate: DateTime.parse(map['birthDate'] as String),
        gender: map['gender'] as String,
        seekingGenders: List<String>.from(map['seekingGenders'] as List? ?? []),
        country: map['country'] as String,
        city: map['city'] as String,
        bio: map['bio'] as String,
        relationshipIntent: map['relationshipIntent'] as String,
        profession: map['profession'] as String?,
        languages: List<String>.from(map['languages'] as List? ?? []),
        interests: List<String>.from(map['interests'] as List? ?? []),
        culturalOrigins: List<String>.from(map['culturalOrigins'] as List? ?? []),
        values: map['values'] as String?,
      );
}
