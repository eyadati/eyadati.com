// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'call_log.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CallLogImpl _$$CallLogImplFromJson(Map<String, dynamic> json) =>
    _$CallLogImpl(
      id: json['id'] as String,
      doctorId: json['doctor_id'] as String,
      patientPhone: json['patient_phone'] as String,
      patientName: json['patient_name'] as String?,
      patientId: json['patient_id'] as String?,
      status: json['status'] as String? ?? 'pending',
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$$CallLogImplToJson(_$CallLogImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'doctor_id': instance.doctorId,
      'patient_phone': instance.patientPhone,
      'patient_name': instance.patientName,
      'patient_id': instance.patientId,
      'status': instance.status,
      'created_at': instance.createdAt.toIso8601String(),
    };
