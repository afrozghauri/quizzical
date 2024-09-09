import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:frontend_quizzical/config/app_config.dart';
import 'package:frontend_quizzical/providers/auth_provider.dart';

final quizProvider =
    StateNotifierProvider<QuizNotifier, AsyncValue<List<Map<String, dynamic>>>>(
  (ref) => QuizNotifier(ref),
);

class QuizNotifier
    extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  final Ref ref;

  QuizNotifier(this.ref) : super(const AsyncValue.loading());

  Future<void> fetchQuizzes() async {
    state = const AsyncValue.loading();

    try {
      final token = await ref.watch(authProvider.notifier).getIdToken();

      if (token == null) {
        throw Exception('User not authenticated');
      }

      // 1. Fetch the list of quizzes
      final quizzesResponse = await http.get(
        Uri.parse('${AppConfig.baseUrl}/quizzes/my-quizzes'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (quizzesResponse.statusCode == 200) {
        final List<dynamic> quizData = jsonDecode(quizzesResponse.body);

        // 2. For each quiz, fetch its questions
        final List<Map<String, dynamic>> populatedQuizzes = await Future.wait(
          quizData.map((quiz) async {
            final quizId = quiz['_id'];

            // Fetch questions for this quiz (using the new endpoint)
            final questionsResponse = await http.get(
              Uri.parse('${AppConfig.baseUrl}/quizzes/$quizId/questions'),
              headers: {'Authorization': 'Bearer $token'},
            );

            if (questionsResponse.statusCode == 200) {
              final List<dynamic> questionsData =
                  jsonDecode(questionsResponse.body);

              return {
                ...quiz,
                'questions':
                    questionsData, // Assign the fetched questions directly
              };
            } else {
              throw Exception('Failed to fetch questions for quiz $quizId');
            }
          }),
        );

        state = AsyncValue.data(populatedQuizzes);
      } else {
        throw Exception('Failed to fetch quizzes');
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<Map<String, dynamic>?> saveQuiz(Map<String, dynamic> quizData,
      {bool isEditing = false, String? quizId}) async {
    // Get the ID token from the AuthProvider
    final token = await ref.watch(authProvider.notifier).getIdToken();

    if (token == null) {
      throw Exception('User not authenticated');
    }

    try {
      final url = isEditing
          ? Uri.parse('${AppConfig.baseUrl}/quizzes/$quizId')
          : Uri.parse('${AppConfig.baseUrl}/quizzes/save');

      print('API Request URL: $url');
      print(
          'Request Headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"}');
      print('Request Body: $quizData');

      final response = await (isEditing ? http.put : http.post)(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(quizData),
      );

      print('Response Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Quiz saved/updated successfully
        final responseData = jsonDecode(response.body);

        // Ensure the response contains the saved quiz data
        if (responseData is Map<String, dynamic>) {
          await fetchQuizzes();
          return responseData;
        } else {
          throw Exception('Invalid response from server after saving quiz');
        }
      } else {
        // Handle quiz save/update failure
        final errorBody = jsonDecode(response.body);
        final errorMessage = errorBody['message'] ?? 'Failed to save quiz';
        throw Exception(errorMessage);
      }
    } catch (e) {
      // Handle network or other errors
      print('Error saving quiz: $e');
      throw Exception('An error occurred while saving the quiz');
    }
  }
}
