import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/doctor.dart';

class FavoriteRepository {
  final SupabaseClient _client;

  FavoriteRepository(this._client);

  Future<List<Doctor>> getFavorites() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _client
          .from('favorites')
          .select('doctor_id, doctors(*)')
          .eq('patient_id', userId)
          .order('created_at', ascending: false);

      final favorites = <Doctor>[];
      for (final item in response as List) {
        final doctorData = item['doctors'] as Map<String, dynamic>?;
        if (doctorData != null) {
          favorites.add(Doctor.fromDatabase(doctorData));
        }
      }
      return favorites;
    } catch (e) {
      return [];
    }
  }

  Future<bool> isFavorite(String doctorId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return false;

      final response = await _client
          .from('favorites')
          .select('patient_id')
          .eq('patient_id', userId)
          .eq('doctor_id', doctorId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      return false;
    }
  }

  Future<FavoriteResult> addFavorite(String doctorId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        return FavoriteResult.failure('User not authenticated');
      }

      await _client.from('favorites').insert({
        'patient_id': userId,
        'doctor_id': doctorId,
      });

      return FavoriteResult.success();
    } catch (e) {
      return FavoriteResult.failure('Failed to add favorite');
    }
  }

  Future<bool> removeFavorite(String doctorId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return false;

      await _client
          .from('favorites')
          .delete()
          .eq('patient_id', userId)
          .eq('doctor_id', doctorId);

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> toggleFavorite(String doctorId) async {
    final isFav = await isFavorite(doctorId);
    if (isFav) {
      final result = await removeFavorite(doctorId);
      return !result;
    } else {
      final result = await addFavorite(doctorId);
      return result.isSuccess;
    }
  }

  Future<int> getFavoritesCount() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return 0;

      final response = await _client
          .from('favorites')
          .select()
          .eq('patient_id', userId);

      return (response as List).length;
    } catch (e) {
      return 0;
    }
  }
}

class FavoriteResult {
  final bool isSuccess;
  final String? error;

  FavoriteResult._({
    required this.isSuccess,
    this.error,
  });

  factory FavoriteResult.success() {
    return FavoriteResult._(isSuccess: true);
  }

  factory FavoriteResult.failure(String error) {
    return FavoriteResult._(isSuccess: false, error: error);
  }
}
