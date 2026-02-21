import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/data/models/app_settings.dart';
import '../../../../core/data/providers/repository_providers.dart';
import '../../../../core/data/repositories/settings_repository.dart';
import '../../../../core/utils/exceptions.dart';
import '../../../../core/utils/logger.dart';

part 'settings_notifier.g.dart';
part 'settings_notifier.freezed.dart';

/// Settings state
@freezed
class SettingsState with _$SettingsState {
  const factory SettingsState({
    required AppSettings settings,
    required bool isLoading,
    required AppFailure? failure,
  }) = _SettingsState;

  factory SettingsState.initial() => SettingsState(
        settings: AppSettings.defaultSettings(),
        isLoading: true,
        failure: null,
      );
}

/// Settings state notifier
@riverpod
class SettingsNotifier extends _$SettingsNotifier {
  late final SettingsRepository _repository;

  @override
  SettingsState build() {
    // Get repository from provider
    _repository = ref.read(settingsRepositoryProvider);

    // Load settings
    loadSettings();

    ref.onDispose(() {
      // Cleanup if needed
    });

    return SettingsState.initial();
  }

  /// Load settings from storage
  Future<void> loadSettings() async {
    state = state.copyWith(isLoading: true, failure: null);

    final result = await _repository.getSettings();
    result.when(
      success: (settings) {
        state = SettingsState(
          settings: settings,
          isLoading: false,
          failure: null,
        );
      },
      failure: (error, stackTrace) {
        AppLogger.e('Failed to load settings', error, stackTrace);
        state = SettingsState(
          settings: AppSettings.defaultSettings(),
          isLoading: false,
          failure: _handleAppFailure(error, stackTrace),
        );
      },
    );
  }

  /// Update dark mode
  Future<void> setDarkMode(bool value) async {
    final newSettings = state.settings.copyWith(darkMode: value);
    await _updateSettings(newSettings);
  }

  /// Update font size
  Future<void> setFontSize(double value) async {
    final clampedValue = value.clamp(8.0, 24.0);
    final newSettings = state.settings.copyWith(fontSize: clampedValue);
    await _updateSettings(newSettings);
  }

  /// Update scroll direction
  Future<void> setScrollDirection(ScrollDirection value) async {
    final newSettings = state.settings.copyWith(scrollDirection: value);
    await _updateSettings(newSettings);
  }

  /// Update auto crop margins
  Future<void> setAutoCropMargins(bool value) async {
    final newSettings = state.settings.copyWith(autoCropMargins: value);
    await _updateSettings(newSettings);
  }

  /// Update brightness
  Future<void> setBrightness(double value) async {
    final clampedValue = value.clamp(0.0, 1.0);
    final newSettings = state.settings.copyWith(brightness: clampedValue);
    await _updateSettings(newSettings);
  }

  /// Update all settings at once
  Future<void> _updateSettings(AppSettings newSettings) async {
    // Optimistic update
    state = state.copyWith(settings: newSettings);

    final result = await _repository.updateSettings(newSettings);
    result.when(
      failure: (error, stackTrace) {
        AppLogger.e('Failed to update settings', error, stackTrace);
        state = state.copyWith(failure: _handleAppFailure(error, stackTrace));
      },
      success: (_) {
        // Settings already updated optimistically
      },
    );
  }

  /// Reset to default settings
  Future<void> resetToDefaults() async {
    state = state.copyWith(isLoading: true);

    final result = await _repository.resetToDefaults();
    result.when(
      success: (settings) {
        state = SettingsState(
          settings: settings,
          isLoading: false,
          failure: null,
        );
      },
      failure: (error, stackTrace) {
        AppLogger.e('Failed to reset settings', error, stackTrace);
        state = SettingsState(
          settings: AppSettings.defaultSettings(),
          isLoading: false,
          failure: _handleAppFailure(error, stackTrace),
        );
      },
    );
  }

  /// Dismiss any failure
  void dismissFailure() {
    state = state.copyWith(failure: null);
  }

  AppFailure? _handleAppFailure(Object error, StackTrace? stackTrace) {
    if (error is AppException) {
      return AppFailure.fromException(error);
    }
    return AppFailure(
      message: error.toString(),
      cause: error,
      stackTrace: stackTrace,
    );
  }
}

/// Simplified provider for just app settings (for theme selection)
@riverpod
Future<AppSettings> appSettings(Ref ref) async {
  final repository = ref.watch(settingsRepositoryProvider);
  final result = await repository.getSettings();
  return result.when(
    success: (settings) => settings,
    failure: (error, stackTrace) => AppSettings.defaultSettings(),
  );
}
