import 'package:eyadati/models/schedule_slot_model.dart';
import 'package:eyadati/models/appointment_data.dart';

class PotentialSlot {
  final DateTime startTime;
  final DateTime endTime;
  final int durationMinutes;

  const PotentialSlot({
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
  });

  @override
  String toString() =>
      '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PotentialSlot &&
          runtimeType == other.runtimeType &&
          startTime == other.startTime &&
          durationMinutes == other.durationMinutes;

  @override
  int get hashCode => startTime.hashCode ^ durationMinutes.hashCode;
}

class SlotEngine {
  final List<ScheduleSlot> scheduleSlots;
  final int appointmentDuration;
  final int consultationDuration;

  const SlotEngine({
    required this.scheduleSlots,
    this.appointmentDuration = 20,
    this.consultationDuration = 30,
  });

  static int _getDayOfWeek(DateTime date) => date.weekday % 7;

  List<PotentialSlot> generateSlotsForDay(
    DateTime date, {
    int? duration,
    bool isConsultation = false,
  }) {
    final effectiveDuration = duration ??
        (isConsultation ? consultationDuration : appointmentDuration);

    return _generateSlots(
      date: date,
      scheduleSlots: scheduleSlots,
      duration: effectiveDuration,
    );
  }

  List<PotentialSlot> generateConsultationSlotsForDay(DateTime date) {
    return _generateSlots(
      date: date,
      scheduleSlots: scheduleSlots,
      duration: consultationDuration,
    );
  }

  List<PotentialSlot> generateAppointmentSlotsForDay(DateTime date) {
    return _generateSlots(
      date: date,
      scheduleSlots: scheduleSlots,
      duration: appointmentDuration,
    );
  }

  List<PotentialSlot> _generateSlots({
    required DateTime date,
    required List<ScheduleSlot> scheduleSlots,
    required int duration,
  }) {
    final dayOfWeek = _getDayOfWeek(date);
    final daySlots = scheduleSlots.where((s) => s.dayOfWeek == dayOfWeek && s.isActive).toList();

    if (daySlots.isEmpty) return [];

    final now = DateTime.now();
    final isToday = date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;

    final List<PotentialSlot> slots = [];

    for (final slot in daySlots) {
      final slotTimes = _generateFromScheduleSlot(
        slot,
        date,
        duration,
        isToday: isToday,
        now: now,
      );
      slots.addAll(slotTimes);
    }

    slots.sort((a, b) => a.startTime.compareTo(b.startTime));
    return slots;
  }

  List<PotentialSlot> _generateFromScheduleSlot(
    ScheduleSlot scheduleSlot,
    DateTime date,
    int duration, {
    required bool isToday,
    required DateTime now,
  }) {
    final List<PotentialSlot> slots = [];

    final startMinutes = scheduleSlot.startTime;
    final endMinutes = scheduleSlot.endTime;
    final breakStartMinutes = scheduleSlot.breakStart;
    final breakEndMinutes = scheduleSlot.breakEnd;

    for (int m = startMinutes; m + duration <= endMinutes; m += duration) {
      final slotStart = date.add(Duration(minutes: m));
      final slotEnd = slotStart.add(Duration(minutes: duration));

      if (isToday && slotStart.isBefore(now)) continue;

      if (breakStartMinutes != null && breakEndMinutes != null) {
        if (m < breakEndMinutes! && (m + duration) > breakStartMinutes!) continue;
      }

      slots.add(PotentialSlot(
        startTime: slotStart,
        endTime: slotEnd,
        durationMinutes: duration,
      ));
    }

    return slots;
  }

  List<PotentialSlot> filterOccupied(
    List<PotentialSlot> potentialSlots,
    List<AppointmentData> appointments,
  ) {
    final activeAppointments = appointments.where(
      (apt) => apt.status == 'upcoming' || apt.status == 'pending',
    ).toList();
    if (activeAppointments.isEmpty) return potentialSlots;

    return potentialSlots.where((slot) {
      return !activeAppointments.any((apt) => _overlaps(slot, apt));
    }).toList();
  }

  bool _overlaps(PotentialSlot slot, AppointmentData apt) {
    return slot.startTime.isBefore(apt.endTime) &&
        slot.endTime.isAfter(apt.startTime);
  }

  List<PotentialSlot> getAvailableSlots(
    DateTime date, {
    int? duration,
    bool isConsultation = false,
    List<AppointmentData> existingAppointments = const [],
  }) {
    final potential = generateSlotsForDay(
      date,
      duration: duration,
      isConsultation: isConsultation,
    );
    return filterOccupied(potential, existingAppointments);
  }

  bool hasScheduleForDay(DateTime date) {
    final dayOfWeek = _getDayOfWeek(date);
    return scheduleSlots.any((s) => s.dayOfWeek == dayOfWeek && s.isActive);
  }

  List<ScheduleSlot> getScheduleForDay(DateTime date) {
    final dayOfWeek = _getDayOfWeek(date);
    return scheduleSlots.where((s) => s.dayOfWeek == dayOfWeek && s.isActive).toList();
  }

  int getWorkingHoursForDay(DateTime date) {
    final daySlots = getScheduleForDay(date);
    if (daySlots.isEmpty) return 0;

    int totalMinutes = 0;
    for (final slot in daySlots) {
      final startMins = slot.startTime;
      final endMins = slot.endTime;
      totalMinutes += endMins - startMins;

      if (slot.breakStart != null && slot.breakEnd != null) {
        totalMinutes -= slot.breakEnd! - slot.breakStart!;
      }
    }
    return totalMinutes ~/ 60;
  }

  static String minutesToTime(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }
}