import 'package:flutter/material.dart';

class QuestionForm extends StatefulWidget {
  final VoidCallback onSave;
  final TextEditingController questionController;
  final List<TextEditingController> answerControllers;
  final String? selectedQuestionType;
  final List<bool> isAnswerCorrect;
  final VoidCallback onAddAnswer;
  final Function(int) onRemoveAnswer;
  final Function(String?) onQuestionTypeChanged;

  final bool isEditing;

  const QuestionForm({
    super.key,
    required this.questionController,
    required this.onSave,
    this.answerControllers = const [],
    required this.selectedQuestionType,
    this.isAnswerCorrect = const [],
    required this.onAddAnswer,
    required this.onRemoveAnswer,
    required this.onQuestionTypeChanged,
    this.isEditing = false,
  });

  @override
  _QuestionFormState createState() => _QuestionFormState();
}

class _QuestionFormState extends State<QuestionForm> {
  bool _showAnswers = false;

  @override
  @override
  void initState() {
    super.initState();
    _showAnswers = widget.isEditing && widget.answerControllers.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          controller: widget.questionController,
          decoration: const InputDecoration(labelText: 'Type your question'),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter the question text';
            }
            return null;
          },
          enabled: widget.isEditing,
        ),
        Row(
          children: [
            const Text('Single Answer'),
            Radio<String>(
              value: 'single',
              groupValue: widget.selectedQuestionType,
              onChanged: widget.isEditing ? widget.onQuestionTypeChanged : null,
            ),
            const Text('Multiple Answers'),
            Radio<String>(
              value: 'multiple',
              groupValue: widget.selectedQuestionType,
              onChanged: widget.isEditing ? widget.onQuestionTypeChanged : null,
            ),
          ],
        ),

        // Conditionally display answers and "Add Answer" button
        if (_showAnswers)
          ...widget.answerControllers.asMap().entries.map((answerEntry) {
            final answerIndex = answerEntry.key;
            final answerController = answerEntry.value;
            return Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: answerController,
                    decoration: InputDecoration(
                      labelText: 'Answer ${answerIndex + 1}',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the answer text';
                      }
                      return null;
                    },
                    enabled: widget.isEditing,
                  ),
                ),
                if (widget.isEditing)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => widget.onRemoveAnswer(answerIndex),
                  ),
                if (widget.isEditing)
                  Checkbox(
                    value: widget.isAnswerCorrect[answerIndex],
                    onChanged: (value) {
                      setState(() {
                        widget.isAnswerCorrect[answerIndex] = value!;

                        // For single-answer questions, ensure only one answer can be correct
                        if (widget.selectedQuestionType == 'single' && value) {
                          for (int i = 0;
                              i < widget.isAnswerCorrect.length;
                              i++) {
                            if (i != answerIndex) {
                              widget.isAnswerCorrect[i] = false;
                            }
                          }
                        }
                      });
                    },
                  ),
              ],
            );
          }),

        if (_showAnswers &&
            widget.answerControllers.length < 5 &&
            widget.isEditing)
          ElevatedButton(
            onPressed: widget.onAddAnswer,
            child: const Text('Add Answer'),
          ),

        // Conditionally display "Add Answer" button for new questions
        if (!_showAnswers && widget.isEditing)
          ElevatedButton(
            onPressed: () {
              setState(() {
                _showAnswers = true;
                widget.onAddAnswer(); // Add an initial answer
              });
            },
            child: const Text('Add Answer'),
          ),

        const SizedBox(height: 16),
      ],
    );
  }
}
