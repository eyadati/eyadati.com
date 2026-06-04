// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'call_log.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

CallLog _$CallLogFromJson(Map<String, dynamic> json) {
  return _CallLog.fromJson(json);
}

/// @nodoc
mixin _$CallLog {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'doctor_id')
  String get doctorId => throw _privateConstructorUsedError;
  @JsonKey(name: 'patient_phone')
  String get patientPhone => throw _privateConstructorUsedError;
  @JsonKey(name: 'patient_name')
  String? get patientName => throw _privateConstructorUsedError;
  @JsonKey(name: 'patient_id')
  String? get patientId => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// Serializes this CallLog to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CallLog
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CallLogCopyWith<CallLog> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CallLogCopyWith<$Res> {
  factory $CallLogCopyWith(CallLog value, $Res Function(CallLog) then) =
      _$CallLogCopyWithImpl<$Res, CallLog>;
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'doctor_id') String doctorId,
    @JsonKey(name: 'patient_phone') String patientPhone,
    @JsonKey(name: 'patient_name') String? patientName,
    @JsonKey(name: 'patient_id') String? patientId,
    String status,
    @JsonKey(name: 'created_at') DateTime createdAt,
  });
}

/// @nodoc
class _$CallLogCopyWithImpl<$Res, $Val extends CallLog>
    implements $CallLogCopyWith<$Res> {
  _$CallLogCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CallLog
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? doctorId = null,
    Object? patientPhone = null,
    Object? patientName = freezed,
    Object? patientId = freezed,
    Object? status = null,
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
            patientPhone: null == patientPhone
                ? _value.patientPhone
                : patientPhone // ignore: cast_nullable_to_non_nullable
                      as String,
            patientName: freezed == patientName
                ? _value.patientName
                : patientName // ignore: cast_nullable_to_non_nullable
                      as String?,
            patientId: freezed == patientId
                ? _value.patientId
                : patientId // ignore: cast_nullable_to_non_nullable
                      as String?,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as String,
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
abstract class _$$CallLogImplCopyWith<$Res> implements $CallLogCopyWith<$Res> {
  factory _$$CallLogImplCopyWith(
    _$CallLogImpl value,
    $Res Function(_$CallLogImpl) then,
  ) = __$$CallLogImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'doctor_id') String doctorId,
    @JsonKey(name: 'patient_phone') String patientPhone,
    @JsonKey(name: 'patient_name') String? patientName,
    @JsonKey(name: 'patient_id') String? patientId,
    String status,
    @JsonKey(name: 'created_at') DateTime createdAt,
  });
}

/// @nodoc
class __$$CallLogImplCopyWithImpl<$Res>
    extends _$CallLogCopyWithImpl<$Res, _$CallLogImpl>
    implements _$$CallLogImplCopyWith<$Res> {
  __$$CallLogImplCopyWithImpl(
    _$CallLogImpl _value,
    $Res Function(_$CallLogImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CallLog
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? doctorId = null,
    Object? patientPhone = null,
    Object? patientName = freezed,
    Object? patientId = freezed,
    Object? status = null,
    Object? createdAt = null,
  }) {
    return _then(
      _$CallLogImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        doctorId: null == doctorId
            ? _value.doctorId
            : doctorId // ignore: cast_nullable_to_non_nullable
                  as String,
        patientPhone: null == patientPhone
            ? _value.patientPhone
            : patientPhone // ignore: cast_nullable_to_non_nullable
                  as String,
        patientName: freezed == patientName
            ? _value.patientName
            : patientName // ignore: cast_nullable_to_non_nullable
                  as String?,
        patientId: freezed == patientId
            ? _value.patientId
            : patientId // ignore: cast_nullable_to_non_nullable
                  as String?,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String,
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
class _$CallLogImpl implements _CallLog {
  const _$CallLogImpl({
    required this.id,
    @JsonKey(name: 'doctor_id') required this.doctorId,
    @JsonKey(name: 'patient_phone') required this.patientPhone,
    @JsonKey(name: 'patient_name') this.patientName,
    @JsonKey(name: 'patient_id') this.patientId,
    this.status = 'pending',
    @JsonKey(name: 'created_at') required this.createdAt,
  });

  factory _$CallLogImpl.fromJson(Map<String, dynamic> json) =>
      _$$CallLogImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'doctor_id')
  final String doctorId;
  @override
  @JsonKey(name: 'patient_phone')
  final String patientPhone;
  @override
  @JsonKey(name: 'patient_name')
  final String? patientName;
  @override
  @JsonKey(name: 'patient_id')
  final String? patientId;
  @override
  @JsonKey()
  final String status;
  @override
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  @override
  String toString() {
    return 'CallLog(id: $id, doctorId: $doctorId, patientPhone: $patientPhone, patientName: $patientName, patientId: $patientId, status: $status, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CallLogImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.doctorId, doctorId) ||
                other.doctorId == doctorId) &&
            (identical(other.patientPhone, patientPhone) ||
                other.patientPhone == patientPhone) &&
            (identical(other.patientName, patientName) ||
                other.patientName == patientName) &&
            (identical(other.patientId, patientId) ||
                other.patientId == patientId) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    doctorId,
    patientPhone,
    patientName,
    patientId,
    status,
    createdAt,
  );

  /// Create a copy of CallLog
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CallLogImplCopyWith<_$CallLogImpl> get copyWith =>
      __$$CallLogImplCopyWithImpl<_$CallLogImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CallLogImplToJson(this);
  }
}

abstract class _CallLog implements CallLog {
  const factory _CallLog({
    required final String id,
    @JsonKey(name: 'doctor_id') required final String doctorId,
    @JsonKey(name: 'patient_phone') required final String patientPhone,
    @JsonKey(name: 'patient_name') final String? patientName,
    @JsonKey(name: 'patient_id') final String? patientId,
    final String status,
    @JsonKey(name: 'created_at') required final DateTime createdAt,
  }) = _$CallLogImpl;

  factory _CallLog.fromJson(Map<String, dynamic> json) = _$CallLogImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'doctor_id')
  String get doctorId;
  @override
  @JsonKey(name: 'patient_phone')
  String get patientPhone;
  @override
  @JsonKey(name: 'patient_name')
  String? get patientName;
  @override
  @JsonKey(name: 'patient_id')
  String? get patientId;
  @override
  String get status;
  @override
  @JsonKey(name: 'created_at')
  DateTime get createdAt;

  /// Create a copy of CallLog
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CallLogImplCopyWith<_$CallLogImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
