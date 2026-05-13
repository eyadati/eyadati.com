import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eyadati/core/utils/supabase_client.dart';

class DoctorsState {
  final List<Doctor> doctors;
  final String searchQuery;
  final String selectedSpecialty;
  final bool isLoading;
  final String? errorMessage;

  const DoctorsState({
    this.doctors = const [],
    this.searchQuery = '',
    this.selectedSpecialty = '',
    this.isLoading = false,
    this.errorMessage,
  });

  DoctorsState copyWith({
    List<Doctor>? doctors,
    String? searchQuery,
    String? selectedSpecialty,
    bool? isLoading,
    String? errorMessage,
  }) {
    return DoctorsState(
      doctors: doctors ?? this.doctors,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedSpecialty: selectedSpecialty ?? this.selectedSpecialty,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class Doctor {
  final String id;
  final String name;
  final String specialty;
  final String? avatarUrl;
  final double rating;
  final int reviewCount;
  final int experienceYears;
  final String? location;
  final String? bio;
  final double consultationFee;
  final List<String> availableDays;
  final String? startTime;
  final String? endTime;
  final int appointmentDuration;
  final int consultationDuration;

  Doctor({
    required this.id,
    required this.name,
    required this.specialty,
    this.avatarUrl,
    this.rating = 4.5,
    this.reviewCount = 0,
    this.experienceYears = 0,
    this.location,
    this.bio,
    this.consultationFee = 0,
    this.availableDays = const [],
    this.startTime,
    this.endTime,
    this.appointmentDuration = 20,
    this.consultationDuration = 30,
  });

  factory Doctor.fromMap(Map<String, dynamic> map) {
    final profile = map['profiles'] as Map<String, dynamic>?;
    final days = (map['available_days'] as String?)?.split(',').where((d) => d.isNotEmpty).toList() ?? [];
    return Doctor(
      id: map['id'] as String,
      name: profile?['full_name'] as String? ?? 'Docteur',
      specialty: map['specialty'] as String? ?? 'Médecine générale',
      avatarUrl: profile?['avatar_url'] as String?,
      rating: (map['rating'] as num?)?.toDouble() ?? 4.5,
      reviewCount: map['review_count'] as int? ?? 0,
      experienceYears: map['experience_years'] as int? ?? 0,
      location: profile?['city'] as String?,
      bio: map['bio'] as String?,
      consultationFee: (map['consultation_fee'] as num?)?.toDouble() ?? 0,
      availableDays: days,
      startTime: map['opening_at'] as String?,
      endTime: map['closing_at'] as String?,
      appointmentDuration: map['appointment_duration'] as int? ?? 20,
      consultationDuration: map['consultation_duration'] as int? ?? 30,
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
      final result = await SupabaseInitializer.client
          .from('doctors')
          .select('id, specialty, consultation_fee, experience_years, bio, opening_at, closing_at, rating, review_count, profiles(full_name, avatar_url, city)')
          .order('rating', ascending: false)
          .limit(50);

      final doctors = (result as List).map((row) => Doctor.fromMap(row as Map<String, dynamic>)).toList();

      state = state.copyWith(
        isLoading: false,
        doctors: doctors,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  void searchDoctors(String query) {
    state = state.copyWith(searchQuery: query);
    _filterDoctors();
  }

  void filterBySpecialty(String specialty) {
    state = state.copyWith(selectedSpecialty: specialty);
    _filterDoctors();
  }

  Future<void> _filterDoctors() async {
    await loadDoctors();
    final query = state.searchQuery.toLowerCase();
    final specialty = state.selectedSpecialty;
    final allDoctors = state.doctors;

    final filtered = allDoctors.where((d) {
      final matchesQuery = query.isEmpty ||
          d.name.toLowerCase().contains(query) ||
          d.specialty.toLowerCase().contains(query) ||
          (d.location?.toLowerCase().contains(query) ?? false);
      final matchesSpecialty = specialty.isEmpty || d.specialty == specialty;
      return matchesQuery && matchesSpecialty;
    }).toList();

    state = state.copyWith(doctors: filtered);
  }

  Future<void> refresh() async {
    state = state.copyWith(searchQuery: '', selectedSpecialty: '');
    await loadDoctors();
  }

  Doctor? getDoctorById(String id) {
    try {
      return state.doctors.firstWhere((d) => d.id == id);
    } catch (_) {
      return null;
    }
  }

  void clearError() {
    state = DoctorsState(
      doctors: state.doctors,
      searchQuery: state.searchQuery,
      selectedSpecialty: state.selectedSpecialty,
      isLoading: state.isLoading,
    );
  }
}