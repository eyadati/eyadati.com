import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:eyadati/core/utils/supabase_client.dart';
import 'package:eyadati/core/utils/doctor_colors.dart';
import 'package:eyadati/models/appointment_data.dart';
import 'package:eyadati/models/schedule_slot_model.dart';
import 'package:eyadati/features/clinic/data/clinic_booking_service.dart';
import 'package:uuid/uuid.dart';

class ClinicGroupMember {
  final String doctorId;
  final String doctorName;
  final Color color;
  final DateTime? subscriptionEnd;
  final bool isPaused;
  final bool isTest;
  final List<DaySchedule> schedules;

  ClinicGroupMember({
    required this.doctorId,
    required this.doctorName,
    this.color = Colors.blueGrey,
    this.subscriptionEnd,
    this.isPaused = false,
    this.isTest = false,
    this.schedules = const [],
  });

  bool get isAvailable {
    if (isTest) return false;
    if (isPaused) return false;
    if (subscriptionEnd != null && subscriptionEnd!.isBefore(DateTime.now())) return false;
    return true;
  }

  String? get unavailabilityReason {
    if (isTest) return 'Profil test';
    if (isPaused) return 'Profil suspendu';
    if (subscriptionEnd != null && subscriptionEnd!.isBefore(DateTime.now())) return 'Abonnement expiré';
    return null;
  }
}

class ClinicState {
  final List<ClinicGroupMember> members;
  final List<AppointmentData> appointments;
  final String? clinicGroupId;
  final String clinicName;
  final bool isLoading;
  final String? error;
  final Set<String> hiddenDoctorIds;

  const ClinicState({
    this.members = const [],
    this.appointments = const [],
    this.clinicGroupId,
    this.clinicName = '',
    this.isLoading = false,
    this.error,
    this.hiddenDoctorIds = const {},
  });

  int get pendingCount {
    return appointments.where((a) => a.status == 'upcoming' && a.bookingType == 'online').length;
  }

  int get availableDoctorCount {
    return members.where((m) => m.isAvailable).length;
  }

  List<AppointmentData> get filteredAppointments {
    if (hiddenDoctorIds.isEmpty) return appointments;
    return appointments.where((a) => !hiddenDoctorIds.contains(a.doctorId)).toList();
  }

  ClinicState copyWith({
    List<ClinicGroupMember>? members,
    List<AppointmentData>? appointments,
    String? clinicGroupId,
    String? clinicName,
    bool? isLoading,
    String? error,
    Set<String>? hiddenDoctorIds,
    bool clearError = false,
  }) {
    return ClinicState(
      members: members ?? this.members,
      appointments: appointments ?? this.appointments,
      clinicGroupId: clinicGroupId ?? this.clinicGroupId,
      clinicName: clinicName ?? this.clinicName,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      hiddenDoctorIds: hiddenDoctorIds ?? this.hiddenDoctorIds,
    );
  }
}

final clinicProvider = StateNotifierProvider<ClinicNotifier, ClinicState>((ref) {
  return ClinicNotifier();
});

class ClinicNotifier extends StateNotifier<ClinicState> {
  RealtimeChannel? _appointmentChannel;
  RealtimeChannel? _scheduleChannel;
  RealtimeChannel? _membersChannel;
  RealtimeChannel? _healthChannel;
  Timer? _debounceTimer;
  String? lastSelectedDoctorId;

  SupabaseClient get _client => SupabaseInitializer.client;

  ClinicNotifier() : super(const ClinicState());

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  String? suggestMostAvailableDoctor(DateTime dateTime) {
    return ClinicBookingService.suggestMostAvailableDoctor(
      members: state.members,
      appointments: state.appointments,
      dateTime: dateTime,
    );
  }

