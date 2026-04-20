// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pdf_chat_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$ChatMessage {
  /// Unique identifier for the message
  String get id => throw _privateConstructorUsedError;

  /// The message content (markdown formatted for AI responses)
  String get content => throw _privateConstructorUsedError;

  /// Whether this message was sent by the user
  bool get isUser => throw _privateConstructorUsedError;

  /// When the message was created
  DateTime get timestamp => throw _privateConstructorUsedError;

  /// Whether this message is currently being processed
  bool get isProcessing => throw _privateConstructorUsedError;

  /// Whether this message failed to get a response
  bool get isFailed => throw _privateConstructorUsedError;

  /// Error message if processing failed
  String? get error => throw _privateConstructorUsedError;

  /// Create a copy of ChatMessage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ChatMessageCopyWith<ChatMessage> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ChatMessageCopyWith<$Res> {
  factory $ChatMessageCopyWith(
    ChatMessage value,
    $Res Function(ChatMessage) then,
  ) = _$ChatMessageCopyWithImpl<$Res, ChatMessage>;
  @useResult
  $Res call({
    String id,
    String content,
    bool isUser,
    DateTime timestamp,
    bool isProcessing,
    bool isFailed,
    String? error,
  });
}

/// @nodoc
class _$ChatMessageCopyWithImpl<$Res, $Val extends ChatMessage>
    implements $ChatMessageCopyWith<$Res> {
  _$ChatMessageCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ChatMessage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? content = null,
    Object? isUser = null,
    Object? timestamp = null,
    Object? isProcessing = null,
    Object? isFailed = null,
    Object? error = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            content: null == content
                ? _value.content
                : content // ignore: cast_nullable_to_non_nullable
                      as String,
            isUser: null == isUser
                ? _value.isUser
                : isUser // ignore: cast_nullable_to_non_nullable
                      as bool,
            timestamp: null == timestamp
                ? _value.timestamp
                : timestamp // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            isProcessing: null == isProcessing
                ? _value.isProcessing
                : isProcessing // ignore: cast_nullable_to_non_nullable
                      as bool,
            isFailed: null == isFailed
                ? _value.isFailed
                : isFailed // ignore: cast_nullable_to_non_nullable
                      as bool,
            error: freezed == error
                ? _value.error
                : error // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ChatMessageImplCopyWith<$Res>
    implements $ChatMessageCopyWith<$Res> {
  factory _$$ChatMessageImplCopyWith(
    _$ChatMessageImpl value,
    $Res Function(_$ChatMessageImpl) then,
  ) = __$$ChatMessageImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String content,
    bool isUser,
    DateTime timestamp,
    bool isProcessing,
    bool isFailed,
    String? error,
  });
}

