import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_reader_app/core/data/models/app_settings.dart';
import 'package:pdf_reader_app/core/constants/app_constants.dart';

void main() {
  group('AppSettings', () {
    test('should create instance with all fields', () {
      final settings = AppSettings(
        darkMode: true,
        fontSize: 16.0,
        scrollDirection: ScrollDirection.horizontal,
        autoCropMargins: true,
        brightness: 0.7,
      );

      expect(settings.darkMode, true);
      expect(settings.fontSize, 16.0);
      expect(settings.scrollDirection, ScrollDirection.horizontal);
      expect(settings.autoCropMargins, true);
      expect(settings.brightness, 0.7);
    });

    test('should create default settings', () {
      final settings = AppSettings.defaultSettings();

      expect(settings.darkMode, AppConstants.defaultDarkMode);
      expect(settings.fontSize, AppConstants.defaultFontSize);
      expect(settings.autoCropMargins, AppConstants.defaultAutoCrop);
      expect(settings.brightness, AppConstants.defaultBrightness);
      expect(settings.scrollDirection, ScrollDirection.vertical);
    });

    test('should serialize to JSON correctly', () {
      final settings = AppSettings(
        darkMode: true,
        fontSize: 18.5,
        scrollDirection: ScrollDirection.horizontal,
        autoCropMargins: false,
        brightness: 0.8,
      );

      final json = settings.toJson();

      expect(json['darkMode'], true);
      expect(json['fontSize'], 18.5);
      expect(json['scrollDirection'], 'horizontal');
      expect(json['autoCropMargins'], false);
      expect(json['brightness'], 0.8);
    });

    test('should deserialize from JSON correctly', () {
      final json = {
        'darkMode': true,
        'fontSize': 18.5,
        'scrollDirection': 'horizontal',
        'autoCropMargins': false,
        'brightness': 0.8,
      };

      final settings = AppSettings.fromJson(json);

      expect(settings.darkMode, true);
      expect(settings.fontSize, 18.5);
      expect(settings.scrollDirection, ScrollDirection.horizontal);
      expect(settings.autoCropMargins, false);
      expect(settings.brightness, 0.8);
    });

    test('should handle vertical scroll direction in JSON', () {
      final json = {
        'darkMode': false,
        'fontSize': 14.0,
        'scrollDirection': 'vertical',
        'autoCropMargins': true,
        'brightness': 0.5,
      };

      final settings = AppSettings.fromJson(json);

      expect(settings.scrollDirection, ScrollDirection.vertical);
    });

    test('copyWith should create new instance with updated values', () {
      final settings = AppSettings(
        darkMode: false,
        fontSize: 14.0,
        scrollDirection: ScrollDirection.vertical,
        autoCropMargins: false,
        brightness: 0.5,
      );

      final updated = settings.copyWith(
        darkMode: true,
        fontSize: 18.0,
      );

      expect(updated.darkMode, true);
      expect(updated.fontSize, 18.0);
      expect(updated.scrollDirection, ScrollDirection.vertical);
      expect(updated.autoCropMargins, false);
      expect(updated.brightness, 0.5);
    });

    test('copyWith should preserve original values when not specified', () {
      final original = AppSettings(
        darkMode: false,
        fontSize: 14.0,
        scrollDirection: ScrollDirection.vertical,
        autoCropMargins: false,
        brightness: 0.5,
      );

      final copied = original.copyWith();

      expect(copied.darkMode, original.darkMode);
      expect(copied.fontSize, original.fontSize);
      expect(copied.scrollDirection, original.scrollDirection);
      expect(copied.autoCropMargins, original.autoCropMargins);
      expect(copied.brightness, original.brightness);
    });
  });
}
