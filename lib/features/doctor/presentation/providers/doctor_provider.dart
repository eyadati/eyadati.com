import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eyadati/models/schedule_slot_model.dart';
import 'package:eyadati/services/providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DoctorState {
  final String? userId;
  final String name;
  final String email;
  final String specialty;
  final String city;
  final String phone;
  final List<String> workingDays;
  final String startTime;
  final String endTime;
  final int consultationDuration;
  final int appointmentDuration;
  final String avatarUrl;
  final int todayAppointments;
  final int weekAppointments;
  final int totalPatients;
  final double earnings;
  final List<AppointmentData> upcomingAppointments;
  final List<ScheduleSlot> scheduleSlots;
  final bool isLoading;
  final bool setupCompleted;
  final String? errorMessage;

  const DoctorState({
    this.userId,
    this.name = '',
    this.email = '',
    this.specialty = '',
    this.city = '',
    this.phone = '',
    this.workingDays = const [],
    this.startTime = '09:00:00',
    this.endTime = '17:00:00',
    this.consultationDuration = 30,
    this.appointmentDuration = 20,
    this.avatarUrl = '',
    this.todayAppointments = 0,
    this.weekAppointments = 0,
    this.totalPatients = 0,
    this.earnings = 0,
    this.upcomingAppointments = const [],
    this.scheduleSlots = const [],
    this.isLoading = false,
    this.setupCompleted = false,
    this.errorMessage,
  });

  DoctorState copyWith({
    String? userId,
    String? name,
    String? email,
    String? specialty,
    String? city,
    String? phone,
    List<String>? workingDays,
    String? startTime,
    String? endTime,
    int? consultationDuration,
    int? appointmentDuration,
    String? avatarUrl,
    int? todayAppointments,
    int? weekAppointments,
    int? totalPatients,
    double? earnings,
    List<AppointmentData>? upcomingAppointments,
    List<ScheduleSlot>? scheduleSlots,
    bool? isLoading,
    bool? setupCompleted,
    String? errorMessage,
  }) {
    return DoctorState(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      specialty: specialty ?? this.specialty,
      city: city ?? this.city,
      phone: phone ?? this.phone,
      workingDays: workingDays ?? this.workingDays,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      consultationDuration: consultationDuration ?? this.consultationDuration,
      appointmentDuration: appointmentDuration ?? this.appointmentDuration,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      todayAppointments: todayAppointments ?? this.todayAppointments,
      weekAppointments: weekAppointments ?? this.weekAppointments,
      totalPatients: totalPatients ?? this.totalPatients,
      earnings: earnings ?? this.earnings,
      upcomingAppointments: upcomingAppointments ?? this.upcomingAppointments,
      scheduleSlots: scheduleSlots ?? this.scheduleSlots,
      isLoading: isLoading ?? this.isLoading,
      setupCompleted: setupCompleted ?? this.setupCompleted,
      errorMessage: errorMessage,
    );
  }
}

class AppointmentData {
  final String id;
  final DateTime startTime;
  final DateTime endTime;
  final String patientName;
  final String? patientAvatar;
  final String status;
  final bool isConsultation;
  final String? notes;
  final int duration;
  final String? patientId;

  AppointmentData({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.patientName,
    this.patientAvatar,
    required this.status,
    this.isConsultation = false,
    this.notes,
    this.duration = 30,
    this.patientId,
  });
}

final doctorProvider = StateNotifierProvider<DoctorNotifier, DoctorState>((ref) {
  return DoctorNotifier(ref);
});

class DoctorNotifier extends StateNotifier<DoctorState> {
  final Ref _ref;
  SupabaseClient get _client => _ref.read(supabaseClientProvider);

  DoctorNotifier(this._ref) : super(const DoctorState()) {
    loadDoctorData();
  }

  Future<void> loadDoctorData() async {
    state = state.copyWith(isLoading: true);
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        state = state.copyWith(isLoading: false, setupCompleted: false);
        return;
      }

