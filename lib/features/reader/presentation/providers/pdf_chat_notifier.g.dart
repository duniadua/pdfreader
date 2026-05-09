// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pdf_chat_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$pdfAIServiceHash() => r'a58a168dbce8caacf20396126f5574a95afda0ba';

/// Provider for PDF AI service
///
/// Copied from [pdfAIService].
@ProviderFor(pdfAIService)
final pdfAIServiceProvider = AutoDisposeProvider<PdfAIService>.internal(
  pdfAIService,
  name: r'pdfAIServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$pdfAIServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PdfAIServiceRef = AutoDisposeProviderRef<PdfAIService>;
String _$pdfChatNotifierHash() => r'70dbdfb7038bbd721c73c53cb969bd341a7d1fcc';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

abstract class _$PdfChatNotifier
    extends BuildlessAutoDisposeNotifier<PdfChatState> {
  late final String pdfId;

  PdfChatState build(String pdfId);
}

/// Provider for PDF chat state management
///
/// Copied from [PdfChatNotifier].
@ProviderFor(PdfChatNotifier)
const pdfChatNotifierProvider = PdfChatNotifierFamily();

/// Provider for PDF chat state management
///
/// Copied from [PdfChatNotifier].
class PdfChatNotifierFamily extends Family<PdfChatState> {
  /// Provider for PDF chat state management
  ///
  /// Copied from [PdfChatNotifier].
  const PdfChatNotifierFamily();

  /// Provider for PDF chat state management
  ///
  /// Copied from [PdfChatNotifier].
  PdfChatNotifierProvider call(String pdfId) {
    return PdfChatNotifierProvider(pdfId);
  }

  @override
  PdfChatNotifierProvider getProviderOverride(
    covariant PdfChatNotifierProvider provider,
  ) {
    return call(provider.pdfId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'pdfChatNotifierProvider';
}

/// Provider for PDF chat state management
///
/// Copied from [PdfChatNotifier].
class PdfChatNotifierProvider
    extends AutoDisposeNotifierProviderImpl<PdfChatNotifier, PdfChatState> {
  /// Provider for PDF chat state management
  ///
  /// Copied from [PdfChatNotifier].
  PdfChatNotifierProvider(String pdfId)
    : this._internal(
        () => PdfChatNotifier()..pdfId = pdfId,
        from: pdfChatNotifierProvider,
        name: r'pdfChatNotifierProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$pdfChatNotifierHash,
        dependencies: PdfChatNotifierFamily._dependencies,
        allTransitiveDependencies:
            PdfChatNotifierFamily._allTransitiveDependencies,
        pdfId: pdfId,
      );

  PdfChatNotifierProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.pdfId,
  }) : super.internal();

  final String pdfId;

  @override
  PdfChatState runNotifierBuild(covariant PdfChatNotifier notifier) {
    return notifier.build(pdfId);
  }

  @override
  Override overrideWith(PdfChatNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: PdfChatNotifierProvider._internal(
        () => create()..pdfId = pdfId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        pdfId: pdfId,
      ),
    );
  }

  @override
  AutoDisposeNotifierProviderElement<PdfChatNotifier, PdfChatState>
  createElement() {
    return _PdfChatNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PdfChatNotifierProvider && other.pdfId == pdfId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, pdfId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin PdfChatNotifierRef on AutoDisposeNotifierProviderRef<PdfChatState> {
  /// The parameter `pdfId` of this provider.
  String get pdfId;
}

class _PdfChatNotifierProviderElement
    extends AutoDisposeNotifierProviderElement<PdfChatNotifier, PdfChatState>
    with PdfChatNotifierRef {
  _PdfChatNotifierProviderElement(super.provider);

  @override
  String get pdfId => (origin as PdfChatNotifierProvider).pdfId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
