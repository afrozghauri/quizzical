import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend_quizzical/config/app_config.dart';

class AuthService {
  // Login Method
  Future<String?> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      print('Response status code: ${response.statusCode}');
      if (response.statusCode == 201) {
        // Login successful
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData.containsKey('token') &&
            responseData['token'] != null) {
          final token = responseData['token'] as String;
          print('Login successful');
          return token;
        } else {
          throw Exception('token is missing or null in the login response');
        }
      } else if (response.statusCode == 401) {
        // Handle 401 Unauthorized (invalid credentials)
        final Map<String, dynamic> errorBody = jsonDecode(response.body);
        final errorMessage =
            errorBody['message'] ?? 'Invalid email or password';
        throw Exception(errorMessage);
      } else if (response.statusCode == 400) {
        final Map<String, dynamic> errorBody = jsonDecode(response.body);
        final errorMessage = errorBody['message'] ?? 'Invalid request data';
        throw Exception(errorMessage);
      } else {
        // Handl}e other errors (e.g., 500 Internal Server Error)
        throw Exception(
            'An error occurred during login. Please try again later.');
      }
    } on http.ClientException catch (e) {
      // Handle network errors (e.g., no internet connection)
      print('Network error during login: $e');
      throw Exception(
          'No internet connection. Please check your network settings.');
    } on FormatException catch (e) {
      // Handle JSON parsing errors
      print('JSON parsing error during login: $e');
      throw Exception('Invalid response from the server.');
    } catch (e) {
      // Handle other unexpected errors
      print('Unexpected error during login: $e');
      throw Exception(
          'An unexpected error occurred during login. Please try again later.');
    }
  }
}
