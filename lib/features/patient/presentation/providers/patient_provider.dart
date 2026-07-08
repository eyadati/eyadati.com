import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eyadati/core/utils/supabase_client.dart';
import 'package:eyadati/features/auth/presentation/providers/auth_provider.dart';
import 'package:eyadati/repositories/profile_repository.dart';
import 'package:eyadati/services/local_notification_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PatientState {
  final String name;
  final String email;
  final String phone;
  final String city;
  final String avatarUrl;
  final int upcomingCount;
  final int favoritesCount;
  final int noShowCount;
  final int globalPresentCount;
  final int globalNoShowCount;
  final List<PatientAppointmentViewModel> upcomingAppointments;
  final List<PatientAppointmentViewModel> pastAppointments;
  final List<PatientAppointmentViewModel> cancelledAppointments;
  final bool isLoading;
  final String? errorMessage;

  const PatientState({
    this.name = '',
    this.email = '',
    this.phone = '',
    this.city = '',
    this.avatarUrl = '',
    this.upcomingCount = 0,
    this.favoritesCount = 0,
    this.noShowCount = 0,
    this.globalPresentCount = 0,
    this.globalNoShowCount = 0,
    this.upcomingAppointments = const [],
    this.pastAppointments = const [],
    this.cancelledAppointments = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  static const double _bayesianPrior = 1.0;
  static const int _minHistory = 3;

  int get totalGlobalAppts => globalPresentCount + globalNoShowCount;
  bool get hasSufficientHistory => totalGlobalAppts >= _minHistory;
  double get attendanceRate {
    final total = totalGlobalAppts;
    if (total == 0) return 1.0;
    return (globalPresentCount + _bayesianPrior) / (total + _bayesianPrior);
  }

  PatientState copyWith({
    String? name,
    String? email,
    String? phone,
    String? city,
    String? avatarUrl,
    int? upcomingCount,
    int? favoritesCount,
    int? noShowCount,
    int? globalPresentCount,
    int? globalNoShowCount,
    List<PatientAppointmentViewModel>? upcomingAppointments,
    List<PatientAppointmentViewModel>? pastAppointments,
    List<PatientAppointmentViewModel>? cancelledAppointments,
    bool? isLoading,
    String? errorMessage,
  }) {
    return PatientState(
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      city: city ?? this.city,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      upcomingCount: upcomingCount ?? this.upcomingCount,
      favoritesCount: favoritesCount ?? this.favoritesCount,
      noShowCount: noShowCount ?? this.noShowCount,
      globalPresentCount: globalPresentCount ?? this.globalPresentCount,
      globalNoShowCount: globalNoShowCount ?? this.globalNoShowCount,
      upcomingAppointments: upcomingAppointments ?? this.upcomingAppointments,
      pastAppointments: pastAppointments ?? this.pastAppointments,
      cancelledAppointments:
          cancelledAppointments ?? this.cancelledAppointments,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class PatientAppointmentViewModel {
  final String id;
  final String doctorId;
  final String doctorName;
  final String doctorSpecialty;
  final String? doctorAvatar;
  final String? doctorAddress;
  final String? doctorPhone;
  final String? mapsLink;
  final DateTime dateTime;
  final int duration;
  final String status;
  final bool isConsultation;
  final String? notes;

  PatientAppointmentViewModel({
    required this.id,
    required this.doctorId,
    required this.doctorName,
    required this.doctorSpecialty,
    this.doctorAvatar,
    this.doctorAddress,
    this.doctorPhone,
    this.mapsLink,
    required this.dateTime,
    required this.duration,
    required this.status,
    this.isConsultation = false,
    this.notes,
  });

  factory PatientAppointmentViewModel.fromMap(
    Map<String, dynamic> map,
    String doctorName,
    String doctorSpecialty,
    String? doctorAvatar,
    String? doctorAddress,
    String? doctorPhone,
    String? mapsLink,
  ) {
    return PatientAppointmentViewModel(
      id: map['id'] as String,
      doctorId: map['doctor_id'] as String,
      doctorName: doctorName,
      doctorSpecialty: doctorSpecialty,
      doctorAvatar: doctorAvatar,
      doctorAddress: doctorAddress,
      doctorPhone: doctorPhone,
      mapsLink: mapsLink,
      dateTime: DateTime.parse(map['scheduled_at'] as String),
      duration: map['duration'] as int? ?? 30,
      status: map['status'] as String? ?? 'upcoming',
      isConsultation: map['is_consultation'] as bool? ?? false,
      notes: map['notes'] as String?,
    );
  }
}

final patientProvider = StateNotifierProvider<PatientNotifier, PatientState>((
  ref,
) {
  return PatientNotifier(ref);
});

class PatientNotifier extends StateNotifier<PatientState> {
  final Ref _ref;
  final SupabaseClient _client = SupabaseInitializer.client;
  RealtimeChannel? _appointmentsChannel;

  PatientNotifier(this._ref) : super(const PatientState()) {
    _subscribeToAppointments();
    loadPatientData();
  }

  void _subscribeToAppointments() {
    final user = _client.auth.currentUser;
    if (user == null) return;

    _appointmentsChannel = _client
        .channel('patient_appointments_${user.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'appointments',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'patient_id',
            value: user.id,
          ),
          callback: (payload) => loadPatientData(),
        )
        .subscribe();
  }

  @override
  void dispose() {
    _appointmentsChannel?.unsubscribe();
    super.dispose();
  }

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
          .select('full_name, email, phone, city, avatar_url')
          .eq('id', userId)
          .maybeSingle();

      final now = DateTime.now();
      final appointmentsResult = await SupabaseInitializer.client
          .from('appointments')
          .select(
            'id, doctor_id, scheduled_at, duration, status, is_consultation, notes, doctors(specialty, address, maps_link, photo_url)',
          )
          .eq('patient_id', userId)
          .order('scheduled_at', ascending: false)
          .limit(50);

      final attendanceData = await SupabaseInitializer.client
          .from('appointments')
          .select('attendance_status')
          .eq('patient_id', userId)
          .not('attendance_status', 'is', null);

      int globalPresentCount = 0;
      int globalNoShowCount = 0;
      for (final row in attendanceData as List) {
        final status = row['attendance_status'] as String;
        if (status == 'present') {
          globalPresentCount++;
        } else if (status == 'no_show') {
          globalNoShowCount++;
        }
      }
      final noShowCount = globalNoShowCount;

      final favoritesResult = await SupabaseInitializer.client
          .from('favorites')
          .select('doctor_id')
          .eq('patient_id', userId);

      final doctorIds = appointmentsResult
          .map((r) => r['doctor_id'] as String)
          .toSet()
          .toList();

      final Map<String, Map<String, dynamic>> doctorProfileMap = {};
      if (doctorIds.isNotEmpty) {
        try {
          final profiles = await SupabaseInitializer.client
              .rpc('get_doctor_profiles', params: {'doctor_ids': doctorIds});
          for (final p in profiles) {
            doctorProfileMap[p['id'] as String] = p as Map<String, dynamic>;
          }
        } catch (e) {
          try {
            final profiles = await SupabaseInitializer.client
                .from('profiles')
                .select('id, full_name, avatar_url, phone')
                .inFilter('id', doctorIds);
            for (final p in profiles) {
              doctorProfileMap[p['id'] as String] = p;
            }
          } catch (_) {
          }
        }
      }

      List<PatientAppointmentViewModel> upcoming = [];
      List<PatientAppointmentViewModel> past = [];
      List<PatientAppointmentViewModel> cancelled = [];

      for (final row in appointmentsResult) {
        final docMap = row['doctors'] as Map<String, dynamic>?;
        final doctorId = row['doctor_id'] as String;
        final profileData = doctorProfileMap[doctorId];

        final doctorName = profileData?['full_name'] as String? ?? 'Docteur';
        final doctorSpecialty = docMap?['specialty'] as String? ?? '';
        final doctorAvatar = profileData?['avatar_url'] as String? ??
            docMap?['photo_url'] as String?;
        final doctorAddress = docMap?['address'] as String?;
        final doctorPhone = profileData?['phone'] as String?;
        final mapsLink = docMap?['maps_link'] as String?;

        final apt = PatientAppointmentViewModel(
          id: row['id'] as String,
          doctorId: row['doctor_id'] as String,
          doctorName: doctorName,
          doctorSpecialty: doctorSpecialty,
          doctorAvatar: doctorAvatar,
          doctorAddress: doctorAddress,
          doctorPhone: doctorPhone,
          mapsLink: mapsLink,
          dateTime: DateTime.parse(row['scheduled_at'] as String),
          duration: row['duration'] as int? ?? 30,
          status: row['status'] as String? ?? 'upcoming',
          isConsultation: row['is_consultation'] as bool? ?? false,
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
        city: profileResult?['city'] as String? ?? '',
        avatarUrl: profileResult?['avatar_url'] as String? ?? '',
        upcomingCount: upcoming.length,
        favoritesCount: (favoritesResult as List).length,
        noShowCount: noShowCount,
        globalPresentCount: globalPresentCount,
        globalNoShowCount: globalNoShowCount,
        upcomingAppointments: upcoming,
        pastAppointments: past,
        cancelledAppointments: cancelled,
      );

    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> scheduleReminders({
    required String appointmentId,
    required DateTime scheduledAt,
  }) async {
    try {
      await LocalNotificationService.scheduleAppointmentReminders(
        appointmentId: appointmentId,
        scheduledAt: scheduledAt,
      );
    } catch (e) {
      debugPrint('scheduleReminders error: $e');
    }
  }

  Future<bool> cancelAppointment(String appointmentId) async {
    try {
      await SupabaseInitializer.client
          .from('appointments')
          .update({'status': 'cancelled', 'fcm_reminder_sent': true})
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

  Future<bool> updateProfile({
    required String fullName,
    required String phone,
    required String city,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return false;

      final repo = ProfileRepository(_client);
      final result = await repo.updateProfile(
        userId: userId,
        fullName: fullName,
        phone: phone,
        city: city,
      );

      if (result.isSuccess) {
        await loadPatientData();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}