      final doctorData = await _client
          .from('doctors')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (doctorData == null) {
        state = state.copyWith(
          isLoading: false,
          setupCompleted: false,
          userId: user.id,
          email: user.email ?? '',
        );
        return;
      }

      final profile = await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      final startOfWeek = startOfDay.subtract(Duration(days: now.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 7));

      final todayAppts = await _client
          .from('appointments')
          .select()
          .eq('doctor_id', user.id)
          .eq('status', 'confirmed')
          .gte('scheduled_at', startOfDay.toIso8601String())
          .lt('scheduled_at', endOfDay.toIso8601String())
          .count();

      final weekAppts = await _client
          .from('appointments')
          .select()
          .eq('doctor_id', user.id)
          .eq('status', 'confirmed')
          .gte('scheduled_at', startOfWeek.toIso8601String())
          .lt('scheduled_at', endOfWeek.toIso8601String())
          .count();

      final upcomingAppts = await _client
          .from('appointments')
          .select('''
            id,
            scheduled_at,
            duration,
            status,
            appointment_type,
            patient:profiles!patient_id (
              full_name,
              avatar_url
            )
          ''')
          .eq('doctor_id', user.id)
          .eq('status', 'confirmed')
          .gte('scheduled_at', now.toIso8601String())
          .order('scheduled_at')
          .limit(5);

      final scheduleSlots = await _client
          .from('doctor_schedule')
          .select()
          .eq('doctor_id', user.id)
          .eq('is_active', true)
          .order('day_of_week');

      final workingDays = (doctorData['working_days'] as List<dynamic>?)
              ?.map((d) => d.toString())
              .toList() ??
          [];
      final startTimeStr = doctorData['opening_at']?.toString() ?? '09:00:00';
      final endTimeStr = doctorData['closing_at']?.toString() ?? '17:00:00';

      final upcomingAppointments = upcomingAppts.map((a) {
        final start = DateTime.parse(a['scheduled_at'] as String);
        final duration = a['duration'] as int? ?? 30;
        return AppointmentData(
          id: a['id'] as String,
          startTime: start,
          endTime: start.add(Duration(minutes: duration)),
          patientName: (a['patient'] as Map<String, dynamic>?)?['full_name'] as String? ?? 'Patient',
          patientAvatar: (a['patient'] as Map<String, dynamic>?)?['avatar_url'] as String?,
          status: a['status'] as String,
          isConsultation: a['appointment_type'] == 'consultation',
          notes: a['notes'] as String?,
          duration: duration,
          patientId: (a['patient'] as Map<String, dynamic>?)?['id'] as String?,
        );
      }).toList();

      final schedule = scheduleSlots.map((s) => ScheduleSlot(
        id: s['id'] as String,
        doctorId: s['doctor_id'] as String,
        dayOfWeek: s['day_of_week'] as int,
        startTime: s['start_time'] as String,
        endTime: s['end_time'] as String,
        isActive: s['is_active'] as bool? ?? true,
      )).toList();

