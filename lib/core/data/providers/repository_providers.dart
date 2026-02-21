import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../repositories/pdf_repository.dart';
import '../repositories/settings_repository.dart';
import '../../services/thumbnail_service.dart';

part 'repository_providers.g.dart';

/// Provider for SharedPreferences
@riverpod
Future<SharedPreferences> sharedPreferences(Ref ref) async {
  return await SharedPreferences.getInstance();
}

/// Provider for ThumbnailService
@riverpod
ThumbnailService thumbnailService(Ref ref) {
  return ThumbnailService();
}

/// Provider for PdfRepository
@riverpod
PdfRepository pdfRepository(Ref ref) {
  throw UnimplementedError('SharedPreferences must be provided first');
}

/// Provider for PdfRepository with SharedPreferences
@riverpod
PdfRepository sharedPreferencesPdfRepository(Ref ref) {
  final prefsAsync = ref.watch(sharedPreferencesProvider);
  final thumbnailService = ref.watch(thumbnailServiceProvider);
  return prefsAsync.when(
    data: (prefs) => SharedPreferencesPdfRepository(
      prefs: prefs,
      thumbnailService: thumbnailService,
    ),
    loading: () => throw Exception('SharedPreferences not ready'),
    error: (error, stackTrace) => throw Exception('Failed to load SharedPreferences'),
  );
}

/// Provider for SettingsRepository
@riverpod
SettingsRepository settingsRepository(Ref ref) {
  final prefsAsync = ref.watch(sharedPreferencesProvider);
  return prefsAsync.when(
    data: (prefs) => SharedPreferencesSettingsRepository(prefs: prefs),
    loading: () => throw Exception('SharedPreferences not ready'),
    error: (error, stackTrace) => throw Exception('Failed to load SharedPreferences'),
  );
}
