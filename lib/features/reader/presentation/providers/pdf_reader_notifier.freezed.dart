// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pdf_reader_notifier.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$PdfReaderState {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() loading,
    required TResult Function(PdfDocument pdf) loaded,
    required TResult Function() notFound,
    required TResult Function(String filePath) fileNotFound,
    required TResult Function(String message) error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? loading,
    TResult? Function(PdfDocument pdf)? loaded,
    TResult? Function()? notFound,
    TResult? Function(String filePath)? fileNotFound,
    TResult? Function(String message)? error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? loading,
    TResult Function(PdfDocument pdf)? loaded,
    TResult Function()? notFound,
    TResult Function(String filePath)? fileNotFound,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_PdfReaderLoading value) loading,
    required TResult Function(_PdfReaderLoaded value) loaded,
    required TResult Function(_PdfReaderNotFound value) notFound,
    required TResult Function(_PdfReaderFileNotFound value) fileNotFound,
    required TResult Function(_PdfReaderError value) error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_PdfReaderLoading value)? loading,
    TResult? Function(_PdfReaderLoaded value)? loaded,
    TResult? Function(_PdfReaderNotFound value)? notFound,
    TResult? Function(_PdfReaderFileNotFound value)? fileNotFound,
    TResult? Function(_PdfReaderError value)? error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_PdfReaderLoading value)? loading,
    TResult Function(_PdfReaderLoaded value)? loaded,
    TResult Function(_PdfReaderNotFound value)? notFound,
    TResult Function(_PdfReaderFileNotFound value)? fileNotFound,
    TResult Function(_PdfReaderError value)? error,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PdfReaderStateCopyWith<$Res> {
  factory $PdfReaderStateCopyWith(
    PdfReaderState value,
    $Res Function(PdfReaderState) then,
  ) = _$PdfReaderStateCopyWithImpl<$Res, PdfReaderState>;
}

/// @nodoc
class _$PdfReaderStateCopyWithImpl<$Res, $Val extends PdfReaderState>
    implements $PdfReaderStateCopyWith<$Res> {
  _$PdfReaderStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PdfReaderState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$PdfReaderLoadingImplCopyWith<$Res> {
  factory _$$PdfReaderLoadingImplCopyWith(
    _$PdfReaderLoadingImpl value,
    $Res Function(_$PdfReaderLoadingImpl) then,
  ) = __$$PdfReaderLoadingImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$PdfReaderLoadingImplCopyWithImpl<$Res>
    extends _$PdfReaderStateCopyWithImpl<$Res, _$PdfReaderLoadingImpl>
    implements _$$PdfReaderLoadingImplCopyWith<$Res> {
  __$$PdfReaderLoadingImplCopyWithImpl(
    _$PdfReaderLoadingImpl _value,
    $Res Function(_$PdfReaderLoadingImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PdfReaderState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$PdfReaderLoadingImpl implements _PdfReaderLoading {
  const _$PdfReaderLoadingImpl();

  @override
  String toString() {
    return 'PdfReaderState.loading()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$PdfReaderLoadingImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() loading,
    required TResult Function(PdfDocument pdf) loaded,
    required TResult Function() notFound,
    required TResult Function(String filePath) fileNotFound,
    required TResult Function(String message) error,
  }) {
    return loading();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? loading,
    TResult? Function(PdfDocument pdf)? loaded,
    TResult? Function()? notFound,
    TResult? Function(String filePath)? fileNotFound,
    TResult? Function(String message)? error,
  }) {
    return loading?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? loading,
    TResult Function(PdfDocument pdf)? loaded,
    TResult Function()? notFound,
    TResult Function(String filePath)? fileNotFound,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (loading != null) {
      return loading();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_PdfReaderLoading value) loading,
    required TResult Function(_PdfReaderLoaded value) loaded,
    required TResult Function(_PdfReaderNotFound value) notFound,
    required TResult Function(_PdfReaderFileNotFound value) fileNotFound,
    required TResult Function(_PdfReaderError value) error,
  }) {
    return loading(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_PdfReaderLoading value)? loading,
    TResult? Function(_PdfReaderLoaded value)? loaded,
    TResult? Function(_PdfReaderNotFound value)? notFound,
    TResult? Function(_PdfReaderFileNotFound value)? fileNotFound,
    TResult? Function(_PdfReaderError value)? error,
  }) {
    return loading?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_PdfReaderLoading value)? loading,
    TResult Function(_PdfReaderLoaded value)? loaded,
    TResult Function(_PdfReaderNotFound value)? notFound,
    TResult Function(_PdfReaderFileNotFound value)? fileNotFound,
    TResult Function(_PdfReaderError value)? error,
    required TResult orElse(),
  }) {
    if (loading != null) {
      return loading(this);
    }
    return orElse();
  }
}

