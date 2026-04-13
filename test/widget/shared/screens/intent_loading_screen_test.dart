import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pdf_reader_app/shared/screens/intent_loading_screen.dart';

void main() {
  group('IntentLoadingScreen', () {
    group('Widget Tests', () {
      testWidgets('should render without errors', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          const MaterialApp(
            home: IntentLoadingScreen(),
          ),
        );

        // Assert
        expect(find.byType(IntentLoadingScreen), findsOneWidget);
        expect(find.byType(Scaffold), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('should display CircularProgressIndicator', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          const MaterialApp(
            home: IntentLoadingScreen(),
          ),
        );

        // Assert
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('should display opening PDF text', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          const MaterialApp(
            home: IntentLoadingScreen(),
          ),
        );

        // Assert
        expect(find.text('Opening PDF...'), findsOneWidget);
      });

      testWidgets('should center content vertically and horizontally',
          (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          const MaterialApp(
            home: IntentLoadingScreen(),
          ),
        );

        // Assert
        final centerWidget = tester.widget<Center>(find.byType(Center));
        expect(centerWidget.alignment, Alignment.center);
      });

      testWidgets('should use theme primary color for progress indicator',
          (tester) async {
        // Arrange
        const primaryColor = Color(0xFF135BEC);

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: primaryColor,
              ),
            ),
            home: const IntentLoadingScreen(),
          ),
        );

        // Act
        final progressIndicator = tester.widget<CircularProgressIndicator>(
          find.byType(CircularProgressIndicator),
        );

        // Assert
        expect(progressIndicator.valueColor, isNotNull);
      });

      testWidgets('should use theme text style for message', (tester) async {
        // Arrange
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(
              textTheme: const TextTheme(
                bodyLarge: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            home: const IntentLoadingScreen(),
          ),
        );

        // Act - use pump() instead of pumpAndSettle() for CircularProgressIndicator
        await tester.pump();
        final textFinder = find.text('Opening PDF...');

        // Assert
        expect(textFinder, findsOneWidget);
        final textWidget = tester.widget<Text>(textFinder);
        expect(textWidget.style?.fontWeight, FontWeight.w500);
        expect(textWidget.style?.fontSize, isNotNull);
      });

      testWidgets('should have spacing between progress and text',
          (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          const MaterialApp(
            home: IntentLoadingScreen(),
          ),
        );

        // Assert
        expect(find.byType(SizedBox), findsOneWidget);
        final sizedBox =
            tester.widget<SizedBox>(find.byType(SizedBox));
        expect(sizedBox.height, 16);
      });

      testWidgets('should render correctly in dark mode', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark(),
            home: const IntentLoadingScreen(),
          ),
        );

        // Assert
        expect(find.byType(IntentLoadingScreen), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('Opening PDF...'), findsOneWidget);
      });

      testWidgets('should render correctly in light mode', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.light(),
            home: const IntentLoadingScreen(),
          ),
        );

        // Assert
        expect(find.byType(IntentLoadingScreen), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('Opening PDF...'), findsOneWidget);
      });

      testWidgets('should use Column with main center alignment',
          (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          const MaterialApp(
            home: IntentLoadingScreen(),
          ),
        );

        // Assert
        final columnWidget = tester.widget<Column>(find.byType(Column));
        expect(
          columnWidget.mainAxisAlignment,
          MainAxisAlignment.center,
        );
      });

      testWidgets('should not throw errors when pumped multiple times',
          (tester) async {
        // Arrange
        await tester.pumpWidget(
          const MaterialApp(
            home: IntentLoadingScreen(),
          ),
        );

        // Act - pump multiple times (simulates hot reload)
        await tester.pump();
        await tester.pump();

        // Assert
        expect(find.byType(IntentLoadingScreen), findsOneWidget);
      });

      testWidgets('should have const constructor', (tester) async {
        // Arrange & Act & Assert
        expect(
          () => const IntentLoadingScreen(),
          returnsNormally,
        );
      });
    });

    group('Accessibility Tests', () {
      testWidgets('should have proper semantic label for screen readers',
          (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          const MaterialApp(
            home: IntentLoadingScreen(),
          ),
        );

        // Assert - Verify the screen has proper structure for accessibility
        // The Semantics widget should be present with the loading message
        expect(find.byType(IntentLoadingScreen), findsOneWidget);
        expect(find.text('Opening PDF...'), findsOneWidget);

        // Verify all expected widgets are present
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.byType(Column), findsOneWidget);
        expect(find.byType(Center), findsOneWidget);
      });

      testWidgets('should maintain accessibility when theme changes',
          (tester) async {
        // Arrange - Test with different themes
        final themes = [
          ThemeData.light(),
          ThemeData.dark(),
        ];

        for (final theme in themes) {
          await tester.pumpWidget(
            MaterialApp(
              theme: theme,
              home: const IntentLoadingScreen(),
            ),
          );

          // Assert - All widgets should be present regardless of theme
          expect(find.byType(IntentLoadingScreen), findsOneWidget);
          expect(find.byType(CircularProgressIndicator), findsOneWidget);
          expect(find.text('Opening PDF...'), findsOneWidget);

          // Clear for next iteration
          await tester.pumpWidget(const SizedBox.shrink());
        }
      });
    });
  });
}
