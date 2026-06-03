class AppointmentData {
  final String id;
  final DateTime startTime;
  final DateTime endTime;
  final String patientName;
  final String? patientAvatar;
  final String? patientPhone;
  final String status;
  final bool isConsultation;
  final String? notes;
  final int duration;
  final String? patientId;
  final String bookingType;
  final String doctorId;
  final String doctorName;

  AppointmentData({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.patientName,
    this.patientAvatar,
    this.patientPhone,
    required this.status,
    this.isConsultation = false,
    this.notes,
    this.duration = 30,
    this.patientId,
    this.bookingType = 'online',
    this.doctorId = '',
    this.doctorName = '',
  });
}