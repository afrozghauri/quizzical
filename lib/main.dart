import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:frontend_quizzical/firebase_options.dart';
import 'package:frontend_quizzical/routes/app_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend_quizzical/screens/quiz_taking_screen.dart';
import 'package:url_launcher/url_launcher.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Use FutureBuilder to wait for initial link handling
  runApp(
    ProviderScope(
      child: FutureBuilder<String?>(
        future: handleInitialLink(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const MaterialApp(
              home: Scaffold(body: Center(child: CircularProgressIndicator())),
            );
          } else if (snapshot.hasError) {
            return MaterialApp(
              home: Scaffold(
                body: Center(
                  child: Text('Error: ${snapshot.error}'),
                ),
              ),
            );
          } else {
            final initialPermalink = snapshot.data;
            return MyApp(initialPermalink: initialPermalink);
          }
        },
      ),
    ),
  );
}

// Create a GlobalKey for the Navigator
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Function to handle incoming links (both initial and while app is running)
Future<String?> handleInitialLink() async {
  // Get the initial link using your platform-specific method (e.g., deep_links package)
  final Uri? uri = await getInitialLink();

  if (uri != null) {
    handleIncomingLink(uri);
    return uri.pathSegments.last;
  } else {
    return null;
  }
}

// Function to retrieve the initial link (platform-specific implementation needed)
Future<Uri?> getInitialLink() async {
  // Replace this with your platform-specific logic to get the initial link
  // (e.g., using deep_links package or similar)
  print('** Implement platform-specific logic to get initial link here **');
  return null; // Placeholder until you implement the logic
}

// Function to handle incoming links (both initial and while app is running)
void handleIncomingLink(Uri uri) {
  // Check if the scheme and host match your app configuration
  if (uri.scheme == 'https' && uri.host == 'your_app_domain') {
    // Update with your actual app domain
    final pathSegments = uri.pathSegments;

    // Check for the /quizzes/<quiz_id> format
    if (pathSegments.isNotEmpty && pathSegments[0] == 'quizzes') {
      final permalink = pathSegments[1];

      // Navigate to QuizTakingScreen with the permalink
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => QuizTakingScreen(permalink: permalink),
        ),
      );
    } else {
      // Handle other deep link paths or invalid links
      print('Invalid deep link path: ${uri.path}');
    }
  } else {
    // Handle external links (not from your app domain)
    launch(uri.toString());
  }
}

class MyApp extends StatelessWidget {
  final String? initialPermalink;

  MyApp({super.key, this.initialPermalink});

  final ThemeData _appTheme = ThemeData(
    primarySwatch: Colors.blue,
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Quizzical',
      theme: _appTheme,
      initialRoute: initialPermalink != null
          ? '/quiz-taking/$initialPermalink'
          : '/login',
      onGenerateRoute: (settings) {
        if (settings.name?.startsWith('/quiz-taking/') == true) {
          final permalink = settings.name!.split('/').last;
          return MaterialPageRoute(
            builder: (_) => QuizTakingScreen(permalink: permalink),
          );
        }
        return null;
      },
      routes: routes,
    );
  }
}
