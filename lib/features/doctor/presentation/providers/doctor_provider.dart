import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eyadati/models/schedule_slot_model.dart';

class DoctorState {
  final String? userId;
  final String name;
  final String email;
  final String specialty;
  final String avatarUrl;
  final int todayAppointments;
  final int weekAppointments;
  final int totalPatients;
  final double earnings;
  final List<AppointmentData> upcomingAppointments;
  final List<ScheduleSlot> scheduleSlots;
  final bool isLoading;
  final String? errorMessage;

  const DoctorState({
    this.userId,
    this.name = '',
    this.email = '',
    this.specialty = '',
    this.avatarUrl = '',
    this.todayAppointments = 0,
    this.weekAppointments = 0,
    this.totalPatients = 0,
    this.earnings = 0,
    this.upcomingAppointments = const [],
    this.scheduleSlots = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  DoctorState copyWith({
    String? userId,
    String? name,
    String? email,
    String? specialty,
    String? avatarUrl,
    int? todayAppointments,
    int? weekAppointments,
    int? totalPatients,
    double? earnings,
    List<AppointmentData>? upcomingAppointments,
    List<ScheduleSlot>? scheduleSlots,
    bool? isLoading,
    String? errorMessage,
  }) {
    return DoctorState(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      specialty: specialty ?? this.specialty,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      todayAppointments: todayAppointments ?? this.todayAppointments,
      weekAppointments: weekAppointments ?? this.weekAppointments,
      totalPatients: totalPatients ?? this.totalPatients,
      earnings: earnings ?? this.earnings,
      upcomingAppointments: upcomingAppointments ?? this.upcomingAppointments,
      scheduleSlots: scheduleSlots ?? this.scheduleSlots,
      isLoading: isLoading ?? this.isLoading,
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

  AppointmentData({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.patientName,
    this.patientAvatar,
    required this.status,
    this.isConsultation = false,
    this.notes,
  });
}

final doctorProvider = StateNotifierProvider<DoctorNotifier, DoctorState>((ref) {
  return DoctorNotifier();
});

class DoctorNotifier extends StateNotifier<DoctorState> {
  DoctorNotifier() : super(const DoctorState()) {
    loadDoctorData();
  }

  Future<void> loadDoctorData() async {
    state = state.copyWith(isLoading: true);
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      state = state.copyWith(
        isLoading: false,
        userId: 'test-doctor-id',
        name: 'Dr. Hassan Tazi',
        email: 'hassan.tazi@eyadati.com',
        specialty: 'Cardiologie',
        todayAppointments: 5,
        weekAppointments: 23,
        totalPatients: 156,
        earnings: 34500,
        upcomingAppointments: [
          AppointmentData(
            id: '1',
            startTime: DateTime.now().add(const Duration(hours: 1)),
            endTime: DateTime.now().add(const Duration(hours: 2)),
            patientName: 'Ahmed Benali',
            status: 'confirmed',
            isConsultation: true,
          ),
          AppointmentData(
            id: '2',
            startTime: DateTime.now().add(const Duration(hours: 3)),
            endTime: DateTime.now().add(const Duration(hours: 3, minutes: 30)),
            patientName: 'Fatima El Amrani',
            status: 'confirmed',
            isConsultation: false,
          ),
          AppointmentData(
            id: '3',
            startTime: DateTime.now().add(const Duration(hours: 5)),
            endTime: DateTime.now().add(const Duration(hours: 5, minutes: 30)),
            patientName: 'Youssef Idrissi',
            status: 'pending',
            isConsultation: true,
          ),
        ],
        scheduleSlots: [
          ScheduleSlot(
            id: '1',
            doctorId: 'test-doctor-id',
            dayOfWeek: 1,
            startTime: '09:00:00',
            endTime: '12:00:00',
          ),
          ScheduleSlot(
            id: '2',
            doctorId: 'test-doctor-id',
            dayOfWeek: 1,
            startTime: '14:00:00',
            endTime: '17:00:00',
          ),
          ScheduleSlot(
            id: '3',
            doctorId: 'test-doctor-id',
            dayOfWeek: 2,
            startTime: '09:00:00',
            endTime: '13:00:00',
          ),
          ScheduleSlot(
            id: '4',
            doctorId: 'test-doctor-id',
            dayOfWeek: 3,
            startTime: '09:00:00',
            endTime: '12:00:00',
          ),
          ScheduleSlot(
            id: '5',
            doctorId: 'test-doctor-id',
            dayOfWeek: 3,
            startTime: '14:00:00',
            endTime: '18:00:00',
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

  Future<void> loadScheduleForDay(int dayOfWeek) async {
    state = state.copyWith(isLoading: true);
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      final slots = [
        ScheduleSlot(
          id: '1-$dayOfWeek',
          doctorId: state.userId ?? '',
          dayOfWeek: dayOfWeek,
          startTime: '09:00:00',
          endTime: '12:00:00',
        ),
        if (dayOfWeek != 0 && dayOfWeek != 6)
          ScheduleSlot(
            id: '2-$dayOfWeek',
            doctorId: state.userId ?? '',
            dayOfWeek: dayOfWeek,
            startTime: '14:00:00',
            endTime: '17:00:00',
          ),
      ];
      state = state.copyWith(
        isLoading: false,
        scheduleSlots: slots,
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
      final newSlot = ScheduleSlot(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        doctorId: state.userId ?? '',
        dayOfWeek: dayOfWeek,
        startTime: startTime,
        endTime: endTime,
      );
      state = state.copyWith(
        scheduleSlots: [...state.scheduleSlots, newSlot],
      );
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
      final updatedSlots = state.scheduleSlots.where((s) => s.id != slotId).toList();
      state = state.copyWith(scheduleSlots: updatedSlots);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> refresh() async {
    await loadDoctorData();
  }

  void clearError() {
    state = DoctorState(
      userId: state.userId,
      name: state.name,
      email: state.email,
      specialty: state.specialty,
      avatarUrl: state.avatarUrl,
      todayAppointments: state.todayAppointments,
      weekAppointments: state.weekAppointments,
      totalPatients: state.totalPatients,
      earnings: state.earnings,
      upcomingAppointments: state.upcomingAppointments,
      scheduleSlots: state.scheduleSlots,
      isLoading: state.isLoading,
    );
  }
}