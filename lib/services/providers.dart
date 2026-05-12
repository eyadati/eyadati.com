import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../repositories/repositories.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return AuthRepository(client);
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return ProfileRepository(client);
});

final doctorRepositoryProvider = Provider<DoctorRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return DoctorRepository(client);
});

final appointmentRepositoryProvider = Provider<AppointmentRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return AppointmentRepository(client);
});

final favoriteRepositoryProvider = Provider<FavoriteRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return FavoriteRepository(client);
});
