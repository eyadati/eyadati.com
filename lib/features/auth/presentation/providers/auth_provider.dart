import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../models/profile.dart';
import '../../../../repositories/auth_repository.dart';
import '../../../../services/providers.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final User? user;
  final Profile? profile;
  final String? error;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.profile,
    this.error,
  });

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    Profile? profile,
    String? error,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      profile: profile ?? this.profile,
      error: error,
    );
  }

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isDoctor => profile?.role == 'doctor';
  bool get isPatient => profile?.role == 'patient';
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;
  final Ref _ref;

  AuthNotifier(this._authRepository, this._ref) : super(const AuthState()) {
    _initAuth();
  }

  void _initAuth() {
    _authRepository.authStateChanges.listen((user) async {
      if (user != null) {
        await _loadProfile(user);
      } else {
        state = const AuthState(status: AuthStatus.unauthenticated);
      }
    });

    final currentUser = _authRepository.currentUser;
    if (currentUser != null) {
      _loadProfile(currentUser);
    } else {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> _loadProfile(User user) async {
    try {
      final profileRepo = _ref.read(profileRepositoryProvider);
      final profile = await profileRepo.getProfile(user.id);
      state = AuthState(
        status: AuthStatus.authenticated,
        user: user,
        profile: profile,
      );
    } catch (e) {
      state = AuthState(
        status: AuthStatus.authenticated,
        user: user,
        error: 'Failed to load profile',
      );
    }
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(status: AuthStatus.loading);

    final result = await _authRepository.signIn(
      email: email,
      password: password,
    );

    if (result.isSuccess) {
      await _loadProfile(result.user!);
      return true;
    } else {
      state = state.copyWith(
        status: AuthStatus.error,
        error: result.error,
      );
      return false;
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
    required String role,
  }) async {
    state = state.copyWith(status: AuthStatus.loading);

    final result = await _authRepository.signUp(
      email: email,
      password: password,
      fullName: fullName,
      role: role,
    );

    if (result.isSuccess) {
      await _loadProfile(result.user!);
      return true;
    } else {
      state = state.copyWith(
        status: AuthStatus.error,
        error: result.error,
      );
      return false;
    }
  }

  Future<void> signOut() async {
    await _authRepository.signOut();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  void clearError() {
    if (state.status == AuthStatus.error) {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> refreshProfile() async {
    final user = _authRepository.currentUser;
    if (user != null) {
      await _loadProfile(user);
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return AuthNotifier(authRepo, ref);
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuthenticated;
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authProvider).user;
});

final currentProfileProvider = Provider<Profile?>((ref) {
  return ref.watch(authProvider).profile;
});

final userRoleProvider = Provider<UserRole?>((ref) {
  final profile = ref.watch(currentProfileProvider);
  if (profile == null) return null;
  return UserRole.fromString(profile.role);
});