/// @nodoc
class __$$ChatMessageImplCopyWithImpl<$Res>
    extends _$ChatMessageCopyWithImpl<$Res, _$ChatMessageImpl>
    implements _$$ChatMessageImplCopyWith<$Res> {
  __$$ChatMessageImplCopyWithImpl(
    _$ChatMessageImpl _value,
    $Res Function(_$ChatMessageImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ChatMessage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? content = null,
    Object? isUser = null,
    Object? timestamp = null,
    Object? isProcessing = null,
    Object? isFailed = null,
    Object? error = freezed,
  }) {
    return _then(
      _$ChatMessageImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        content: null == content
            ? _value.content
            : content // ignore: cast_nullable_to_non_nullable
                  as String,
        isUser: null == isUser
            ? _value.isUser
            : isUser // ignore: cast_nullable_to_non_nullable
                  as bool,
        timestamp: null == timestamp
            ? _value.timestamp
            : timestamp // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        isProcessing: null == isProcessing
            ? _value.isProcessing
            : isProcessing // ignore: cast_nullable_to_non_nullable
                  as bool,
        isFailed: null == isFailed
            ? _value.isFailed
            : isFailed // ignore: cast_nullable_to_non_nullable
                  as bool,
        error: freezed == error
            ? _value.error
            : error // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc

class _$ChatMessageImpl implements _ChatMessage {
  const _$ChatMessageImpl({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.isProcessing = false,
    this.isFailed = false,
    this.error,
  });

  /// Unique identifier for the message
  @override
  final String id;

  /// The message content (markdown formatted for AI responses)
  @override
  final String content;

  /// Whether this message was sent by the user
  @override
  final bool isUser;

  /// When the message was created
  @override
  final DateTime timestamp;

  /// Whether this message is currently being processed
  @override
  @JsonKey()
  final bool isProcessing;

  /// Whether this message failed to get a response
  @override
  @JsonKey()
  final bool isFailed;

  /// Error message if processing failed
  @override
  final String? error;

  @override
  String toString() {
    return 'ChatMessage(id: $id, content: $content, isUser: $isUser, timestamp: $timestamp, isProcessing: $isProcessing, isFailed: $isFailed, error: $error)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ChatMessageImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.content, content) || other.content == content) &&
            (identical(other.isUser, isUser) || other.isUser == isUser) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            (identical(other.isProcessing, isProcessing) ||
                other.isProcessing == isProcessing) &&
            (identical(other.isFailed, isFailed) ||
                other.isFailed == isFailed) &&
            (identical(other.error, error) || other.error == error));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    content,
    isUser,
    timestamp,
    isProcessing,
    isFailed,
    error,
  );

  /// Create a copy of ChatMessage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ChatMessageImplCopyWith<_$ChatMessageImpl> get copyWith =>
      __$$ChatMessageImplCopyWithImpl<_$ChatMessageImpl>(this, _$identity);
}

abstract class _ChatMessage implements ChatMessage {
  const factory _ChatMessage({
    required final String id,
    required final String content,
    required final bool isUser,
    required final DateTime timestamp,
    final bool isProcessing,
    final bool isFailed,
    final String? error,
  }) = _$ChatMessageImpl;

  /// Unique identifier for the message
  @override
  String get id;

  /// The message content (markdown formatted for AI responses)
  @override
  String get content;

  /// Whether this message was sent by the user
  @override
  bool get isUser;

  /// When the message was created
  @override
  DateTime get timestamp;

  /// Whether this message is currently being processed
  @override
  bool get isProcessing;

  /// Whether this message failed to get a response
  @override
  bool get isFailed;

  /// Error message if processing failed
  @override
  String? get error;

  /// Create a copy of ChatMessage
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ChatMessageImplCopyWith<_$ChatMessageImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$PdfChatState {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function(
      List<ChatMessage> messages,
      bool isLoading,
      bool isExtractingText,
      double? extractProgress,
      String? error,
      String? extractedText,
      String? currentPdfPath,
    )
    visible,
    required TResult Function() hidden,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function(
      List<ChatMessage> messages,
      bool isLoading,
      bool isExtractingText,
      double? extractProgress,
      String? error,
      String? extractedText,
      String? currentPdfPath,
    )?
    visible,
    TResult? Function()? hidden,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function(
      List<ChatMessage> messages,
      bool isLoading,
      bool isExtractingText,
      double? extractProgress,
      String? error,
      String? extractedText,
      String? currentPdfPath,
    )?
    visible,
    TResult Function()? hidden,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_PdfChatStateInitial value) initial,
    required TResult Function(_PdfChatStateVisible value) visible,
    required TResult Function(_PdfChatStateHidden value) hidden,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_PdfChatStateInitial value)? initial,
    TResult? Function(_PdfChatStateVisible value)? visible,
    TResult? Function(_PdfChatStateHidden value)? hidden,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_PdfChatStateInitial value)? initial,
    TResult Function(_PdfChatStateVisible value)? visible,
    TResult Function(_PdfChatStateHidden value)? hidden,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PdfChatStateCopyWith<$Res> {
  factory $PdfChatStateCopyWith(
    PdfChatState value,
    $Res Function(PdfChatState) then,
  ) = _$PdfChatStateCopyWithImpl<$Res, PdfChatState>;
}

/// @nodoc
class _$PdfChatStateCopyWithImpl<$Res, $Val extends PdfChatState>
    implements $PdfChatStateCopyWith<$Res> {
  _$PdfChatStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PdfChatState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$PdfChatStateInitialImplCopyWith<$Res> {
  factory _$$PdfChatStateInitialImplCopyWith(
    _$PdfChatStateInitialImpl value,
    $Res Function(_$PdfChatStateInitialImpl) then,
  ) = __$$PdfChatStateInitialImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$PdfChatStateInitialImplCopyWithImpl<$Res>
    extends _$PdfChatStateCopyWithImpl<$Res, _$PdfChatStateInitialImpl>
    implements _$$PdfChatStateInitialImplCopyWith<$Res> {
  __$$PdfChatStateInitialImplCopyWithImpl(
    _$PdfChatStateInitialImpl _value,
    $Res Function(_$PdfChatStateInitialImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PdfChatState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$PdfChatStateInitialImpl implements _PdfChatStateInitial {
  const _$PdfChatStateInitialImpl();

  @override
  String toString() {
    return 'PdfChatState.initial()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PdfChatStateInitialImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function(
      List<ChatMessage> messages,
      bool isLoading,
      bool isExtractingText,
      double? extractProgress,
      String? error,
      String? extractedText,
      String? currentPdfPath,
    )
    visible,
    required TResult Function() hidden,
  }) {
    return initial();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function(
      List<ChatMessage> messages,
      bool isLoading,
      bool isExtractingText,
      double? extractProgress,
      String? error,
      String? extractedText,
      String? currentPdfPath,
    )?
    visible,
    TResult? Function()? hidden,
  }) {
    return initial?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function(
      List<ChatMessage> messages,
      bool isLoading,
      bool isExtractingText,
      double? extractProgress,
      String? error,
      String? extractedText,
      String? currentPdfPath,
    )?
    visible,
    TResult Function()? hidden,
    required TResult orElse(),
  }) {
    if (initial != null) {
      return initial();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_PdfChatStateInitial value) initial,
    required TResult Function(_PdfChatStateVisible value) visible,
    required TResult Function(_PdfChatStateHidden value) hidden,
  }) {
    return initial(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_PdfChatStateInitial value)? initial,
    TResult? Function(_PdfChatStateVisible value)? visible,
    TResult? Function(_PdfChatStateHidden value)? hidden,
  }) {
    return initial?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_PdfChatStateInitial value)? initial,
    TResult Function(_PdfChatStateVisible value)? visible,
    TResult Function(_PdfChatStateHidden value)? hidden,
    required TResult orElse(),
  }) {
    if (initial != null) {
      return initial(this);
    }
    return orElse();
  }
}

