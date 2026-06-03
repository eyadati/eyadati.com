// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'payment_history.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

PaymentHistory _$PaymentHistoryFromJson(Map<String, dynamic> json) {
  return _PaymentHistory.fromJson(json);
}

/// @nodoc
mixin _$PaymentHistory {
  String get id => throw _privateConstructorUsedError;
  String get doctorId => throw _privateConstructorUsedError;
  int get amount => throw _privateConstructorUsedError;
  String get currency => throw _privateConstructorUsedError;
  String? get chargilyCheckoutId => throw _privateConstructorUsedError;
  String? get chargilyEventId => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  String get planType => throw _privateConstructorUsedError;
  int get durationDays => throw _privateConstructorUsedError;
  DateTime get periodStart => throw _privateConstructorUsedError;
  DateTime get periodEnd => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// Serializes this PaymentHistory to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PaymentHistory
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PaymentHistoryCopyWith<PaymentHistory> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PaymentHistoryCopyWith<$Res> {
  factory $PaymentHistoryCopyWith(
    PaymentHistory value,
    $Res Function(PaymentHistory) then,
  ) = _$PaymentHistoryCopyWithImpl<$Res, PaymentHistory>;
  @useResult
  $Res call({
    String id,
    String doctorId,
    int amount,
    String currency,
    String? chargilyCheckoutId,
    String? chargilyEventId,
    String status,
    String planType,
    int durationDays,
    DateTime periodStart,
    DateTime periodEnd,
    DateTime createdAt,
  });
}

/// @nodoc
class _$PaymentHistoryCopyWithImpl<$Res, $Val extends PaymentHistory>
    implements $PaymentHistoryCopyWith<$Res> {
  _$PaymentHistoryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PaymentHistory
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? doctorId = null,
    Object? amount = null,
    Object? currency = null,
    Object? chargilyCheckoutId = freezed,
    Object? chargilyEventId = freezed,
    Object? status = null,
    Object? planType = null,
    Object? durationDays = null,
    Object? periodStart = null,
    Object? periodEnd = null,
    Object? createdAt = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            doctorId: null == doctorId
                ? _value.doctorId
                : doctorId // ignore: cast_nullable_to_non_nullable
                      as String,
            amount: null == amount
                ? _value.amount
                : amount // ignore: cast_nullable_to_non_nullable
                      as int,
            currency: null == currency
                ? _value.currency
                : currency // ignore: cast_nullable_to_non_nullable
                      as String,
            chargilyCheckoutId: freezed == chargilyCheckoutId
                ? _value.chargilyCheckoutId
                : chargilyCheckoutId // ignore: cast_nullable_to_non_nullable
                      as String?,
            chargilyEventId: freezed == chargilyEventId
                ? _value.chargilyEventId
                : chargilyEventId // ignore: cast_nullable_to_non_nullable
                      as String?,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as String,
            planType: null == planType
                ? _value.planType
                : planType // ignore: cast_nullable_to_non_nullable
                      as String,
            durationDays: null == durationDays
                ? _value.durationDays
                : durationDays // ignore: cast_nullable_to_non_nullable
                      as int,
            periodStart: null == periodStart
                ? _value.periodStart
                : periodStart // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            periodEnd: null == periodEnd
                ? _value.periodEnd
                : periodEnd // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PaymentHistoryImplCopyWith<$Res>
    implements $PaymentHistoryCopyWith<$Res> {
  factory _$$PaymentHistoryImplCopyWith(
    _$PaymentHistoryImpl value,
    $Res Function(_$PaymentHistoryImpl) then,
  ) = __$$PaymentHistoryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String doctorId,
    int amount,
    String currency,
    String? chargilyCheckoutId,
    String? chargilyEventId,
    String status,
    String planType,
    int durationDays,
    DateTime periodStart,
    DateTime periodEnd,
    DateTime createdAt,
  });
}

