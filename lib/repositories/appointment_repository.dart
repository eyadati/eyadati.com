import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/appointment.dart';
import '../models/doctor.dart';

class AppointmentRepository {
  final SupabaseClient _client;

  AppointmentRepository(this._client);

  Future<List<Appointment>> getPatientAppointments({
    String? status,
    int? limit,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return [];

      final query = _client
          .from('appointments')
          .select()
          .eq('patient_id', userId);

      PostgrestFilterBuilder<PostgrestList> filteredQuery;
      
      if (status != null) {
        filteredQuery = query.eq('status', status);
      } else {
        filteredQuery = query;
      }

      if (limit != null) {
        final response = await filteredQuery.limit(limit).order('scheduled_at', ascending: false);
        return (response as List)
            .map((json) => Appointment.fromDatabase(json))
            .toList();
      }

      final response = await filteredQuery.order('scheduled_at', ascending: false);
      return (response as List)
          .map((json) => Appointment.fromDatabase(json))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Appointment>> getDoctorAppointments({
    String? status,
    DateTime? fromDate,
    DateTime? toDate,
    int? limit,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return [];

      var query = _client
          .from('appointments')
          .select()
          .eq('doctor_id', userId);

      if (status != null) {
        query = query.eq('status', status);
      }

      if (fromDate != null) {
        query = query.gte('scheduled_at', fromDate.toIso8601String());
      }

      if (toDate != null) {
        query = query.lte('scheduled_at', toDate.toIso8601String());
      }

      final response = await query.order('scheduled_at', ascending: true);
      return (response as List)
          .map((json) => Appointment.fromDatabase(json))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Appointment>> getDoctorAppointmentsByDate(DateTime date) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return [];

      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final response = await _client
          .from('appointments')
          .select()
          .eq('doctor_id', userId)
          .gte('scheduled_at', startOfDay.toIso8601String())
          .lt('scheduled_at', endOfDay.toIso8601String())
          .order('scheduled_at', ascending: true);

      return (response as List)
          .map((json) => Appointment.fromDatabase(json))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<Appointment?> getAppointment(String appointmentId) async {
    try {
      final response = await _client
          .from('appointments')
          .select()
          .eq('id', appointmentId)
          .maybeSingle();

      if (response == null) return null;
      return Appointment.fromDatabase(response);
    } catch (e) {
      return null;
    }
  }

  Future<AppointmentResult> createAppointment({
    required String doctorId,
    required DateTime scheduledAt,
    required int duration,
    required String patientName,
    String? patientPhone,
    bool isConsultation = false,
    String? notes,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        return AppointmentResult.failure('User not authenticated');
      }

      final data = {
        'doctor_id': doctorId,
        'patient_id': userId,
        'scheduled_at': scheduledAt.toIso8601String(),
        'duration': duration,
        'status': 'upcoming',
        'booking_type': 'online',
        'is_consultation': isConsultation,
        'patient_name_snapshot': patientName,
        'patient_phone_snapshot': patientPhone,
        'notes': notes,
      };

      final response = await _client
          .from('appointments')
          .insert(data)
          .select()
          .maybeSingle();

      if (response == null) {
        return AppointmentResult.failure('Failed to create appointment');
      }

      return AppointmentResult.success(Appointment.fromDatabase(response));
    } catch (e) {
      final errorMsg = e.toString().toLowerCase();
      if (errorMsg.contains('not available') || errorMsg.contains('conflict')) {
        return AppointmentResult.failure('This time slot is not available');
      }
      if (errorMsg.contains('not available for booking')) {
        return AppointmentResult.failure('Doctor is not available for booking');
      }
      return AppointmentResult.failure('Failed to create appointment');
    }
  }

  Future<AppointmentResult> createManualAppointment({
    required String doctorId,
    required DateTime scheduledAt,
    required int duration,
    required String patientName,
    String? patientPhone,
    String? notes,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        return AppointmentResult.failure('User not authenticated');
      }

      final data = {
        'doctor_id': doctorId,
        'scheduled_at': scheduledAt.toIso8601String(),
        'duration': duration,
        'status': 'upcoming',
        'booking_type': 'manual',
        'is_consultation': false,
        'patient_name_snapshot': patientName,
        'patient_phone_snapshot': patientPhone,
        'notes': notes,
      };

      final response = await _client
          .from('appointments')
          .insert(data)
          .select()
          .maybeSingle();

      if (response == null) {
        return AppointmentResult.failure('Failed to create manual appointment');
      }

      return AppointmentResult.success(Appointment.fromDatabase(response));
    } catch (e) {
      return AppointmentResult.failure('Failed to create manual appointment');
    }
  }

  Future<bool> cancelAppointment(String appointmentId) async {
    try {
      await _client
          .from('appointments')
          .update({'status': 'cancelled'})
          .eq('id', appointmentId)
          .eq('status', 'upcoming');
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateAppointmentStatus(
    String appointmentId,
    AppointmentStatus status,
  ) async {
    try {
      await _client
          .from('appointments')
          .update({'status': status.name})
          .eq('id', appointmentId);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<List<TimeSlot>> generateAvailableSlots({
    required String doctorId,
    required DateTime date,
    required int durationMinutes,
  }) async {
    try {
      final doctorResponse = await _client
          .from('doctors')
          .select()
          .eq('id', doctorId)
          .maybeSingle();

      if (doctorResponse == null) return [];

      final doctor = Doctor.fromDatabase(doctorResponse);

      final dayName = _getDayName(date);
      if (!doctor.workingDays.contains(dayName)) {
        return [];
      }

      final existingAppointments = await getDoctorAppointmentsByDate(date);

      final slots = <TimeSlot>[];
      final slotStart = doctor.openingAt;
      final slotEnd = doctor.closingAt;

      for (var hour = slotStart; hour < slotEnd; hour++) {
        for (var minute = 0; minute < 60; minute += durationMinutes) {
          final startTime = DateTime(date.year, date.month, date.day, hour, minute);
          final endTime = startTime.add(Duration(minutes: durationMinutes));

          if (endTime.hour > slotEnd || (endTime.hour == slotEnd && endTime.minute > 0)) {
            continue;
          }

          bool isBreak = false;
          if (doctor.breakStart != null && doctor.breakEnd != null) {
            final breakStartMinutes = doctor.breakStart! * 60;
            final breakEndMinutes = doctor.breakEnd! * 60;
            final slotMinutes = hour * 60 + minute;
            final slotEndMinutes = slotMinutes + durationMinutes;

            if ((slotMinutes >= breakStartMinutes && slotMinutes < breakEndMinutes) ||
                (slotEndMinutes > breakStartMinutes && slotEndMinutes <= breakEndMinutes)) {
              isBreak = true;
            }
          }

          bool isBooked = existingAppointments.any((apt) {
            final aptEnd = apt.scheduledAt.add(Duration(minutes: apt.duration));
            return startTime.isBefore(aptEnd) && endTime.isAfter(apt.scheduledAt);
          });

          slots.add(TimeSlot(
            startTime: startTime,
            endTime: endTime,
            durationMinutes: durationMinutes,
            isAvailable: !isBreak && !isBooked && startTime.isAfter(DateTime.now()),
          ));
        }
      }

      return slots;
    } catch (e) {
      return [];
    }
  }

  String _getDayName(DateTime date) {
    const days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    return days[date.weekday - 1];
  }
}

class AppointmentResult {
  final bool isSuccess;
  final Appointment? appointment;
  final String? error;

  AppointmentResult._({
    required this.isSuccess,
    this.appointment,
    this.error,
  });

  factory AppointmentResult.success(Appointment appointment) {
    return AppointmentResult._(isSuccess: true, appointment: appointment);
  }

  factory AppointmentResult.failure(String error) {
    return AppointmentResult._(isSuccess: false, error: error);
  }
}
