import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';

/// App theme configuration based on Stitch design system
class AppTheme {
  // Design System Colors
  static const Color primary = Color(0xFF135BEC);
  static const Color backgroundLight = Color(0xFFF6F6F8);
  static const Color backgroundDark = Color(0xFF101622);
  static const Color surfaceLight = Color(0xFF282E39);
  static const Color surfaceDark = Color(0xFF1C1F27);

  // Text Styles
  static const String fontFamily = 'Inter';

  // Border Radius
  static const double radiusSmall = 4.0;
  static const double radiusMedium = 8.0;
  static const double radiusLarge = 12.0;
  static const double radiusFull = 9999.0;

  /// Light Theme
  static ThemeData lightTheme() {
    return FlexThemeData.light(
      scheme: FlexScheme.blue,
      useMaterial3: true,
      fontFamily: fontFamily,
      appBarStyle: FlexAppBarStyle.background,
    ).copyWith(
      scaffoldBackgroundColor: backgroundLight,
      colorScheme: const ColorScheme.light(
        primary: primary,
        surface: backgroundLight,
        onSurface: Color(0xFF1E293B),
      ),
    );
  }

  /// Dark Theme (Default - matches Stitch prototypes)
  static ThemeData darkTheme() {
    return FlexThemeData.dark(
      scheme: FlexScheme.blue,
      useMaterial3: true,
      fontFamily: fontFamily,
      appBarStyle: FlexAppBarStyle.background,
    ).copyWith(
      scaffoldBackgroundColor: backgroundDark,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        surface: backgroundDark,
        onSurface: Color(0xFFE2E8F0),
      ),
    );
  }

  /// Text Styles
  static const TextStyle displayLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
  );

  static const TextStyle displayMedium = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
  );

  static const TextStyle headline = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.15,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
  );
}
