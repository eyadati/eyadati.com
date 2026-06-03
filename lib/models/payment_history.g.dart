// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_history.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PaymentHistoryImpl _$$PaymentHistoryImplFromJson(Map<String, dynamic> json) =>
    _$PaymentHistoryImpl(
      id: json['id'] as String,
      doctorId: json['doctorId'] as String,
      amount: (json['amount'] as num).toInt(),
      currency: json['currency'] as String,
      chargilyCheckoutId: json['chargilyCheckoutId'] as String?,
      chargilyEventId: json['chargilyEventId'] as String?,
      status: json['status'] as String,
      planType: json['planType'] as String,
      durationDays: (json['durationDays'] as num).toInt(),
      periodStart: DateTime.parse(json['periodStart'] as String),
      periodEnd: DateTime.parse(json['periodEnd'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$PaymentHistoryImplToJson(
  _$PaymentHistoryImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'doctorId': instance.doctorId,
  'amount': instance.amount,
  'currency': instance.currency,
  'chargilyCheckoutId': instance.chargilyCheckoutId,
  'chargilyEventId': instance.chargilyEventId,
  'status': instance.status,
  'planType': instance.planType,
  'durationDays': instance.durationDays,
  'periodStart': instance.periodStart.toIso8601String(),
  'periodEnd': instance.periodEnd.toIso8601String(),
  'createdAt': instance.createdAt.toIso8601String(),
};
