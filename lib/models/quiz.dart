import 'question.dart'; // Import the Question model

class Quiz {
  final String id;
  final String title;
  final List<Question> questions;

  Quiz({
    required this.id,
    required this.title,
    required this.questions,
  });

  factory Quiz.fromJson(Map<String, dynamic> json) {
    return Quiz(
      id: json['_id'],
      title: json['title'],
      questions: List<Question>.from(
          json['questions'].map((x) => Question.fromJson(x))),
    );
  }
}
