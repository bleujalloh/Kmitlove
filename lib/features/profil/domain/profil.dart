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

/// Habitude de vie à trois niveaux, réutilisée pour le tabac et l'alcool
/// — comme sur les applications de rencontre courantes (Tinder, Bumble,
/// Hinge).
class LifestyleHabit {
  static const jamais = 'jamais';
  static const parfois = 'parfois';
  static const souvent = 'souvent';

  static const all = [jamais, parfois, souvent];

  static String label(String value) {
    switch (value) {
      case jamais:
        return 'Jamais';
      case parfois:
        return 'Parfois';
      case souvent:
        return 'Souvent';
      default:
        return value;
    }
  }
}

class ChildrenStatus {
  static const hasChildren = 'a_des_enfants';
  static const wantsChildren = 'veut_des_enfants';
  static const doesNotWantChildren = 'ne_veut_pas_denfants';
  static const notSure = 'ne_sait_pas_encore';

  static const all = [hasChildren, wantsChildren, doesNotWantChildren, notSure];

  static String label(String value) {
    switch (value) {
      case hasChildren:
        return 'A déjà des enfants';
      case wantsChildren:
        return 'Veut des enfants';
      case doesNotWantChildren:
        return 'Ne veut pas d\'enfants';
      case notSure:
        return 'Ne sait pas encore';
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
    this.heightCm,
    this.educationLevel,
    this.smokingHabit,
    this.drinkingHabit,
    this.childrenStatus,
    this.lookingFor,
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

  /// Les champs suivants complètent la fiche comme sur les applications
  /// de rencontre courantes — tous facultatifs, pour ne jamais bloquer
  /// la création de profil sur une information secondaire.
  final int? heightCm;
  final String? educationLevel;
  final String? smokingHabit;
  final String? drinkingHabit;
  final String? childrenStatus;
  final String? lookingFor;

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
        'heightCm': heightCm,
        'educationLevel': educationLevel,
        'smokingHabit': smokingHabit,
        'drinkingHabit': drinkingHabit,
        'childrenStatus': childrenStatus,
        'lookingFor': lookingFor,
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
        heightCm: (map['heightCm'] as num?)?.toInt(),
        educationLevel: map['educationLevel'] as String?,
        smokingHabit: map['smokingHabit'] as String?,
        drinkingHabit: map['drinkingHabit'] as String?,
        childrenStatus: map['childrenStatus'] as String?,
        lookingFor: map['lookingFor'] as String?,
      );
}
