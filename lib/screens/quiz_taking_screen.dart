import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend_quizzical/config/app_config.dart';

import 'package:frontend_quizzical/models/quiz.dart';
import 'package:frontend_quizzical/providers/auth_provider.dart';

import 'results_screen.dart';

class QuizTakingScreen extends ConsumerStatefulWidget {
  final String permalink;

  const QuizTakingScreen({super.key, required this.permalink});

  @override
  _QuizTakingScreenState createState() => _QuizTakingScreenState();
}

class _QuizTakingScreenState extends ConsumerState<QuizTakingScreen>
    with AutomaticKeepAliveClientMixin {
  Quiz? quiz;
  int currentQuestionIndex = 0;
  Map<String, List<String>?> selectedAnswers = {};
  bool isLoading = true;

  final _authProvider = Provider((ref) => ref.watch(authProvider.notifier));

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    fetchQuiz();
  }

  Future<void> fetchQuiz() async {
    try {
      final fetchedQuiz = await fetchQuizByPermalink(widget.permalink);
      setState(() {
        quiz = fetchedQuiz;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching quiz: $e');
      setState(() {
        isLoading = false;
      });
      // Handle the error appropriately (e.g., show an error message to the user)
    }
  }

  Future<Quiz> fetchQuizByPermalink(String permalink) async {
    final token = await ref.read(_authProvider).getIdToken();

    if (token == null) {
      throw Exception('User not authenticated');
    }

    final response = await http.get(
      Uri.parse('${AppConfig.baseUrl}/quizzes/permalink/$permalink'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return Quiz.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load quiz');
    }
  }

  void handleAnswerSelection(String questionId, String? selectedAnswer) {
    setState(() {
      final currentQuestion = quiz!.questions[currentQuestionIndex];
      if (currentQuestion.type == 'single') {
        // For single-choice questions:
        // If selectedAnswer is null, assign an empty list
        // Otherwise, assign a list containing the selectedAnswer
        selectedAnswers[questionId] =
            selectedAnswer != null ? [selectedAnswer] : [];
      } else if (currentQuestion.type == 'multiple') {
        // For multiple-choice questions, handle adding/removing answer IDs
        final currentSelectedAnswers = selectedAnswers[questionId] ?? [];
        if (selectedAnswer != null &&
            !currentSelectedAnswers.contains(selectedAnswer)) {
          // Add the answer ID if it's not already selected
          selectedAnswers[questionId] = [
            ...currentSelectedAnswers,
            selectedAnswer
          ];
        } else if (selectedAnswer != null) {
          // Remove the answer ID if it's already selected
          selectedAnswers[questionId] = currentSelectedAnswers
              .where((id) => id != selectedAnswer)
              .toList();
        }
      }
    });
  }

  void nextQuestion() {
    if (currentQuestionIndex < (quiz?.questions.length ?? 0) - 1) {
      setState(() {
        currentQuestionIndex++;
      });
    } else {
      // Convert selectedAnswers to Map<String, String?> before passing to ResultsScreen
      final singleAnswerMap = selectedAnswers.map((questionId, answers) =>
          MapEntry(
              questionId, answers?.isNotEmpty == true ? answers!.first : null));

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResultsScreen(
            quiz: quiz!,
            selectedAnswers: singleAnswerMap, // Pass the converted map
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // For AutomaticKeepAliveClientMixin

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (quiz == null) {
      return const Center(child: Text('Quiz not found'));
    }

    final currentQuestion = quiz!.questions[currentQuestionIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(quiz!.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Question ${currentQuestionIndex + 1}:',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(currentQuestion.text),
            const SizedBox(height: 16),
            if (currentQuestion.type == 'single')
              ...currentQuestion.answers.map((answer) {
                return RadioListTile<String>(
                  title: Text(answer.text),
                  value: answer.id,
                  groupValue: selectedAnswers[currentQuestion.id]
                      ?.first, // Access the first element (or null if the list is empty)
                  onChanged: (value) =>
                      handleAnswerSelection(currentQuestion.id, value),
                );
              })
            else if (currentQuestion.type == 'multiple')
              ...currentQuestion.answers.map((answer) {
                return CheckboxListTile(
                  title: Text(answer.text),
                  value: selectedAnswers[currentQuestion.id]
                          ?.contains(answer.id) ??
                      false,
                  onChanged: (value) {
                    setState(() {
                      if (value!) {
                        // If checked, add the answer ID to the list (or create a new list if it's null)
                        selectedAnswers[currentQuestion.id] =
                            (selectedAnswers[currentQuestion.id] ?? []) +
                                [answer.id];
                      } else {
                        // If unchecked, remove the answer ID from the list
                        selectedAnswers[currentQuestion.id] =
                            selectedAnswers[currentQuestion.id]
                                ?.where((id) => id != answer.id)
                                .toList();
                      }
                    });
                  },
                );
              }),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: nextQuestion,
        child: const Icon(Icons.arrow_forward),
      ),
    );
  }
}
