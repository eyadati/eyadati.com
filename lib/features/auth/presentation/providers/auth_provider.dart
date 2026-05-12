import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum UserRole { patient, doctor, none }

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final authStateProvider = StreamProvider<AuthState>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client.auth.onAuthStateChange;
});

final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (state) => state.session?.user,
    loading: () => null,
    error: (_, __) => null,
  );
});

final userRoleProvider = FutureProvider<UserRole>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return UserRole.none;

  final client = ref.read(supabaseClientProvider);
  final response = await client
      .from('profiles')
      .select('role')
      .eq('id', user.id)
      .maybeSingle();

  if (response == null) return UserRole.none;

  final role = response['role'] as String?;
  switch (role) {
    case 'patient':
      return UserRole.patient;
    case 'doctor':
      return UserRole.doctor;
    default:
      return UserRole.none;
  }
});

class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  final SupabaseClient _client;

  AuthNotifier(this._client) : super(const AsyncValue.data(null));

  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      state = AsyncValue.data(response.user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signUp(String email, String password, String fullName, String role) async {
    state = const AsyncValue.loading();
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'role': role,
        },
      );
      state = AsyncValue.data(response.user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
    state = const AsyncValue.data(null);
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AsyncValue<User?>>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return AuthNotifier(client);
});
