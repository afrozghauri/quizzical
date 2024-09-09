import 'package:flutter/material.dart';
import 'package:frontend_quizzical/models/quiz.dart';

// ... (your data models)

class ResultsScreen extends StatelessWidget {
  final Quiz quiz;
  final Map<String, String?> selectedAnswers;

  const ResultsScreen(
      {super.key, required this.quiz, required this.selectedAnswers});

  int calculateScore() {
    int score = 0;
    for (var question in quiz.questions) {
      final selectedAnswerId = selectedAnswers[question.id];
      if (selectedAnswerId != null &&
          question.answers.any(
              (answer) => answer.id == selectedAnswerId && answer.isCorrect)) {
        score++;
      }
    }
    return score;
  }

  @override
  Widget build(BuildContext context) {
    final score = calculateScore();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Results'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Your Score: $score / ${quiz.questions.length}',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // Add more feedback or details as needed
          ],
        ),
      ),
    );
  }
}
