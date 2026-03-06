// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'drive_repository.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$DriveResult<T> {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(T data) success,
    required TResult Function(DriveFailure failure) failure,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(T data)? success,
    TResult? Function(DriveFailure failure)? failure,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(T data)? success,
    TResult Function(DriveFailure failure)? failure,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(DriveSuccess<T> value) success,
    required TResult Function(DriveFailureResult<T> value) failure,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(DriveSuccess<T> value)? success,
    TResult? Function(DriveFailureResult<T> value)? failure,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(DriveSuccess<T> value)? success,
    TResult Function(DriveFailureResult<T> value)? failure,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DriveResultCopyWith<T, $Res> {
  factory $DriveResultCopyWith(
    DriveResult<T> value,
    $Res Function(DriveResult<T>) then,
  ) = _$DriveResultCopyWithImpl<T, $Res, DriveResult<T>>;
}

/// @nodoc
class _$DriveResultCopyWithImpl<T, $Res, $Val extends DriveResult<T>>
    implements $DriveResultCopyWith<T, $Res> {
  _$DriveResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DriveResult
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$DriveSuccessImplCopyWith<T, $Res> {
  factory _$$DriveSuccessImplCopyWith(
    _$DriveSuccessImpl<T> value,
    $Res Function(_$DriveSuccessImpl<T>) then,
  ) = __$$DriveSuccessImplCopyWithImpl<T, $Res>;
  @useResult
  $Res call({T data});
}

/// @nodoc
class __$$DriveSuccessImplCopyWithImpl<T, $Res>
    extends _$DriveResultCopyWithImpl<T, $Res, _$DriveSuccessImpl<T>>
    implements _$$DriveSuccessImplCopyWith<T, $Res> {
  __$$DriveSuccessImplCopyWithImpl(
    _$DriveSuccessImpl<T> _value,
    $Res Function(_$DriveSuccessImpl<T>) _then,
  ) : super(_value, _then);

  /// Create a copy of DriveResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? data = freezed}) {
    return _then(
      _$DriveSuccessImpl<T>(
        freezed == data
            ? _value.data
            : data // ignore: cast_nullable_to_non_nullable
                  as T,
      ),
    );
  }
}

/// @nodoc

class _$DriveSuccessImpl<T> implements DriveSuccess<T> {
  const _$DriveSuccessImpl(this.data);

  @override
  final T data;

  @override
  String toString() {
    return 'DriveResult<$T>.success(data: $data)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DriveSuccessImpl<T> &&
            const DeepCollectionEquality().equals(other.data, data));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(data));

  /// Create a copy of DriveResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DriveSuccessImplCopyWith<T, _$DriveSuccessImpl<T>> get copyWith =>
      __$$DriveSuccessImplCopyWithImpl<T, _$DriveSuccessImpl<T>>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(T data) success,
    required TResult Function(DriveFailure failure) failure,
  }) {
    return success(data);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(T data)? success,
    TResult? Function(DriveFailure failure)? failure,
  }) {
    return success?.call(data);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(T data)? success,
    TResult Function(DriveFailure failure)? failure,
    required TResult orElse(),
  }) {
    if (success != null) {
      return success(data);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(DriveSuccess<T> value) success,
    required TResult Function(DriveFailureResult<T> value) failure,
  }) {
    return success(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(DriveSuccess<T> value)? success,
    TResult? Function(DriveFailureResult<T> value)? failure,
  }) {
    return success?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(DriveSuccess<T> value)? success,
    TResult Function(DriveFailureResult<T> value)? failure,
    required TResult orElse(),
  }) {
    if (success != null) {
      return success(this);
    }
    return orElse();
  }
}

abstract class DriveSuccess<T> implements DriveResult<T> {
  const factory DriveSuccess(final T data) = _$DriveSuccessImpl<T>;

  T get data;

  /// Create a copy of DriveResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DriveSuccessImplCopyWith<T, _$DriveSuccessImpl<T>> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$DriveFailureResultImplCopyWith<T, $Res> {
  factory _$$DriveFailureResultImplCopyWith(
    _$DriveFailureResultImpl<T> value,
    $Res Function(_$DriveFailureResultImpl<T>) then,
  ) = __$$DriveFailureResultImplCopyWithImpl<T, $Res>;
  @useResult
  $Res call({DriveFailure failure});

