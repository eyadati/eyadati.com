import 'package:freezed_annotation/freezed_annotation.dart';

part 'call_log.freezed.dart';
part 'call_log.g.dart';

@freezed
class CallLog with _$CallLog {
  const factory CallLog({
    required String id,
    @JsonKey(name: 'doctor_id') required String doctorId,
    @JsonKey(name: 'patient_phone') required String patientPhone,
    @JsonKey(name: 'patient_name') String? patientName,
    @JsonKey(name: 'patient_id') String? patientId,
    @Default('pending') String status,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _CallLog;

  factory CallLog.fromJson(Map<String, dynamic> json) => _$CallLogFromJson(json);
}
