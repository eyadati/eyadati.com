import 'package:eyadati/core/utils/time_utils.dart';
import 'package:eyadati/models/appointment_data.dart';
import '../presentation/providers/clinic_provider.dart';

class ClinicBookingService {
  /// Validates if a walk-in slot is available for the given doctor.
  /// Returns null if valid, or an error message string if invalid.
  static String? validateWalkInSlot({
    required List<ClinicGroupMember> members,
    required List<AppointmentData> appointments,
    required String doctorId,
    required DateTime scheduledAt,
    required int duration,
  }) {
    final member = members.firstWhere(
      (m) => m.doctorId == doctorId,
      orElse: () => ClinicGroupMember(doctorId: '', doctorName: ''),
    );
    if (member.doctorId.isEmpty) return 'Médecin introuvable';
    if (!member.isAvailable) return 'Ce médecin n\'est pas disponible : ${member.unavailabilityReason ?? 'raison inconnue'}';
    final dayOfWeek = scheduledAt.weekday % 7;
    final daySchedules = member.schedules.where((s) => s.dayOfWeek == dayOfWeek).toList();
    if (daySchedules.isEmpty) return 'Ce médecin ne travaille pas ce jour';
    final startMinute = TimeUtils.extractMinuteFromDate(scheduledAt);
    final endMinute = startMinute + duration;
    bool withinSchedule = false;
    for (final s in daySchedules) {
      if (startMinute >= s.startTime && endMinute <= s.endTime) {
        withinSchedule = true;
        if (s.hasBreak && TimeUtils.overlaps(startMinute, endMinute, s.breakStart!, s.breakEnd!)) {
          return 'Ce créneau tombe pendant la pause du médecin';
        }
        break;
      }
    }
    if (!withinSchedule) return 'Ce médecin ne travaille pas à cette heure';
    final dayAppointments = appointments.where((a) =>
      a.doctorId == doctorId &&
      a.startTime.year == scheduledAt.year &&
      a.startTime.month == scheduledAt.month &&
      a.startTime.day == scheduledAt.day &&
      a.status != 'cancelled' &&
      a.status != 'absent'
    );
    for (final apt in dayAppointments) {
      final aptStart = TimeUtils.extractMinuteFromDate(apt.startTime);
      final aptEnd = TimeUtils.extractMinuteFromDate(apt.endTime);
      if (TimeUtils.overlaps(startMinute, endMinute, aptStart, aptEnd)) {
        return 'Ce créneau est déjà occupé par un autre rendez-vous';
      }
    }
    return null;
  }

  /// Suggests the most available doctor for a given date/time.
  /// Prioritizes doctors who are available AND have a valid schedule at that time.
  static String? suggestMostAvailableDoctor({
    required List<ClinicGroupMember> members,
    required List<AppointmentData> appointments,
    required DateTime dateTime,
  }) {
    final available = members.where((m) => m.isAvailable).toList();
    if (available.isEmpty) return null;
    if (available.length == 1) return available.first.doctorId;

    final startOfDay = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final candidates = <ClinicGroupMember>[];
    for (final m in available) {
      final error = validateWalkInSlot(
        members: members,
        appointments: appointments,
        doctorId: m.doctorId,
        scheduledAt: dateTime,
        duration: 20,
      );
      if (error == null) {
        candidates.add(m);
      }
    }

    if (candidates.isEmpty) return available.first.doctorId;

    candidates.sort((a, b) {
      final aCount = appointments.where((apt) =>
        apt.doctorId == a.doctorId &&
        apt.startTime.isAfter(startOfDay) &&
        apt.startTime.isBefore(endOfDay) &&
        apt.status != 'cancelled'
      ).length;
      final bCount = appointments.where((apt) =>
        apt.doctorId == b.doctorId &&
        apt.startTime.isAfter(startOfDay) &&
        apt.startTime.isBefore(endOfDay) &&
        apt.status != 'cancelled'
      ).length;
      return aCount.compareTo(bCount);
    });

    return candidates.first.doctorId;
  }
}
