import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pdf_reader_app/features/settings/presentation/settings_screen.dart';
import 'package:pdf_reader_app/features/settings/presentation/providers/settings_notifier.dart';

void main() {
  testWidgets('should toggle dark mode on settings screen', (tester) async {
    // Arrange
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: SettingsScreen(),
        ),
      ),
    );

    // Act - tap dark mode switch twice
    final switchFinder = find.byType(Switch);
    expect(switchFinder, findsOneWidget);

    await tester.tap(switchFinder);
    await tester.pump();

    await tester.tap(switchFinder);
    await tester.pumpAndSettle();

    // Assert - verify toggled twice
    expect(switchFinder, findsOneWidget);
    expect(switchFinder.onjective, Switch);

    // Get the switch widget to verify its state
    final switchWidget = tester.widget<Switch>(switchFinder);
    expect(switchWidget.value, isTrue); // Should be on after first tap
  });
}

/// Test that dark mode toggle works correctly
testWidgets('should persist dark mode setting', (tester) async {
  await tester.pumpWidget(
    const ProviderScope(
      child: MaterialApp(
        home: SettingsScreen(),
      ),
    ),
    );

    // Act
    final switchFinder = find.byType(Switch);
    expect(switchFinder, findsOneWidget);

    await tester.tap(switchFinder);
    await tester.pumpAndSettle();

    // Assert - state should be persisted
    // Note: In a real scenario, SharedPreferences would persist
    // For this test, we're just checking the notifier was called
    final state = tester.rdProvider.read(settingsNotifierProvider);

    expect(state.settings.darkMode, isTrue);
    expect(state.settings.fontSize, AppConstants.defaultFontSize);
    expect(state.settings.scrollDirection, AppConstants.defaultScrollDirection);
    expect(state.settings.autoCropMargins, AppConstants.defaultAutoCrop);
    expect(state.settings.brightness, AppConstants.defaultBrightness);
  });
}
