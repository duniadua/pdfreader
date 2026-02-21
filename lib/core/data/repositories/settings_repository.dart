import 'package:shared_preferences/shared_preferences.dart';

import '../../constants/app_constants.dart';
import '../../utils/exceptions.dart';
import '../../utils/logger.dart';
import '../../utils/result.dart';
import '../models/app_settings.dart';

/// Repository interface for app settings
abstract class SettingsRepository {
  /// Get current settings
  Future<Result<AppSettings>> getSettings();

  /// Update settings
  Future<Result<AppSettings>> updateSettings(AppSettings settings);

  /// Reset to defaults
  Future<Result<AppSettings>> resetToDefaults();

  /// Stream of settings changes
  Stream<AppSettings> get settingsStream;
}

/// Implementation of SettingsRepository
class SharedPreferencesSettingsRepository implements SettingsRepository {
  const SharedPreferencesSettingsRepository({
    required SharedPreferences prefs,
  }) : _prefs = prefs;

  final SharedPreferences _prefs;

  static const String _darkModeKey = 'dark_mode';
  static const String _fontSizeKey = 'font_size';
  static const String _scrollDirectionKey = 'scroll_direction';
  static const String _autoCropKey = 'auto_crop_margins';
  static const String _brightnessKey = 'brightness';

  @override
  Future<Result<AppSettings>> getSettings() async {
    try {
      final settings = AppSettings(
        darkMode: _prefs.getBool(_darkModeKey) ?? AppConstants.defaultDarkMode,
        fontSize: _prefs.getDouble(_fontSizeKey) ?? AppConstants.defaultFontSize,
        scrollDirection: _prefs.getString(_scrollDirectionKey) == 'horizontal'
            ? ScrollDirection.horizontal
            : ScrollDirection.vertical,
        autoCropMargins: _prefs.getBool(_autoCropKey) ?? AppConstants.defaultAutoCrop,
        brightness: _prefs.getDouble(_brightnessKey) ?? AppConstants.defaultBrightness,
      );
      return Result.success(settings);
    } catch (e, st) {
      AppLogger.e('Failed to load settings', e, st);
      return Result.failure(
        const StorageException('Failed to load settings'),
        st,
      );
    }
  }

  @override
  Future<Result<AppSettings>> updateSettings(AppSettings settings) async {
    try {
      await _prefs.setBool(_darkModeKey, settings.darkMode);
      await _prefs.setDouble(_fontSizeKey, settings.fontSize);
      await _prefs.setString(
        _scrollDirectionKey,
        settings.scrollDirection == ScrollDirection.horizontal ? 'horizontal' : 'vertical',
      );
      await _prefs.setBool(_autoCropKey, settings.autoCropMargins);
      await _prefs.setDouble(_brightnessKey, settings.brightness);
      AppLogger.i('Settings updated');
      return Result.success(settings);
    } catch (e, st) {
      AppLogger.e('Failed to save settings', e, st);
      return Result.failure(
        const StorageException('Failed to save settings'),
        st,
      );
    }
  }

  @override
  Future<Result<AppSettings>> resetToDefaults() async {
    try {
      final settings = AppSettings.defaultSettings();
      return updateSettings(settings);
    } catch (e, st) {
      AppLogger.e('Failed to reset settings', e, st);
      return Result.failure(
        const StorageException('Failed to reset settings'),
        st,
      );
    }
  }

  @override
  Stream<AppSettings> get settingsStream {
    // Return a stream that emits when settings change
    return Stream.periodic(
      const Duration(seconds: 1),
      (_) => AppSettings(
        darkMode: _prefs.getBool(_darkModeKey) ?? AppConstants.defaultDarkMode,
        fontSize: _prefs.getDouble(_fontSizeKey) ?? AppConstants.defaultFontSize,
        scrollDirection: _prefs.getString(_scrollDirectionKey) == 'horizontal'
            ? ScrollDirection.horizontal
            : ScrollDirection.vertical,
        autoCropMargins: _prefs.getBool(_autoCropKey) ?? AppConstants.defaultAutoCrop,
        brightness: _prefs.getDouble(_brightnessKey) ?? AppConstants.defaultBrightness,
      ),
    ).distinct();
  }
}
