// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'doctor.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$DoctorImpl _$$DoctorImplFromJson(Map<String, dynamic> json) => _$DoctorImpl(
  id: json['id'] as String,
  specialty: json['specialty'] as String,
  address: json['address'] as String,
  city: json['city'] as String?,
  mapsLink: json['mapsLink'] as String?,
  latitude: (json['latitude'] as num?)?.toDouble(),
  longitude: (json['longitude'] as num?)?.toDouble(),
  bio: json['bio'] as String?,
  photoUrl: json['photoUrl'] as String?,
  appointmentDuration: (json['appointmentDuration'] as num?)?.toInt() ?? 20,
  consultationDuration: (json['consultationDuration'] as num?)?.toInt() ?? 40,
  openingAt: json['openingAt'] as String? ?? '09:00:00',
  closingAt: json['closingAt'] as String? ?? '17:00:00',
  breakStart: (json['breakStart'] as num?)?.toInt(),
  breakEnd: (json['breakEnd'] as num?)?.toInt(),
  workingDays:
      (json['workingDays'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  manualPause: json['manualPause'] as bool? ?? false,
  subscriptionEnd: json['subscriptionEnd'] == null
      ? null
      : DateTime.parse(json['subscriptionEnd'] as String),
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$$DoctorImplToJson(_$DoctorImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'specialty': instance.specialty,
      'address': instance.address,
      'city': instance.city,
      'mapsLink': instance.mapsLink,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'bio': instance.bio,
      'photoUrl': instance.photoUrl,
      'appointmentDuration': instance.appointmentDuration,
      'consultationDuration': instance.consultationDuration,
      'openingAt': instance.openingAt,
      'closingAt': instance.closingAt,
      'breakStart': instance.breakStart,
      'breakEnd': instance.breakEnd,
      'workingDays': instance.workingDays,
      'manualPause': instance.manualPause,
      'subscriptionEnd': instance.subscriptionEnd?.toIso8601String(),
      'createdAt': instance.createdAt?.toIso8601String(),
    };
