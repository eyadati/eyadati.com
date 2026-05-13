import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_state.dart';
import '../../../../core/utils/supabase_client.dart';
import '../../../../repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(SupabaseInitializer.client);
});

final authProvider = StateNotifierProvider<AuthNotifier, AppAuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthNotifier(repository);
});

class AuthNotifier extends StateNotifier<AppAuthState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(const AppAuthState());

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true);
    try {
      final result = await _repository.signIn(email: email, password: password);
      if (result.isSuccess) {
        final user = result.user!;
        final role = user.userMetadata?['role'] as String? ?? 'patient';
        final setupCompleted = role == 'patient' ? true : await _checkDoctorSetup(user.id);
        state = state.copyWith(
          isAuthenticated: true,
          isLoading: false,
          isInitialized: true,
          setupCompleted: setupCompleted,
          userId: user.id,
          email: email,
          role: role,
          isDoctor: role == 'doctor',
        );
        return true;
      }
      state = state.copyWith(
        isLoading: false,
        isInitialized: true,
        errorMessage: result.error ?? 'Identifiants incorrects',
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String role,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final result = await _repository.signUp(
        email: email,
        password: password,
        fullName: name,
        role: role,
      );
      if (result.isSuccess) {
        final setupCompleted = role == 'patient' ? true : false;
        state = state.copyWith(
          isAuthenticated: true,
          isLoading: false,
          isInitialized: true,
          setupCompleted: setupCompleted,
          userId: result.user?.id,
          email: email,
          role: role,
          isDoctor: role == 'doctor',
        );
        return true;
      }
      state = state.copyWith(
        isLoading: false,
        isInitialized: true,
        errorMessage: result.error ?? "Erreur lors de l'inscription",
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isInitialized: true,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  Future<void> logout() async {
    await _repository.signOut();
    state = const AppAuthState(isInitialized: true);
  }

  Future<bool> _checkDoctorSetup(String userId) async {
    try {
      final doctor = await SupabaseInitializer.client
          .from('doctors')
          .select('id')
          .eq('id', userId)
          .maybeSingle();
      return doctor != null;
    } catch (e) {
      return false;
    }
  }

  Future<void> checkAuthStatus() async {
    state = state.copyWith(isLoading: true);
    print('[AuthProvider] checkAuthStatus called');
    try {
      final user = _repository.currentUser;
      print('[AuthProvider] currentUser: ${user?.id ?? "null"}, email: ${user?.email ?? "null"}');
      if (user != null) {
        final role = user.userMetadata?['role'] as String? ?? 'patient';
        print('[AuthProvider] user role: $role');
        final setupCompleted = role == 'patient' ? true : await _checkDoctorSetup(user.id);
        print('[AuthProvider] doctor setup completed: $setupCompleted');
        state = state.copyWith(
          isAuthenticated: true,
          isLoading: false,
          isInitialized: true,
          setupCompleted: setupCompleted,
          userId: user.id,
          email: user.email,
          role: role,
          isDoctor: role == 'doctor',
        );
        print('[AuthProvider] State updated - isAuthenticated: true, isInitialized: true, setupCompleted: $setupCompleted');
      } else {
        print('[AuthProvider] No user found - setting isInitialized only');
        state = state.copyWith(
          isLoading: false,
          isInitialized: true,
        );
      }
    } catch (e) {
      print('[AuthProvider] Error in checkAuthStatus: $e');
      state = state.copyWith(
        isLoading: false,
        isInitialized: true,
      );
    }
  }

  Future<void> refreshSetupStatus() async {
    final userId = state.userId;
    if (userId == null || !state.isDoctor) return;

    final setupCompleted = await _checkDoctorSetup(userId);
    state = state.copyWith(setupCompleted: setupCompleted);
  }

  void clearError() {
    state = AppAuthState(
      isAuthenticated: state.isAuthenticated,
      isDoctor: state.isDoctor,
      isLoading: state.isLoading,
      userId: state.userId,
      email: state.email,
      role: state.role,
      setupCompleted: state.setupCompleted,
    );
  }

  Future<bool> resetPassword(String email) async {
    state = state.copyWith(isLoading: true);
    try {
      final result = await _repository.resetPassword(email);
      state = state.copyWith(isLoading: false);
      if (!result.isSuccess) {
        state = AppAuthState(
          isAuthenticated: state.isAuthenticated,
          isDoctor: state.isDoctor,
          isLoading: state.isLoading,
          errorMessage: result.error,
          userId: state.userId,
          email: state.email,
          role: state.role,
          setupCompleted: state.setupCompleted,
        );
      }
      return result.isSuccess;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }
}