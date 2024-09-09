import 'package:flutter/material.dart';

// Function to generate initial question data
Map<String, dynamic> createEmptyQuestion() {
  return {
    'text': '',
    'answers': [],
    'correctAnswers': [],
    'type': 'single',
  };
}

// Function to build a ListTile for a saved question
Widget buildSavedQuestionListItem(int questionNumber,
    Map<String, dynamic> question, VoidCallback onEdit, VoidCallback onDelete) {
  return ListTile(
    leading: Text('$questionNumber. '),
    title: Text(
        question['questionController'].text), // Access text from the controller
    subtitle: Text(question['type']),
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.edit),
          onPressed: onEdit,
        ),
        IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: onDelete,
        ),
      ],
    ),
  );
}
