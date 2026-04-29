import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import 'core/cache/cache_manager.dart';
import 'core/data/providers/repository_providers.dart';
import 'core/providers/intent_loading_provider.dart';
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
  StreamSubscription<String>? _intentSubscription;

  @override
  void initState() {
    super.initState();
    // Check for pending PDF intent after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPendingPdfIntent(ref);
      // Subscribe to subsequent intents (app already running).
      final intentHandler = ref.read(pdfIntentHandlerProvider);
      _intentSubscription = intentHandler.intentStream.listen((filePath) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        AppLogger.i('[$timestamp] Received subsequent PDF intent via stream: $filePath');
        _handleIncomingIntent(filePath, flowType: 'subsequent');
      });
    });
  }

  @override
  void dispose() {
    _intentSubscription?.cancel();
    super.dispose();
  }

  Future<void> _checkPendingPdfIntent(WidgetRef ref) async {
    final startTime = DateTime.now().millisecondsSinceEpoch;
    AppLogger.i('[$startTime] _checkPendingPdfIntent START');

    final intentHandler = ref.read(pdfIntentHandlerProvider);
    final filePath = await intentHandler.getPendingFilePath();

    final elapsed = DateTime.now().millisecondsSinceEpoch - startTime;
    if (filePath != null) {
      AppLogger.i('[$elapsed] _checkPendingPdfIntent: found pending path, setting loading=true');
      // Set loading state to show progress indicator
      ref.read(intentLoadingProvider.notifier).setProcessing(true);
      await _handleIncomingIntent(filePath, flowType: 'initial');
    } else {
      AppLogger.i('[$elapsed] _checkPendingPdfIntent: no pending path (normal launch)');
    }
  }

  Future<void> _handleIncomingIntent(String filePath, {String flowType = 'subsequent'}) async {
    final startTime = DateTime.now().millisecondsSinceEpoch;
    AppLogger.i('[$startTime] _handleIncomingIntent START (flow: $flowType): $filePath');

    if (!mounted) return;

    final intentHandler = ref.read(pdfIntentHandlerProvider);

    // Handle intent and get result
    final handleStart = DateTime.now().millisecondsSinceEpoch;
    final result = await intentHandler.handlePdfIntent(filePath);
    final handleElapsed = DateTime.now().millisecondsSinceEpoch - handleStart;
    AppLogger.i('[$handleElapsed] handlePdfIntent completed');

    // Clear loading state
    if (mounted) {
      AppLogger.i('[$DateTime.now().millisecondsSinceEpoch] intentLoadingProvider set to false');
      ref.read(intentLoadingProvider.notifier).setProcessing(false);
    }

    // Handle result
    if (!mounted) return;

    final outcomeTime = DateTime.now().millisecondsSinceEpoch;
    switch (result) {
      case PdfIntentSuccessData(:final pdfId):
        final readerUrl = '${AppRoutes.reader}?pdfId=$pdfId';
        AppLogger.i('[$outcomeTime] Navigating to reader: $readerUrl');
        ref.read(routerProvider).go(readerUrl);
      case PdfIntentFailureData(:final error):
        AppLogger.i('[$outcomeTime] Showing error to user: $error');
        // Show error message to user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Dismiss',
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
        AppLogger.e('PDF intent failed: $error');
    }

    final totalElapsed = DateTime.now().millisecondsSinceEpoch - startTime;
    AppLogger.i('[$totalElapsed] _handleIncomingIntent END (total: ${totalElapsed}ms, flow: $flowType)');
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
