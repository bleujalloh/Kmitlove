import '../../../l10n/app_localizations.dart';

/// Intentions relationnelles possibles (cahier des charges section 4.2).
/// Les valeurs stockées (`serieuse`, `famille`...) sont des codes stables,
/// jamais affichés directement — `label()` ne fait que choisir le texte
/// dans la langue courante, donc un profil existant reste lisible quelle
/// que soit la langue active au moment de l'affichage.
class RelationshipIntent {
  static const serieuse = 'relation_serieuse';
  static const famille = 'relation_durable_famille';
  static const decouverte = 'decouverte_amoureuse';
  static const mariage = 'mariage';

  static const all = [serieuse, famille, decouverte, mariage];

  static String label(String value, AppLocalizations l10n) {
    switch (value) {
      case serieuse:
        return l10n.relationshipIntentSerieuse;
      case famille:
        return l10n.relationshipIntentFamille;
      case decouverte:
        return l10n.relationshipIntentDecouverte;
      case mariage:
        return l10n.relationshipIntentMariage;
      default:
        return value;
    }
  }
}

/// Genres possibles (profil et préférence de recherche) — les valeurs
/// stockées restent ces mots français (comme `PersonalQuality` plus bas),
/// `label()` ne traduit que l'affichage.
class Gender {
  static const femme = 'Femme';
  static const homme = 'Homme';

  static const all = [femme, homme];

  static String label(String value, AppLocalizations l10n) {
    switch (value) {
      case femme:
        return l10n.genderWoman;
      default:
        return l10n.genderMan;
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

  static String label(String value, AppLocalizations l10n) {
    switch (value) {
      case jamais:
        return l10n.lifestyleHabitNever;
      case parfois:
        return l10n.lifestyleHabitSometimes;
      case souvent:
        return l10n.lifestyleHabitOften;
      default:
        return value;
    }
  }
}

/// Qualités que le membre choisit de mettre en avant sur sa fiche,
/// comme sur les applications de rencontre courantes — liste fermée
/// pour que ça reste rapide à remplir et comparable entre profils. Les
/// valeurs stockées restent ces mots français (changer ça casserait les
/// profils déjà enregistrés) ; `label()` ne traduit que l'affichage.
class PersonalQuality {
  // Source unique : `all` et `label()` sont tous deux dérivés de cette
  // seule liste, pour qu'il soit impossible d'ajouter/renommer une
  // qualité d'un côté sans l'autre (contrairement à deux listes
  // indépendantes à tenir manuellement synchronisées).
  static final List<(String value, String Function(AppLocalizations) label)> _entries = [
    ('Drôle', (l10n) => l10n.qualityFunny),
    ('Ambitieux(se)', (l10n) => l10n.qualityAmbitious),
    ('Calme', (l10n) => l10n.qualityCalm),
    ('Aventurier(ère)', (l10n) => l10n.qualityAdventurous),
    ('Romantique', (l10n) => l10n.qualityRomantic),
    ('Généreux(se)', (l10n) => l10n.qualityGenerous),
    ('Sincère', (l10n) => l10n.qualitySincere),
    ('Spirituel(le)', (l10n) => l10n.qualitySpiritual),
    ('Attentionné(e)', (l10n) => l10n.qualityCaring),
    ('Déterminé(e)', (l10n) => l10n.qualityDetermined),
    ('Créatif(ve)', (l10n) => l10n.qualityCreative),
    ('Loyal(e)', (l10n) => l10n.qualityLoyal),
    ('Patient(e)', (l10n) => l10n.qualityPatient),
    ('Optimiste', (l10n) => l10n.qualityOptimistic),
  ];

  static List<String> get all => _entries.map((e) => e.$1).toList();

  static String label(String value, AppLocalizations l10n) {
    for (final entry in _entries) {
      if (entry.$1 == value) return entry.$2(l10n);
    }
    return value;
  }
}

class ChildrenStatus {
  static const hasChildren = 'a_des_enfants';
  static const wantsChildren = 'veut_des_enfants';
  static const doesNotWantChildren = 'ne_veut_pas_denfants';
  static const notSure = 'ne_sait_pas_encore';

  static const all = [hasChildren, wantsChildren, doesNotWantChildren, notSure];

  static String label(String value, AppLocalizations l10n) {
    switch (value) {
      case hasChildren:
        return l10n.childrenStatusHas;
      case wantsChildren:
        return l10n.childrenStatusWants;
      case doesNotWantChildren:
        return l10n.childrenStatusDoesNotWant;
      case notSure:
        return l10n.childrenStatusNotSure;
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
    this.qualities = const [],
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
  final List<String> qualities;

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
        'qualities': qualities,
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
        qualities: List<String>.from(map['qualities'] as List? ?? []),
      );
}
