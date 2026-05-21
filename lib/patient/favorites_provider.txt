import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eyadati/core/utils/supabase_client.dart';
import 'package:eyadati/features/auth/presentation/providers/auth_provider.dart';

class FavoritesState {
  final List<String> favoriteDoctorIds;
  final bool isLoading;
  final String? errorMessage;

  const FavoritesState({
    this.favoriteDoctorIds = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  FavoritesState copyWith({
    List<String>? favoriteDoctorIds,
    bool? isLoading,
    String? errorMessage,
  }) {
    return FavoritesState(
      favoriteDoctorIds: favoriteDoctorIds ?? this.favoriteDoctorIds,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

final favoritesProvider = StateNotifierProvider<FavoritesNotifier, FavoritesState>((ref) {
  return FavoritesNotifier(ref);
});

class FavoritesNotifier extends StateNotifier<FavoritesState> {
  final Ref _ref;

  FavoritesNotifier(this._ref) : super(const FavoritesState());

  Future<void> loadFavorites() async {
    state = state.copyWith(isLoading: true);
    try {
      final authState = _ref.read(authProvider);
      final userId = authState.userId;
      if (userId == null) {
        state = state.copyWith(isLoading: false);
        return;
      }

      final result = await SupabaseInitializer.client
          .from('favorites')
          .select('doctor_id')
          .eq('patient_id', userId);

      final ids = (result as List).map((row) => row['doctor_id'] as String).toList();
      state = state.copyWith(
        isLoading: false,
        favoriteDoctorIds: ids,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  bool isFavorite(String doctorId) {
    return state.favoriteDoctorIds.contains(doctorId);
  }

  Future<void> toggleFavorite(String doctorId) async {
    try {
      final authState = _ref.read(authProvider);
      final userId = authState.userId;
      if (userId == null) return;

      if (isFavorite(doctorId)) {
        await SupabaseInitializer.client
            .from('favorites')
            .delete()
            .eq('patient_id', userId)
            .eq('doctor_id', doctorId);
        state = state.copyWith(
          favoriteDoctorIds: state.favoriteDoctorIds.where((id) => id != doctorId).toList(),
        );
      } else {
        await SupabaseInitializer.client
            .from('favorites')
            .insert({'patient_id': userId, 'doctor_id': doctorId});
        state = state.copyWith(
          favoriteDoctorIds: [...state.favoriteDoctorIds, doctorId],
        );
      }
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> refresh() async {
    await loadFavorites();
  }
}