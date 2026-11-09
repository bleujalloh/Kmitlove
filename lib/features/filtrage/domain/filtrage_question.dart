class FiltrageQuestion {
  const FiltrageQuestion({
    required this.id,
    required this.theme,
    required this.question,
    required this.options,
  });

  final String id;
  final String theme;
  final String question;
  final List<String> options;

  factory FiltrageQuestion.fromMap(Map<String, dynamic> map) {
    return FiltrageQuestion(
      id: map['id'] as String,
      theme: map['theme'] as String,
      question: map['question'] as String,
      options: List<String>.from(map['options'] as List),
    );
  }
}
