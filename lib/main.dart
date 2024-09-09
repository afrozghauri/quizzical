import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:frontend_quizzical/config/app_config.dart';
import 'firebase_options.dart';
import 'package:frontend_quizzical/routes/app_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uni_links/uni_links.dart';
import 'package:frontend_quizzical/screens/quiz_taking_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Future to handle initial link and set initial route
  Future<String?> handleInitialLink() async {
    try {
      final initialLink = await getInitialLink();
      if (initialLink != null) {
        final uri = Uri.parse(initialLink); // Parse the initialLink into a Uri
        handleIncomingLink(uri); // Pass the Uri to handleIncomingLink
        return uri.pathSegments.last; // Extract permalink or return null
      } else {
        return null;
      }
    } on PlatformException {
      // Handle platform-specific errors
      print('Error getting initial link');
      return null;
    }
  }

  linkStream.listen((String? link) {
    if (link != null) {
      handleIncomingLink(Uri.parse(link)); // Parse link into Uri before passing
    }
  }, onError: (err) {
    print('Error handling incoming link: $err');
  });

  // Use FutureBuilder to wait for initialLink handling
  runApp(
    ProviderScope(
      child: FutureBuilder<String?>(
        future: handleInitialLink(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const MaterialApp(
                home:
                    Scaffold(body: Center(child: CircularProgressIndicator())));
          } else if (snapshot.hasError) {
            return MaterialApp(
                home: Scaffold(
                    body: Center(child: Text('Error: ${snapshot.error}'))));
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
void handleIncomingLink(Uri uri) {
  // Change parameter type to Uri

  // Check if the scheme and host match your app configuration
  if (uri.scheme == 'quizzical' &&
      uri.host == AppConfig.baseUrl.replaceFirst('http://', '')) {
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
