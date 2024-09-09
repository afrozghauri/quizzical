import 'package:firebase_auth/firebase_auth.dart' as fire_auth;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:frontend_quizzical/models/user.dart';
import 'package:frontend_quizzical/services/auth_service.dart';

// Create a StateNotifierProvider for managing authentication state
final authProvider =
    StateNotifierProvider<AuthProvider, User?>((ref) => AuthProvider());

class AuthProvider extends StateNotifier<User?> {
  final _secureStorage = const FlutterSecureStorage();
  static const _tokenKey = 'firebase_id_token';

  AuthProvider() : super(null) {
    _loadToken();
  }

  Future<void> _loadToken() async {
    final storedToken = await _secureStorage.read(key: _tokenKey);
    if (storedToken != null) {
      try {
        // If a token is found, try to authenticate with Firebase
        await fire_auth.FirebaseAuth.instance
            .signInWithCustomToken(storedToken);

        // Get the currently authenticated Firebase user
        final fire_auth.User? firebaseUser =
            fire_auth.FirebaseAuth.instance.currentUser;

        if (firebaseUser != null) {
          // Convert Firebase User to your custom User model using the named constructor
          final user = User(
            id: firebaseUser.uid,
            email: firebaseUser.email!,
          );
          state = user; // Update the state with your custom User object
        }
      } on fire_auth.FirebaseAuthException catch (e) {
        // Handle Firebase Authentication errors (e.g., token expired)
        print('Firebase Auth error during token loading: $e');
        // Clear the invalid token from storage
        await _secureStorage.delete(key: _tokenKey);
      }
    }
  }

  // Login method
  Future<void> login(String email, String password) async {
    try {
      final authService = AuthService();
      final idToken = await authService.login(email, password);

      if (idToken != null) {
        // Login successful, store the ID token securely
        await _secureStorage.write(key: _tokenKey, value: idToken);

        // Sign in to Firebase directly using the ID token
        await fire_auth.FirebaseAuth.instance.signInWithCustomToken(idToken);

        // Get the currently authenticated Firebase user
        final firebaseUser = fire_auth.FirebaseAuth.instance.currentUser;
        if (firebaseUser != null) {
          // Convert Firebase User to your custom User model
          final user = User(
            id: firebaseUser.uid,
            email: firebaseUser.email!,
          );
          state = user;
        } else {
          throw Exception('User not found after login');
        }
      } else {
        // Handle login failure
        throw Exception('Login failed');
      }
    } on fire_auth.FirebaseAuthException catch (e) {
      // Handle Firebase Authentication errors
      print('Firebase Auth error during login: $e');
      throw Exception('Firebase Authentication failed: ${e.message}');
    } catch (e) {
      // Handle other exceptions (including the one from AuthService)
      print('Error during login: $e');
      rethrow;
    }
  }

  // Get ID token (accessible globally)
  Future<String?> getIdToken() async {
    final fire_auth.User? user = fire_auth.FirebaseAuth.instance.currentUser;
    if (user == null) {
      return null;
    }

    try {
      return await user.getIdToken(true);
    } on fire_auth.FirebaseAuthException catch (e) {
      print('Error refreshing ID token: $e');

      // If refresh fails, try to reauthenticate silently
      if (e.code == 'firebase_auth/user-token-expired' ||
          e.code == 'firebase_auth/user-disabled') {
        try {
          await user.reload(); // Reload user data, might trigger silent refresh
          return await user.getIdToken(true);
        } catch (reloadError) {
          print('Error reloading user: $reloadError');
          // If silent refresh also fails, handle it appropriately (e.g., force re-login)
          // ... your error handling logic here
          throw Exception('Token refresh and user reload failed');
        }
      } else {
        // Handle other token refresh errors
        throw Exception('Error refreshing ID token: ${e.message}');
      }
    }
  }
}
