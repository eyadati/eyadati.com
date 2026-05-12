import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../models/appointment.dart';
import '../../../../repositories/appointment_repository.dart';
import '../../../../services/providers.dart';

final patientAppointmentsProvider = FutureProvider<List<Appointment>>((ref) async {
  final repository = ref.watch(appointmentRepositoryProvider);
  return repository.getPatientAppointments();
});

final upcomingAppointmentsProvider = FutureProvider<List<Appointment>>((ref) async {
  final repository = ref.watch(appointmentRepositoryProvider);
  return repository.getPatientAppointments(status: 'upcoming');
});

final doctorAppointmentsProvider = FutureProvider<List<Appointment>>((ref) async {
  final repository = ref.watch(appointmentRepositoryProvider);
  return repository.getDoctorAppointments();
});

final doctorAppointmentsByDateProvider = FutureProvider.family<List<Appointment>, DateTime>((ref, date) async {
  final repository = ref.watch(appointmentRepositoryProvider);
  return repository.getDoctorAppointmentsByDate(date);
});

final appointmentProvider = FutureProvider.family<Appointment?, String>((ref, id) async {
  final repository = ref.watch(appointmentRepositoryProvider);
  return repository.getAppointment(id);
});

class BookingState {
  final bool isLoading;
  final String? error;
  final Appointment? appointment;

  const BookingState({
    this.isLoading = false,
    this.error,
    this.appointment,
  });

  BookingState copyWith({
    bool? isLoading,
    String? error,
    Appointment? appointment,
  }) {
    return BookingState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      appointment: appointment ?? this.appointment,
    );
  }
}

class BookingNotifier extends StateNotifier<BookingState> {
  final AppointmentRepository _repository;

  BookingNotifier(this._repository) : super(const BookingState());

  Future<bool> bookAppointment({
    required String doctorId,
    required DateTime scheduledAt,
    required int duration,
    required String patientName,
    String? patientPhone,
    bool isConsultation = false,
    String? notes,
  }) async {
    state = const BookingState(isLoading: true);

    final result = await _repository.createAppointment(
      doctorId: doctorId,
      scheduledAt: scheduledAt,
      duration: duration,
      patientName: patientName,
      patientPhone: patientPhone,
      isConsultation: isConsultation,
      notes: notes,
    );

    if (result.isSuccess) {
      state = BookingState(appointment: result.appointment);
      return true;
    } else {
      state = BookingState(error: result.error);
      return false;
    }
  }

  Future<bool> createManualAppointment({
    required String doctorId,
    required DateTime scheduledAt,
    required int duration,
    required String patientName,
    String? patientPhone,
    String? notes,
  }) async {
    state = const BookingState(isLoading: true);

    final result = await _repository.createManualAppointment(
      doctorId: doctorId,
      scheduledAt: scheduledAt,
      duration: duration,
      patientName: patientName,
      patientPhone: patientPhone,
      notes: notes,
    );

    if (result.isSuccess) {
      state = BookingState(appointment: result.appointment);
      return true;
    } else {
      state = BookingState(error: result.error);
      return false;
    }
  }

  Future<bool> cancelAppointment(String appointmentId) async {
    state = const BookingState(isLoading: true);

    final success = await _repository.cancelAppointment(appointmentId);

    if (success) {
      state = const BookingState();
      return true;
    } else {
      state = const BookingState(error: 'Failed to cancel appointment');
      return false;
    }
  }

  Future<bool> updateStatus(String appointmentId, AppointmentStatus status) async {
    state = const BookingState(isLoading: true);

    final success = await _repository.updateAppointmentStatus(appointmentId, status);

    if (success) {
      state = const BookingState();
      return true;
    } else {
      state = const BookingState(error: 'Failed to update appointment');
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void reset() {
    state = const BookingState();
  }
}

final bookingProvider = StateNotifierProvider<BookingNotifier, BookingState>((ref) {
  final repository = ref.watch(appointmentRepositoryProvider);
  return BookingNotifier(repository);
});

final availableSlotsProvider = FutureProvider.family<List<TimeSlot>, SlotRequest>((ref, request) async {
  final repository = ref.watch(appointmentRepositoryProvider);
  return repository.generateAvailableSlots(
    doctorId: request.doctorId,
    date: request.date,
    durationMinutes: request.durationMinutes,
  );
});

class SlotRequest {
  final String doctorId;
  final DateTime date;
  final int durationMinutes;

  const SlotRequest({
    required this.doctorId,
    required this.date,
    required this.durationMinutes,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SlotRequest &&
          runtimeType == other.runtimeType &&
          doctorId == other.doctorId &&
          date == other.date &&
          durationMinutes == other.durationMinutes;

  @override
  int get hashCode => doctorId.hashCode ^ date.hashCode ^ durationMinutes.hashCode;
}