      state = state.copyWith(
        isLoading: false,
        setupCompleted: true,
        userId: user.id,
        name: profile?['full_name'] as String? ?? doctorData['specialty'] as String? ?? 'Docteur',
        email: user.email ?? '',
        specialty: doctorData['specialty'] as String? ?? '',
        city: doctorData['city'] as String? ?? '',
        phone: profile?['phone'] as String? ?? '',
        workingDays: workingDays,
        startTime: startTimeStr,
        endTime: endTimeStr,
        consultationDuration: doctorData['consultation_duration'] as int? ?? 30,
        appointmentDuration: doctorData['appointment_duration'] as int? ?? 20,
        avatarUrl: profile?['avatar_url'] as String? ?? '',
        todayAppointments: todayAppts.count,
        weekAppointments: weekAppts.count,
        totalPatients: 0,
        earnings: 0,
        upcomingAppointments: upcomingAppointments,
        scheduleSlots: schedule,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

Future<void> saveSetup({
    required List<String> workingDays,
    required String startTime,
    required String endTime,
    required int consultationDuration,
    required int appointmentDuration,
    required String specialty,
    required String city,
    required String address,
    String? phone,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final user = _client.auth.currentUser;
      if (user == null) throw Exception('Not authenticated');

      print('[DoctorNotifier] Saving doctor setup for user: ${user.id}');

      // Get user data from auth metadata
      final role = user.userMetadata?['role'] as String? ?? 'doctor';
      final fullName = user.userMetadata?['full_name'] as String? ?? '';

      // 1. Upsert profile with complete data
      await _client.from('profiles').upsert({
        'id': user.id,
        'role': role,
        'full_name': fullName,
        'phone': phone,
        'city': city,
      }, onConflict: 'id');

      // 2. Upsert doctor record
      final dayMapping = {
        'lundi': 1, 'mardi': 2, 'mercredi': 3, 'jeudi': 4,
        'vendredi': 5, 'samedi': 6, 'dimanche': 0
      };

      final doctorData = {
        'id': user.id,
        'specialty': specialty,
        'address': address,
        'city': city,
        'opening_at': startTime,
        'closing_at': endTime,
        'working_days': workingDays,
        'consultation_duration': consultationDuration,
        'appointment_duration': appointmentDuration,
      };
      print('[DoctorNotifier] Upserting doctor data: $doctorData');

      await _client.from('doctors').upsert(doctorData, onConflict: 'id');

      // 3. Create schedule entries for each working day
      for (final day in workingDays) {
        final dayOfWeek = dayMapping[day] ?? 1;
        print('[DoctorNotifier] Creating schedule slot for day: $dayOfWeek');
        await _client.from('doctor_schedule').delete()
            .eq('doctor_id', user.id)
            .eq('day_of_week', dayOfWeek);
        await _client.from('doctor_schedule').insert({
          'doctor_id': user.id,
          'day_of_week': dayOfWeek,
          'start_time': startTime,
          'end_time': endTime,
          'is_active': true,
        });
      }

      print('[DoctorNotifier] Setup completed successfully');

      state = state.copyWith(
        isLoading: false,
        setupCompleted: true,
        specialty: specialty,
        city: city,
        phone: phone,
        workingDays: workingDays,
        startTime: startTime,
        endTime: endTime,
        consultationDuration: consultationDuration,
        appointmentDuration: appointmentDuration,
      );
    } catch (e) {
      print('[DoctorNotifier] Error in saveSetup: $e');
      state = state.copyWith(
        isLoading: false,
        setupCompleted: false,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> loadScheduleForDay(int dayOfWeek) async {
    final userId = state.userId;
    if (userId == null) {
      state = state.copyWith(isLoading: false, scheduleSlots: []);
      return;
    }

    state = state.copyWith(isLoading: true);
    try {
      final slots = await _client
          .from('doctor_schedule')
          .select()
          .eq('doctor_id', userId)
          .eq('day_of_week', dayOfWeek)
          .eq('is_active', true);
      
      state = state.copyWith(
        isLoading: false,
        scheduleSlots: slots.map((s) => ScheduleSlot(
          id: s['id'] as String,
          doctorId: s['doctor_id'] as String,
          dayOfWeek: s['day_of_week'] as int,
          startTime: s['start_time'] as String,
          endTime: s['end_time'] as String,
          isActive: s['is_active'] as bool? ?? true,
        )).toList(),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> addScheduleSlot({
    required int dayOfWeek,
    required String startTime,
    required String endTime,
  }) async {
    try {
      final result = await _client.from('doctor_schedule').insert({
        'doctor_id': state.userId,
        'day_of_week': dayOfWeek,
        'start_time': startTime,
        'end_time': endTime,
        'is_active': true,
      }).select().maybeSingle();

      if (result != null) {
        final newSlot = ScheduleSlot(
          id: result['id'] as String,
          doctorId: result['doctor_id'] as String,
          dayOfWeek: result['day_of_week'] as int,
          startTime: result['start_time'] as String,
          endTime: result['end_time'] as String,
          isActive: result['is_active'] as bool? ?? true,
        );
        state = state.copyWith(
          scheduleSlots: [...state.scheduleSlots, newSlot],
        );
      }
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> updateScheduleSlot({
    required String slotId,
    String? startTime,
    String? endTime,
    bool? isActive,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (startTime != null) updates['start_time'] = startTime;
      if (endTime != null) updates['end_time'] = endTime;
      if (isActive != null) updates['is_active'] = isActive;

      await _client.from('doctor_schedule').update(updates).eq('id', slotId);

      final updatedSlots = state.scheduleSlots.map((slot) {
        if (slot.id == slotId) {
          return slot.copyWith(
            startTime: startTime,
            endTime: endTime,
            isActive: isActive,
          );
        }
        return slot;
      }).toList();
      state = state.copyWith(scheduleSlots: updatedSlots);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> deleteScheduleSlot(String slotId) async {
    try {
      await _client.from('doctor_schedule').delete().eq('id', slotId);
      final updatedSlots = state.scheduleSlots.where((s) => s.id != slotId).toList();
      state = state.copyWith(scheduleSlots: updatedSlots);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<List<Map<String, dynamic>>> searchPatients(String query) async {
    if (query.length < 2) return [];
    try {
      final results = await _client
          .from('profiles')
          .select('id, full_name, phone')
          .eq('role', 'patient')
          .ilike('full_name', '%$query%')
          .limit(10);
      return (results as List).cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  Future<bool> createAppointment({
    required String patientId,
    required DateTime scheduledAt,
    required int duration,
    required String appointmentType,
    String? notes,
  }) async {
    try {
      final result = await _client.from('appointments').insert({
        'doctor_id': state.userId,
        'patient_id': patientId,
        'scheduled_at': scheduledAt.toIso8601String(),
        'duration': duration,
        'appointment_type': appointmentType,
        'notes': notes,
        'status': 'pending',
      }).select('''
        id,
        scheduled_at,
        duration,
        status,
        appointment_type,
        notes,
        patient:profiles!patient_id (
          full_name,
          avatar_url
        )
      ''').maybeSingle();

      if (result != null) {
        final start = DateTime.parse(result['scheduled_at'] as String);
        final dur = result['duration'] as int? ?? 30;
        final newAppt = AppointmentData(
          id: result['id'] as String,
          startTime: start,
          endTime: start.add(Duration(minutes: dur)),
          patientName: (result['patient'] as Map<String, dynamic>?)?['full_name'] as String? ?? 'Patient',
          patientAvatar: (result['patient'] as Map<String, dynamic>?)?['avatar_url'] as String?,
          status: result['status'] as String,
          isConsultation: result['appointment_type'] == 'consultation',
          notes: result['notes'] as String?,
          duration: dur,
          patientId: patientId,
        );
        state = state.copyWith(
          upcomingAppointments: [...state.upcomingAppointments, newAppt]..sort((a, b) => a.startTime.compareTo(b.startTime)),
        );
        return true;
      }
      return false;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> updateAppointmentStatus(String appointmentId, String status) async {
    try {
      await _client.from('appointments').update({'status': status}).eq('id', appointmentId);
      final updated = state.upcomingAppointments.map((a) {
        if (a.id == appointmentId) {
          return AppointmentData(
            id: a.id,
            startTime: a.startTime,
            endTime: a.endTime,
            patientName: a.patientName,
            patientAvatar: a.patientAvatar,
            status: status,
            isConsultation: a.isConsultation,
            notes: a.notes,
            duration: a.duration,
            patientId: a.patientId,
          );
        }
        return a;
      }).toList();
      state = state.copyWith(upcomingAppointments: updated);
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> deleteAppointment(String appointmentId) async {
    try {
      await _client.from('appointments').delete().eq('id', appointmentId);
      final updated = state.upcomingAppointments.where((a) => a.id != appointmentId).toList();
      state = state.copyWith(upcomingAppointments: updated);
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  Future<void> refresh() async {
    await loadDoctorData();
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}