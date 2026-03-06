// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'drive_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$DriveState {
  bool get isConnected => throw _privateConstructorUsedError;
  bool get isLoading => throw _privateConstructorUsedError;
  bool get isDownloading => throw _privateConstructorUsedError;
  String? get userName => throw _privateConstructorUsedError;
  String? get downloadingFileName => throw _privateConstructorUsedError;
  String? get errorMessage => throw _privateConstructorUsedError;
  List<DriveFileModel> get files => throw _privateConstructorUsedError;

  /// Create a copy of DriveState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DriveStateCopyWith<DriveState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DriveStateCopyWith<$Res> {
  factory $DriveStateCopyWith(
    DriveState value,
    $Res Function(DriveState) then,
  ) = _$DriveStateCopyWithImpl<$Res, DriveState>;
  @useResult
  $Res call({
    bool isConnected,
    bool isLoading,
    bool isDownloading,
    String? userName,
    String? downloadingFileName,
    String? errorMessage,
    List<DriveFileModel> files,
  });
}

/// @nodoc
class _$DriveStateCopyWithImpl<$Res, $Val extends DriveState>
    implements $DriveStateCopyWith<$Res> {
  _$DriveStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DriveState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isConnected = null,
    Object? isLoading = null,
    Object? isDownloading = null,
    Object? userName = freezed,
    Object? downloadingFileName = freezed,
    Object? errorMessage = freezed,
    Object? files = null,
  }) {
    return _then(
      _value.copyWith(
            isConnected: null == isConnected
                ? _value.isConnected
                : isConnected // ignore: cast_nullable_to_non_nullable
                      as bool,
            isLoading: null == isLoading
                ? _value.isLoading
                : isLoading // ignore: cast_nullable_to_non_nullable
                      as bool,
            isDownloading: null == isDownloading
                ? _value.isDownloading
                : isDownloading // ignore: cast_nullable_to_non_nullable
                      as bool,
            userName: freezed == userName
                ? _value.userName
                : userName // ignore: cast_nullable_to_non_nullable
                      as String?,
            downloadingFileName: freezed == downloadingFileName
                ? _value.downloadingFileName
                : downloadingFileName // ignore: cast_nullable_to_non_nullable
                      as String?,
            errorMessage: freezed == errorMessage
                ? _value.errorMessage
                : errorMessage // ignore: cast_nullable_to_non_nullable
                      as String?,
            files: null == files
                ? _value.files
                : files // ignore: cast_nullable_to_non_nullable
                      as List<DriveFileModel>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$DriveStateImplCopyWith<$Res>
    implements $DriveStateCopyWith<$Res> {
  factory _$$DriveStateImplCopyWith(
    _$DriveStateImpl value,
    $Res Function(_$DriveStateImpl) then,
  ) = __$$DriveStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    bool isConnected,
    bool isLoading,
    bool isDownloading,
    String? userName,
    String? downloadingFileName,
    String? errorMessage,
    List<DriveFileModel> files,
  });
}

/// @nodoc
class __$$DriveStateImplCopyWithImpl<$Res>
    extends _$DriveStateCopyWithImpl<$Res, _$DriveStateImpl>
    implements _$$DriveStateImplCopyWith<$Res> {
  __$$DriveStateImplCopyWithImpl(
    _$DriveStateImpl _value,
    $Res Function(_$DriveStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of DriveState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isConnected = null,
    Object? isLoading = null,
    Object? isDownloading = null,
    Object? userName = freezed,
    Object? downloadingFileName = freezed,
    Object? errorMessage = freezed,
    Object? files = null,
  }) {
    return _then(
      _$DriveStateImpl(
        isConnected: null == isConnected
            ? _value.isConnected
            : isConnected // ignore: cast_nullable_to_non_nullable
                  as bool,
        isLoading: null == isLoading
            ? _value.isLoading
            : isLoading // ignore: cast_nullable_to_non_nullable
                  as bool,
        isDownloading: null == isDownloading
            ? _value.isDownloading
            : isDownloading // ignore: cast_nullable_to_non_nullable
                  as bool,
        userName: freezed == userName
            ? _value.userName
            : userName // ignore: cast_nullable_to_non_nullable
                  as String?,
        downloadingFileName: freezed == downloadingFileName
            ? _value.downloadingFileName
            : downloadingFileName // ignore: cast_nullable_to_non_nullable
                  as String?,
        errorMessage: freezed == errorMessage
            ? _value.errorMessage
            : errorMessage // ignore: cast_nullable_to_non_nullable
                  as String?,
        files: null == files
            ? _value._files
            : files // ignore: cast_nullable_to_non_nullable
                  as List<DriveFileModel>,
      ),
    );
  }
}

/// @nodoc

class _$DriveStateImpl implements _DriveState {
  const _$DriveStateImpl({
    this.isConnected = false,
    this.isLoading = false,
    this.isDownloading = false,
    this.userName,
    this.downloadingFileName,
    this.errorMessage,
    final List<DriveFileModel> files = const [],
  }) : _files = files;

  @override
  @JsonKey()
  final bool isConnected;
  @override
  @JsonKey()
  final bool isLoading;
  @override
  @JsonKey()
  final bool isDownloading;
  @override
  final String? userName;
  @override
  final String? downloadingFileName;
  @override
  final String? errorMessage;
  final List<DriveFileModel> _files;
  @override
  @JsonKey()
  List<DriveFileModel> get files {
    if (_files is EqualUnmodifiableListView) return _files;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_files);
  }

  @override
  String toString() {
    return 'DriveState(isConnected: $isConnected, isLoading: $isLoading, isDownloading: $isDownloading, userName: $userName, downloadingFileName: $downloadingFileName, errorMessage: $errorMessage, files: $files)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DriveStateImpl &&
            (identical(other.isConnected, isConnected) ||
                other.isConnected == isConnected) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.isDownloading, isDownloading) ||
                other.isDownloading == isDownloading) &&
            (identical(other.userName, userName) ||
                other.userName == userName) &&
            (identical(other.downloadingFileName, downloadingFileName) ||
                other.downloadingFileName == downloadingFileName) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage) &&
            const DeepCollectionEquality().equals(other._files, _files));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    isConnected,
    isLoading,
    isDownloading,
    userName,
    downloadingFileName,
    errorMessage,
    const DeepCollectionEquality().hash(_files),
  );

  /// Create a copy of DriveState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DriveStateImplCopyWith<_$DriveStateImpl> get copyWith =>
      __$$DriveStateImplCopyWithImpl<_$DriveStateImpl>(this, _$identity);
}

abstract class _DriveState implements DriveState {
  const factory _DriveState({
    final bool isConnected,
    final bool isLoading,
    final bool isDownloading,
    final String? userName,
    final String? downloadingFileName,
    final String? errorMessage,
    final List<DriveFileModel> files,
  }) = _$DriveStateImpl;

  @override
  bool get isConnected;
  @override
  bool get isLoading;
  @override
  bool get isDownloading;
  @override
  String? get userName;
  @override
  String? get downloadingFileName;
  @override
  String? get errorMessage;
  @override
  List<DriveFileModel> get files;

  /// Create a copy of DriveState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DriveStateImplCopyWith<_$DriveStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