  Future<void> loadClinicGroup() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        state = state.copyWith(isLoading: false, error: 'Not authenticated');
        return;
      }

      final memberRows = await _client
          .from('clinic_group_members')
          .select('clinic_group_id, doctor_id, color')
          .eq('doctor_id', user.id)
          .limit(1);

      if (memberRows.isEmpty) {
        state = state.copyWith(isLoading: false);
        return;
      }

      final groupId = memberRows[0]['clinic_group_id'] as String;

      final groupInfo = await _client
          .from('clinic_groups')
          .select('name')
          .eq('id', groupId)
          .limit(1)
          .maybeSingle();
      final clinicName = groupInfo?['name'] as String? ?? '';

      final allMembers = await _client
          .from('clinic_group_members')
          .select('doctor_id, color')
          .eq('clinic_group_id', groupId);

      final doctorIds = allMembers
          .map((m) => m['doctor_id'] as String)
          .toList();

      final profiles = await _client
          .from('profiles')
          .select('id, full_name')
          .inFilter('id', doctorIds);

      final nameMap = <String, String>{};
      for (final p in profiles) {
        nameMap[p['id'] as String] = p['full_name'] as String? ?? '';
      }

      final colorGen = DoctorColorGenerator();
      final scheduleMap = await _fetchDoctorSchedules(doctorIds);
      final healthMap = await _fetchDoctorHealth(doctorIds);
      final members = <ClinicGroupMember>[];
      for (int i = 0; i < allMembers.length; i++) {
        final m = allMembers[i];
        final docId = m['doctor_id'] as String;
        final health = healthMap[docId] ?? {};
        members.add(ClinicGroupMember(
          doctorId: docId,
          doctorName: nameMap[docId] ?? '',
          color: colorGen.getColor(docId),
          subscriptionEnd: health['subscription_end'] != null
              ? DateTime.parse(health['subscription_end'] as String)
              : null,
          isPaused: health['manual_pause'] as bool? ?? false,
          isTest: health['is_test'] as bool? ?? false,
          schedules: scheduleMap[docId] ?? [],
        ));
      }

      state = state.copyWith(
        members: members,
        clinicGroupId: groupId,
        clinicName: clinicName,
      );

      await _loadAppointments(doctorIds, nameMap, colorGen);
      _subscribeAll(groupId, doctorIds: doctorIds);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> _loadAppointments(
    List<String> doctorIds,
    Map<String, String> nameMap,
    DoctorColorGenerator colorGen,
  ) async {
    try {
      final data = await _client
          .from('appointments')
          .select('''
            id,
            scheduled_at,
            duration,
            status,
            is_consultation,
            booking_type,
            notes,
            patient_name_snapshot,
            patient_phone_snapshot,
            patient:profiles!patient_id (
              id,
              full_name,
              avatar_url
            ),
            doctor_id
          ''')
           .inFilter('doctor_id', doctorIds)
          .gte('scheduled_at', DateTime.now().subtract(const Duration(days: 30)).toUtc().toIso8601String())
          .lte('scheduled_at', DateTime.now().add(const Duration(days: 90)).toUtc().toIso8601String())
          .order('scheduled_at', ascending: false);

      final appointments = data.map((a) {
        final start = DateTime.parse(a['scheduled_at'] as String);
        final duration = a['duration'] as int? ?? 30;
        final patientNameSnapshot = a['patient_name_snapshot'] as String?;
        final patientData = a['patient'] as Map<String, dynamic>?;
        final patientFullName = patientData?['full_name'] as String?;
        final resolvedName = patientNameSnapshot ?? patientFullName ?? 'Patient';
        final docId = a['doctor_id'] as String? ?? '';

        return AppointmentData(
          id: a['id'] as String,
          startTime: start,
          endTime: start.add(Duration(minutes: duration)),
          patientName: resolvedName,
          patientAvatar: (patientData)?['avatar_url'] as String?,
          patientPhone: a['patient_phone_snapshot'] as String?,
          status: a['status'] as String,
          isConsultation: a['is_consultation'] as bool? ?? false,
          notes: a['notes'] as String?,
          duration: duration,
          patientId: (patientData)?['id'] as String?,
          bookingType: a['booking_type'] as String? ?? 'online',
          doctorId: docId,
          doctorName: nameMap[docId] ?? '',
        );
      }).toList();

      state = state.copyWith(
        appointments: appointments,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<Map<String, List<DaySchedule>>> _fetchDoctorSchedules(List<String> doctorIds) async {
    try {
      final rows = await _client
          .from('doctor_schedule')
          .select()
          .inFilter('doctor_id', doctorIds)
          .eq('is_active', true);
      final map = <String, List<DaySchedule>>{};
      for (final row in rows) {
        final slot = DaySchedule.fromDbMap(row);
        map.putIfAbsent(slot.doctorId, () => []).add(slot);
      }
      return map;
    } catch (_) {
      return {};
    }
  }

  Future<Map<String, Map<String, dynamic>>> _fetchDoctorHealth(List<String> doctorIds) async {
    try {
      final rows = await _client
          .from('doctors')
          .select('id, subscription_end, manual_pause, is_test')
          .inFilter('id', doctorIds);
      final map = <String, Map<String, dynamic>>{};
      for (final row in rows) {
        map[row['id'] as String] = row;
      }
      return map;
    } catch (_) {
      return {};
    }
  }

  /// Creates a walk-in appointment after validating availability.
  /// Throws with a user-friendly message if the slot is invalid.
  Future<void> createWalkIn({
    required String doctorId,
    required String patientName,
    String? patientPhone,
    required DateTime scheduledAt,
    required int duration,
    bool isConsultation = false,
  }) async {
    final validationError = ClinicBookingService.validateWalkInSlot(
      members: state.members,
      appointments: state.appointments,
      doctorId: doctorId,
      scheduledAt: scheduledAt,
      duration: duration,
    );
    if (validationError != null) {
      throw Exception(validationError);
    }

    state = state.copyWith(isLoading: true);

    try {
      final user = _client.auth.currentUser;
      if (user == null) throw Exception('Non connecté');

      final result = await _client.rpc('create_clinic_appointment', params: {
        'p_doctor_id': doctorId,
        'p_scheduled_at': scheduledAt.toUtc().toIso8601String(),
        'p_duration': duration,
        'p_patient_name': patientName,
        'p_patient_phone': patientPhone ?? '',
        'p_is_consultation': isConsultation,
      });

      if (result is Map && result['success'] == false) {
        throw Exception(result['error'] ?? 'Créneau non disponible');
      }

      state = state.copyWith(isLoading: false);
      await refresh();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  void toggleDoctorFilter(String doctorId) {
    final hidden = Set<String>.from(state.hiddenDoctorIds);
    if (hidden.contains(doctorId)) {
      hidden.remove(doctorId);
    } else {
      hidden.add(doctorId);
    }
    state = state.copyWith(hiddenDoctorIds: hidden);
  }

  void showAllDoctors() {
    state = state.copyWith(hiddenDoctorIds: const {});
  }

  Future<void> removeDoctor(String doctorId) async {
    if (state.clinicGroupId == null) return;

    try {
      await _client
          .from('clinic_group_members')
          .delete()
          .eq('clinic_group_id', state.clinicGroupId!)
          .eq('doctor_id', doctorId);

      final user = _client.auth.currentUser;
      if (user != null && doctorId == user.id) {
        state = const ClinicState();
        return;
      }

      await refresh();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<String?> addDoctorByEmail(String email) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return 'Non connecté';

      final profiles = await _client
          .from('profiles')
          .select('id, full_name')
          .eq('email', email)
          .or('role.eq.doctor,id.eq.${user.id}')
          .limit(1);

      if (profiles.isEmpty) {
        return 'Aucun médecin trouvé avec cet email';
      }

      final doctorId = profiles[0]['id'] as String;
      final doctorName = profiles[0]['full_name'] as String? ?? '';

      late final String groupId;

      if (state.clinicGroupId != null) {
        final existing = await _client
            .from('clinic_group_members')
            .select('id')
            .eq('clinic_group_id', state.clinicGroupId!)
            .eq('doctor_id', doctorId)
            .limit(1);

        if (existing.isNotEmpty) {
          return '${doctorName} est déjà dans la clinique';
        }
        groupId = state.clinicGroupId!;
      } else {
        final existingGroup = await _client
            .from('clinic_group_members')
            .select('clinic_group_id')
            .eq('doctor_id', user.id)
            .limit(1);

        if (existingGroup.isNotEmpty) {
          groupId = existingGroup[0]['clinic_group_id'] as String;
          state = state.copyWith(clinicGroupId: groupId);

          final existingMember = await _client
              .from('clinic_group_members')
              .select('id')
              .eq('clinic_group_id', groupId)
              .eq('doctor_id', doctorId)
              .limit(1);

          if (existingMember.isNotEmpty) {
            await refresh();
            return '${doctorName} est déjà dans la clinique';
          }
        } else {
          groupId = const Uuid().v4();

          await _client.from('clinic_groups').insert({
            'id': groupId,
            'name': 'Ma clinique',
          });

          await _client.from('clinic_group_members').insert({
            'clinic_group_id': groupId,
            'doctor_id': user.id,
          });

          state = state.copyWith(clinicGroupId: groupId, clinicName: 'Ma clinique');
        }
      }

      if (doctorId != user.id) {
        await _client.from('clinic_group_members').insert({
          'clinic_group_id': groupId,
          'doctor_id': doctorId,
        });
      }

      await refresh();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> refresh() async {
    final groupId = state.clinicGroupId;
    if (groupId == null) return;

    try {
      final allMembers = await _client
          .from('clinic_group_members')
          .select('doctor_id, color')
          .eq('clinic_group_id', groupId);

      final doctorIds = allMembers.map((m) => m['doctor_id'] as String).toList();

      final profiles = await _client
          .from('profiles')
          .select('id, full_name')
          .inFilter('id', doctorIds);

      final nameMap = <String, String>{};
      for (final p in profiles) {
        nameMap[p['id'] as String] = p['full_name'] as String? ?? '';
      }

      final colorGen = DoctorColorGenerator();
      final scheduleMap = await _fetchDoctorSchedules(doctorIds);
      final healthMap = await _fetchDoctorHealth(doctorIds);
      final members = <ClinicGroupMember>[];
      for (int i = 0; i < allMembers.length; i++) {
        final m = allMembers[i];
        final docId = m['doctor_id'] as String;
        final health = healthMap[docId] ?? {};
        members.add(ClinicGroupMember(
          doctorId: docId,
          doctorName: nameMap[docId] ?? '',
          color: colorGen.getColor(docId),
          subscriptionEnd: health['subscription_end'] != null
              ? DateTime.parse(health['subscription_end'] as String)
              : null,
          isPaused: health['manual_pause'] as bool? ?? false,
          isTest: health['is_test'] as bool? ?? false,
          schedules: scheduleMap[docId] ?? [],
        ));
      }

      state = state.copyWith(members: members);
      await _loadAppointments(doctorIds, nameMap, colorGen);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void _silentRefresh() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      refresh();
    });
  }

  void _subscribeAll(String groupId, {List<String>? doctorIds}) {
    _appointmentChannel?.unsubscribe();
    _scheduleChannel?.unsubscribe();
    _membersChannel?.unsubscribe();
    _healthChannel?.unsubscribe();

    _appointmentChannel = _client
        .channel('clinic_appointments_$groupId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'appointments',
          callback: (_) => _silentRefresh(),
          filter: doctorIds != null && doctorIds.length == 1
              ? PostgresChangeFilter(
                  type: PostgresChangeFilterType.eq,
                  column: 'doctor_id',
                  value: doctorIds.first,
                )
              : null,
        )
        .subscribe();

    _scheduleChannel = _client
        .channel('clinic_schedule_$groupId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'doctor_schedule',
          callback: (_) => _silentRefresh(),
        )
        .subscribe();

    _membersChannel = _client
        .channel('clinic_members_$groupId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'clinic_group_members',
          callback: (_) => _silentRefresh(),
        )
        .subscribe();

    _healthChannel = _client
        .channel('clinic_health_$groupId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'doctors',
          callback: (_) => _silentRefresh(),
          filter: doctorIds != null && doctorIds.length == 1
              ? PostgresChangeFilter(
                  type: PostgresChangeFilterType.eq,
                  column: 'id',
                  value: doctorIds.first,
                )
              : null,
        )
        .subscribe();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _appointmentChannel?.unsubscribe();
    _scheduleChannel?.unsubscribe();
    _membersChannel?.unsubscribe();
    _healthChannel?.unsubscribe();
    super.dispose();
  }
}