  $DriveFailureCopyWith<$Res> get failure;
}

/// @nodoc
class __$$DriveFailureResultImplCopyWithImpl<T, $Res>
    extends _$DriveResultCopyWithImpl<T, $Res, _$DriveFailureResultImpl<T>>
    implements _$$DriveFailureResultImplCopyWith<T, $Res> {
  __$$DriveFailureResultImplCopyWithImpl(
    _$DriveFailureResultImpl<T> _value,
    $Res Function(_$DriveFailureResultImpl<T>) _then,
  ) : super(_value, _then);

  /// Create a copy of DriveResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? failure = null}) {
    return _then(
      _$DriveFailureResultImpl<T>(
        null == failure
            ? _value.failure
            : failure // ignore: cast_nullable_to_non_nullable
                  as DriveFailure,
      ),
    );
  }

  /// Create a copy of DriveResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $DriveFailureCopyWith<$Res> get failure {
    return $DriveFailureCopyWith<$Res>(_value.failure, (value) {
      return _then(_value.copyWith(failure: value));
    });
  }
}

/// @nodoc

class _$DriveFailureResultImpl<T> implements DriveFailureResult<T> {
  const _$DriveFailureResultImpl(this.failure);

  @override
  final DriveFailure failure;

  @override
  String toString() {
    return 'DriveResult<$T>.failure(failure: $failure)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DriveFailureResultImpl<T> &&
            (identical(other.failure, failure) || other.failure == failure));
  }

  @override
  int get hashCode => Object.hash(runtimeType, failure);

  /// Create a copy of DriveResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DriveFailureResultImplCopyWith<T, _$DriveFailureResultImpl<T>>
  get copyWith =>
      __$$DriveFailureResultImplCopyWithImpl<T, _$DriveFailureResultImpl<T>>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(T data) success,
    required TResult Function(DriveFailure failure) failure,
  }) {
    return failure(this.failure);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(T data)? success,
    TResult? Function(DriveFailure failure)? failure,
  }) {
    return failure?.call(this.failure);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(T data)? success,
    TResult Function(DriveFailure failure)? failure,
    required TResult orElse(),
  }) {
    if (failure != null) {
      return failure(this.failure);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(DriveSuccess<T> value) success,
    required TResult Function(DriveFailureResult<T> value) failure,
  }) {
    return failure(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(DriveSuccess<T> value)? success,
    TResult? Function(DriveFailureResult<T> value)? failure,
  }) {
    return failure?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(DriveSuccess<T> value)? success,
    TResult Function(DriveFailureResult<T> value)? failure,
    required TResult orElse(),
  }) {
    if (failure != null) {
      return failure(this);
    }
    return orElse();
  }
}

abstract class DriveFailureResult<T> implements DriveResult<T> {
  const factory DriveFailureResult(final DriveFailure failure) =
      _$DriveFailureResultImpl<T>;

  DriveFailure get failure;

