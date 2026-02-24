import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf_reader_app/core/data/repositories/settings_repository.dart';
import 'package:pdf_reader_app/core/data/models/app_settings.dart';
import 'package:pdf_reader_app/core/constants/app_constants.dart';

@GenerateMocks([SharedPreferences])
import 'settings_repository_test.mocks.dart';

void main() {
  late SharedPreferencesSettingsRepository repository;
  late MockSharedPreferences mockPrefs;

  setUp(() {
    mockPrefs = MockSharedPreferences();
    repository = SharedPreferencesSettingsRepository(prefs: mockPrefs);
  });

  group('SharedPreferencesSettingsRepository', () {
    group('getSettings', () {
      test('should return settings when all values exist', () async {
        when(mockPrefs.getBool('dark_mode')).thenReturn(true);
        when(mockPrefs.getDouble('font_size')).thenReturn(18.0);
        when(mockPrefs.getString('scroll_direction')).thenReturn('horizontal');
        when(mockPrefs.getBool('auto_crop_margins')).thenReturn(false);
        when(mockPrefs.getDouble('brightness')).thenReturn(0.7);

        final result = await repository.getSettings();

        result.when(
          success: (settings) {
            expect(settings.darkMode, true);
            expect(settings.fontSize, 18.0);
            expect(settings.scrollDirection, ScrollDirection.horizontal);
            expect(settings.autoCropMargins, false);
            expect(settings.brightness, 0.7);
          },
          failure: (_, __) => fail('Should not return failure'),
        );
      });

      test('should return default settings when values do not exist', () async {
        when(mockPrefs.getBool(any)).thenReturn(null);
        when(mockPrefs.getDouble(any)).thenReturn(null);
        when(mockPrefs.getString(any)).thenReturn(null);

        final result = await repository.getSettings();

        result.when(
          success: (settings) {
            expect(settings.darkMode, AppConstants.defaultDarkMode);
            expect(settings.fontSize, AppConstants.defaultFontSize);
            expect(settings.scrollDirection, ScrollDirection.vertical);
            expect(settings.autoCropMargins, AppConstants.defaultAutoCrop);
            expect(settings.brightness, AppConstants.defaultBrightness);
          },
          failure: (_, __) => fail('Should not return failure'),
        );
      });

      test('should handle horizontal scroll direction correctly', () async {
        when(mockPrefs.getBool(any)).thenReturn(null);
        when(mockPrefs.getDouble(any)).thenReturn(null);
        when(mockPrefs.getString('scroll_direction')).thenReturn('horizontal');

        final result = await repository.getSettings();

        result.when(
          success: (settings) {
            expect(settings.scrollDirection, ScrollDirection.horizontal);
          },
          failure: (_, __) => fail('Should not return failure'),
        );
      });
    });

    group('updateSettings', () {
      test('should save all settings values', () async {
        when(mockPrefs.setBool(any, any)).thenAnswer((_) async => true);
        when(mockPrefs.setDouble(any, any)).thenAnswer((_) async => true);
        when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);

        final settings = AppSettings(
          darkMode: true,
          fontSize: 20.0,
          scrollDirection: ScrollDirection.horizontal,
          autoCropMargins: true,
          brightness: 0.9,
        );

        final result = await repository.updateSettings(settings);

        result.when(
          success: (_) {
            verify(mockPrefs.setBool('dark_mode', true)).called(1);
            verify(mockPrefs.setDouble('font_size', 20.0)).called(1);
            verify(mockPrefs.setString('scroll_direction', 'horizontal')).called(1);
            verify(mockPrefs.setBool('auto_crop_margins', true)).called(1);
            verify(mockPrefs.setDouble('brightness', 0.9)).called(1);
          },
          failure: (_, __) => fail('Should not return failure'),
        );
      });

      test('should save vertical scroll direction', () async {
        when(mockPrefs.setBool(any, any)).thenAnswer((_) async => true);
        when(mockPrefs.setDouble(any, any)).thenAnswer((_) async => true);
        when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);

        final settings = AppSettings(
          darkMode: false,
          fontSize: 14.0,
          scrollDirection: ScrollDirection.vertical,
          autoCropMargins: false,
          brightness: 0.5,
        );

        final result = await repository.updateSettings(settings);

        result.when(
          success: (_) {
            verify(mockPrefs.setString('scroll_direction', 'vertical')).called(1);
          },
          failure: (_, __) => fail('Should not return failure'),
        );
      });

      test('should return failure when save fails', () async {
        when(mockPrefs.setBool(any, any)).thenThrow(Exception('Save failed'));

        final settings = AppSettings(
          darkMode: true,
          fontSize: 16.0,
          scrollDirection: ScrollDirection.vertical,
          autoCropMargins: false,
          brightness: 0.5,
        );

        final result = await repository.updateSettings(settings);

        result.when(
          success: (_) => fail('Should return failure'),
          failure: (_, __) => expect(true, true), // Expected failure
        );
      });
    });

    group('resetToDefaults', () {
      test('should reset to default settings', () async {
        when(mockPrefs.setBool(any, any)).thenAnswer((_) async => true);
        when(mockPrefs.setDouble(any, any)).thenAnswer((_) async => true);
        when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);

        final result = await repository.resetToDefaults();

        result.when(
          success: (settings) {
            expect(settings.darkMode, AppConstants.defaultDarkMode);
            expect(settings.fontSize, AppConstants.defaultFontSize);
            expect(settings.scrollDirection, ScrollDirection.vertical);
            expect(settings.autoCropMargins, AppConstants.defaultAutoCrop);
            expect(settings.brightness, AppConstants.defaultBrightness);
          },
          failure: (_, __) => fail('Should not return failure'),
        );
      });
    });

    group('settingsStream', () {
      test('should emit settings periodically', () async {
        when(mockPrefs.getBool('dark_mode')).thenReturn(true);
        when(mockPrefs.getDouble('font_size')).thenReturn(18.0);
        when(mockPrefs.getString('scroll_direction')).thenReturn('vertical');
        when(mockPrefs.getBool('auto_crop_margins')).thenReturn(false);
        when(mockPrefs.getDouble('brightness')).thenReturn(0.7);

        final stream = repository.settingsStream;

        final settings = await stream.first;

        expect(settings.darkMode, true);
        expect(settings.fontSize, 18.0);
      });
    });
  });
}
