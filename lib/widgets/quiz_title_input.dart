import 'package:flutter/material.dart';

class QuizTitleInput extends StatelessWidget {
  final TextEditingController controller;

  const QuizTitleInput({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: const InputDecoration(labelText: 'Quiz Title'),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a quiz title';
        }
        return null;
      },
    );
  }
}