abstract class _PdfReaderLoading implements PdfReaderState {
  const factory _PdfReaderLoading() = _$PdfReaderLoadingImpl;
}

/// @nodoc
abstract class _$$PdfReaderLoadedImplCopyWith<$Res> {
  factory _$$PdfReaderLoadedImplCopyWith(
    _$PdfReaderLoadedImpl value,
    $Res Function(_$PdfReaderLoadedImpl) then,
  ) = __$$PdfReaderLoadedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({PdfDocument pdf});
}

/// @nodoc
class __$$PdfReaderLoadedImplCopyWithImpl<$Res>
    extends _$PdfReaderStateCopyWithImpl<$Res, _$PdfReaderLoadedImpl>
    implements _$$PdfReaderLoadedImplCopyWith<$Res> {
  __$$PdfReaderLoadedImplCopyWithImpl(
    _$PdfReaderLoadedImpl _value,
    $Res Function(_$PdfReaderLoadedImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PdfReaderState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? pdf = null}) {
    return _then(
      _$PdfReaderLoadedImpl(
        null == pdf
            ? _value.pdf
            : pdf // ignore: cast_nullable_to_non_nullable
                  as PdfDocument,
      ),
    );
  }
}

/// @nodoc

class _$PdfReaderLoadedImpl implements _PdfReaderLoaded {
  const _$PdfReaderLoadedImpl(this.pdf);

  @override
  final PdfDocument pdf;

  @override
  String toString() {
    return 'PdfReaderState.loaded(pdf: $pdf)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PdfReaderLoadedImpl &&
            (identical(other.pdf, pdf) || other.pdf == pdf));
  }

  @override
  int get hashCode => Object.hash(runtimeType, pdf);

  /// Create a copy of PdfReaderState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PdfReaderLoadedImplCopyWith<_$PdfReaderLoadedImpl> get copyWith =>
      __$$PdfReaderLoadedImplCopyWithImpl<_$PdfReaderLoadedImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() loading,
    required TResult Function(PdfDocument pdf) loaded,
    required TResult Function() notFound,
    required TResult Function(String filePath) fileNotFound,
    required TResult Function(String message) error,
  }) {
    return loaded(pdf);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? loading,
    TResult? Function(PdfDocument pdf)? loaded,
    TResult? Function()? notFound,
    TResult? Function(String filePath)? fileNotFound,
    TResult? Function(String message)? error,
  }) {
    return loaded?.call(pdf);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? loading,
    TResult Function(PdfDocument pdf)? loaded,
    TResult Function()? notFound,
    TResult Function(String filePath)? fileNotFound,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (loaded != null) {
      return loaded(pdf);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_PdfReaderLoading value) loading,
    required TResult Function(_PdfReaderLoaded value) loaded,
    required TResult Function(_PdfReaderNotFound value) notFound,
    required TResult Function(_PdfReaderFileNotFound value) fileNotFound,
    required TResult Function(_PdfReaderError value) error,
  }) {
    return loaded(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_PdfReaderLoading value)? loading,
    TResult? Function(_PdfReaderLoaded value)? loaded,
    TResult? Function(_PdfReaderNotFound value)? notFound,
    TResult? Function(_PdfReaderFileNotFound value)? fileNotFound,
    TResult? Function(_PdfReaderError value)? error,
  }) {
    return loaded?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_PdfReaderLoading value)? loading,
    TResult Function(_PdfReaderLoaded value)? loaded,
    TResult Function(_PdfReaderNotFound value)? notFound,
    TResult Function(_PdfReaderFileNotFound value)? fileNotFound,
    TResult Function(_PdfReaderError value)? error,
    required TResult orElse(),
  }) {
    if (loaded != null) {
      return loaded(this);
    }
    return orElse();
  }
}

abstract class _PdfReaderLoaded implements PdfReaderState {
  const factory _PdfReaderLoaded(final PdfDocument pdf) = _$PdfReaderLoadedImpl;

  PdfDocument get pdf;

