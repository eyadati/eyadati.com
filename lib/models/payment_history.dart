import 'package:freezed_annotation/freezed_annotation.dart';

part 'payment_history.freezed.dart';
part 'payment_history.g.dart';

@freezed
class PaymentHistory with _$PaymentHistory {
  const factory PaymentHistory({
    required String id,
    required String doctorId,
    required int amount,
    required String currency,
    String? chargilyCheckoutId,
    String? chargilyEventId,
    required String status,
    required String planType,
    required int durationDays,
    required DateTime periodStart,
    required DateTime periodEnd,
    required DateTime createdAt,
  }) = _PaymentHistory;

  factory PaymentHistory.fromJson(Map<String, dynamic> json) =>
      _$PaymentHistoryFromJson(json);

  factory PaymentHistory.fromDatabase(Map<String, dynamic> json) {
    return PaymentHistory(
      id: json['id'] as String,
      doctorId: json['doctor_id'] as String,
      amount: json['amount'] as int,
      currency: json['currency'] as String? ?? 'dzd',
      chargilyCheckoutId: json['chargily_checkout_id'] as String?,
      chargilyEventId: json['chargily_event_id'] as String?,
      status: json['status'] as String? ?? 'completed',
      planType: json['plan_type'] as String? ?? 'monthly',
      durationDays: json['duration_days'] as int? ?? 30,
      periodStart: DateTime.parse(json['period_start'] as String),
      periodEnd: DateTime.parse(json['period_end'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
