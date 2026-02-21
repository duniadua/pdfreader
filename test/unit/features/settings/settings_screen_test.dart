import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:pdf_reader_app/core/data/models/app_settings.dart';
import 'package:pdf_reader_app/core/data/repositories/settings_repository.dart';
import 'package:pdf_reader_app/core/constants/app_constants.dart';
import 'package:pdf_reader_app/core/utils/result.dart' as result;
import 'package:pdf_reader_app/features/settings/presentation/providers/settings_notifier.dart';

@GenerateMocks([SettingsRepository])
import 'settings_screen_test.mocks.dart';

void main() {
  late MockSettingsRepository mockRepository;
  late ProviderContainer container;

  setUp(() {
    mockRepository = MockSettingsRepository();
    container = ProviderContainer(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(mockRepository),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('SettingsNotifier', () {
    test('should return initial state when created', () async {
      // Arrange
      when(mockRepository.getSettings()).thenAnswer(
        (_) async => result.Result.success(AppSettings.defaultSettings()),
      );

      // Act
      await container.pump();

      // Assert
      final state = container.read(settingsNotifierProvider);
      expect(state.isLoading, false);
      expect(state.settings.darkMode, AppConstants.defaultDarkMode);
      expect(state.settings.fontSize, AppConstants.defaultFontSize);
      expect(state.settings.scrollDirection, AppConstants.defaultScrollDirection);
      expect(state.settings.autoCropMargins, AppConstants.defaultAutoCrop);
      expect(state.settings.brightness, AppConstants.defaultBrightness);
      expect(state.failure, isNull);
    });

    test('should load settings from repository on build', () async {
      // Arrange
      final testSettings = AppSettings(
        darkMode: true,
        fontSize: 16,
        scrollDirection: ScrollDirection.horizontal,
        autoCropMargins: false,
        brightness: 0.8,
      );

      when(mockRepository.getSettings()).thenAnswer(
        (_) async => result.Result.success(testSettings),
      );

      // Act
      await container.pump();

      // Assert
      final state = container.read(settingsNotifierProvider);
      expect(state.isLoading, false);
      expect(state.settings.darkMode, true);
      expect(state.settings.fontSize, 16);
      expect(state.settings.scrollDirection, ScrollDirection.horizontal);
      expect(state.settings.autoCropMargins, false);
      expect(state.settings.brightness, 0.8);
      expect(state.failure, isNull);
    });

    test('should set dark mode to true', () async {
      // Arrange
      when(mockRepository.getSettings()).thenAnswer(
        (_) async => result.Result.success(AppSettings.defaultSettings()),
      );
      when(mockRepository.updateSettings(any)).thenAnswer(
        (_) async => result.Result.success(AppSettings.defaultSettings()),
      );

      // Act
      await container.pump();
      await container.read(settingsNotifierProvider.notifier).setDarkMode(true);
      await container.pump();

      // Assert
      final state = container.read(settingsNotifierProvider);
      expect(state.settings.darkMode, true);
      verify(mockRepository.updateSettings(any)).called(1);
    });

    test('should set dark mode to false', () async {
      // Arrange
      when(mockRepository.getSettings()).thenAnswer(
        (_) async => result.Result.success(AppSettings.defaultSettings()),
      );
      when(mockRepository.updateSettings(any)).thenAnswer(
        (_) async => result.Result.success(AppSettings.defaultSettings()),
      );

      // Act
      await container.pump();
      await container.read(settingsNotifierProvider.notifier).setDarkMode(false);
      await container.pump();

      // Assert
      final state = container.read(settingsNotifierProvider);
      expect(state.settings.darkMode, false);
      verify(mockRepository.updateSettings(any)).called(1);
    });

    test('should toggle dark mode from false to true', () async {
      // Arrange
      when(mockRepository.getSettings()).thenAnswer(
        (_) async => result.Result.success(AppSettings.defaultSettings()),
      );
      when(mockRepository.updateSettings(any)).thenAnswer(
        (_) async => result.Result.success(AppSettings.defaultSettings()),
      );

      // Act
      await container.pump();
      await container.read(settingsNotifierProvider.notifier).setDarkMode(true);
      await container.pump();
      await container.read(settingsNotifierProvider.notifier).setDarkMode(false);
      await container.pump();

      // Assert
      final state = container.read(settingsNotifierProvider);
      expect(state.settings.darkMode, false);
      verify(mockRepository.updateSettings(any)).called(2);
    });

    test('should set font size', () async {
      // Arrange
      when(mockRepository.getSettings()).thenAnswer(
        (_) async => result.Result.success(AppSettings.defaultSettings()),
      );
      when(mockRepository.updateSettings(any)).thenAnswer(
        (_) async => result.Result.success(AppSettings.defaultSettings()),
      );

      // Act
      await container.pump();
      await container.read(settingsNotifierProvider.notifier).setFontSize(18);
      await container.pump();

      // Assert
      final state = container.read(settingsNotifierProvider);
      expect(state.settings.fontSize, 18);
      verify(mockRepository.updateSettings(any)).called(1);
    });

    test('should clamp font size to minimum', () async {
      // Arrange
      when(mockRepository.getSettings()).thenAnswer(
        (_) async => result.Result.success(AppSettings.defaultSettings()),
      );
      when(mockRepository.updateSettings(any)).thenAnswer(
        (_) async => result.Result.success(AppSettings.defaultSettings()),
      );

      // Act
      await container.pump();
      await container.read(settingsNotifierProvider.notifier).setFontSize(4);
      await container.pump();

      // Assert
      final state = container.read(settingsNotifierProvider);
      expect(state.settings.fontSize, AppConstants.minFontSize);
    });

    test('should clamp font size to maximum', () async {
      // Arrange
      when(mockRepository.getSettings()).thenAnswer(
        (_) async => result.Result.success(AppSettings.defaultSettings()),
      );
      when(mockRepository.updateSettings(any)).thenAnswer(
        (_) async => result.Result.success(AppSettings.defaultSettings()),
      );

      // Act
      await container.pump();
      await container.read(settingsNotifierProvider.notifier).setFontSize(30);
      await container.pump();

      // Assert
      final state = container.read(settingsNotifierProvider);
      expect(state.settings.fontSize, AppConstants.maxFontSize);
    });

    test('should set scroll direction to vertical', () async {
      // Arrange
      when(mockRepository.getSettings()).thenAnswer(
        (_) async => result.Result.success(AppSettings.defaultSettings()),
      );
      when(mockRepository.updateSettings(any)).thenAnswer(
        (_) async => result.Result.success(AppSettings.defaultSettings()),
      );

      // Act
      await container.pump();
      await container.read(settingsNotifierProvider.notifier).setScrollDirection(ScrollDirection.vertical);
      await container.pump();

      // Assert
      final state = container.read(settingsNotifierProvider);
      expect(state.settings.scrollDirection, ScrollDirection.vertical);
      verify(mockRepository.updateSettings(any)).called(1);
    });

    test('should set scroll direction to horizontal', () async {
      // Arrange
      when(mockRepository.getSettings()).thenAnswer(
        (_) async => result.Result.success(AppSettings.defaultSettings()),
      );
      when(mockRepository.updateSettings(any)).thenAnswer(
        (_) async => result.Result.success(AppSettings.defaultSettings()),
      );

      // Act
      await container.pump();
      await container.read(settingsNotifierProvider.notifier).setScrollDirection(ScrollDirection.horizontal);
      await container.pump();

      // Assert
      final state = container.read(settingsNotifierProvider);
      expect(state.settings.scrollDirection, ScrollDirection.horizontal);
      verify(mockRepository.updateSettings(any)).called(1);
    });

    test('should set auto crop margins', () async {
      // Arrange
      when(mockRepository.getSettings()).thenAnswer(
        (_) async => result.Result.success(AppSettings.defaultSettings()),
      );
      when(mockRepository.updateSettings(any)).thenAnswer(
        (_) async => result.Result.success(AppSettings.defaultSettings()),
      );

      // Act
      await container.pump();
      await container.read(settingsNotifierProvider.notifier).setAutoCropMargins(true);
      await container.pump();

      // Assert
      final state = container.read(settingsNotifierProvider);
      expect(state.settings.autoCropMargins, true);
      verify(mockRepository.updateSettings(any)).called(1);
    });

    test('should set brightness', () async {
      // Arrange
      when(mockRepository.getSettings()).thenAnswer(
        (_) async => result.Result.success(AppSettings.defaultSettings()),
      );
      when(mockRepository.updateSettings(any)).thenAnswer(
        (_) async => result.Result.success(AppSettings.defaultSettings()),
      );

      // Act
      await container.pump();
      await container.read(settingsNotifierProvider.notifier).setBrightness(0.9);
      await container.pump();

      // Assert
      final state = container.read(settingsNotifierProvider);
      expect(state.settings.brightness, closeTo(0.9, 0.01));
      verify(mockRepository.updateSettings(any)).called(1);
    });

    test('should clamp brightness to minimum', () async {
      // Arrange
      when(mockRepository.getSettings()).thenAnswer(
        (_) async => result.Result.success(AppSettings.defaultSettings()),
      );
      when(mockRepository.updateSettings(any)).thenAnswer(
        (_) async => result.Result.success(AppSettings.defaultSettings()),
      );

      // Act
      await container.pump();
      await container.read(settingsNotifierProvider.notifier).setBrightness(-0.5);
      await container.pump();

      // Assert
      final state = container.read(settingsNotifierProvider);
      expect(state.settings.brightness, 0.0);
    });

    test('should clamp brightness to maximum', () async {
      // Arrange
      when(mockRepository.getSettings()).thenAnswer(
        (_) async => result.Result.success(AppSettings.defaultSettings()),
      );
      when(mockRepository.updateSettings(any)).thenAnswer(
        (_) async => result.Result.success(AppSettings.defaultSettings()),
      );

      // Act
      await container.pump();
      await container.read(settingsNotifierProvider.notifier).setBrightness(1.5);
      await container.pump();

      // Assert
      final state = container.read(settingsNotifierProvider);
      expect(state.settings.brightness, 1.0);
    });

    test('should dismiss failure', () async {
      // Arrange
      when(mockRepository.getSettings()).thenAnswer(
        (_) async => result.Result.success(AppSettings.defaultSettings()),
      );

      // Act
      await container.pump();
      container.read(settingsNotifierProvider.notifier).dismissFailure();
      await container.pump();

      // Assert
      final state = container.read(settingsNotifierProvider);
      expect(state.failure, isNull);
    });

    test('should reset to defaults', () async {
      // Arrange
      when(mockRepository.getSettings()).thenAnswer(
        (_) async => result.Result.success(AppSettings.defaultSettings()),
      );
      when(mockRepository.resetToDefaults()).thenAnswer(
        (_) async => result.Result.success(AppSettings.defaultSettings()),
      );

      // Act
      await container.pump();
      await container.read(settingsNotifierProvider.notifier).resetToDefaults();
      await container.pump();

      // Assert
      final state = container.read(settingsNotifierProvider);
      expect(state.settings.darkMode, AppConstants.defaultDarkMode);
      expect(state.settings.fontSize, AppConstants.defaultFontSize);
      expect(state.settings.scrollDirection, AppConstants.defaultScrollDirection);
      expect(state.settings.autoCropMargins, AppConstants.defaultAutoCrop);
      expect(state.settings.brightness, AppConstants.defaultBrightness);
      verify(mockRepository.resetToDefaults()).called(1);
    });
  });
}
