import 'package:flutter/material.dart';

/// App-wide constants derived from Stitch design system
class AppConstants {
  AppConstants._();

  // Design System Colors from Stitch prototypes
  static const Color primaryColor = Color(0xFF135BEC);
  static const Color backgroundLight = Color(0xFFF6F6F8);
  static const Color backgroundDark = Color(0xFF101622);

  // Navigation
  static const List<String> bottomNavItems = ['Library', 'Favorites', 'Timeline', 'Cloud'];

  // Storage Keys
  static const String keyRecentPdfs = 'recent_pdfs';
  static const String keyFavorites = 'favorite_pdfs';
  static const String keySettings = 'app_settings';

  // PDF Settings Defaults
  static const double minFontSize = 8.0;
  static const double maxFontSize = 24.0;
  static const double defaultFontSize = 14.0;
  static const double defaultBrightness = 0.75;
  static const bool defaultDarkMode = true;
  static const bool defaultAutoCrop = true;
  static const ScrollDirection defaultScrollDirection = ScrollDirection.vertical;

  // File Filters
  static const List<String> supportedPdfExtensions = ['pdf'];

  // Pagination
  static const int defaultRecentLimit = 10;
  static const int defaultPageSize = 20;

  // Animation durations
  static const Duration shortAnimation = Duration(milliseconds: 150);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);
}

/// Scroll direction enum for PDF viewing
enum ScrollDirection { vertical, horizontal }
