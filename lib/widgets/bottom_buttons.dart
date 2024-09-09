import 'package:flutter/material.dart';

class BottomButtons extends StatelessWidget {
  final bool isEditingQuestion;
  final int questionCount;
  final VoidCallback? onSaveQuestion;
  final VoidCallback onAddQuestion;
  final Future<void> Function({bool isPublished, String? quizId}) onCreateQuiz;

  const BottomButtons({
    super.key,
    required this.isEditingQuestion,
    required this.questionCount,
    this.onSaveQuestion,
    required this.onAddQuestion,
    required this.onCreateQuiz,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          if (isEditingQuestion) ...[
            ElevatedButton(
              onPressed: onSaveQuestion,
              child: const Text('Save Question'),
            ),
            const SizedBox(height: 16),
          ] else ...[
            if (questionCount < 10)
              ElevatedButton(
                onPressed: onAddQuestion,
                child: const Text('Add a Question'),
              ),
            const SizedBox(height: 16),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ElevatedButton(
                onPressed: () async {
                  await onCreateQuiz(
                      isPublished: false); // Await the result of onCreateQuiz
                }, // Edit Later
                child: const Text('Edit Later'),
              ),
              ElevatedButton(
                onPressed: () async {
                  await onCreateQuiz(isPublished: true);
                }, // Publish Quiz
                child: const Text('Publish Quiz'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