/// @nodoc
class __$$PaymentHistoryImplCopyWithImpl<$Res>
    extends _$PaymentHistoryCopyWithImpl<$Res, _$PaymentHistoryImpl>
    implements _$$PaymentHistoryImplCopyWith<$Res> {
  __$$PaymentHistoryImplCopyWithImpl(
    _$PaymentHistoryImpl _value,
    $Res Function(_$PaymentHistoryImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PaymentHistory
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? doctorId = null,
    Object? amount = null,
    Object? currency = null,
    Object? chargilyCheckoutId = freezed,
    Object? chargilyEventId = freezed,
    Object? status = null,
    Object? planType = null,
    Object? durationDays = null,
    Object? periodStart = null,
    Object? periodEnd = null,
    Object? createdAt = null,
  }) {
    return _then(
      _$PaymentHistoryImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        doctorId: null == doctorId
            ? _value.doctorId
            : doctorId // ignore: cast_nullable_to_non_nullable
                  as String,
        amount: null == amount
            ? _value.amount
            : amount // ignore: cast_nullable_to_non_nullable
                  as int,
        currency: null == currency
            ? _value.currency
            : currency // ignore: cast_nullable_to_non_nullable
                  as String,
        chargilyCheckoutId: freezed == chargilyCheckoutId
            ? _value.chargilyCheckoutId
            : chargilyCheckoutId // ignore: cast_nullable_to_non_nullable
                  as String?,
        chargilyEventId: freezed == chargilyEventId
            ? _value.chargilyEventId
            : chargilyEventId // ignore: cast_nullable_to_non_nullable
                  as String?,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String,
        planType: null == planType
            ? _value.planType
            : planType // ignore: cast_nullable_to_non_nullable
                  as String,
        durationDays: null == durationDays
            ? _value.durationDays
            : durationDays // ignore: cast_nullable_to_non_nullable
                  as int,
        periodStart: null == periodStart
            ? _value.periodStart
            : periodStart // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        periodEnd: null == periodEnd
            ? _value.periodEnd
            : periodEnd // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PaymentHistoryImpl implements _PaymentHistory {
  const _$PaymentHistoryImpl({
    required this.id,
    required this.doctorId,
    required this.amount,
    required this.currency,
    this.chargilyCheckoutId,
    this.chargilyEventId,
    required this.status,
    required this.planType,
    required this.durationDays,
    required this.periodStart,
    required this.periodEnd,
    required this.createdAt,
  });

  factory _$PaymentHistoryImpl.fromJson(Map<String, dynamic> json) =>
      _$$PaymentHistoryImplFromJson(json);

  @override
  final String id;
  @override
  final String doctorId;
  @override
  final int amount;
  @override
  final String currency;
  @override
  final String? chargilyCheckoutId;
  @override
  final String? chargilyEventId;
  @override
  final String status;
  @override
  final String planType;
  @override
  final int durationDays;
  @override
  final DateTime periodStart;
  @override
  final DateTime periodEnd;
  @override
  final DateTime createdAt;

  @override
  String toString() {
    return 'PaymentHistory(id: $id, doctorId: $doctorId, amount: $amount, currency: $currency, chargilyCheckoutId: $chargilyCheckoutId, chargilyEventId: $chargilyEventId, status: $status, planType: $planType, durationDays: $durationDays, periodStart: $periodStart, periodEnd: $periodEnd, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PaymentHistoryImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.doctorId, doctorId) ||
                other.doctorId == doctorId) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.currency, currency) ||
                other.currency == currency) &&
            (identical(other.chargilyCheckoutId, chargilyCheckoutId) ||
                other.chargilyCheckoutId == chargilyCheckoutId) &&
            (identical(other.chargilyEventId, chargilyEventId) ||
                other.chargilyEventId == chargilyEventId) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.planType, planType) ||
                other.planType == planType) &&
            (identical(other.durationDays, durationDays) ||
                other.durationDays == durationDays) &&
            (identical(other.periodStart, periodStart) ||
                other.periodStart == periodStart) &&
            (identical(other.periodEnd, periodEnd) ||
                other.periodEnd == periodEnd) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    doctorId,
    amount,
    currency,
    chargilyCheckoutId,
    chargilyEventId,
    status,
    planType,
    durationDays,
    periodStart,
    periodEnd,
    createdAt,
  );

  /// Create a copy of PaymentHistory
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PaymentHistoryImplCopyWith<_$PaymentHistoryImpl> get copyWith =>
      __$$PaymentHistoryImplCopyWithImpl<_$PaymentHistoryImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$PaymentHistoryImplToJson(this);
  }
}

abstract class _PaymentHistory implements PaymentHistory {
  const factory _PaymentHistory({
    required final String id,
    required final String doctorId,
    required final int amount,
    required final String currency,
    final String? chargilyCheckoutId,
    final String? chargilyEventId,
    required final String status,
    required final String planType,
    required final int durationDays,
    required final DateTime periodStart,
    required final DateTime periodEnd,
    required final DateTime createdAt,
  }) = _$PaymentHistoryImpl;

  factory _PaymentHistory.fromJson(Map<String, dynamic> json) =
      _$PaymentHistoryImpl.fromJson;

  @override
  String get id;
  @override
  String get doctorId;
  @override
  int get amount;
  @override
  String get currency;
  @override
  String? get chargilyCheckoutId;
  @override
  String? get chargilyEventId;
  @override
  String get status;
  @override
  String get planType;
  @override
  int get durationDays;
  @override
  DateTime get periodStart;
  @override
  DateTime get periodEnd;
  @override
  DateTime get createdAt;

  /// Create a copy of PaymentHistory
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PaymentHistoryImplCopyWith<_$PaymentHistoryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
