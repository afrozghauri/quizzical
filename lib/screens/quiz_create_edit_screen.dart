import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend_quizzical/providers/quiz_provider.dart';
import 'package:frontend_quizzical/utils/question_utils.dart';
import 'package:frontend_quizzical/widgets/bottom_buttons.dart';
import 'package:frontend_quizzical/widgets/question_form.dart';
import 'package:frontend_quizzical/widgets/quiz_title_input.dart';

class QuizCreateEditScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? quizData;

  const QuizCreateEditScreen({super.key, this.quizData});

  @override
  ConsumerState<QuizCreateEditScreen> createState() =>
      _QuizCreateEditScreenState();
}

class _QuizCreateEditScreenState extends ConsumerState<QuizCreateEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  List<Map<String, dynamic>> _questions = [];
  int _currentQuestionIndex = -1;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.quizData != null;
    if (_isEditing) {
      _titleController.text = widget.quizData!['title'];
      _questions =
          List<Map<String, dynamic>>.from(widget.quizData!['questions']);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _addQuestion() {
    setState(() {
      _questions.add({
        'text': '',
        'answers': [], // Start with an empty list of answers
        'correctAnswers': [],
        'type': 'single',
        'questionController': TextEditingController(),
        'answerControllers': <TextEditingController>[],
        'isAnswerCorrect': <bool>[],
      });
      _currentQuestionIndex = _questions.length - 1;
    });
  }

  void _editQuestion(int index) {
    setState(() {
      _currentQuestionIndex = index;
    });
  }

  void _deleteQuestion(int index) {
    setState(() {
      _questions.removeAt(index);
      if (_currentQuestionIndex >= _questions.length) {
        _currentQuestionIndex = _questions.length - 1;
      }
    });
  }

  void _saveQuestion(Map<String, dynamic> questionData) {
    setState(() {
      _questions[_currentQuestionIndex] = questionData;
    });
  }

  Future<void> _createOrUpdateQuiz({bool? isPublished, String? quizId}) async {
    if (_formKey.currentState!.validate()) {
      // Extract essential data from _questions
      final List<Map<String, dynamic>> questionsData =
          _questions.map((question) {
        // Filter out empty answers and their corresponding 'isAnswerCorrect' values
        final filteredAnswers = (question['answers'] as List<dynamic>)
            .where((answer) => answer != null && answer.toString().isNotEmpty)
            .toList();
        final filteredIsAnswerCorrect = (question['isAnswerCorrect']
                as List<dynamic>)
            .sublist(0,
                filteredAnswers.length) // Ensure same length as filteredAnswers
            .cast<bool>(); // Cast to List<bool>

        final List<Map<String, dynamic>> answersData =
            filteredAnswers.asMap().entries.map((entry) {
          final index = entry.key;
          final answerText = entry.value;
          return {
            'text': answerText,
            'isCorrect': filteredIsAnswerCorrect[index],
          };
        }).toList();

        return {
          'text': question['questionController'].text,
          'answers': answersData,
          'type': question['type'],
        };
      }).toList();
      final quizData = {
        'title': _titleController.text,
        'questions': questionsData,
        'isPublished': isPublished,
      };

      print('Quiz Data before API call (Frontend): $quizData');

      try {
        if (_isEditing) {
          await ref.read(quizProvider.notifier).saveQuiz(
                quizData,
                isEditing: true,
                quizId: widget.quizData!['_id'],
              );
        } else {
          await ref.read(quizProvider.notifier).saveQuiz(quizData);
        }

        // Refresh the quiz list after saving/updating the quiz
        await ref.read(quizProvider.notifier).fetchQuizzes();

        print('API call successful');
        Navigator.pop(context, true);
      } catch (e) {
        print('Error saving quiz: $e'); // Log the error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Quiz' : 'Create Quiz'),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    QuizTitleInput(controller: _titleController),
                    const SizedBox(height: 16),

                    // Conditionally display either the QuestionForm or the list of saved questions
                    _currentQuestionIndex != -1
                        ? QuestionForm(
                            isEditing: true,
                            questionController:
                                _questions[_currentQuestionIndex]
                                    ['questionController'],
                            answerControllers: _questions[_currentQuestionIndex]
                                ['answerControllers'],
                            selectedQuestionType:
                                _questions[_currentQuestionIndex]['type'],
                            isAnswerCorrect: _questions[_currentQuestionIndex][
                                'isAnswerCorrect'], // Pass isAnswerCorrect from question data
                            onAddAnswer: () {
                              setState(() {
                                _questions[_currentQuestionIndex]
                                        ['answerControllers']
                                    .add(TextEditingController());
                                _questions[_currentQuestionIndex]['answers']
                                    .add('');
                                _questions[_currentQuestionIndex]
                                        ['isAnswerCorrect']
                                    .add(false);
                              });
                            },
                            onRemoveAnswer: (index) {
                              setState(() {
                                _questions[_currentQuestionIndex]
                                        ['answerControllers']
                                    .removeAt(index);
                                _questions[_currentQuestionIndex]['answers']
                                    .removeAt(index);
                                _questions[_currentQuestionIndex]
                                        ['isAnswerCorrect']
                                    .removeAt(index);
                              });
                            },
                            onQuestionTypeChanged: (newValue) {
                              setState(() {
                                _questions[_currentQuestionIndex]['type'] =
                                    newValue;
                                // If switching to 'single', reset all isAnswerCorrect to false
                                if (newValue == 'single') {
                                  _questions[_currentQuestionIndex]
                                          ['isAnswerCorrect'] =
                                      List.generate(
                                          _questions[_currentQuestionIndex]
                                                  ['answers']
                                              .length,
                                          (_) => false);
                                }
                              });
                            },
                            onSave: () {
                              _saveQuestion({
                                'text': _questions[_currentQuestionIndex]
                                    ['text'],
                                'answers': _questions[_currentQuestionIndex]
                                    ['answers'],
                                'correctAnswers': _questions[
                                        _currentQuestionIndex]
                                    ['isAnswerCorrect'], // Use isAnswerCorrect
                                'type': _questions[_currentQuestionIndex]
                                    ['type'],
                              });

                              // After saving, reset the currentQuestionIndex to -1 to hide the QuestionForm
                              setState(() {
                                _currentQuestionIndex = -1;
                              });
                            },
                          )
                        :
                        // Display the list of saved questions only if there are questions and not editing a question
                        _questions.isNotEmpty
                            ? ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _questions.length,
                                itemBuilder: (context, index) {
                                  final question = _questions[index];

                                  return buildSavedQuestionListItem(
                                    index + 1,
                                    question,
                                    () => _editQuestion(index),
                                    () => _deleteQuestion(index),
                                  );
                                },
                              )
                            : Container(),
                  ],
                ),
              ),
            ),
            BottomButtons(
              isEditingQuestion: _currentQuestionIndex != -1,
              questionCount: _questions.length,
              // onSaveQuestion now directly hides the QuestionForm
              onSaveQuestion: () {
                setState(() {
                  _currentQuestionIndex = -1;
                });
              },
              onAddQuestion: _addQuestion,
              onCreateQuiz: _createOrUpdateQuiz,
            ),
          ],
        ),
      ),
    );
  }
}
