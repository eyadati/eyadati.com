import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/utils/input_validator.dart';
import '../core/utils/security_validator.dart';

class AuthRepository {
  final SupabaseClient _client;

  AuthRepository(this._client);

  Stream<User?> get authStateChanges => _client.auth.onAuthStateChange.map(
        (event) => event.session?.user,
      );

  User? get currentUser => _client.auth.currentUser;

  bool get isAuthenticated => currentUser != null;

  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    final emailError = InputValidator.validateEmail(email);
    if (emailError != null) {
      return AuthResult.failure(emailError);
    }

    final passwordError = InputValidator.validatePassword(password);
    if (passwordError != null) {
      return AuthResult.failure(passwordError);
    }

    try {
      final response = await _client.auth.signInWithPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );

      if (response.user == null) {
        return AuthResult.failure('Invalid email or password');
      }

      return AuthResult.success(response.user!);
    } on AuthException catch (e) {
      return AuthResult.failure(_mapAuthError(e.message));
    } catch (e) {
      return AuthResult.failure('Connection error. Please try again.');
    }
  }

  Future<AuthResult> signUp({
    required String email,
    required String password,
    required String fullName,
    required String role,
    String? phone,
  }) async {
    final emailError = InputValidator.validateEmail(email);
    if (emailError != null) {
      return AuthResult.failure(emailError);
    }

    final passwordError = InputValidator.validatePassword(password);
    if (passwordError != null) {
      return AuthResult.failure(passwordError);
    }

    final nameError = InputValidator.validateFullName(fullName);
    if (nameError != null) {
      return AuthResult.failure(nameError);
    }

    if (role != 'patient' && role != 'doctor') {
      return AuthResult.failure('Invalid role. Must be patient or doctor.');
    }

    try {
      final sanitizedName = SecurityValidator.sanitizeHtml(fullName.trim());

      final metadata = <String, dynamic>{
        'full_name': sanitizedName,
        'role': role,
      };
      if (phone != null && phone.trim().isNotEmpty) {
        metadata['phone'] = phone.trim();
      }

      final response = await _client.auth.signUp(
        email: email.trim().toLowerCase(),
        password: password,
        data: metadata,
      );

      if (response.user == null) {
        return AuthResult.failure('Registration failed. Please try again.');
      }

      return AuthResult.success(response.user!);
    } on AuthException catch (e) {
      return AuthResult.failure(_mapAuthError(e.message));
    } catch (e) {
      return AuthResult.failure('Connection error. Please try again.');
    }
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<AuthResult> resetPassword(String email) async {
    final emailError = InputValidator.validateEmail(email);
    if (emailError != null) {
      return AuthResult.failure(emailError);
    }

    try {
      await _client.auth.resetPasswordForEmail(email.trim().toLowerCase());
      return AuthResult.success(null);
    } on AuthException catch (e) {
      return AuthResult.failure(_mapAuthError(e.message));
    } catch (e) {
      return AuthResult.failure('Connection error. Please try again.');
    }
  }

  String _mapAuthError(String message) {
    final lowerMessage = message.toLowerCase();
    if (lowerMessage.contains('invalid login credentials')) {
      return 'Invalid email or password';
    } else if (lowerMessage.contains('already registered')) {
      return 'This email is already registered';
    } else if (lowerMessage.contains('password')) {
      return 'Password must be at least 6 characters';
    } else if (lowerMessage.contains('email')) {
      return 'Please enter a valid email address';
    }
    return message;
  }
}

class AuthResult {
  final bool isSuccess;
  final User? user;
  final String? error;

  AuthResult._({
    required this.isSuccess,
    this.user,
    this.error,
  });

  factory AuthResult.success(User? user) {
    return AuthResult._(isSuccess: true, user: user);
  }

  factory AuthResult.failure(String error) {
    return AuthResult._(isSuccess: false, error: error);
  }
}
