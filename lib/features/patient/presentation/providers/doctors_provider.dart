import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eyadati/core/utils/supabase_client.dart';
import 'package:eyadati/models/doctor.dart';

const _sentinel = Object();

class DoctorsState {
  final List<Doctor> allDoctors; // Source of truth
  final List<Doctor> doctors; // Filtered/computed list
  final String searchQuery;
  final String selectedSpecialty;
  final String? selectedCity;
  final bool isLoading;
  final String? errorMessage;

  const DoctorsState({
    this.allDoctors = const [],
    this.doctors = const [],
    this.searchQuery = '',
    this.selectedSpecialty = '',
    this.selectedCity,
    this.isLoading = false,
    this.errorMessage,
  });

  DoctorsState copyWith({
    List<Doctor>? allDoctors,
    List<Doctor>? doctors,
    String? searchQuery,
    String? selectedSpecialty,
    Object? selectedCity = _sentinel,
    bool? isLoading,
    Object? errorMessage = _sentinel,
  }) {
    return DoctorsState(
      allDoctors: allDoctors ?? this.allDoctors,
      doctors: doctors ?? this.doctors,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedSpecialty: selectedSpecialty ?? this.selectedSpecialty,
      selectedCity: selectedCity == _sentinel ? this.selectedCity : selectedCity as String?,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage == _sentinel ? this.errorMessage : errorMessage as String?,
    );
  }
}

final doctorsProvider = StateNotifierProvider<DoctorsNotifier, DoctorsState>((ref) {
  return DoctorsNotifier();
});

class DoctorsNotifier extends StateNotifier<DoctorsState> {
  DoctorsNotifier() : super(const DoctorsState()) {
    loadDoctors();
  }

  Future<void> loadDoctors() async {
    state = state.copyWith(isLoading: true);
    try {
      final now = DateTime.now().toIso8601String();
      final result = await SupabaseInitializer.client
          .from('doctors')
          .select('id, specialty, city, bio, manual_pause, subscription_end, appointment_duration, consultation_duration, profiles(full_name, avatar_url, city)')
          .eq('manual_pause', false)
          .gt('subscription_end', now)
          .order('created_at', ascending: false)
          .limit(50);

      final fetchedDoctors = (result as List).map((row) {
        final profile = row['profiles'] as Map<String, dynamic>?;
        final doctor = Doctor.fromDatabase(row as Map<String, dynamic>);
        return doctor.copyWith(
          name: profile?['full_name'] as String? ?? 'Docteur',
          photoUrl: profile?['avatar_url'] as String?,
          city: (row['city'] as String?) ?? (profile?['city'] as String?),
        );
      }).toList();

      state = state.copyWith(
        isLoading: false,
        allDoctors: fetchedDoctors,
      );
      _applyFilters();
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
    _applyFilters();
  }

  void setSpecialty(String specialty) {
    state = state.copyWith(selectedSpecialty: specialty);
    _applyFilters();
  }

  void setCity(String? city) {
    state = state.copyWith(selectedCity: city);
    _applyFilters();
  }

  void clearSearch() {
    state = state.copyWith(searchQuery: '');
    _applyFilters();
  }

  void clearFilters() {
    state = state.copyWith(
      searchQuery: '',
      selectedSpecialty: '',
      selectedCity: null,
    );
    _applyFilters();
  }

  Future<void> refresh() async {
    await loadDoctors();
  }

  void _applyFilters() {
    final query = state.searchQuery.toLowerCase();
    final specialty = state.selectedSpecialty.toLowerCase();
    final city = state.selectedCity?.toLowerCase();

    final filtered = state.allDoctors.where((d) {
      final matchesQuery = query.isEmpty ||
          d.name.toLowerCase().contains(query) ||
          d.specialty.toLowerCase().contains(query) ||
          (d.city?.toLowerCase().contains(query) ?? false);
      
      final matchesSpecialty = specialty.isEmpty || d.specialty.toLowerCase() == specialty;
      
      final matchesCity = city == null || city.isEmpty || (d.city?.toLowerCase() == city);

      return matchesQuery && matchesSpecialty && matchesCity;
    }).toList();

    state = state.copyWith(doctors: filtered);
  }
}