  /// Create a copy of DriveResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DriveFailureResultImplCopyWith<T, _$DriveFailureResultImpl<T>>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$DriveFailure {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() notAuthenticated,
    required TResult Function(String message) networkError,
    required TResult Function(String message) downloadFailed,
    required TResult Function(String message) unknown,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? notAuthenticated,
    TResult? Function(String message)? networkError,
    TResult? Function(String message)? downloadFailed,
    TResult? Function(String message)? unknown,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? notAuthenticated,
    TResult Function(String message)? networkError,
    TResult Function(String message)? downloadFailed,
    TResult Function(String message)? unknown,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(DriveNotAuthenticated value) notAuthenticated,
    required TResult Function(DriveNetworkError value) networkError,
    required TResult Function(DriveDownloadFailed value) downloadFailed,
    required TResult Function(DriveUnknown value) unknown,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(DriveNotAuthenticated value)? notAuthenticated,
    TResult? Function(DriveNetworkError value)? networkError,
    TResult? Function(DriveDownloadFailed value)? downloadFailed,
    TResult? Function(DriveUnknown value)? unknown,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(DriveNotAuthenticated value)? notAuthenticated,
    TResult Function(DriveNetworkError value)? networkError,
    TResult Function(DriveDownloadFailed value)? downloadFailed,
    TResult Function(DriveUnknown value)? unknown,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DriveFailureCopyWith<$Res> {
  factory $DriveFailureCopyWith(
    DriveFailure value,
    $Res Function(DriveFailure) then,
  ) = _$DriveFailureCopyWithImpl<$Res, DriveFailure>;
}

/// @nodoc
class _$DriveFailureCopyWithImpl<$Res, $Val extends DriveFailure>
    implements $DriveFailureCopyWith<$Res> {
  _$DriveFailureCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DriveFailure
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$DriveNotAuthenticatedImplCopyWith<$Res> {
  factory _$$DriveNotAuthenticatedImplCopyWith(
    _$DriveNotAuthenticatedImpl value,
    $Res Function(_$DriveNotAuthenticatedImpl) then,
  ) = __$$DriveNotAuthenticatedImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$DriveNotAuthenticatedImplCopyWithImpl<$Res>
    extends _$DriveFailureCopyWithImpl<$Res, _$DriveNotAuthenticatedImpl>
    implements _$$DriveNotAuthenticatedImplCopyWith<$Res> {
  __$$DriveNotAuthenticatedImplCopyWithImpl(
    _$DriveNotAuthenticatedImpl _value,
    $Res Function(_$DriveNotAuthenticatedImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of DriveFailure
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$DriveNotAuthenticatedImpl implements DriveNotAuthenticated {
  const _$DriveNotAuthenticatedImpl();

  @override
  String toString() {
    return 'DriveFailure.notAuthenticated()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DriveNotAuthenticatedImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() notAuthenticated,
    required TResult Function(String message) networkError,
    required TResult Function(String message) downloadFailed,
    required TResult Function(String message) unknown,
  }) {
    return notAuthenticated();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? notAuthenticated,
    TResult? Function(String message)? networkError,
    TResult? Function(String message)? downloadFailed,
    TResult? Function(String message)? unknown,
  }) {
    return notAuthenticated?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? notAuthenticated,
    TResult Function(String message)? networkError,
    TResult Function(String message)? downloadFailed,
    TResult Function(String message)? unknown,
    required TResult orElse(),
  }) {
    if (notAuthenticated != null) {
      return notAuthenticated();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(DriveNotAuthenticated value) notAuthenticated,
    required TResult Function(DriveNetworkError value) networkError,
    required TResult Function(DriveDownloadFailed value) downloadFailed,
    required TResult Function(DriveUnknown value) unknown,
  }) {
    return notAuthenticated(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(DriveNotAuthenticated value)? notAuthenticated,
    TResult? Function(DriveNetworkError value)? networkError,
    TResult? Function(DriveDownloadFailed value)? downloadFailed,
    TResult? Function(DriveUnknown value)? unknown,
  }) {
    return notAuthenticated?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(DriveNotAuthenticated value)? notAuthenticated,
    TResult Function(DriveNetworkError value)? networkError,
    TResult Function(DriveDownloadFailed value)? downloadFailed,
    TResult Function(DriveUnknown value)? unknown,
    required TResult orElse(),
  }) {
    if (notAuthenticated != null) {
      return notAuthenticated(this);
    }
    return orElse();
  }
}

abstract class DriveNotAuthenticated implements DriveFailure {
  const factory DriveNotAuthenticated() = _$DriveNotAuthenticatedImpl;
}

/// @nodoc
abstract class _$$DriveNetworkErrorImplCopyWith<$Res> {
  factory _$$DriveNetworkErrorImplCopyWith(
    _$DriveNetworkErrorImpl value,
    $Res Function(_$DriveNetworkErrorImpl) then,
  ) = __$$DriveNetworkErrorImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String message});
}