abstract class _PdfChatStateInitial implements PdfChatState {
  const factory _PdfChatStateInitial() = _$PdfChatStateInitialImpl;
}

/// @nodoc
abstract class _$$PdfChatStateVisibleImplCopyWith<$Res> {
  factory _$$PdfChatStateVisibleImplCopyWith(
    _$PdfChatStateVisibleImpl value,
    $Res Function(_$PdfChatStateVisibleImpl) then,
  ) = __$$PdfChatStateVisibleImplCopyWithImpl<$Res>;
  @useResult
  $Res call({
    List<ChatMessage> messages,
    bool isLoading,
    bool isExtractingText,
    double? extractProgress,
    String? error,
    String? extractedText,
    String? currentPdfPath,
  });
}

/// @nodoc
class __$$PdfChatStateVisibleImplCopyWithImpl<$Res>
    extends _$PdfChatStateCopyWithImpl<$Res, _$PdfChatStateVisibleImpl>
    implements _$$PdfChatStateVisibleImplCopyWith<$Res> {
  __$$PdfChatStateVisibleImplCopyWithImpl(
    _$PdfChatStateVisibleImpl _value,
    $Res Function(_$PdfChatStateVisibleImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PdfChatState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? messages = null,
    Object? isLoading = null,
    Object? isExtractingText = null,
    Object? extractProgress = freezed,
    Object? error = freezed,
    Object? extractedText = freezed,
    Object? currentPdfPath = freezed,
  }) {
    return _then(
      _$PdfChatStateVisibleImpl(
        messages: null == messages
            ? _value._messages
            : messages // ignore: cast_nullable_to_non_nullable
                  as List<ChatMessage>,
        isLoading: null == isLoading
            ? _value.isLoading
            : isLoading // ignore: cast_nullable_to_non_nullable
                  as bool,
        isExtractingText: null == isExtractingText
            ? _value.isExtractingText
            : isExtractingText // ignore: cast_nullable_to_non_nullable
                  as bool,
        extractProgress: freezed == extractProgress
            ? _value.extractProgress
            : extractProgress // ignore: cast_nullable_to_non_nullable
                  as double?,
        error: freezed == error
            ? _value.error
            : error // ignore: cast_nullable_to_non_nullable
                  as String?,
        extractedText: freezed == extractedText
            ? _value.extractedText
            : extractedText // ignore: cast_nullable_to_non_nullable
                  as String?,
        currentPdfPath: freezed == currentPdfPath
            ? _value.currentPdfPath
            : currentPdfPath // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc

class _$PdfChatStateVisibleImpl implements _PdfChatStateVisible {
  const _$PdfChatStateVisibleImpl({
    final List<ChatMessage> messages = const [],
    this.isLoading = false,
    this.isExtractingText = false,
    this.extractProgress,
    this.error,
    this.extractedText,
    this.currentPdfPath,
  }) : _messages = messages;

  /// All messages in the conversation
  final List<ChatMessage> _messages;

  /// All messages in the conversation
  @override
  @JsonKey()
  List<ChatMessage> get messages {
    if (_messages is EqualUnmodifiableListView) return _messages;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_messages);
  }

  /// Whether a message/AI operation is currently processing
  @override
  @JsonKey()
  final bool isLoading;

  /// Whether text is currently being extracted from PDF
  @override
  @JsonKey()
  final bool isExtractingText;

  /// Current text extraction progress (0.0 to 1.0)
  @override
  final double? extractProgress;

  /// Error message if an operation failed
  @override
  final String? error;

  /// The extracted PDF text for AI context
  @override
  final String? extractedText;

  /// The current PDF file path (persists across provider rebuilds)
  @override
  final String? currentPdfPath;

  @override
  String toString() {
    return 'PdfChatState.visible(messages: $messages, isLoading: $isLoading, isExtractingText: $isExtractingText, extractProgress: $extractProgress, error: $error, extractedText: $extractedText, currentPdfPath: $currentPdfPath)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PdfChatStateVisibleImpl &&
            const DeepCollectionEquality().equals(other._messages, _messages) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.isExtractingText, isExtractingText) ||
                other.isExtractingText == isExtractingText) &&
            (identical(other.extractProgress, extractProgress) ||
                other.extractProgress == extractProgress) &&
            (identical(other.error, error) || other.error == error) &&
            (identical(other.extractedText, extractedText) ||
                other.extractedText == extractedText) &&
            (identical(other.currentPdfPath, currentPdfPath) ||
                other.currentPdfPath == currentPdfPath));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_messages),
    isLoading,
    isExtractingText,
    extractProgress,
    error,
    extractedText,
    currentPdfPath,
  );

  /// Create a copy of PdfChatState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PdfChatStateVisibleImplCopyWith<_$PdfChatStateVisibleImpl> get copyWith =>
      __$$PdfChatStateVisibleImplCopyWithImpl<_$PdfChatStateVisibleImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function(
      List<ChatMessage> messages,
      bool isLoading,
      bool isExtractingText,
      double? extractProgress,
      String? error,
      String? extractedText,
      String? currentPdfPath,
    )
    visible,
    required TResult Function() hidden,
  }) {
    return visible(
      messages,
      isLoading,
      isExtractingText,
      extractProgress,
      error,
      extractedText,
      currentPdfPath,
    );
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function(
      List<ChatMessage> messages,
      bool isLoading,
      bool isExtractingText,
      double? extractProgress,
      String? error,
      String? extractedText,
      String? currentPdfPath,
    )?
    visible,
    TResult? Function()? hidden,
  }) {
    return visible?.call(
      messages,
      isLoading,
      isExtractingText,
      extractProgress,
      error,
      extractedText,
      currentPdfPath,
    );
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function(
      List<ChatMessage> messages,
      bool isLoading,
      bool isExtractingText,
      double? extractProgress,
      String? error,
      String? extractedText,
      String? currentPdfPath,
    )?
    visible,
    TResult Function()? hidden,
    required TResult orElse(),
  }) {
    if (visible != null) {
      return visible(
        messages,
        isLoading,
        isExtractingText,
        extractProgress,
        error,
        extractedText,
        currentPdfPath,
      );
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_PdfChatStateInitial value) initial,
    required TResult Function(_PdfChatStateVisible value) visible,
    required TResult Function(_PdfChatStateHidden value) hidden,
  }) {
    return visible(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_PdfChatStateInitial value)? initial,
    TResult? Function(_PdfChatStateVisible value)? visible,
    TResult? Function(_PdfChatStateHidden value)? hidden,
  }) {
    return visible?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_PdfChatStateInitial value)? initial,
    TResult Function(_PdfChatStateVisible value)? visible,
    TResult Function(_PdfChatStateHidden value)? hidden,
    required TResult orElse(),
  }) {
    if (visible != null) {
      return visible(this);
    }
    return orElse();
  }
}

