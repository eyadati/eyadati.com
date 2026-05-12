import 'package:flutter_riverpod/flutter_riverpod.dart';

class PatientState {
  final String name;
  final String email;
  final String phone;
  final String avatarUrl;
  final int upcomingCount;
  final int favoritesCount;
  final List<Appointment> upcomingAppointments;
  final bool isLoading;
  final String? errorMessage;

  const PatientState({
    this.name = '',
    this.email = '',
    this.phone = '',
    this.avatarUrl = '',
    this.upcomingCount = 0,
    this.favoritesCount = 0,
    this.upcomingAppointments = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  PatientState copyWith({
    String? name,
    String? email,
    String? phone,
    String? avatarUrl,
    int? upcomingCount,
    int? favoritesCount,
    List<Appointment>? upcomingAppointments,
    bool? isLoading,
    String? errorMessage,
  }) {
    return PatientState(
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      upcomingCount: upcomingCount ?? this.upcomingCount,
      favoritesCount: favoritesCount ?? this.favoritesCount,
      upcomingAppointments: upcomingAppointments ?? this.upcomingAppointments,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class Appointment {
  final String id;
  final String doctorId;
  final String doctorName;
  final String doctorSpecialty;
  final String? doctorAvatar;
  final DateTime dateTime;
  final int duration;
  final String status;
  final bool isConsultation;
  final String? notes;

  Appointment({
    required this.id,
    required this.doctorId,
    required this.doctorName,
    required this.doctorSpecialty,
    this.doctorAvatar,
    required this.dateTime,
    required this.duration,
    required this.status,
    this.isConsultation = false,
    this.notes,
  });
}

final patientProvider = StateNotifierProvider<PatientNotifier, PatientState>((ref) {
  return PatientNotifier();
});

class PatientNotifier extends StateNotifier<PatientState> {
  PatientNotifier() : super(const PatientState());

  Future<void> loadPatientData() async {
    state = state.copyWith(isLoading: true);
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      state = state.copyWith(
        isLoading: false,
        name: 'Ahmed Benali',
        email: 'ahmed@example.com',
        phone: '0612345678',
        upcomingCount: 2,
        favoritesCount: 3,
        upcomingAppointments: [
          Appointment(
            id: '1',
            doctorId: 'd1',
            doctorName: 'Dr. Fatima Zahra',
            doctorSpecialty: 'Cardiologie',
            dateTime: DateTime.now().add(const Duration(days: 2, hours: 10)),
            duration: 30,
            status: 'confirmed',
            isConsultation: true,
          ),
          Appointment(
            id: '2',
            doctorId: 'd2',
            doctorName: 'Dr. Youssef Amrani',
            doctorSpecialty: 'Généraliste',
            dateTime: DateTime.now().add(const Duration(days: 5, hours: 14)),
            duration: 20,
            status: 'pending',
            isConsultation: false,
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

  Future<void> refreshAppointments() async {
    await loadPatientData();
  }

  void clearError() {
    state = PatientState(
      name: state.name,
      email: state.email,
      phone: state.phone,
      avatarUrl: state.avatarUrl,
      upcomingCount: state.upcomingCount,
      favoritesCount: state.favoritesCount,
      upcomingAppointments: state.upcomingAppointments,
      isLoading: state.isLoading,
    );
  }
}