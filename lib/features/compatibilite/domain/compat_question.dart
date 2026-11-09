class CompatQuestion {
  const CompatQuestion({required this.id, required this.theme, required this.question});

  final String id;
  final String theme;
  final String question;

  factory CompatQuestion.fromFirestore(String id, Map<String, dynamic> data) {
    return CompatQuestion(
      id: id,
      theme: data['theme'] as String,
      question: data['question'] as String,
    );
  }
}

const compatThemeLabels = {
  'vision_couple': 'Vision du couple',
  'valeurs_culture': 'Valeurs et culture',
  'famille': 'Famille',
  'mode_vie': 'Mode de vie',
  'communication': 'Communication',
};
