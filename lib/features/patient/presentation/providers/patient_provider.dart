import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eyadati/core/utils/supabase_client.dart';
import 'package:eyadati/features/auth/presentation/providers/auth_provider.dart';
import 'package:eyadati/repositories/profile_repository.dart';
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
  });

  static const int _minHistory = 3;

  int get totalGlobalAppts => globalPresentCount;
  bool get hasSufficientHistory => totalGlobalAppts >= _minHistory;
  double get attendanceRate {
    final total = totalGlobalAppts;
    if (total == 0) return 1.0;
    return (total - globalNoShowCount) / total;
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

final patientProvider =
    AsyncNotifierProvider<PatientNotifier, PatientState>(() {
  return PatientNotifier();
});

class PatientNotifier extends AsyncNotifier<PatientState> {
  SupabaseClient get _client => SupabaseInitializer.client;
  RealtimeChannel? _appointmentsChannel;
  Timer? _debounceTimer;
  bool _isFetching = false;
  StreamSubscription? _authSubscription;

  @override
  Future<PatientState> build() async {
    _subscribeToAppointments();
    _listenToAuth();
    return _load();
  }

  void dispose() {
    _appointmentsChannel?.unsubscribe();
    _debounceTimer?.cancel();
    _authSubscription?.cancel();
  }

  void _listenToAuth() {
    _authSubscription = _client.auth.onAuthStateChange.listen((data) {
      if (data.session == null) {
        _appointmentsChannel?.unsubscribe();
        _appointmentsChannel = null;
      } else {
        _subscribeToAppointments();
      }
    });
  }

  void _subscribeToAppointments() {
    final user = _client.auth.currentUser;
    if (user == null) return;

    _appointmentsChannel?.unsubscribe();
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
          callback: (_) => _silentRefresh(),
        )
        .subscribe();
  }

  void _silentRefresh() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      if (_isFetching) return;
      _isFetching = true;
      try {
        final result = await _fetchData();
        if (result != null) state = AsyncData(result);
      } catch (_) {
      } finally {
        _isFetching = false;
      }
    });
  }

  Future<PatientState?> _fetchData() async {
    final userId = ref.read(authProvider).userId;
    if (userId == null) return null;

    final profileResult = await _client
        .from('profiles')
        .select('full_name, email, phone, city, avatar_url')
        .eq('id', userId)
        .maybeSingle();

    final now = DateTime.now();
    final appointmentsResult = await _client
        .from('appointments')
        .select(
          'id, doctor_id, scheduled_at, duration, status, is_consultation, notes, doctors(specialty, address, maps_link, photo_url)',
        )
        .eq('patient_id', userId)
        .order('scheduled_at', ascending: false)
        .limit(50);

    final attendanceData = await _client
        .from('appointments')
        .select('attendance_status')
        .eq('patient_id', userId);

    int globalPresentCount = 0;
    int globalNoShowCount = 0;
    for (final row in attendanceData as List) {
      globalPresentCount++;
      final status = row['attendance_status'] as String?;
      if (status == 'no_show') {
        globalNoShowCount++;
      }
    }

    final favoritesResult = await _client
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
        final profiles = await _client
            .rpc('get_doctor_profiles', params: {'doctor_ids': doctorIds});
        for (final p in profiles) {
          doctorProfileMap[p['id'] as String] = p as Map<String, dynamic>;
        }
      } catch (e) {
        try {
          final profiles = await _client
              .from('profiles')
              .select('id, full_name, avatar_url, phone')
              .inFilter('id', doctorIds);
          for (final p in profiles) {
            doctorProfileMap[p['id'] as String] = p;
          }
        } catch (_) {}
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
      final doctorAvatar =
          profileData?['avatar_url'] as String? ?? docMap?['photo_url'] as String?;
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

    return PatientState(
      name: profileResult?['full_name'] as String? ?? '',
      email: profileResult?['email'] as String? ?? '',
      phone: profileResult?['phone'] as String? ?? '',
      city: profileResult?['city'] as String? ?? '',
      avatarUrl: profileResult?['avatar_url'] as String? ?? '',
      upcomingCount: upcoming.length,
      favoritesCount: (favoritesResult as List).length,
      noShowCount: globalNoShowCount,
      globalPresentCount: globalPresentCount,
      globalNoShowCount: globalNoShowCount,
      upcomingAppointments: upcoming,
      pastAppointments: past,
      cancelledAppointments: cancelled,
    );
  }

  Future<PatientState> _load() async {
    if (_isFetching) return state.valueOrNull ?? const PatientState();
    _isFetching = true;
    try {
      final result = await _fetchData();
      return result ?? const PatientState();
    } finally {
      _isFetching = false;
    }
  }

  Future<void> loadPatientData() async {
    state = const AsyncLoading<PatientState>().copyWithPrevious(state);
    state = await AsyncValue.guard(() => _load());
  }

  Future<String?> addAppointment({
    required String doctorId,
    required String doctorName,
    required String doctorSpecialty,
    String? doctorAvatar,
    String? doctorAddress,
    String? doctorPhone,
    String? mapsLink,
    required DateTime scheduledAt,
    required int duration,
    String? notes,
    bool isConsultation = false,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    final currentState = state.valueOrNull ?? const PatientState();

    try {
      final response = await _client.from('appointments').insert({
        'doctor_id': doctorId,
        'patient_id': userId,
        'scheduled_at': scheduledAt.toIso8601String(),
        'duration': duration,
        'status': 'upcoming',
        'booking_type': 'online',
        'is_consultation': isConsultation,
        if (currentState.name.isNotEmpty) 'patient_name_snapshot': currentState.name,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      }).select('id');

      final appointmentId = (response as List).first['id'] as String;

      final viewModel = PatientAppointmentViewModel(
        id: appointmentId,
        doctorId: doctorId,
        doctorName: doctorName,
        doctorSpecialty: doctorSpecialty,
        doctorAvatar: doctorAvatar,
        doctorAddress: doctorAddress,
        doctorPhone: doctorPhone,
        mapsLink: mapsLink,
        dateTime: scheduledAt,
        duration: duration,
        status: 'upcoming',
        isConsultation: isConsultation,
        notes: notes,
      );

      final delta = scheduledAt.difference(DateTime.now());
      final Duration reminderLead;
      if (delta > const Duration(hours: 6)) {
        reminderLead = const Duration(hours: 6);
      } else if (delta > const Duration(hours: 2)) {
        reminderLead = const Duration(hours: 2);
      } else {
        reminderLead = Duration.zero;
      }
      if (reminderLead > Duration.zero) {
        final reminderAt = scheduledAt.subtract(reminderLead);
        await _client
            .from('appointments')
            .update({'reminder_at': reminderAt.toIso8601String()})
            .eq('id', appointmentId);
      }

      state = AsyncData(currentState.copyWith(
        upcomingAppointments: [viewModel, ...currentState.upcomingAppointments],
        upcomingCount: currentState.upcomingCount + 1,
      ));

      return appointmentId;
    } catch (e) {
      loadPatientData();
      return null;
    }
  }

  Future<bool> cancelAppointment(String appointmentId) async {
    try {
      await _client
          .from('appointments')
          .update({'status': 'cancelled'})
          .eq('id', appointmentId);
      await loadPatientData();
      return true;
    } catch (_) {
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
    } catch (_) {
      return false;
    }
  }
}
