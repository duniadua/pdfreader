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

DriveFileModel _$DriveFileModelFromJson(Map<String, dynamic> json) {
  return _DriveFileModel.fromJson(json);
}

/// @nodoc
mixin _$DriveFileModel {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  int get size => throw _privateConstructorUsedError;
  DateTime get createdTime => throw _privateConstructorUsedError;
  String? get thumbnailLink => throw _privateConstructorUsedError;
  String? get webViewLink => throw _privateConstructorUsedError;

  /// Serializes this DriveFileModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of DriveFileModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DriveFileModelCopyWith<DriveFileModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DriveFileModelCopyWith<$Res> {
  factory $DriveFileModelCopyWith(
    DriveFileModel value,
    $Res Function(DriveFileModel) then,
  ) = _$DriveFileModelCopyWithImpl<$Res, DriveFileModel>;
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
class _$DriveFileModelCopyWithImpl<$Res, $Val extends DriveFileModel>
    implements $DriveFileModelCopyWith<$Res> {
  _$DriveFileModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DriveFileModel
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
abstract class _$$DriveFileModelImplCopyWith<$Res>
    implements $DriveFileModelCopyWith<$Res> {
  factory _$$DriveFileModelImplCopyWith(
    _$DriveFileModelImpl value,
    $Res Function(_$DriveFileModelImpl) then,
  ) = __$$DriveFileModelImplCopyWithImpl<$Res>;
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
class __$$DriveFileModelImplCopyWithImpl<$Res>
    extends _$DriveFileModelCopyWithImpl<$Res, _$DriveFileModelImpl>
    implements _$$DriveFileModelImplCopyWith<$Res> {
  __$$DriveFileModelImplCopyWithImpl(
    _$DriveFileModelImpl _value,
    $Res Function(_$DriveFileModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of DriveFileModel
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
      _$DriveFileModelImpl(
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
class _$DriveFileModelImpl implements _DriveFileModel {
  const _$DriveFileModelImpl({
    required this.id,
    required this.name,
    required this.size,
    required this.createdTime,
    this.thumbnailLink,
    this.webViewLink,
  });

  factory _$DriveFileModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$DriveFileModelImplFromJson(json);

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
    return 'DriveFileModel(id: $id, name: $name, size: $size, createdTime: $createdTime, thumbnailLink: $thumbnailLink, webViewLink: $webViewLink)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DriveFileModelImpl &&
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

  /// Create a copy of DriveFileModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DriveFileModelImplCopyWith<_$DriveFileModelImpl> get copyWith =>
      __$$DriveFileModelImplCopyWithImpl<_$DriveFileModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$DriveFileModelImplToJson(this);
  }
}

abstract class _DriveFileModel implements DriveFileModel {
  const factory _DriveFileModel({
    required final String id,
    required final String name,
    required final int size,
    required final DateTime createdTime,
    final String? thumbnailLink,
    final String? webViewLink,
  }) = _$DriveFileModelImpl;

  factory _DriveFileModel.fromJson(Map<String, dynamic> json) =
      _$DriveFileModelImpl.fromJson;

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

  /// Create a copy of DriveFileModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DriveFileModelImplCopyWith<_$DriveFileModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
