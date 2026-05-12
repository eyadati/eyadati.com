import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  });
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
      await Future.delayed(const Duration(milliseconds: 500));
      state = state.copyWith(
        isLoading: false,
        doctors: [
          Doctor(
            id: 'd1',
            name: 'Dr. Fatima Zahra',
            specialty: 'Cardiologie',
            rating: 4.8,
            reviewCount: 124,
            experienceYears: 12,
            location: 'Casablanca',
            consultationFee: 350,
            availableDays: ['Lun', 'Mer', 'Ven'],
          ),
          Doctor(
            id: 'd2',
            name: 'Dr. Youssef Amrani',
            specialty: 'Médecine générale',
            rating: 4.6,
            reviewCount: 89,
            experienceYears: 8,
            location: 'Rabat',
            consultationFee: 250,
            availableDays: ['Mar', 'Jeu', 'Sam'],
          ),
          Doctor(
            id: 'd3',
            name: 'Dr. Aicha Benjelloun',
            specialty: 'Dermatologie',
            rating: 4.9,
            reviewCount: 156,
            experienceYears: 15,
            location: 'Marrakech',
            consultationFee: 400,
            availableDays: ['Lun', 'Mar', 'Mer'],
          ),
          Doctor(
            id: 'd4',
            name: 'Dr. Hassan Tazi',
            specialty: 'Orthopédie',
            rating: 4.7,
            reviewCount: 78,
            experienceYears: 10,
            location: 'Casablanca',
            consultationFee: 450,
            availableDays: ['Dim', 'Mer', 'Ven'],
          ),
          Doctor(
            id: 'd5',
            name: 'Dr. Sara Idrissi',
            specialty: 'Pédiatrie',
            rating: 4.9,
            reviewCount: 201,
            experienceYears: 14,
            location: 'Fès',
            consultationFee: 300,
            availableDays: ['Lun', 'Mer', 'Jeu', 'Sam'],
          ),
        ],
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
  }

  void filterBySpecialty(String specialty) {
    state = state.copyWith(selectedSpecialty: specialty);
  }

  Future<void> refresh() async {
    await loadDoctors();
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