/// @nodoc
class __$$DriveNetworkErrorImplCopyWithImpl<$Res>
    extends _$DriveFailureCopyWithImpl<$Res, _$DriveNetworkErrorImpl>
    implements _$$DriveNetworkErrorImplCopyWith<$Res> {
  __$$DriveNetworkErrorImplCopyWithImpl(
    _$DriveNetworkErrorImpl _value,
    $Res Function(_$DriveNetworkErrorImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of DriveFailure
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? message = null}) {
    return _then(
      _$DriveNetworkErrorImpl(
        null == message
            ? _value.message
            : message // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$DriveNetworkErrorImpl implements DriveNetworkError {
  const _$DriveNetworkErrorImpl(this.message);

  @override
  final String message;

  @override
  String toString() {
    return 'DriveFailure.networkError(message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DriveNetworkErrorImpl &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  /// Create a copy of DriveFailure
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DriveNetworkErrorImplCopyWith<_$DriveNetworkErrorImpl> get copyWith =>
      __$$DriveNetworkErrorImplCopyWithImpl<_$DriveNetworkErrorImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() notAuthenticated,
    required TResult Function(String message) networkError,
    required TResult Function(String message) downloadFailed,
    required TResult Function(String message) unknown,
  }) {
    return networkError(message);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? notAuthenticated,
    TResult? Function(String message)? networkError,
    TResult? Function(String message)? downloadFailed,
    TResult? Function(String message)? unknown,
  }) {
    return networkError?.call(message);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? notAuthenticated,
    TResult Function(String message)? networkError,
    TResult Function(String message)? downloadFailed,
    TResult Function(String message)? unknown,
    required TResult orElse(),
  }) {
    if (networkError != null) {
      return networkError(message);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(DriveNotAuthenticated value) notAuthenticated,
    required TResult Function(DriveNetworkError value) networkError,
    required TResult Function(DriveDownloadFailed value) downloadFailed,
    required TResult Function(DriveUnknown value) unknown,
  }) {
    return networkError(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(DriveNotAuthenticated value)? notAuthenticated,
    TResult? Function(DriveNetworkError value)? networkError,
    TResult? Function(DriveDownloadFailed value)? downloadFailed,
    TResult? Function(DriveUnknown value)? unknown,
  }) {
    return networkError?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(DriveNotAuthenticated value)? notAuthenticated,
    TResult Function(DriveNetworkError value)? networkError,
    TResult Function(DriveDownloadFailed value)? downloadFailed,
    TResult Function(DriveUnknown value)? unknown,
    required TResult orElse(),
  }) {
    if (networkError != null) {
      return networkError(this);
    }
    return orElse();
  }
}

abstract class DriveNetworkError implements DriveFailure {
  const factory DriveNetworkError(final String message) =
      _$DriveNetworkErrorImpl;

  String get message;

  /// Create a copy of DriveFailure
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DriveNetworkErrorImplCopyWith<_$DriveNetworkErrorImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$DriveDownloadFailedImplCopyWith<$Res> {
  factory _$$DriveDownloadFailedImplCopyWith(
    _$DriveDownloadFailedImpl value,
    $Res Function(_$DriveDownloadFailedImpl) then,
  ) = __$$DriveDownloadFailedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String message});
}

/// @nodoc
class __$$DriveDownloadFailedImplCopyWithImpl<$Res>
    extends _$DriveFailureCopyWithImpl<$Res, _$DriveDownloadFailedImpl>
    implements _$$DriveDownloadFailedImplCopyWith<$Res> {
  __$$DriveDownloadFailedImplCopyWithImpl(
    _$DriveDownloadFailedImpl _value,
    $Res Function(_$DriveDownloadFailedImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of DriveFailure
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? message = null}) {
    return _then(
      _$DriveDownloadFailedImpl(
        null == message
            ? _value.message
            : message // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$DriveDownloadFailedImpl implements DriveDownloadFailed {
  const _$DriveDownloadFailedImpl(this.message);

  @override
  final String message;

  @override
  String toString() {
    return 'DriveFailure.downloadFailed(message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DriveDownloadFailedImpl &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  /// Create a copy of DriveFailure
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DriveDownloadFailedImplCopyWith<_$DriveDownloadFailedImpl> get copyWith =>
      __$$DriveDownloadFailedImplCopyWithImpl<_$DriveDownloadFailedImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() notAuthenticated,
    required TResult Function(String message) networkError,
    required TResult Function(String message) downloadFailed,
    required TResult Function(String message) unknown,
  }) {
    return downloadFailed(message);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? notAuthenticated,
    TResult? Function(String message)? networkError,
    TResult? Function(String message)? downloadFailed,
    TResult? Function(String message)? unknown,
  }) {
    return downloadFailed?.call(message);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? notAuthenticated,
    TResult Function(String message)? networkError,
    TResult Function(String message)? downloadFailed,
    TResult Function(String message)? unknown,
    required TResult orElse(),
  }) {
    if (downloadFailed != null) {
      return downloadFailed(message);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(DriveNotAuthenticated value) notAuthenticated,
    required TResult Function(DriveNetworkError value) networkError,
    required TResult Function(DriveDownloadFailed value) downloadFailed,
    required TResult Function(DriveUnknown value) unknown,
  }) {
    return downloadFailed(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(DriveNotAuthenticated value)? notAuthenticated,
    TResult? Function(DriveNetworkError value)? networkError,
    TResult? Function(DriveDownloadFailed value)? downloadFailed,
    TResult? Function(DriveUnknown value)? unknown,
  }) {
    return downloadFailed?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(DriveNotAuthenticated value)? notAuthenticated,
    TResult Function(DriveNetworkError value)? networkError,
    TResult Function(DriveDownloadFailed value)? downloadFailed,
    TResult Function(DriveUnknown value)? unknown,
    required TResult orElse(),
  }) {
    if (downloadFailed != null) {
      return downloadFailed(this);
    }
    return orElse();
  }
}

