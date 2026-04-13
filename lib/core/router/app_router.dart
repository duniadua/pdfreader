import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../features/library/presentation/library_screen.dart';
import '../../features/reader/presentation/pdf_reader_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../shared/screens/intent_loading_screen.dart';
import '../providers/intent_loading_provider.dart';

part 'app_router.g.dart';

/// Route names for navigation
class AppRoutes {
  static const String library = '/library';
  static const String reader = '/reader';
  static const String settings = '/settings';
  static const String favorites = '/favorites';
  static const String timeline = '/timeline';
  static const String cloud = '/cloud';
  static const String intentLoading = '/intent-loading';
}

/// Error page for unmatched routes
class _ErrorPage extends StatelessWidget {
  const _ErrorPage({required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Page Not Found')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Page not found',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                error,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go(AppRoutes.library),
                child: const Text('Go to Library'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// GoRouter configuration provider
@riverpod
GoRouter router(Ref ref) {
  return GoRouter(
    initialLocation: AppRoutes.library,
    debugLogDiagnostics: false,
    redirect: (context, state) {
      // If processing an intent, show loading screen
      final isProcessingIntent = ref.read(intentLoadingProvider);
      final currentPath = state.uri.path;

      // Redirect to loading if processing intent (but not already at loading)
      if (isProcessingIntent && currentPath != AppRoutes.intentLoading) {
        return AppRoutes.intentLoading;
      }

      // If at loading route but not processing intent, go to library
      if (!isProcessingIntent && currentPath == AppRoutes.intentLoading) {
        return AppRoutes.library;
      }

      // Handle PDF file URIs from intent (file:// or content://)
      final uri = state.uri;
      final path = uri.path;

      // Check if this looks like a file path (not a route)
      if (path.contains('.pdf') || path.startsWith('/storage/') || path.startsWith('/content/')) {
        return AppRoutes.library;
      }

      return null;
    },
    routes: [
      // Intent Loading Screen - shows while processing PDF from external apps
      GoRoute(
        path: AppRoutes.intentLoading,
        pageBuilder: (context, state) =>
            const MaterialPage(child: IntentLoadingScreen()),
      ),

      // Main Library Screen with Bottom Navigation
      GoRoute(
        path: AppRoutes.library,
        pageBuilder: (context, state) =>
            const MaterialPage(child: LibraryScreen()),
      ),

      // PDF Reader Screen
      GoRoute(
        path: AppRoutes.reader,
        pageBuilder: (context, state) {
          final pdfId = state.uri.queryParameters['pdfId'];
          if (pdfId == null || pdfId.isEmpty) {
            return const MaterialPage(
              child: _ErrorPage(error: 'PDF ID is required'),
            );
          }
          return MaterialPage(child: PdfReaderScreen(pdfId: pdfId));
        },
      ),

      // Settings Screen
      GoRoute(
        path: AppRoutes.settings,
        pageBuilder: (context, state) =>
            const MaterialPage(child: SettingsScreen()),
      ),

      // Favorites (implemented in library tab)
      GoRoute(
        path: AppRoutes.favorites,
        pageBuilder: (context, state) => const MaterialPage(
          child: LibraryScreen(initialTab: LibraryTab.favorites),
        ),
      ),

      // Timeline (implemented in library tab)
      GoRoute(
        path: AppRoutes.timeline,
        pageBuilder: (context, state) => const MaterialPage(
          child: LibraryScreen(initialTab: LibraryTab.timeline),
        ),
      ),

      // Cloud (implemented in library tab - local only)
      GoRoute(
        path: AppRoutes.cloud,
        pageBuilder: (context, state) => const MaterialPage(
          child: LibraryScreen(initialTab: LibraryTab.cloud),
        ),
      ),
    ],
    errorBuilder: (context, state) => _ErrorPage(error: state.uri.toString()),
  );
}
