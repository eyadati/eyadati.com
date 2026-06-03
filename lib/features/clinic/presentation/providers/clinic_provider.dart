import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:eyadati/core/utils/supabase_client.dart';
import 'package:eyadati/core/utils/doctor_colors.dart';
import 'package:eyadati/models/appointment_data.dart';

class ClinicGroupMember {
  final String doctorId;
  final String doctorName;
  final Color color;

  ClinicGroupMember({
    required this.doctorId,
    required this.doctorName,
    this.color = Colors.blueGrey,
  });
}

class ClinicState {
  final List<ClinicGroupMember> members;
  final List<AppointmentData> appointments;
  final String? clinicGroupId;
  final bool isLoading;
  final String? error;
  final Set<String> hiddenDoctorIds;

  const ClinicState({
    this.members = const [],
    this.appointments = const [],
    this.clinicGroupId,
    this.isLoading = false,
    this.error,
    this.hiddenDoctorIds = const {},
  });

  List<AppointmentData> get filteredAppointments {
    if (hiddenDoctorIds.isEmpty) return appointments;
    return appointments.where((a) => !hiddenDoctorIds.contains(a.doctorId)).toList();
  }

  ClinicState copyWith({
    List<ClinicGroupMember>? members,
    List<AppointmentData>? appointments,
    String? clinicGroupId,
    bool? isLoading,
    String? error,
    Set<String>? hiddenDoctorIds,
    bool clearError = false,
  }) {
    return ClinicState(
      members: members ?? this.members,
      appointments: appointments ?? this.appointments,
      clinicGroupId: clinicGroupId ?? this.clinicGroupId,
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
  RealtimeChannel? _channel;

  SupabaseClient get _client => SupabaseInitializer.client;

  ClinicNotifier() : super(const ClinicState());

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
      final members = <ClinicGroupMember>[];
      for (int i = 0; i < allMembers.length; i++) {
        final m = allMembers[i];
        final docId = m['doctor_id'] as String;
        members.add(ClinicGroupMember(
          doctorId: docId,
          doctorName: nameMap[docId] ?? '',
          color: colorGen.getColor(i),
        ));
      }

      state = state.copyWith(
        members: members,
        clinicGroupId: groupId,
      );

      await _loadAppointments(doctorIds, nameMap, colorGen);
      _subscribe();
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

  Future<void> createWalkIn({
    required String doctorId,
    required String patientName,
    String? patientPhone,
    required DateTime scheduledAt,
    required int duration,
    bool isConsultation = false,
  }) async {
    state = state.copyWith(isLoading: true);

    try {
      final user = _client.auth.currentUser;
      if (user == null) throw Exception('Not authenticated');

      await _client.from('appointments').insert({
        'doctor_id': doctorId,
        'patient_name_snapshot': patientName,
        'patient_phone_snapshot': patientPhone ?? '',
        'scheduled_at': scheduledAt.toUtc().toIso8601String(),
        'duration': duration,
        'status': 'upcoming',
        'booking_type': 'manual',
        'is_consultation': isConsultation,
      });

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
      final profiles = await _client
          .from('profiles')
          .select('id, full_name')
          .eq('email', email)
          .eq('role', 'doctor')
          .limit(1);

      if (profiles.isEmpty) {
        return 'Aucun médecin trouvé avec cet email';
      }

      final doctorId = profiles[0]['id'] as String;
      final doctorName = profiles[0]['full_name'] as String? ?? '';

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
      }

      String groupId;
      if (state.clinicGroupId == null) {
        final user = _client.auth.currentUser;
        if (user == null) return 'Non connecté';

        final groupResult = await _client.from('clinic_groups').insert({
          'name': 'Ma clinique',
        }).select('id').single();

        groupId = groupResult['id'] as String;

        await _client.from('clinic_group_members').insert({
          'clinic_group_id': groupId,
          'doctor_id': user.id,
        });

        state = state.copyWith(clinicGroupId: groupId);
      } else {
        groupId = state.clinicGroupId!;
      }

      await _client.from('clinic_group_members').insert({
        'clinic_group_id': groupId,
        'doctor_id': doctorId,
      });

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
      final members = <ClinicGroupMember>[];
      for (int i = 0; i < allMembers.length; i++) {
        final m = allMembers[i];
        final docId = m['doctor_id'] as String;
        members.add(ClinicGroupMember(
          doctorId: docId,
          doctorName: nameMap[docId] ?? '',
          color: colorGen.getColor(i),
        ));
      }

      state = state.copyWith(members: members);
      await _loadAppointments(doctorIds, nameMap, colorGen);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void _subscribe() {
    _channel?.unsubscribe();
    _channel = _client
        .channel('clinic_appointments_${state.clinicGroupId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'appointments',
          callback: (_) {
            refresh();
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }
}
