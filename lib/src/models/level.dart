class Level {
  const Level({
    required this.level,
    required this.type,
    required this.question,
    required this.answer,
    required this.accept,
    required this.hint,
    required this.solution,
  });

  final int level;
  final String type;
  final String question;
  final String answer;
  final List<String> accept;
  final String hint;
  final String solution;

  factory Level.fromJson(Map<String, dynamic> json) => Level(
        level: json['level'] as int,
        type: json['type'] as String,
        question: json['question'] as String,
        answer: json['answer'] as String,
        accept: (json['accept'] as List<dynamic>).cast<String>(),
        hint: json['hint'] as String,
        solution: json['solution'] as String,
      );

  /// Normalizes an answer: uppercase, letters only (strips spaces,
  /// punctuation, hyphens) so "spoon fed" matches "SPOONFED".
  static String normalize(String s) =>
      s.toUpperCase().replaceAll(RegExp(r'[^A-Z]'), '');

  bool matches(String input) {
    final n = normalize(input);
    if (n.isEmpty) return false;
    if (n == normalize(answer)) return true;
    return accept.any((a) => normalize(a) == n);
  }
}
