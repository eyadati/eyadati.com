import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eyadati/core/utils/supabase_client.dart';
import 'package:eyadati/features/auth/presentation/providers/auth_provider.dart';

class PatientState {
  final String name;
  final String email;
  final String phone;
  final String avatarUrl;
  final int upcomingCount;
  final int favoritesCount;
  final List<Appointment> upcomingAppointments;
  final List<Appointment> pastAppointments;
  final List<Appointment> cancelledAppointments;
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
    this.pastAppointments = const [],
    this.cancelledAppointments = const [],
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
    List<Appointment>? pastAppointments,
    List<Appointment>? cancelledAppointments,
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
      pastAppointments: pastAppointments ?? this.pastAppointments,
      cancelledAppointments: cancelledAppointments ?? this.cancelledAppointments,
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

  factory Appointment.fromMap(Map<String, dynamic> map, String doctorName, String doctorSpecialty, String? doctorAvatar) {
    return Appointment(
      id: map['id'] as String,
      doctorId: map['doctor_id'] as String,
      doctorName: doctorName,
      doctorSpecialty: doctorSpecialty,
      doctorAvatar: doctorAvatar,
      dateTime: DateTime.parse(map['scheduled_at'] as String),
      duration: map['duration'] as int? ?? 30,
      status: map['status'] as String? ?? 'pending',
      isConsultation: map['appointment_type'] == 'consultation',
      notes: map['notes'] as String?,
    );
  }
}

final patientProvider = StateNotifierProvider<PatientNotifier, PatientState>((ref) {
  return PatientNotifier(ref);
});

class PatientNotifier extends StateNotifier<PatientState> {
  final Ref _ref;

  PatientNotifier(this._ref) : super(const PatientState());

  Future<void> loadPatientData() async {
    state = state.copyWith(isLoading: true);
    try {
      final authState = _ref.read(authProvider);
      final userId = authState.userId;
      if (userId == null) {
        state = state.copyWith(isLoading: false);
        return;
      }

      final profileResult = await SupabaseInitializer.client
          .from('profiles')
          .select('full_name, email, phone, avatar_url')
          .eq('id', userId)
          .maybeSingle();

      final now = DateTime.now();
      final appointmentsResult = await SupabaseInitializer.client
          .from('appointments')
          .select('id, doctor_id, scheduled_at, duration, status, appointment_type, notes, doctors(full_name, specialty, avatar_url)')
          .eq('patient_id', userId)
          .order('scheduled_at', ascending: false)
          .limit(50);

      final favoritesResult = await SupabaseInitializer.client
          .from('favorites')
          .select('id')
          .eq('patient_id', userId);

      List<Appointment> upcoming = [];
      List<Appointment> past = [];
      List<Appointment> cancelled = [];

      for (final row in appointmentsResult) {
        final docMap = row['doctors'] as Map<String, dynamic>?;
        final doctorName = docMap?['full_name'] as String? ?? 'Docteur';
        final doctorSpecialty = docMap?['specialty'] as String? ?? '';
        final doctorAvatar = docMap?['avatar_url'] as String?;

        final apt = Appointment(
          id: row['id'] as String,
          doctorId: row['doctor_id'] as String,
          doctorName: doctorName,
          doctorSpecialty: doctorSpecialty,
          doctorAvatar: doctorAvatar,
          dateTime: DateTime.parse(row['scheduled_at'] as String),
          duration: row['duration'] as int? ?? 30,
          status: row['status'] as String? ?? 'pending',
          isConsultation: row['appointment_type'] == 'consultation',
          notes: row['notes'] as String?,
        );

        if (row['status'] == 'cancelled') {
          cancelled.add(apt);
        } else if (apt.dateTime.isAfter(now)) {
          upcoming.add(apt);
        } else {
          past.add(apt);
        }
      }

      state = state.copyWith(
        isLoading: false,
        name: profileResult?['full_name'] as String? ?? '',
        email: profileResult?['email'] as String? ?? '',
        phone: profileResult?['phone'] as String? ?? '',
        avatarUrl: profileResult?['avatar_url'] as String? ?? '',
        upcomingCount: upcoming.length,
        favoritesCount: (favoritesResult as List).length,
        upcomingAppointments: upcoming,
        pastAppointments: past,
        cancelledAppointments: cancelled,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<bool> cancelAppointment(String appointmentId) async {
    try {
      await SupabaseInitializer.client
          .from('appointments')
          .update({'status': 'cancelled'})
          .eq('id', appointmentId);
      await loadPatientData();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> refreshAppointments() async {
    await loadPatientData();
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}