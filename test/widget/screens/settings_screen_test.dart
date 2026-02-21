import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_reader_app/features/settings/presentation/settings_screen.dart';
import 'package:pdf_reader_app/features/settings/presentation/providers/settings_notifier.dart';
import 'package:pdf_reader_app/core/data/models/app_settings.dart';
import 'package:pdf_reader_app/core/constants/app_constants.dart';

void main() {
  group('SettingsScreen Widget Tests', () {
    testWidgets('should render without errors', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: const MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );

      // Just check it doesn't crash
      await tester.pump();
      expect(find.byType(SettingsScreen), findsOneWidget);
    });
  });

  group('SettingsState Unit Tests', () {
    test('should create initial state with defaults', () {
      final state = SettingsState.initial();

      expect(state.isLoading, true);
      expect(state.settings.darkMode, AppConstants.defaultDarkMode);
      expect(state.settings.fontSize, AppConstants.defaultFontSize);
      expect(state.failure, isNull);
    });

    test('copyWith should update specific fields', () {
      final initial = SettingsState(
        settings: AppSettings.defaultSettings(),
        isLoading: true,
        failure: null,
      );

      final updated = initial.copyWith(isLoading: false);

      expect(updated.isLoading, false);
      expect(updated.settings, initial.settings);
      expect(updated.failure, isNull);
    });

    test('copyWith should update settings', () {
      final initial = SettingsState(
        settings: AppSettings.defaultSettings(),
        isLoading: false,
        failure: null,
      );

      final newSettings = initial.settings.copyWith(darkMode: true);
      final updated = initial.copyWith(settings: newSettings);

      expect(updated.settings.darkMode, true);
      expect(updated.isLoading, false);
    });
  });

  group('AppSettings Defaults', () {
    test('defaultSettings should use AppConstants values', () {
      final settings = AppSettings.defaultSettings();

      expect(settings.darkMode, AppConstants.defaultDarkMode);
      expect(settings.fontSize, AppConstants.defaultFontSize);
      expect(settings.scrollDirection, ScrollDirection.vertical);
      expect(settings.autoCropMargins, AppConstants.defaultAutoCrop);
      expect(settings.brightness, AppConstants.defaultBrightness);
    });
  });
}
