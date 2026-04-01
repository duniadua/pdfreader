import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import 'core/cache/cache_manager.dart';
import 'core/data/providers/repository_providers.dart';
import 'core/router/app_router.dart';
import 'core/services/analytics_service.dart';
import 'core/services/pdf_intent_handler.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/logger.dart';
import 'features/settings/presentation/providers/settings_notifier.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  try {
    await Firebase.initializeApp();
    AppLogger.i('Firebase initialized');

    // Initialize Analytics
    final analytics = FirebaseAnalytics.instance;
    // Set analytics collection enabled
    await analytics.setAnalyticsCollectionEnabled(true);
    // Initialize our AnalyticsService wrapper
    AnalyticsService.instance.initialize(analytics);
    AppLogger.i('Firebase Analytics initialized');

    // Track app open
    await AnalyticsService.instance.trackAppOpen();

    // Initialize Crashlytics
    final crashlytics = FirebaseCrashlytics.instance;

    // Set Crashlytics enabled in release mode only
    if (kReleaseMode) {
      await crashlytics.setCrashlyticsCollectionEnabled(true);
    } else {
      // Disable in debug mode to avoid noise
      await crashlytics.setCrashlyticsCollectionEnabled(false);
      AppLogger.i('Crashlytics disabled in debug mode');
    }

    // Set user identifier to null initially - will be set when user signs in
    await crashlytics.setUserIdentifier('');

    AppLogger.i('Crashlytics initialized');
  } catch (e, st) {
    AppLogger.e('Failed to initialize Firebase', e, st);
    // Continue without Firebase - could be optional features
  }

  // Initialize SharedPreferences early - this ensures it's ready before the app starts
  final prefs = await SharedPreferences.getInstance();
  AppLogger.i('SharedPreferences initialized');

  // Initialize cache manager
  final cacheManager = CacheManager.instance;
  AppLogger.i('Cache manager initialized');

  // Run app with error handling and pre-initialized SharedPreferences
  runApp(
    ProviderScope(
      overrides: [
        // Override the SharedPreferences provider with the pre-initialized value
        sharedPreferencesProvider.overrideWith((ref) => prefs),
      ],
      observers: [_ProviderLogger()],
      child: const PdfReaderApp(),
    ),
  );

  // Flush cache on app exit
  AppLogger.i('App exiting, flushing cache...');
  await cacheManager.dispose();
}

class PdfReaderApp extends ConsumerStatefulWidget {
  const PdfReaderApp({super.key});

  @override
  ConsumerState<PdfReaderApp> createState() => _PdfReaderAppState();
}

class _PdfReaderAppState extends ConsumerState<PdfReaderApp> {
  @override
  void initState() {
    super.initState();
    // Check for pending PDF intent after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPendingPdfIntent(ref);
    });
  }

  Future<void> _checkPendingPdfIntent(WidgetRef ref) async {
    AppLogger.i('=== Checking for pending PDF intent ===');

    final intentHandler = ref.read(pdfIntentHandlerProvider);
    final filePath = await intentHandler.getPendingFilePath();

    AppLogger.i('Pending file path: $filePath');

    if (filePath != null) {
      AppLogger.i('🎯 Processing pending PDF intent: $filePath');

      if (mounted) {
        // Import PDF and navigate to reader
        AppLogger.i('📥 Starting PDF import and navigation...');
        await intentHandler.handlePdfIntent(filePath, (pdfId) {
          AppLogger.i('✅ PDF imported with ID: $pdfId, navigating to reader');
          if (mounted) {
            final readerUrl = '${AppRoutes.reader}?pdfId=$pdfId';
            AppLogger.i('🚀 Navigating to: $readerUrl');
            ref.read(routerProvider).go(readerUrl);
          } else {
            AppLogger.w('⚠️ Widget not mounted, cannot navigate');
          }
        });
      }
    } else {
      AppLogger.i('ℹ️ No pending PDF intent found');
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final settingsState = ref.watch(settingsNotifierProvider);
    final settings = settingsState.settings;

    return MaterialApp.router(
      title: 'PDF Reader',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: settings.darkMode ? ThemeMode.dark : ThemeMode.light,
      routerConfig: router,
    );
  }
}

/// Observer for logging provider changes
class _ProviderLogger extends ProviderObserver {
  @override
  void didAddProvider(
    ProviderBase<Object?> provider,
    Object? value,
    ProviderContainer container,
  ) {
    // Only log in debug mode
    if (kDebugMode) {
      debugPrint('Provider added: ${provider.name ?? provider.runtimeType}');
    }
  }

  @override
  void providerDidFail(
    ProviderBase<Object?> provider,
    Object error,
    StackTrace stackTrace,
    ProviderContainer container,
  ) {
    debugPrint('Provider error: ${provider.name ?? provider.runtimeType}');
    debugPrint('Error: $error');
    debugPrint('StackTrace: $stackTrace');
  }
}
