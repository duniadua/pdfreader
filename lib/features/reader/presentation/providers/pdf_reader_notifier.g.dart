// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pdf_reader_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$pdfReaderNotifierHash() => r'8f783f9de1d5cba580387d8e5bab269d2b2257f8';

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

abstract class _$PdfReaderNotifier
    extends BuildlessAutoDisposeNotifier<PdfReaderState> {
  late final String pdfId;

  PdfReaderState build(String pdfId);
}

/// Provider for PDF reader state
///
/// Copied from [PdfReaderNotifier].
@ProviderFor(PdfReaderNotifier)
const pdfReaderNotifierProvider = PdfReaderNotifierFamily();

/// Provider for PDF reader state
///
/// Copied from [PdfReaderNotifier].
class PdfReaderNotifierFamily extends Family<PdfReaderState> {
  /// Provider for PDF reader state
  ///
  /// Copied from [PdfReaderNotifier].
  const PdfReaderNotifierFamily();

  /// Provider for PDF reader state
  ///
  /// Copied from [PdfReaderNotifier].
  PdfReaderNotifierProvider call(String pdfId) {
    return PdfReaderNotifierProvider(pdfId);
  }

  @override
  PdfReaderNotifierProvider getProviderOverride(
    covariant PdfReaderNotifierProvider provider,
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
  String? get name => r'pdfReaderNotifierProvider';
}

/// Provider for PDF reader state
///
/// Copied from [PdfReaderNotifier].
class PdfReaderNotifierProvider
    extends AutoDisposeNotifierProviderImpl<PdfReaderNotifier, PdfReaderState> {
  /// Provider for PDF reader state
  ///
  /// Copied from [PdfReaderNotifier].
  PdfReaderNotifierProvider(String pdfId)
    : this._internal(
        () => PdfReaderNotifier()..pdfId = pdfId,
        from: pdfReaderNotifierProvider,
        name: r'pdfReaderNotifierProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$pdfReaderNotifierHash,
        dependencies: PdfReaderNotifierFamily._dependencies,
        allTransitiveDependencies:
            PdfReaderNotifierFamily._allTransitiveDependencies,
        pdfId: pdfId,
      );

  PdfReaderNotifierProvider._internal(
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
  PdfReaderState runNotifierBuild(covariant PdfReaderNotifier notifier) {
    return notifier.build(pdfId);
  }

  @override
  Override overrideWith(PdfReaderNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: PdfReaderNotifierProvider._internal(
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
  AutoDisposeNotifierProviderElement<PdfReaderNotifier, PdfReaderState>
  createElement() {
    return _PdfReaderNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PdfReaderNotifierProvider && other.pdfId == pdfId;
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
mixin PdfReaderNotifierRef on AutoDisposeNotifierProviderRef<PdfReaderState> {
  /// The parameter `pdfId` of this provider.
  String get pdfId;
}

class _PdfReaderNotifierProviderElement
    extends
        AutoDisposeNotifierProviderElement<PdfReaderNotifier, PdfReaderState>
    with PdfReaderNotifierRef {
  _PdfReaderNotifierProviderElement(super.provider);

  @override
  String get pdfId => (origin as PdfReaderNotifierProvider).pdfId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
