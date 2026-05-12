import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../models/doctor.dart';
import '../../../../repositories/favorite_repository.dart';
import '../../../../services/providers.dart';

final favoritesProvider = FutureProvider<List<Doctor>>((ref) async {
  final repository = ref.watch(favoriteRepositoryProvider);
  return repository.getFavorites();
});

final isFavoriteProvider = FutureProvider.family<bool, String>((ref, doctorId) async {
  final repository = ref.watch(favoriteRepositoryProvider);
  return repository.isFavorite(doctorId);
});

class FavoriteNotifier extends StateNotifier<AsyncValue<void>> {
  final FavoriteRepository _repository;

  FavoriteNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<bool> toggleFavorite(String doctorId) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repository.toggleFavorite(doctorId);
      state = const AsyncValue.data(null);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> addFavorite(String doctorId) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repository.addFavorite(doctorId);
      state = const AsyncValue.data(null);
      return result.isSuccess;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> removeFavorite(String doctorId) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repository.removeFavorite(doctorId);
      state = const AsyncValue.data(null);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final favoriteNotifierProvider = StateNotifierProvider<FavoriteNotifier, AsyncValue<void>>((ref) {
  final repository = ref.watch(favoriteRepositoryProvider);
  return FavoriteNotifier(repository);
});