  /// Create a copy of PdfReaderState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PdfReaderLoadedImplCopyWith<_$PdfReaderLoadedImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$PdfReaderNotFoundImplCopyWith<$Res> {
  factory _$$PdfReaderNotFoundImplCopyWith(
    _$PdfReaderNotFoundImpl value,
    $Res Function(_$PdfReaderNotFoundImpl) then,
  ) = __$$PdfReaderNotFoundImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$PdfReaderNotFoundImplCopyWithImpl<$Res>
    extends _$PdfReaderStateCopyWithImpl<$Res, _$PdfReaderNotFoundImpl>
    implements _$$PdfReaderNotFoundImplCopyWith<$Res> {
  __$$PdfReaderNotFoundImplCopyWithImpl(
    _$PdfReaderNotFoundImpl _value,
    $Res Function(_$PdfReaderNotFoundImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PdfReaderState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$PdfReaderNotFoundImpl implements _PdfReaderNotFound {
  const _$PdfReaderNotFoundImpl();

  @override
  String toString() {
    return 'PdfReaderState.notFound()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$PdfReaderNotFoundImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() loading,
    required TResult Function(PdfDocument pdf) loaded,
    required TResult Function() notFound,
    required TResult Function(String filePath) fileNotFound,
    required TResult Function(String message) error,
  }) {
    return notFound();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? loading,
    TResult? Function(PdfDocument pdf)? loaded,
    TResult? Function()? notFound,
    TResult? Function(String filePath)? fileNotFound,
    TResult? Function(String message)? error,
  }) {
    return notFound?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? loading,
    TResult Function(PdfDocument pdf)? loaded,
    TResult Function()? notFound,
    TResult Function(String filePath)? fileNotFound,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (notFound != null) {
      return notFound();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_PdfReaderLoading value) loading,
    required TResult Function(_PdfReaderLoaded value) loaded,
    required TResult Function(_PdfReaderNotFound value) notFound,
    required TResult Function(_PdfReaderFileNotFound value) fileNotFound,
    required TResult Function(_PdfReaderError value) error,
  }) {
    return notFound(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_PdfReaderLoading value)? loading,
    TResult? Function(_PdfReaderLoaded value)? loaded,
    TResult? Function(_PdfReaderNotFound value)? notFound,
    TResult? Function(_PdfReaderFileNotFound value)? fileNotFound,
    TResult? Function(_PdfReaderError value)? error,
  }) {
    return notFound?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_PdfReaderLoading value)? loading,
    TResult Function(_PdfReaderLoaded value)? loaded,
    TResult Function(_PdfReaderNotFound value)? notFound,
    TResult Function(_PdfReaderFileNotFound value)? fileNotFound,
    TResult Function(_PdfReaderError value)? error,
    required TResult orElse(),
  }) {
    if (notFound != null) {
      return notFound(this);
    }
    return orElse();
  }
}

abstract class _PdfReaderNotFound implements PdfReaderState {
  const factory _PdfReaderNotFound() = _$PdfReaderNotFoundImpl;
}

/// @nodoc
abstract class _$$PdfReaderFileNotFoundImplCopyWith<$Res> {
  factory _$$PdfReaderFileNotFoundImplCopyWith(
    _$PdfReaderFileNotFoundImpl value,
    $Res Function(_$PdfReaderFileNotFoundImpl) then,
  ) = __$$PdfReaderFileNotFoundImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String filePath});
}

/// @nodoc
class __$$PdfReaderFileNotFoundImplCopyWithImpl<$Res>
    extends _$PdfReaderStateCopyWithImpl<$Res, _$PdfReaderFileNotFoundImpl>
    implements _$$PdfReaderFileNotFoundImplCopyWith<$Res> {
  __$$PdfReaderFileNotFoundImplCopyWithImpl(
    _$PdfReaderFileNotFoundImpl _value,
    $Res Function(_$PdfReaderFileNotFoundImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PdfReaderState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? filePath = null}) {
    return _then(
      _$PdfReaderFileNotFoundImpl(
        null == filePath
            ? _value.filePath
            : filePath // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$PdfReaderFileNotFoundImpl implements _PdfReaderFileNotFound {
  const _$PdfReaderFileNotFoundImpl(this.filePath);

  @override
  final String filePath;

  @override
  String toString() {
    return 'PdfReaderState.fileNotFound(filePath: $filePath)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PdfReaderFileNotFoundImpl &&
            (identical(other.filePath, filePath) ||
                other.filePath == filePath));
  }

  @override
  int get hashCode => Object.hash(runtimeType, filePath);

  /// Create a copy of PdfReaderState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PdfReaderFileNotFoundImplCopyWith<_$PdfReaderFileNotFoundImpl>
  get copyWith =>
      __$$PdfReaderFileNotFoundImplCopyWithImpl<_$PdfReaderFileNotFoundImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() loading,
    required TResult Function(PdfDocument pdf) loaded,
    required TResult Function() notFound,
    required TResult Function(String filePath) fileNotFound,
    required TResult Function(String message) error,
  }) {
    return fileNotFound(filePath);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? loading,
    TResult? Function(PdfDocument pdf)? loaded,
    TResult? Function()? notFound,
    TResult? Function(String filePath)? fileNotFound,
    TResult? Function(String message)? error,
  }) {
    return fileNotFound?.call(filePath);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? loading,
    TResult Function(PdfDocument pdf)? loaded,
    TResult Function()? notFound,
    TResult Function(String filePath)? fileNotFound,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (fileNotFound != null) {
      return fileNotFound(filePath);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_PdfReaderLoading value) loading,
    required TResult Function(_PdfReaderLoaded value) loaded,
    required TResult Function(_PdfReaderNotFound value) notFound,
    required TResult Function(_PdfReaderFileNotFound value) fileNotFound,
    required TResult Function(_PdfReaderError value) error,
  }) {
    return fileNotFound(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_PdfReaderLoading value)? loading,
    TResult? Function(_PdfReaderLoaded value)? loaded,
    TResult? Function(_PdfReaderNotFound value)? notFound,
    TResult? Function(_PdfReaderFileNotFound value)? fileNotFound,
    TResult? Function(_PdfReaderError value)? error,
  }) {
    return fileNotFound?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_PdfReaderLoading value)? loading,
    TResult Function(_PdfReaderLoaded value)? loaded,
    TResult Function(_PdfReaderNotFound value)? notFound,
    TResult Function(_PdfReaderFileNotFound value)? fileNotFound,
    TResult Function(_PdfReaderError value)? error,
    required TResult orElse(),
  }) {
    if (fileNotFound != null) {
      return fileNotFound(this);
    }
    return orElse();
  }
}