abstract class _PdfChatStateVisible implements PdfChatState {
  const factory _PdfChatStateVisible({
    final List<ChatMessage> messages,
    final bool isLoading,
    final bool isExtractingText,
    final double? extractProgress,
    final String? error,
    final String? extractedText,
    final String? currentPdfPath,
  }) = _$PdfChatStateVisibleImpl;

  /// All messages in the conversation
  List<ChatMessage> get messages;

  /// Whether a message/AI operation is currently processing
  bool get isLoading;

  /// Whether text is currently being extracted from PDF
  bool get isExtractingText;

  /// Current text extraction progress (0.0 to 1.0)
  double? get extractProgress;

  /// Error message if an operation failed
  String? get error;

  /// The extracted PDF text for AI context
  String? get extractedText;

  /// The current PDF file path (persists across provider rebuilds)
  String? get currentPdfPath;

  /// Create a copy of PdfChatState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PdfChatStateVisibleImplCopyWith<_$PdfChatStateVisibleImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$PdfChatStateHiddenImplCopyWith<$Res> {
  factory _$$PdfChatStateHiddenImplCopyWith(
    _$PdfChatStateHiddenImpl value,
    $Res Function(_$PdfChatStateHiddenImpl) then,
  ) = __$$PdfChatStateHiddenImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$PdfChatStateHiddenImplCopyWithImpl<$Res>
    extends _$PdfChatStateCopyWithImpl<$Res, _$PdfChatStateHiddenImpl>
    implements _$$PdfChatStateHiddenImplCopyWith<$Res> {
  __$$PdfChatStateHiddenImplCopyWithImpl(
    _$PdfChatStateHiddenImpl _value,
    $Res Function(_$PdfChatStateHiddenImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PdfChatState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$PdfChatStateHiddenImpl implements _PdfChatStateHidden {
  const _$PdfChatStateHiddenImpl();

  @override
  String toString() {
    return 'PdfChatState.hidden()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$PdfChatStateHiddenImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function(
      List<ChatMessage> messages,
      bool isLoading,
      bool isExtractingText,
      double? extractProgress,
      String? error,
      String? extractedText,
      String? currentPdfPath,
    )
    visible,
    required TResult Function() hidden,
  }) {
    return hidden();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function(
      List<ChatMessage> messages,
      bool isLoading,
      bool isExtractingText,
      double? extractProgress,
      String? error,
      String? extractedText,
      String? currentPdfPath,
    )?
    visible,
    TResult? Function()? hidden,
  }) {
    return hidden?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function(
      List<ChatMessage> messages,
      bool isLoading,
      bool isExtractingText,
      double? extractProgress,
      String? error,
      String? extractedText,
      String? currentPdfPath,
    )?
    visible,
    TResult Function()? hidden,
    required TResult orElse(),
  }) {
    if (hidden != null) {
      return hidden();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_PdfChatStateInitial value) initial,
    required TResult Function(_PdfChatStateVisible value) visible,
    required TResult Function(_PdfChatStateHidden value) hidden,
  }) {
    return hidden(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_PdfChatStateInitial value)? initial,
    TResult? Function(_PdfChatStateVisible value)? visible,
    TResult? Function(_PdfChatStateHidden value)? hidden,
  }) {
    return hidden?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_PdfChatStateInitial value)? initial,
    TResult Function(_PdfChatStateVisible value)? visible,
    TResult Function(_PdfChatStateHidden value)? hidden,
    required TResult orElse(),
  }) {
    if (hidden != null) {
      return hidden(this);
    }
    return orElse();
  }
}

abstract class _PdfChatStateHidden implements PdfChatState {
  const factory _PdfChatStateHidden() = _$PdfChatStateHiddenImpl;
}
