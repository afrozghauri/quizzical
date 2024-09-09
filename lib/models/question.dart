import 'answer.dart'; // Import the Answer model

class Question {
  final String id;
  final String text;
  final List<Answer> answers;
  final String type;

  Question({
    required this.id,
    required this.text,
    required this.answers,
    required this.type,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['_id'],
      text: json['text'],
      answers:
          List<Answer>.from(json['answers'].map((x) => Answer.fromJson(x))),
      type: json['type'],
    );
  }
}
