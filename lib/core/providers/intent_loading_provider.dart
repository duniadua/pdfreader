import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'intent_loading_provider.g.dart';

/// Provider for tracking PDF intent processing state.
///
/// When true, the router will show a loading screen instead of the
/// library screen while processing an incoming PDF intent from external apps.
@riverpod
class IntentLoading extends _$IntentLoading {
  @override
  bool build() => false;

  /// Set whether an intent is currently being processed.
  void setProcessing(bool value) => state = value;
}