abstract class DriveDownloadFailed implements DriveFailure {
  const factory DriveDownloadFailed(final String message) =
      _$DriveDownloadFailedImpl;

  String get message;

  /// Create a copy of DriveFailure
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DriveDownloadFailedImplCopyWith<_$DriveDownloadFailedImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$DriveUnknownImplCopyWith<$Res> {
  factory _$$DriveUnknownImplCopyWith(
    _$DriveUnknownImpl value,
    $Res Function(_$DriveUnknownImpl) then,
  ) = __$$DriveUnknownImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String message});
}

/// @nodoc
class __$$DriveUnknownImplCopyWithImpl<$Res>
    extends _$DriveFailureCopyWithImpl<$Res, _$DriveUnknownImpl>
    implements _$$DriveUnknownImplCopyWith<$Res> {
  __$$DriveUnknownImplCopyWithImpl(
    _$DriveUnknownImpl _value,
    $Res Function(_$DriveUnknownImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of DriveFailure
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? message = null}) {
    return _then(
      _$DriveUnknownImpl(
        null == message
            ? _value.message
            : message // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$DriveUnknownImpl implements DriveUnknown {
  const _$DriveUnknownImpl(this.message);

  @override
  final String message;

  @override
  String toString() {
    return 'DriveFailure.unknown(message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DriveUnknownImpl &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  /// Create a copy of DriveFailure
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DriveUnknownImplCopyWith<_$DriveUnknownImpl> get copyWith =>
      __$$DriveUnknownImplCopyWithImpl<_$DriveUnknownImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() notAuthenticated,
    required TResult Function(String message) networkError,
    required TResult Function(String message) downloadFailed,
    required TResult Function(String message) unknown,
  }) {
    return unknown(message);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? notAuthenticated,
    TResult? Function(String message)? networkError,
    TResult? Function(String message)? downloadFailed,
    TResult? Function(String message)? unknown,
  }) {
    return unknown?.call(message);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? notAuthenticated,
    TResult Function(String message)? networkError,
    TResult Function(String message)? downloadFailed,
    TResult Function(String message)? unknown,
    required TResult orElse(),
  }) {
    if (unknown != null) {
      return unknown(message);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(DriveNotAuthenticated value) notAuthenticated,
    required TResult Function(DriveNetworkError value) networkError,
    required TResult Function(DriveDownloadFailed value) downloadFailed,
    required TResult Function(DriveUnknown value) unknown,
  }) {
    return unknown(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(DriveNotAuthenticated value)? notAuthenticated,
    TResult? Function(DriveNetworkError value)? networkError,
    TResult? Function(DriveDownloadFailed value)? downloadFailed,
    TResult? Function(DriveUnknown value)? unknown,
  }) {
    return unknown?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(DriveNotAuthenticated value)? notAuthenticated,
    TResult Function(DriveNetworkError value)? networkError,
    TResult Function(DriveDownloadFailed value)? downloadFailed,
    TResult Function(DriveUnknown value)? unknown,
    required TResult orElse(),
  }) {
    if (unknown != null) {
      return unknown(this);
    }
    return orElse();
  }
}

abstract class DriveUnknown implements DriveFailure {
  const factory DriveUnknown(final String message) = _$DriveUnknownImpl;

  String get message;

  /// Create a copy of DriveFailure
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DriveUnknownImplCopyWith<_$DriveUnknownImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
