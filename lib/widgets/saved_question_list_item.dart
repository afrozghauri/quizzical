import 'package:flutter/material.dart';

class SavedQuestionListItem extends StatelessWidget {
  final Map<String, dynamic> quiz;
  final int questionNumber;
  final String questionText;
  final String questionType;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const SavedQuestionListItem({
    super.key,
    required this.questionNumber,
    required this.questionText,
    required this.questionType,
    required this.onEdit,
    required this.onDelete,
    required this.quiz,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Text('$questionNumber. '),
      title: Text(questionText),
      subtitle: Text(questionType),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.pushNamed(context, '/quiz-creation',
                  arguments: quiz); // Pass the quiz data
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
