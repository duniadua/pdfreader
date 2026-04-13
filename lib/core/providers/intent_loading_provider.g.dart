// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'intent_loading_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$intentLoadingHash() => r'611204c0eb4e05383ffcaf615d374a8b4d075490';

/// Provider for tracking PDF intent processing state.
///
/// When true, the router will show a loading screen instead of the
/// library screen while processing an incoming PDF intent from external apps.
///
/// Copied from [IntentLoading].
@ProviderFor(IntentLoading)
final intentLoadingProvider =
    AutoDisposeNotifierProvider<IntentLoading, bool>.internal(
      IntentLoading.new,
      name: r'intentLoadingProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$intentLoadingHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$IntentLoading = AutoDisposeNotifier<bool>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
