// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'library_notifier.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$LibraryState {
  List<PdfDocument> get allPdfs => throw _privateConstructorUsedError;
  List<PdfDocument> get recentPdfs => throw _privateConstructorUsedError;
  List<PdfDocument> get favoritePdfs => throw _privateConstructorUsedError;
  bool get isLoading => throw _privateConstructorUsedError;
  AppFailure? get failure => throw _privateConstructorUsedError;

  /// Create a copy of LibraryState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $LibraryStateCopyWith<LibraryState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LibraryStateCopyWith<$Res> {
  factory $LibraryStateCopyWith(
    LibraryState value,
    $Res Function(LibraryState) then,
  ) = _$LibraryStateCopyWithImpl<$Res, LibraryState>;
  @useResult
  $Res call({
    List<PdfDocument> allPdfs,
    List<PdfDocument> recentPdfs,
    List<PdfDocument> favoritePdfs,
    bool isLoading,
    AppFailure? failure,
  });
}

/// @nodoc
class _$LibraryStateCopyWithImpl<$Res, $Val extends LibraryState>
    implements $LibraryStateCopyWith<$Res> {
  _$LibraryStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of LibraryState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? allPdfs = null,
    Object? recentPdfs = null,
    Object? favoritePdfs = null,
    Object? isLoading = null,
    Object? failure = freezed,
  }) {
    return _then(
      _value.copyWith(
            allPdfs: null == allPdfs
                ? _value.allPdfs
                : allPdfs // ignore: cast_nullable_to_non_nullable
                      as List<PdfDocument>,
            recentPdfs: null == recentPdfs
                ? _value.recentPdfs
                : recentPdfs // ignore: cast_nullable_to_non_nullable
                      as List<PdfDocument>,
            favoritePdfs: null == favoritePdfs
                ? _value.favoritePdfs
                : favoritePdfs // ignore: cast_nullable_to_non_nullable
                      as List<PdfDocument>,
            isLoading: null == isLoading
                ? _value.isLoading
                : isLoading // ignore: cast_nullable_to_non_nullable
                      as bool,
            failure: freezed == failure
                ? _value.failure
                : failure // ignore: cast_nullable_to_non_nullable
                      as AppFailure?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$LibraryStateImplCopyWith<$Res>
    implements $LibraryStateCopyWith<$Res> {
  factory _$$LibraryStateImplCopyWith(
    _$LibraryStateImpl value,
    $Res Function(_$LibraryStateImpl) then,
  ) = __$$LibraryStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    List<PdfDocument> allPdfs,
    List<PdfDocument> recentPdfs,
    List<PdfDocument> favoritePdfs,
    bool isLoading,
    AppFailure? failure,
  });
}

/// @nodoc
class __$$LibraryStateImplCopyWithImpl<$Res>
    extends _$LibraryStateCopyWithImpl<$Res, _$LibraryStateImpl>
    implements _$$LibraryStateImplCopyWith<$Res> {
  __$$LibraryStateImplCopyWithImpl(
    _$LibraryStateImpl _value,
    $Res Function(_$LibraryStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of LibraryState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? allPdfs = null,
    Object? recentPdfs = null,
    Object? favoritePdfs = null,
    Object? isLoading = null,
    Object? failure = freezed,
  }) {
    return _then(
      _$LibraryStateImpl(
        allPdfs: null == allPdfs
            ? _value._allPdfs
            : allPdfs // ignore: cast_nullable_to_non_nullable
                  as List<PdfDocument>,
        recentPdfs: null == recentPdfs
            ? _value._recentPdfs
            : recentPdfs // ignore: cast_nullable_to_non_nullable
                  as List<PdfDocument>,
        favoritePdfs: null == favoritePdfs
            ? _value._favoritePdfs
            : favoritePdfs // ignore: cast_nullable_to_non_nullable
                  as List<PdfDocument>,
        isLoading: null == isLoading
            ? _value.isLoading
            : isLoading // ignore: cast_nullable_to_non_nullable
                  as bool,
        failure: freezed == failure
            ? _value.failure
            : failure // ignore: cast_nullable_to_non_nullable
                  as AppFailure?,
      ),
    );
  }
}

/// @nodoc

class _$LibraryStateImpl implements _LibraryState {
  const _$LibraryStateImpl({
    required final List<PdfDocument> allPdfs,
    required final List<PdfDocument> recentPdfs,
    required final List<PdfDocument> favoritePdfs,
    required this.isLoading,
    required this.failure,
  }) : _allPdfs = allPdfs,
       _recentPdfs = recentPdfs,
       _favoritePdfs = favoritePdfs;

  final List<PdfDocument> _allPdfs;
  @override
  List<PdfDocument> get allPdfs {
    if (_allPdfs is EqualUnmodifiableListView) return _allPdfs;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_allPdfs);
  }

  final List<PdfDocument> _recentPdfs;
  @override
  List<PdfDocument> get recentPdfs {
    if (_recentPdfs is EqualUnmodifiableListView) return _recentPdfs;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_recentPdfs);
  }

  final List<PdfDocument> _favoritePdfs;
  @override
  List<PdfDocument> get favoritePdfs {
    if (_favoritePdfs is EqualUnmodifiableListView) return _favoritePdfs;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_favoritePdfs);
  }

  @override
  final bool isLoading;
  @override
  final AppFailure? failure;

  @override
  String toString() {
    return 'LibraryState(allPdfs: $allPdfs, recentPdfs: $recentPdfs, favoritePdfs: $favoritePdfs, isLoading: $isLoading, failure: $failure)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LibraryStateImpl &&
            const DeepCollectionEquality().equals(other._allPdfs, _allPdfs) &&
            const DeepCollectionEquality().equals(
              other._recentPdfs,
              _recentPdfs,
            ) &&
            const DeepCollectionEquality().equals(
              other._favoritePdfs,
              _favoritePdfs,
            ) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.failure, failure) || other.failure == failure));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_allPdfs),
    const DeepCollectionEquality().hash(_recentPdfs),
    const DeepCollectionEquality().hash(_favoritePdfs),
    isLoading,
    failure,
  );

  /// Create a copy of LibraryState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LibraryStateImplCopyWith<_$LibraryStateImpl> get copyWith =>
      __$$LibraryStateImplCopyWithImpl<_$LibraryStateImpl>(this, _$identity);
}

abstract class _LibraryState implements LibraryState {
  const factory _LibraryState({
    required final List<PdfDocument> allPdfs,
    required final List<PdfDocument> recentPdfs,
    required final List<PdfDocument> favoritePdfs,
    required final bool isLoading,
    required final AppFailure? failure,
  }) = _$LibraryStateImpl;

  @override
  List<PdfDocument> get allPdfs;
  @override
  List<PdfDocument> get recentPdfs;
  @override
  List<PdfDocument> get favoritePdfs;
  @override
  bool get isLoading;
  @override
  AppFailure? get failure;

  /// Create a copy of LibraryState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LibraryStateImplCopyWith<_$LibraryStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
