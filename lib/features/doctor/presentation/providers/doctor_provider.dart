import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eyadati/models/schedule_slot_model.dart';
import 'package:eyadati/models/appointment_data.dart';
import 'package:eyadati/services/providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:eyadati/core/engine/slot_engine.dart';
import 'package:eyadati/core/utils/time_utils.dart';

class DoctorState {
  final String? userId;
  final String name;
  final String email;
  final String specialty;
  final String city;
  final String phone;
  final String address;
  final int consultationDuration;
  final int appointmentDuration;
  final String avatarUrl;
  final String? mapsLink;
  final int todayAppointments;
  final int weekAppointments;
  final int totalPatients;
  final List<AppointmentData> allAppointments;
  final List<AppointmentData> upcomingAppointments;
  final List<ScheduleSlot> scheduleSlots;
  final List<PatientVisitData> patients;
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
    this.address = '',
    this.consultationDuration = 30,
    this.appointmentDuration = 20,
    this.avatarUrl = '',
    this.mapsLink,
    this.todayAppointments = 0,
    this.weekAppointments = 0,
    this.totalPatients = 0,
    this.allAppointments = const [],
    this.upcomingAppointments = const [],
    this.scheduleSlots = const [],
    this.patients = const [],
    this.isLoading = false,
    this.setupCompleted = false,
    this.errorMessage,
  });

  SlotEngine get slotEngine => SlotEngine(
    scheduleSlots: scheduleSlots,
    appointmentDuration: appointmentDuration,
    consultationDuration: consultationDuration,
  );

  List<PotentialSlot> getAvailableSlotsForDay(DateTime date, {bool isConsultation = false}) {
    return slotEngine.getAvailableSlots(
      date,
      isConsultation: isConsultation,
      existingAppointments: allAppointments,
    );
  }

  bool hasScheduleForDay(DateTime date) => slotEngine.hasScheduleForDay(date);

  List<ScheduleSlot> getScheduleForDay(DateTime date) => slotEngine.getScheduleForDay(date);

  int getWorkingHoursForDay(DateTime date) => slotEngine.getWorkingHoursForDay(date);

  List<AppointmentData> getAppointmentsForDay(DateTime date) {
    return allAppointments.where((apt) {
      return apt.startTime.year == date.year &&
          apt.startTime.month == date.month &&
          apt.startTime.day == date.day;
    }).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  DoctorState copyWith({
    String? userId,
    String? name,
    String? email,
    String? specialty,
    String? city,
    String? phone,
    String? address,
    int? consultationDuration,
    int? appointmentDuration,
    String? avatarUrl,
    String? mapsLink,
    int? todayAppointments,
    int? weekAppointments,
    int? totalPatients,
    List<AppointmentData>? allAppointments,
    List<AppointmentData>? upcomingAppointments,
    List<ScheduleSlot>? scheduleSlots,
    List<PatientVisitData>? patients,
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
      address: address ?? this.address,
      consultationDuration: consultationDuration ?? this.consultationDuration,
      appointmentDuration: appointmentDuration ?? this.appointmentDuration,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      mapsLink: mapsLink ?? this.mapsLink,
      todayAppointments: todayAppointments ?? this.todayAppointments,
      weekAppointments: weekAppointments ?? this.weekAppointments,
      totalPatients: totalPatients ?? this.totalPatients,
      allAppointments: allAppointments ?? this.allAppointments,
      upcomingAppointments: upcomingAppointments ?? this.upcomingAppointments,
      scheduleSlots: scheduleSlots ?? this.scheduleSlots,
      patients: patients ?? this.patients,
      isLoading: isLoading ?? this.isLoading,
      setupCompleted: setupCompleted ?? this.setupCompleted,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class PatientVisitData {
  final String? patientId;
  final String patientName;
  final String? patientPhone;
  final int totalVisits;
  final DateTime? lastVisit;

  PatientVisitData({
    this.patientId,
    required this.patientName,
    this.patientPhone,
    required this.totalVisits,
    this.lastVisit,
  });
}

final doctorProvider = StateNotifierProvider<DoctorNotifier, DoctorState>((ref) {
  return DoctorNotifier(ref);
});

class DoctorNotifier extends StateNotifier<DoctorState> {
  final Ref _ref;
  SupabaseClient get _client => _ref.read(supabaseClientProvider);
  RealtimeChannel? _appointmentsChannel;

  DoctorNotifier(this._ref) : super(const DoctorState()) {
    _subscribeToAppointments();
    loadDoctorData();
  }

  void _subscribeToAppointments() {
    final user = _client.auth.currentUser;
    if (user == null) return;

    _appointmentsChannel = _client
        .channel('doctor_appointments_${user.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'appointments',
          callback: (payload) {
            final newRecord = payload.newRecord;
            final oldRecord = payload.oldRecord;
            if (newRecord['doctor_id'] == user.id ||
                oldRecord['doctor_id'] == user.id) {
              _refreshAppointments();
            }
          },
        )
        .subscribe();
  }

  Future<void> _refreshAppointments() async {
    if (state.userId == null) return;
    try {
      final result = await _client
          .from('appointments')
          .select('''
            id,
            scheduled_at,
            duration,
            status,
            appointment_type,
            booking_type,
            notes,
            patient_name_snapshot,
            patient_phone_snapshot,
            patient:profiles!patient_id (
              id,
              full_name,
              avatar_url
            )
          ''')
          .eq('doctor_id', state.userId!)
          .order('scheduled_at', ascending: false);

      final now = DateTime.now();
      final allAppointments = result.map((a) {
        final start = DateTime.parse(a['scheduled_at'] as String);
        final duration = a['duration'] as int? ?? 30;
        return AppointmentData(
          id: a['id'] as String,
          startTime: start,
          endTime: start.add(Duration(minutes: duration)),
          patientName: (a['patient_name_snapshot'] as String?) ??
                       ((a['patient'] as Map<String, dynamic>?)?['full_name'] as String?) ??
                       'Patient',
          patientAvatar: (a['patient'] as Map<String, dynamic>?)?['avatar_url'] as String?,
          patientPhone: a['patient_phone_snapshot'] as String?,
          status: a['status'] as String,
          isConsultation: a['appointment_type'] == 'consultation',
          notes: a['notes'] as String?,
          duration: duration,
          patientId: (a['patient'] as Map<String, dynamic>?)?['id'] as String?,
          bookingType: a['booking_type'] as String? ?? 'online',
        );
      }).toList();

      final upcoming = allAppointments.where((a) => a.startTime.isAfter(now)).toList()
        ..sort((a, b) => a.startTime.compareTo(b.startTime));

      state = state.copyWith(allAppointments: allAppointments, upcomingAppointments: upcoming);
    } catch (_) {}
  }

  @override
  void dispose() {
    _appointmentsChannel?.unsubscribe();
    super.dispose();
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

      final allApptsData = await _client
          .from('appointments')
          .select('''
            id,
            scheduled_at,
            duration,
            status,
            appointment_type,
            notes,
            patient:profiles!patient_id (
              id,
              full_name,
              avatar_url
            )
          ''')
          .eq('doctor_id', user.id)
          .order('scheduled_at', ascending: false);

      final allAppointments = allApptsData.map((a) {
        final start = DateTime.parse(a['scheduled_at'] as String);
        final duration = a['duration'] as int? ?? 30;
        return AppointmentData(
          id: a['id'] as String,
          startTime: start,
          endTime: start.add(Duration(minutes: duration)),
          patientName: (a['patient_name_snapshot'] as String?) ??
                       ((a['patient'] as Map<String, dynamic>?)?['full_name'] as String?) ??
                       'Patient',
          patientAvatar: (a['patient'] as Map<String, dynamic>?)?['avatar_url'] as String?,
          patientPhone: a['patient_phone_snapshot'] as String?,
          status: a['status'] as String,
          isConsultation: a['appointment_type'] == 'consultation',
          notes: a['notes'] as String?,
          duration: duration,
          patientId: (a['patient'] as Map<String, dynamic>?)?['id'] as String?,
          bookingType: a['booking_type'] as String? ?? 'online',
        );
      }).toList();

      final upcomingAppointments = allAppointments
          .where((a) => a.startTime.isAfter(now))
          .toList()
        ..sort((a, b) => a.startTime.compareTo(b.startTime));

      final scheduleSlots = await _client
          .from('doctor_schedule')
          .select()
          .eq('doctor_id', user.id)
          .eq('is_active', true)
          .order('day_of_week');

      final schedule = scheduleSlots.map((s) => ScheduleSlot.fromDbMap(s)).toList();

      state = state.copyWith(
        isLoading: false,
        setupCompleted: true,
        userId: user.id,
        name: profile?['full_name'] as String? ?? doctorData['specialty'] as String? ?? 'Docteur',
        email: user.email ?? '',
        specialty: doctorData['specialty'] as String? ?? '',
        city: doctorData['city'] as String? ?? '',
        phone: profile?['phone'] as String? ?? '',
        address: doctorData['address'] as String? ?? '',
        consultationDuration: doctorData['consultation_duration'] as int? ?? 30,
        appointmentDuration: doctorData['appointment_duration'] as int? ?? 20,
        avatarUrl: profile?['avatar_url'] as String? ?? doctorData['photo_url'] as String? ?? '',
        mapsLink: doctorData['maps_link'] as String?,
        todayAppointments: todayAppts.count,
        weekAppointments: weekAppts.count,
        totalPatients: 0,
        allAppointments: allAppointments,
        upcomingAppointments: upcomingAppointments,
        scheduleSlots: schedule,
      );
      await loadPatients();
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
    String? mapsLink,
    String? photoUrl,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final user = _client.auth.currentUser;
      if (user == null) throw Exception('Not authenticated');

      final role = user.userMetadata?['role'] as String? ?? 'doctor';
      final fullName = user.userMetadata?['full_name'] as String? ?? '';

      await _client.from('profiles').upsert({
        'id': user.id,
        'role': role,
        'full_name': fullName,
        'phone': phone,
        'city': city,
        'avatar_url': photoUrl,
      }, onConflict: 'id');

      final dayMapping = {
        'lundi': 1, 'mardi': 2, 'mercredi': 3, 'jeudi': 4,
        'vendredi': 5, 'samedi': 6, 'dimanche': 0
      };

      final doctorData = {
        'id': user.id,
        'specialty': specialty,
        'address': address,
        'city': city,
        'maps_link': mapsLink,
        'photo_url': photoUrl,
        'consultation_duration': consultationDuration,
        'appointment_duration': appointmentDuration,
      };

      await _client.from('doctors').upsert(doctorData, onConflict: 'id');

      await _client.from('doctor_schedule').delete().eq('doctor_id', user.id);

      for (final day in workingDays) {
        final dayOfWeek = dayMapping[day] ?? 1;
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
        address: address,
        consultationDuration: consultationDuration,
        appointmentDuration: appointmentDuration,
        mapsLink: mapsLink,
        avatarUrl: photoUrl ?? '',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        setupCompleted: false,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  Future<List<ScheduleSlot>> loadScheduleForDay(int dayOfWeek) async {
    final userId = state.userId;
    if (userId == null) return [];

    try {
      final slots = await _client
          .from('doctor_schedule')
          .select()
          .eq('doctor_id', userId)
          .eq('day_of_week', dayOfWeek)
          .eq('is_active', true);

      return slots.map((s) => ScheduleSlot.fromDbMap(s)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> addScheduleSlot({
    required int dayOfWeek,
    required int startTime,
    required int endTime,
    int? breakStart,
    int? breakEnd,
  }) async {
    try {
      final result = await _client.from('doctor_schedule').insert({
        'doctor_id': state.userId,
        'day_of_week': dayOfWeek,
        'start_time': TimeUtils.minutesToString(startTime),
        'end_time': TimeUtils.minutesToString(endTime),
        if (breakStart != null) 'break_start': TimeUtils.minutesToString(breakStart),
        if (breakEnd != null) 'break_end': TimeUtils.minutesToString(breakEnd),
        'is_active': true,
      }).select().maybeSingle();

      if (result != null) {
        final newSlot = ScheduleSlot.fromDbMap(result);
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
    int? startTime,
    int? endTime,
    int? breakStart,
    int? breakEnd,
    bool? isActive,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (startTime != null) updates['start_time'] = TimeUtils.minutesToString(startTime);
      if (endTime != null) updates['end_time'] = TimeUtils.minutesToString(endTime);
      if (breakStart != null) updates['break_start'] = TimeUtils.minutesToString(breakStart);
      if (breakEnd != null) updates['break_end'] = TimeUtils.minutesToString(breakEnd);
      if (isActive != null) updates['is_active'] = isActive;

      await _client.from('doctor_schedule').update(updates).eq('id', slotId);

      final updatedSlots = state.scheduleSlots.map((slot) {
        if (slot.id == slotId) {
          return slot.copyWith(
            startTime: startTime,
            endTime: endTime,
            breakStart: breakStart,
            breakEnd: breakEnd,
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

  Future<void> loadPatients() async {
    if (state.userId == null) return;
    try {
      final result = await _client
          .from('appointments')
          .select('patient_id, patient_name_snapshot, patient_phone_snapshot, scheduled_at, status')
          .eq('doctor_id', state.userId!)
          .order('scheduled_at', ascending: false);

      final Map<String, PatientVisitData> patientMap = {};

      for (final row in result as List) {
        final pid = row['patient_id'] as String?;
        final key = pid ?? row['patient_name_snapshot'] as String? ?? 'unknown';
        final name = row['patient_name_snapshot'] as String? ?? 'Patient';
        final phone = row['patient_phone_snapshot'] as String?;
        final scheduledAt = DateTime.parse(row['scheduled_at'] as String);

        if (patientMap.containsKey(key)) {
          final existing = patientMap[key]!;
          patientMap[key] = PatientVisitData(
            patientId: existing.patientId ?? pid,
            patientName: existing.patientName,
            patientPhone: existing.patientPhone ?? phone,
            totalVisits: existing.totalVisits + 1,
            lastVisit: scheduledAt.isAfter(existing.lastVisit!) ? scheduledAt : existing.lastVisit,
          );
        } else {
          patientMap[key] = PatientVisitData(
            patientId: pid,
            patientName: name,
            patientPhone: phone,
            totalVisits: 1,
            lastVisit: scheduledAt,
          );
        }
      }

      final sortedPatients = patientMap.values.toList()
        ..sort((a, b) => (b.lastVisit ?? DateTime(2000)).compareTo(a.lastVisit ?? DateTime(2000)));

      state = state.copyWith(
        patients: sortedPatients,
        totalPatients: sortedPatients.length,
      );
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
    required DateTime scheduledAt,
    String? patientId,
    String? patientName,
    String? patientPhone,
    String? notes,
  }) async {
    try {
      final insertData = <String, dynamic>{
        'doctor_id': state.userId,
        'scheduled_at': scheduledAt.toIso8601String(),
        'duration': state.appointmentDuration,
        'status': 'confirmed',
        'booking_type': patientId != null ? 'online' : 'manual',
      };

      if (patientId != null) {
        insertData['patient_id'] = patientId;
        insertData['appointment_type'] = 'standard';
      }

      if (patientName != null) {
        insertData['patient_name_snapshot'] = patientName;
        insertData['patient_phone_snapshot'] = patientPhone ?? '';
      }

      if (notes != null && notes.isNotEmpty) {
        insertData['notes'] = notes;
      }

      final result = await _client.from('appointments').insert(insertData).select(
        'id, scheduled_at, duration, status, patient_name_snapshot, patient_phone_snapshot'
      ).maybeSingle();

      if (result != null) {
        final start = DateTime.parse(result['scheduled_at'] as String);
        final dur = result['duration'] as int? ?? state.appointmentDuration;
        final newAppt = AppointmentData(
          id: result['id'] as String,
          startTime: start,
          endTime: start.add(Duration(minutes: dur)),
          patientName: patientName ?? result['patient_name_snapshot'] as String? ?? 'Patient',
          patientPhone: patientPhone ?? result['patient_phone_snapshot'] as String?,
          status: 'upcoming',
          duration: dur,
          patientId: patientId,
          bookingType: patientId != null ? 'online' : 'manual',
        );
        state = state.copyWith(
          upcomingAppointments: [...state.upcomingAppointments, newAppt]
            ..sort((a, b) => a.startTime.compareTo(b.startTime)),
          allAppointments: [newAppt, ...state.allAppointments],
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
    await loadPatients();
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}