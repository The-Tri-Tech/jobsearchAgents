class QuizQuestionModel {
  final int id;
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;

  const QuizQuestionModel({
    required this.id,
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });

  factory QuizQuestionModel.fromJson(Map<String, dynamic> json) {
    return QuizQuestionModel(
      id: json['id'] ?? 0,
      question: json['question'] ?? '',
      options:
          (json['options'] as List? ?? []).map((e) => e.toString()).toList(),
      correctIndex: json['correct_index'] ?? 0,
      explanation: json['explanation'] ?? '',
    );
  }
}

class GenerateQuizResponseModel {
  final String roleTitle;
  final List<QuizQuestionModel> questions;

  const GenerateQuizResponseModel({
    required this.roleTitle,
    required this.questions,
  });

  factory GenerateQuizResponseModel.fromJson(Map<String, dynamic> json) {
    return GenerateQuizResponseModel(
      roleTitle: json['role_title'] ?? 'Target Role',
      questions: (json['questions'] as List? ?? [])
          .map((q) => QuizQuestionModel.fromJson(q))
          .toList(),
    );
  }
}

