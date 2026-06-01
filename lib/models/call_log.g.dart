// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'call_log.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CallLogImpl _$$CallLogImplFromJson(Map<String, dynamic> json) =>
    _$CallLogImpl(
      id: json['id'] as String,
      doctorId: json['doctorId'] as String,
      patientPhone: json['patientPhone'] as String,
      patientName: json['patientName'] as String?,
      patientId: json['patientId'] as String?,
      status: json['status'] as String? ?? 'pending',
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$CallLogImplToJson(_$CallLogImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'doctorId': instance.doctorId,
      'patientPhone': instance.patientPhone,
      'patientName': instance.patientName,
      'patientId': instance.patientId,
      'status': instance.status,
      'createdAt': instance.createdAt.toIso8601String(),
    };
