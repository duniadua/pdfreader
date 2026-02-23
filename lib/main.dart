import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/cache/cache_manager.dart';
import 'core/data/providers/repository_providers.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/logger.dart';
import 'features/settings/presentation/providers/settings_notifier.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
      observers: [
        _ProviderLogger(),
      ],
      child: const PdfReaderApp(),
    ),
  );

  // Flush cache on app exit
  AppLogger.i('App exiting, flushing cache...');
  await cacheManager.dispose();
}

class PdfReaderApp extends ConsumerWidget {
  const PdfReaderApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final settingsAsync = ref.watch(appSettingsProvider);

    return settingsAsync.when(
      data: (settings) {
        return MaterialApp.router(
          title: 'PDF Reader',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme(),
          darkTheme: AppTheme.darkTheme(),
          themeMode: settings.darkMode ? ThemeMode.dark : ThemeMode.light,
          routerConfig: router,
        );
      },
      loading: () => MaterialApp(
        title: 'PDF Reader',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme(),
        home: const _SplashScreen(),
      ),
      error: (error, stackTrace) => MaterialApp(
        title: 'PDF Reader',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme(),
        home: _ErrorScreen(error: error, stackTrace: stackTrace),
      ),
    );
  }
}

/// Splash screen shown while loading
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.picture_as_pdf,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Loading...',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}

/// Error screen shown on initialization failure
class _ErrorScreen extends StatelessWidget {
  const _ErrorScreen({
    required this.error,
    required this.stackTrace,
  });

  final Object error;
  final StackTrace stackTrace;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 24),
              Text(
                'Initialization Error',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  // Could implement retry logic here
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
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
