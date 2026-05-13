import 'package:eyadati/core/utils/time_utils.dart';

class ScheduleSlot {
  final String id;
  final String doctorId;
  final int dayOfWeek;
  final int startTime;
  final int endTime;
  final int? breakStart;
  final int? breakEnd;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ScheduleSlot({
    required this.id,
    required this.doctorId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.breakStart,
    this.breakEnd,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory ScheduleSlot.fromDbMap(Map<String, dynamic> json) {
    return ScheduleSlot(
      id: json['id'] as String,
      doctorId: json['doctor_id'] as String,
      dayOfWeek: json['day_of_week'] as int,
      startTime: _parseTime(json['start_time']),
      endTime: _parseTime(json['end_time']),
      breakStart: json['break_start'] != null ? _parseTime(json['break_start']) : null,
      breakEnd: json['break_end'] != null ? _parseTime(json['break_end']) : null,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  static int _parseTime(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return TimeUtils.stringToMinutes(value);
    return 0;
  }

  factory ScheduleSlot.fromJson(Map<String, dynamic> json) {
    return ScheduleSlot(
      id: json['id'] as String,
      doctorId: json['doctor_id'] as String,
      dayOfWeek: json['day_of_week'] as int,
      startTime: _parseTime(json['start_time']),
      endTime: _parseTime(json['end_time']),
      breakStart: json['break_start'] != null ? _parseTime(json['break_start']) : null,
      breakEnd: json['break_end'] != null ? _parseTime(json['break_end']) : null,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'doctor_id': doctorId,
      'day_of_week': dayOfWeek,
      'start_time': startTime,
      'end_time': endTime,
      if (breakStart != null) 'break_start': breakStart,
      if (breakEnd != null) 'break_end': breakEnd,
      'is_active': isActive,
    };
  }

  ScheduleSlot copyWith({
    String? id,
    String? doctorId,
    int? dayOfWeek,
    int? startTime,
    int? endTime,
    int? breakStart,
    int? breakEnd,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ScheduleSlot(
      id: id ?? this.id,
      doctorId: doctorId ?? this.doctorId,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      breakStart: breakStart ?? this.breakStart,
      breakEnd: breakEnd ?? this.breakEnd,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get hasBreak => breakStart != null && breakEnd != null;

  static String dayName(int dayOfWeek) {
    const days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    return days[dayOfWeek];
  }

  static String dayNameFrench(int dayOfWeek) {
    const days = ['Dimanche', 'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi'];
    return days[dayOfWeek];
  }
}