abstract class _PdfReaderFileNotFound implements PdfReaderState {
  const factory _PdfReaderFileNotFound(final String filePath) =
      _$PdfReaderFileNotFoundImpl;

  String get filePath;

  /// Create a copy of PdfReaderState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PdfReaderFileNotFoundImplCopyWith<_$PdfReaderFileNotFoundImpl>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$PdfReaderErrorImplCopyWith<$Res> {
  factory _$$PdfReaderErrorImplCopyWith(
    _$PdfReaderErrorImpl value,
    $Res Function(_$PdfReaderErrorImpl) then,
  ) = __$$PdfReaderErrorImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String message});
}

/// @nodoc
class __$$PdfReaderErrorImplCopyWithImpl<$Res>
    extends _$PdfReaderStateCopyWithImpl<$Res, _$PdfReaderErrorImpl>
    implements _$$PdfReaderErrorImplCopyWith<$Res> {
  __$$PdfReaderErrorImplCopyWithImpl(
    _$PdfReaderErrorImpl _value,
    $Res Function(_$PdfReaderErrorImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PdfReaderState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? message = null}) {
    return _then(
      _$PdfReaderErrorImpl(
        null == message
            ? _value.message
            : message // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$PdfReaderErrorImpl implements _PdfReaderError {
  const _$PdfReaderErrorImpl(this.message);

  @override
  final String message;

  @override
  String toString() {
    return 'PdfReaderState.error(message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PdfReaderErrorImpl &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  /// Create a copy of PdfReaderState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PdfReaderErrorImplCopyWith<_$PdfReaderErrorImpl> get copyWith =>
      __$$PdfReaderErrorImplCopyWithImpl<_$PdfReaderErrorImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() loading,
    required TResult Function(PdfDocument pdf) loaded,
    required TResult Function() notFound,
    required TResult Function(String filePath) fileNotFound,
    required TResult Function(String message) error,
  }) {
    return error(message);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? loading,
    TResult? Function(PdfDocument pdf)? loaded,
    TResult? Function()? notFound,
    TResult? Function(String filePath)? fileNotFound,
    TResult? Function(String message)? error,
  }) {
    return error?.call(message);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? loading,
    TResult Function(PdfDocument pdf)? loaded,
    TResult Function()? notFound,
    TResult Function(String filePath)? fileNotFound,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (error != null) {
      return error(message);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_PdfReaderLoading value) loading,
    required TResult Function(_PdfReaderLoaded value) loaded,
    required TResult Function(_PdfReaderNotFound value) notFound,
    required TResult Function(_PdfReaderFileNotFound value) fileNotFound,
    required TResult Function(_PdfReaderError value) error,
  }) {
    return error(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_PdfReaderLoading value)? loading,
    TResult? Function(_PdfReaderLoaded value)? loaded,
    TResult? Function(_PdfReaderNotFound value)? notFound,
    TResult? Function(_PdfReaderFileNotFound value)? fileNotFound,
    TResult? Function(_PdfReaderError value)? error,
  }) {
    return error?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_PdfReaderLoading value)? loading,
    TResult Function(_PdfReaderLoaded value)? loaded,
    TResult Function(_PdfReaderNotFound value)? notFound,
    TResult Function(_PdfReaderFileNotFound value)? fileNotFound,
    TResult Function(_PdfReaderError value)? error,
    required TResult orElse(),
  }) {
    if (error != null) {
      return error(this);
    }
    return orElse();
  }
}

abstract class _PdfReaderError implements PdfReaderState {
  const factory _PdfReaderError(final String message) = _$PdfReaderErrorImpl;

  String get message;

  /// Create a copy of PdfReaderState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PdfReaderErrorImplCopyWith<_$PdfReaderErrorImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
