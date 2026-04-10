// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'drive_file.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

DriveFile _$DriveFileFromJson(Map<String, dynamic> json) {
  return _DriveFile.fromJson(json);
}

/// @nodoc
mixin _$DriveFile {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  int get size => throw _privateConstructorUsedError;
  DateTime get createdTime => throw _privateConstructorUsedError;
  String? get thumbnailLink => throw _privateConstructorUsedError;
  String? get webViewLink => throw _privateConstructorUsedError;

  /// Serializes this DriveFile to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of DriveFile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DriveFileCopyWith<DriveFile> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DriveFileCopyWith<$Res> {
  factory $DriveFileCopyWith(DriveFile value, $Res Function(DriveFile) then) =
      _$DriveFileCopyWithImpl<$Res, DriveFile>;
  @useResult
  $Res call({
    String id,
    String name,
    int size,
    DateTime createdTime,
    String? thumbnailLink,
    String? webViewLink,
  });
}

/// @nodoc
class _$DriveFileCopyWithImpl<$Res, $Val extends DriveFile>
    implements $DriveFileCopyWith<$Res> {
  _$DriveFileCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DriveFile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? size = null,
    Object? createdTime = null,
    Object? thumbnailLink = freezed,
    Object? webViewLink = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            size: null == size
                ? _value.size
                : size // ignore: cast_nullable_to_non_nullable
                      as int,
            createdTime: null == createdTime
                ? _value.createdTime
                : createdTime // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            thumbnailLink: freezed == thumbnailLink
                ? _value.thumbnailLink
                : thumbnailLink // ignore: cast_nullable_to_non_nullable
                      as String?,
            webViewLink: freezed == webViewLink
                ? _value.webViewLink
                : webViewLink // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$DriveFileImplCopyWith<$Res>
    implements $DriveFileCopyWith<$Res> {
  factory _$$DriveFileImplCopyWith(
    _$DriveFileImpl value,
    $Res Function(_$DriveFileImpl) then,
  ) = __$$DriveFileImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    int size,
    DateTime createdTime,
    String? thumbnailLink,
    String? webViewLink,
  });
}

/// @nodoc
class __$$DriveFileImplCopyWithImpl<$Res>
    extends _$DriveFileCopyWithImpl<$Res, _$DriveFileImpl>
    implements _$$DriveFileImplCopyWith<$Res> {
  __$$DriveFileImplCopyWithImpl(
    _$DriveFileImpl _value,
    $Res Function(_$DriveFileImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of DriveFile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? size = null,
    Object? createdTime = null,
    Object? thumbnailLink = freezed,
    Object? webViewLink = freezed,
  }) {
    return _then(
      _$DriveFileImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        size: null == size
            ? _value.size
            : size // ignore: cast_nullable_to_non_nullable
                  as int,
        createdTime: null == createdTime
            ? _value.createdTime
            : createdTime // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        thumbnailLink: freezed == thumbnailLink
            ? _value.thumbnailLink
            : thumbnailLink // ignore: cast_nullable_to_non_nullable
                  as String?,
        webViewLink: freezed == webViewLink
            ? _value.webViewLink
            : webViewLink // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$DriveFileImpl implements _DriveFile {
  const _$DriveFileImpl({
    required this.id,
    required this.name,
    required this.size,
    required this.createdTime,
    this.thumbnailLink,
    this.webViewLink,
  });

  factory _$DriveFileImpl.fromJson(Map<String, dynamic> json) =>
      _$$DriveFileImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final int size;
  @override
  final DateTime createdTime;
  @override
  final String? thumbnailLink;
  @override
  final String? webViewLink;

  @override
  String toString() {
    return 'DriveFile(id: $id, name: $name, size: $size, createdTime: $createdTime, thumbnailLink: $thumbnailLink, webViewLink: $webViewLink)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DriveFileImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.size, size) || other.size == size) &&
            (identical(other.createdTime, createdTime) ||
                other.createdTime == createdTime) &&
            (identical(other.thumbnailLink, thumbnailLink) ||
                other.thumbnailLink == thumbnailLink) &&
            (identical(other.webViewLink, webViewLink) ||
                other.webViewLink == webViewLink));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    size,
    createdTime,
    thumbnailLink,
    webViewLink,
  );

  /// Create a copy of DriveFile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DriveFileImplCopyWith<_$DriveFileImpl> get copyWith =>
      __$$DriveFileImplCopyWithImpl<_$DriveFileImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DriveFileImplToJson(this);
  }
}

abstract class _DriveFile implements DriveFile {
  const factory _DriveFile({
    required final String id,
    required final String name,
    required final int size,
    required final DateTime createdTime,
    final String? thumbnailLink,
    final String? webViewLink,
  }) = _$DriveFileImpl;

  factory _DriveFile.fromJson(Map<String, dynamic> json) =
      _$DriveFileImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  int get size;
  @override
  DateTime get createdTime;
  @override
  String? get thumbnailLink;
  @override
  String? get webViewLink;

  /// Create a copy of DriveFile
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DriveFileImplCopyWith<_$DriveFileImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
