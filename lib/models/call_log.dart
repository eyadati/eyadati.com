import 'package:freezed_annotation/freezed_annotation.dart';

part 'call_log.freezed.dart';
part 'call_log.g.dart';

@freezed
class CallLog with _$CallLog {
  const factory CallLog({
    required String id,
    required String doctorId,
    required String patientPhone,
    String? patientName,
    String? patientId,
    @Default('pending') String status,
    required DateTime createdAt,
  }) = _CallLog;

  factory CallLog.fromJson(Map<String, dynamic> json) => _$CallLogFromJson(json);
}
