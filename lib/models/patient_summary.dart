import 'package:eyadati/models/appointment_data.dart';

class PatientSummary {
  final String patientId;
  final String patientName;
  final String? patientPhone;
  final String? patientAvatar;
  final int visitCount;
  final int noShowCount;
  final DateTime? lastNoShowAt;
  final DateTime lastVisitDate;
  final String? latestNotePreview;
  final List<AppointmentData> visits;

  PatientSummary({
    required this.patientId,
    required this.patientName,
    this.patientPhone,
    this.patientAvatar,
    required this.visitCount,
    this.noShowCount = 0,
    this.lastNoShowAt,
    required this.lastVisitDate,
    this.latestNotePreview,
    required this.visits,
  });
}
