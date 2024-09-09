import 'package:flutter/material.dart';
import 'package:frontend_quizzical/screens/login_screen.dart';
import 'package:frontend_quizzical/screens/quiz_list_screen.dart';
import 'package:frontend_quizzical/screens/quiz_create_edit_screen.dart';

// Define your app's routes here (initially empty)
final Map<String, WidgetBuilder> routes = {
  '/login': (context) => const LoginScreen(),
  '/quiz-list': (context) => const QuizListScreen(),
  '/quiz-create-edit': (context) => const QuizCreateEditScreen(),

  // You'll add routes here as you create new screens
};
