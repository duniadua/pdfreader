import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import '../utils/logger.dart';

/// Centralized analytics service for tracking user activity
///
/// This service wraps Firebase Analytics and provides
/// type-safe event tracking methods for all app events.
class AnalyticsService {
  AnalyticsService._();

  static final AnalyticsService instance = AnalyticsService._();

  FirebaseAnalytics? _analytics;

  bool get isInitialized => _analytics != null;

  /// Initialize analytics with Firebase Analytics instance
  void initialize(FirebaseAnalytics analytics) {
    _analytics = analytics;
    AppLogger.i('AnalyticsService initialized');
  }

  FirebaseAnalytics? get _analyticsInstance {
    if (_analytics == null) {
      AppLogger.w('AnalyticsService not initialized');
      return null;
    }
    return _analytics;
  }

  // =====================================================
  // SCREEN VIEW TRACKING
  // =====================================================

  /// Track screen view
  Future<void> trackScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    if (kDebugMode) return; // Skip analytics in debug mode

    try {
      await _analyticsInstance?.logScreenView(
        screenName: screenName,
        screenClass: screenClass,
      );
      AppLogger.d('Analytics: Screen view - $screenName');
    } catch (e) {
      AppLogger.e('Failed to track screen view', e);
    }
  }

  // =====================================================
  // PDF LIBRARY EVENTS
  // =====================================================

  /// Track PDF import
  Future<void> trackPdfImport({bool success = true}) async {
    if (kDebugMode) return;

    try {
      await _analyticsInstance?.logEvent(
        name: 'pdf_import',
        parameters: {'success': success},
      );
      AppLogger.d('Analytics: PDF import - success=$success');
    } catch (e) {
      AppLogger.e('Failed to track PDF import', e);
    }
  }

  /// Track PDF open
  Future<void> trackPdfOpen({
    required String pdfId,
    int? pageCount,
    bool isFavorite = false,
  }) async {
    if (kDebugMode) return;

    try {
      await _analyticsInstance?.logEvent(
        name: 'pdf_open',
        parameters: {
          'pdf_id': pdfId,
          if (pageCount != null) 'page_count': pageCount,
          'is_favorite': isFavorite,
        },
      );
      AppLogger.d('Analytics: PDF open - $pdfId');
    } catch (e) {
      AppLogger.e('Failed to track PDF open', e);
    }
  }

  /// Track PDF close
  Future<void> trackPdfClose({
    required String pdfId,
    required int durationSeconds,
    required int pagesViewed,
  }) async {
    if (kDebugMode) return;

    try {
      await _analyticsInstance?.logEvent(
        name: 'pdf_close',
        parameters: {
          'pdf_id': pdfId,
          'duration_seconds': durationSeconds,
          'pages_viewed': pagesViewed,
        },
      );
      AppLogger.d('Analytics: PDF close - $pdfId (${durationSeconds}s)');
    } catch (e) {
      AppLogger.e('Failed to track PDF close', e);
    }
  }

  /// Track PDF delete
  Future<void> trackPdfDelete({required String pdfId}) async {
    if (kDebugMode) return;

    try {
      await _analyticsInstance?.logEvent(
        name: 'pdf_delete',
        parameters: {'pdf_id': pdfId},
      );
      AppLogger.d('Analytics: PDF delete - $pdfId');
    } catch (e) {
      AppLogger.e('Failed to track PDF delete', e);
    }
  }

  /// Track PDF favorite toggle
  Future<void> trackPdfFavorite({
    required String pdfId,
    required bool isFavorite,
  }) async {
    if (kDebugMode) return;

    try {
      await _analyticsInstance?.logEvent(
        name: 'pdf_favorite',
        parameters: {
          'pdf_id': pdfId,
          'is_favorite': isFavorite,
        },
      );
      AppLogger.d('Analytics: PDF favorite - $pdfId ($isFavorite)');
    } catch (e) {
      AppLogger.e('Failed to track PDF favorite', e);
    }
  }

  /// Track PDF search
  Future<void> trackPdfSearch({required String query}) async {
    if (kDebugMode) return;

    try {
      await _analyticsInstance?.logSearch(searchTerm: query);
      AppLogger.d('Analytics: PDF search - $query');
    } catch (e) {
      AppLogger.e('Failed to track PDF search', e);
    }
  }

  /// Track PDF filter change
  Future<void> trackPdfFilter({
    required String filterType, // 'all', 'favorites', 'recent'
  }) async {
    if (kDebugMode) return;

    try {
      await _analyticsInstance?.logEvent(
        name: 'pdf_filter',
        parameters: {'filter_type': filterType},
      );
      AppLogger.d('Analytics: PDF filter - $filterType');
    } catch (e) {
      AppLogger.e('Failed to track PDF filter', e);
    }
  }

  /// Track PDF sort change
  Future<void> trackPdfSort({
    required String sortType, // 'name', 'date', 'size'
  }) async {
    if (kDebugMode) return;

    try {
      await _analyticsInstance?.logEvent(
        name: 'pdf_sort',
        parameters: {'sort_type': sortType},
      );
      AppLogger.d('Analytics: PDF sort - $sortType');
    } catch (e) {
      AppLogger.e('Failed to track PDF sort', e);
    }
  }

  // =====================================================
  // PDF READER EVENTS
  // =====================================================

  /// Track page navigation
  Future<void> trackPageNavigation({
    required String pdfId,
    required int fromPage,
    required int toPage,
    String navigationType = 'unknown', // 'scroll', 'jump', 'thumbnail', 'slider'
  }) async {
    if (kDebugMode) return;

    try {
      await _analyticsInstance?.logEvent(
        name: 'page_navigation',
        parameters: {
          'pdf_id': pdfId,
          'from_page': fromPage,
          'to_page': toPage,
          'navigation_type': navigationType,
        },
      );
      AppLogger.d('Analytics: Page navigation - $fromPage -> $toPage ($navigationType)');
    } catch (e) {
      AppLogger.e('Failed to track page navigation', e);
    }
  }

  /// Track brightness change
  Future<void> trackBrightnessChange({
    required String level, // 'min', 'low', 'medium', 'high', 'max'
  }) async {
    if (kDebugMode) return;

    try {
      await _analyticsInstance?.logEvent(
        name: 'brightness_change',
        parameters: {'brightness_level': level},
      );
      AppLogger.d('Analytics: Brightness change - $level');
    } catch (e) {
      AppLogger.e('Failed to track brightness change', e);
    }
  }

  /// Track zoom change
  Future<void> trackZoomChange({
    required double zoomLevel,
  }) async {
    if (kDebugMode) return;

    try {
      await _analyticsInstance?.logEvent(
        name: 'zoom_change',
        parameters: {'zoom_level': zoomLevel},
      );
      AppLogger.d('Analytics: Zoom change - $zoomLevel');
    } catch (e) {
      AppLogger.e('Failed to track zoom change', e);
    }
  }

  /// Track rotation change
  Future<void> trackRotationChange({
    required int degrees, // 0, 90, 180, 270
  }) async {
    if (kDebugMode) return;

    try {
      await _analyticsInstance?.logEvent(
        name: 'rotation_change',
        parameters: {'degrees': degrees},
      );
      AppLogger.d('Analytics: Rotation change - $degrees°');
    } catch (e) {
      AppLogger.e('Failed to track rotation change', e);
    }
  }

  /// Track bookmark add
  Future<void> trackBookmarkAdd({
    required String pdfId,
    required int pageNumber,
  }) async {
    if (kDebugMode) return;

    try {
      await _analyticsInstance?.logEvent(
        name: 'bookmark_add',
        parameters: {
          'pdf_id': pdfId,
          'page_number': pageNumber,
        },
      );
      AppLogger.d('Analytics: Bookmark add - $pdfId:$pageNumber');
    } catch (e) {
      AppLogger.e('Failed to track bookmark add', e);
    }
  }

  /// Track bookmark remove
  Future<void> trackBookmarkRemove({
    required String pdfId,
    required int pageNumber,
  }) async {
    if (kDebugMode) return;

    try {
      await _analyticsInstance?.logEvent(
        name: 'bookmark_remove',
        parameters: {
          'pdf_id': pdfId,
          'page_number': pageNumber,
        },
      );
      AppLogger.d('Analytics: Bookmark remove - $pdfId:$pageNumber');
    } catch (e) {
      AppLogger.e('Failed to track bookmark remove', e);
    }
  }

  /// Track table of contents navigation
  Future<void> trackTocNavigation({
    required String pdfId,
    required int destinationPage,
  }) async {
    if (kDebugMode) return;

    try {
      await _analyticsInstance?.logEvent(
        name: 'toc_navigation',
        parameters: {
          'pdf_id': pdfId,
          'destination_page': destinationPage,
        },
      );
      AppLogger.d('Analytics: TOC navigation - $pdfId -> page $destinationPage');
    } catch (e) {
      AppLogger.e('Failed to track TOC navigation', e);
    }
  }

  /// Track PDF share
  Future<void> trackPdfShare({
    required String pdfId,
    required String method, // 'intent', 'copy', etc.
  }) async {
    if (kDebugMode) return;

    try {
      await _analyticsInstance?.logEvent(
        name: 'pdf_share',
        parameters: {
          'pdf_id': pdfId,
          'share_method': method,
        },
      );
      AppLogger.d('Analytics: PDF share - $pdfId via $method');
    } catch (e) {
      AppLogger.e('Failed to track PDF share', e);
    }
  }

  // =====================================================
  // SETTINGS EVENTS
  // =====================================================

  /// Track theme change
  Future<void> trackThemeChange({required bool isDarkMode}) async {
    if (kDebugMode) return;

    try {
      await _analyticsInstance?.logEvent(
        name: 'theme_change',
        parameters: {'theme_mode': isDarkMode ? 'dark' : 'light'},
      );
      AppLogger.d('Analytics: Theme change - ${isDarkMode ? 'dark' : 'light'}');
    } catch (e) {
      AppLogger.e('Failed to track theme change', e);
    }
  }

  /// Track font size change
  Future<void> trackFontSizeChange({required double fontSize}) async {
    if (kDebugMode) return;

    try {
      await _analyticsInstance?.logEvent(
        name: 'font_size_change',
        parameters: {'font_size': fontSize},
      );
      AppLogger.d('Analytics: Font size change - $fontSize');
    } catch (e) {
      AppLogger.e('Failed to track font size change', e);
    }
  }

  /// Track setting toggle
  Future<void> trackSettingToggle({
    required String settingName,
    required bool enabled,
  }) async {
    if (kDebugMode) return;

    try {
      await _analyticsInstance?.logEvent(
        name: 'setting_toggle',
        parameters: {
          'setting_name': settingName,
          'enabled': enabled,
        },
      );
      AppLogger.d('Analytics: Setting toggle - $settingName = $enabled');
    } catch (e) {
      AppLogger.e('Failed to track setting toggle', e);
    }
  }

  /// Track clear cache
  Future<void> trackClearCache({required int cacheSizeMb}) async {
    if (kDebugMode) return;

    try {
      await _analyticsInstance?.logEvent(
        name: 'clear_cache',
        parameters: {'cache_size_mb': cacheSizeMb},
      );
      AppLogger.d('Analytics: Clear cache - ${cacheSizeMb}MB');
    } catch (e) {
      AppLogger.e('Failed to track clear cache', e);
    }
  }

  // =====================================================
  // APP LIFECYCLE EVENTS
  // =====================================================

  /// Track app open
  Future<void> trackAppOpen() async {
    if (kDebugMode) return;

    try {
      await _analyticsInstance?.logAppOpen();
      AppLogger.d('Analytics: App open');
    } catch (e) {
      AppLogger.e('Failed to track app open', e);
    }
  }

  /// Track app background
  Future<void> trackAppBackground() async {
    if (kDebugMode) return;

    try {
      await _analyticsInstance?.logEvent(
        name: 'app_background',
        parameters: null,
      );
      AppLogger.d('Analytics: App background');
    } catch (e) {
      AppLogger.e('Failed to track app background', e);
    }
  }

  /// Track app foreground
  Future<void> trackAppForeground() async {
    if (kDebugMode) return;

    try {
      await _analyticsInstance?.logEvent(
        name: 'app_foreground',
        parameters: null,
      );
      AppLogger.d('Analytics: App foreground');
    } catch (e) {
      AppLogger.e('Failed to track app foreground', e);
    }
  }

  // =====================================================
  // ERROR TRACKING
  // =====================================================

  /// Track error
  Future<void> trackError({
    required String errorMessage,
    String? errorContext,
  }) async {
    try {
      await _analyticsInstance?.logEvent(
        name: 'error',
        parameters: {
          'error_message': errorMessage,
          if (errorContext != null) 'error_context': errorContext,
        },
      );
      AppLogger.d('Analytics: Error - $errorMessage');
    } catch (e) {
      AppLogger.e('Failed to track error', e);
    }
  }

  // =====================================================
  // CUSTOM EVENT
  // =====================================================

  /// Track custom event
  Future<void> trackCustomEvent({
    required String name,
    Map<String, Object?>? parameters,
  }) async {
    if (kDebugMode) return;

    try {
      // Convert nullable map to non-nullable for Firebase Analytics
      final params = parameters?.cast<String, Object>();
      await _analyticsInstance?.logEvent(
        name: name,
        parameters: params,
      );
      AppLogger.d('Analytics: Custom event - $name');
    } catch (e) {
      AppLogger.e('Failed to track custom event', e);
    }
  }

  /// Set user ID
  Future<void> setUserId(String? id) async {
    if (kDebugMode) return;

    try {
      await _analyticsInstance?.setUserId(id: id);
      AppLogger.d('Analytics: User ID set - $id');
    } catch (e) {
      AppLogger.e('Failed to set user ID', e);
    }
  }

  /// Set user property
  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {
    if (kDebugMode) return;

    try {
      await _analyticsInstance?.setUserProperty(name: name, value: value);
      AppLogger.d('Analytics: User property - $name = $value');
    } catch (e) {
      AppLogger.e('Failed to set user property', e);
    }
  }

  // =====================================================
  // GOOGLE DRIVE EVENTS
  // =====================================================

  /// Track Google Drive connection
  Future<void> trackDriveConnect() async {
    if (kDebugMode) return;

    try {
      await _analyticsInstance?.logEvent(
        name: 'drive_connect',
        parameters: null,
      );
      AppLogger.d('Analytics: Drive connect');
    } catch (e) {
      AppLogger.e('Failed to track Drive connect', e);
    }
  }

  /// Track Google Drive disconnect
  Future<void> trackDriveDisconnect() async {
    if (kDebugMode) return;

    try {
      await _analyticsInstance?.logEvent(
        name: 'drive_disconnect',
        parameters: null,
      );
      AppLogger.d('Analytics: Drive disconnect');
    } catch (e) {
      AppLogger.e('Failed to track Drive disconnect', e);
    }
  }

  /// Track Google Drive file download
  Future<void> trackDriveDownload(
    String fileId, {
    bool success = true,
  }) async {
    if (kDebugMode) return;

    try {
      await _analyticsInstance?.logEvent(
        name: 'drive_download',
        parameters: {
          'file_id': fileId,
          'success': success,
        },
      );
      AppLogger.d('Analytics: Drive download - $fileId ($success)');
    } catch (e) {
      AppLogger.e('Failed to track Drive download', e);
    }
  }

  /// Track Google Drive browse
  Future<void> trackDriveBrowse({int fileCount = 0}) async {
    if (kDebugMode) return;

    try {
      await _analyticsInstance?.logEvent(
        name: 'drive_browse',
        parameters: {'file_count': fileCount},
      );
      AppLogger.d('Analytics: Drive browse - $fileCount files');
    } catch (e) {
      AppLogger.e('Failed to track Drive browse', e);
    }
  }

  /// Track Google Drive sign-in attempt
  Future<void> trackDriveSignInAttempt({bool success = true}) async {
    if (kDebugMode) return;

    try {
      await _analyticsInstance?.logEvent(
        name: 'drive_sign_in_attempt',
        parameters: {'success': success},
      );
      AppLogger.d('Analytics: Drive sign-in attempt - $success');
    } catch (e) {
      AppLogger.e('Failed to track Drive sign-in attempt', e);
    }
  }

  /// Track Google Drive file open
  Future<void> trackDriveFileOpen({
    required String fileId,
    required String fileName,
  }) async {
    if (kDebugMode) return;

    try {
      await _analyticsInstance?.logEvent(
        name: 'drive_file_open',
        parameters: {
          'file_id': fileId,
          'file_name': fileName,
        },
      );
      AppLogger.d('Analytics: Drive file open - $fileName');
    } catch (e) {
      AppLogger.e('Failed to track Drive file open', e);
    }
  }
}
