import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend_quizzical/providers/auth_provider.dart';
import 'package:frontend_quizzical/providers/quiz_provider.dart';
import 'package:frontend_quizzical/config/app_config.dart';

class QuizListScreen extends ConsumerStatefulWidget {
  const QuizListScreen({super.key});

  @override
  ConsumerState<QuizListScreen> createState() => _QuizListScreenState();
}

class _QuizListScreenState extends ConsumerState<QuizListScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch quizzes when the screen is first loaded
    ref.read(quizProvider.notifier).fetchQuizzes();
  }

  Future<void> _deleteQuiz(String quizId, WidgetRef ref) async {
    final token = await ref.read(authProvider.notifier).getIdToken();

    if (token == null) {
      // Handle unauthenticated user
      return;
    }

    // Show confirmation dialog
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Quiz'),
        content: const Text('Are you sure you want to delete this quiz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), // No
            child: const Text('No', style: TextStyle(color: Colors.green)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true), // Yes
            child: const Text('Yes', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      try {
        final response = await http.delete(
          Uri.parse('${AppConfig.baseUrl}/quizzes/$quizId'),
          headers: {'Authorization': 'Bearer $token'},
        );

        if (response.statusCode == 200) {
          // Quiz deleted successfully, refresh the quiz list using the provider
          ref.read(quizProvider.notifier).fetchQuizzes();
        } else {
          // Handle quiz deletion failure with a more specific error message if available
          final errorBody = jsonDecode(response.body);
          final errorMessage = errorBody['message'] ?? 'Failed to delete quiz';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage)),
          );
        }
      } catch (e) {
        // Handle network or other errors
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('An error occurred while deleting the quiz')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);
    final quizzesAsyncValue = ref.watch(quizProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Quizzes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result =
                  await Navigator.pushNamed(context, '/quiz-create-edit');
              if (result == true) {
                // Refresh the quiz list using the provider after creating a new quiz
                ref.read(quizProvider.notifier).fetchQuizzes();
              }
            },
          ),
        ],
      ),
      body: user == null
          ? const Center(child: Text('Not logged in'))
          : ref.watch(quizProvider).when(
                data: (quizList) {
                  if (quizList.isNotEmpty) {
                    return ListView.builder(
                      itemCount: quizList.length,
                      itemBuilder: (context, index) {
                        final quiz = quizList[index];
                        final isPublished = quiz['isPublished'] as bool;

                        return ListTile(
                          leading: Text('${index + 1}. '),
                          title: Text(quiz['title']),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isPublished)
                                IconButton(
                                  icon: const Icon(Icons.link,
                                      color: Colors.green),
                                  onPressed: () async {
                                    final permalink = quiz['permalink'];
                                    if (permalink != null) {
                                      await Clipboard.setData(
                                          ClipboardData(text: permalink));
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text('Permalink copied!')),
                                      );
                                    }
                                  },
                                ),
                              IconButton(
                                icon: Icon(
                                  Icons.edit,
                                  color:
                                      isPublished ? Colors.grey : Colors.blue,
                                ),
                                onPressed: isPublished
                                    ? () {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                              content: Text(
                                                  'Published quizzes cannot be edited')),
                                        );
                                      }
                                    : () {
                                        // Navigate to quiz creation screen for editing, passing the quiz data
                                        Navigator.pushNamed(
                                            context, '/quiz-creation',
                                            arguments: quiz);
                                      },
                              ),
                              IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteQuiz(quiz['_id'], ref),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  } else {
                    return const Center(
                      child: Text(
                          'No quizzes here. Use the + icon to make a quiz.'),
                    );
                  }
                },
                error: (error, stackTrace) =>
                    Center(child: Text('Error: $error')),
                loading: () => const Center(child: CircularProgressIndicator()),
              ),
    );
  }
}
