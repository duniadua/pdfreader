import 'dart:typed_data';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/services/google_drive_service.dart' as svc;
import '../../../../core/utils/logger.dart';
import '../../domain/entities/drive_file.dart';
import '../../domain/repositories/drive_repository.dart';
import '../drive_file_cache.dart';

part 'drive_repository_impl.g.dart';

/// Implementation of DriveRepository using GoogleDriveService
@riverpod
DriveRepository driveRepository(DriveRepositoryRef ref) {
  return DriveRepositoryImpl();
}

/// Implementation of DriveRepository using GoogleDriveService
/// Uses existing Google Sign-In - no separate authentication required.
class DriveRepositoryImpl implements DriveRepository {
  final svc.GoogleDriveService _service = svc.GoogleDriveService.instance;

  DriveFileCache? _cache;

  Future<DriveFileCache> get _cacheInstance async {
    _cache ??= await DriveFileCache.create();
    return _cache!;
  }

  @override
  Future<bool> isAuthenticated() async {
    return _service.isSignedIn;
  }

  @override
  String? getCurrentUserEmail() {
    return _service.currentUserEmail;
  }

  @override
  Future<DriveResult<bool>> signIn() async {
    // This method is no longer needed - users sign in through Google Sign-In
    // Return failure to indicate user should use main sign-in flow
    return const DriveResult.failure(DriveFailure.notAuthenticated());
  }

  @override
  Future<void> signOut() async {
    await _service.signOut();
  }

  @override
  Future<DriveResult<bool>> setCredentials({
    required String accessToken,
    required String refreshToken,
    required DateTime expiry,
  }) async {
    try {
      // Initialize the service with the access token from Google Sign-In
      await _service.initialize(accessToken: accessToken);

      return const DriveResult.success(true);
    } catch (e, st) {
      AppLogger.e('Set credentials failed', e, st);
      return DriveResult.failure(DriveFailure.unknown(e.toString()));
    }
  }

  /// Refresh the access token with a new one from Google Sign-In
  Future<DriveResult<bool>> refreshAccessToken(String newAccessToken) async {
    try {
      final success = await _service.refreshToken(newAccessToken);

      if (success) {
        return const DriveResult.success(true);
      } else {
        return const DriveResult.failure(
          DriveFailure.unknown('Failed to refresh token'),
        );
      }
    } catch (e, st) {
      AppLogger.e('Refresh token failed', e, st);
      return DriveResult.failure(DriveFailure.unknown(e.toString()));
    }
  }

  @override
  Future<DriveResult<List<DriveFile>>> getPdfFiles([
    DriveCacheStrategy strategy = DriveCacheStrategy.cacheFirst,
  ]) async {
    if (!_service.isSignedIn) {
      return const DriveResult.failure(DriveFailure.notAuthenticated());
    }

    final cache = await _cacheInstance;

    // Check cache first based on strategy
    if (strategy.useCache) {
      final cached = await cache.get();
      if (cached != null) {
        // Return cached data immediately
        if (strategy.backgroundRefresh) {
          // Refresh in background
          _fetchAndCacheFiles();
        }
        return DriveResult.success(cached, isFromCache: true);
      }
    }

    // Fetch from API
    return await _fetchAndCacheFiles();
  }

  @override
  Future<DriveResult<List<DriveFile>>> refreshPdfFiles() async {
    if (!_service.isSignedIn) {
      return const DriveResult.failure(DriveFailure.notAuthenticated());
    }

    return await _fetchAndCacheFiles();
  }

  @override
  Future<void> clearCache() async {
    final cache = await _cacheInstance;
    await cache.clear();
  }

  Future<DriveResult<List<DriveFile>>> _fetchAndCacheFiles() async {
    try {
      final driveFiles = await _service.listPdfs();

      final models = driveFiles
          .map(
            (file) => DriveFile(
              id: file.id,
              name: file.name,
              size: file.size,
              createdTime: file.createdTime,
              thumbnailLink: file.thumbnailLink,
              webViewLink: file.webViewLink,
            ),
          )
          .toList();

      // Cache the results
      final cache = await _cacheInstance;
      await cache.set(models);

      return DriveResult.success(models, isFromCache: false);
    } catch (e, st) {
      AppLogger.e('Failed to get PDF files', e, st);

      // Try to fallback to cache on network error
      final cache = await _cacheInstance;
      final cached = await cache.get();
      if (cached != null) {
        AppLogger.i('Returning cached data due to network error');
        return DriveResult.success(cached, isFromCache: true);
      }

      return DriveResult.failure(DriveFailure.networkError(e.toString()));
    }
  }

  @override
  Future<DriveResult<String>> downloadPdf(
    String fileId,
    String fileName,
  ) async {
    if (!_service.isSignedIn) {
      return const DriveResult.failure(DriveFailure.notAuthenticated());
    }

    try {
      final path = await _service.downloadPdf(fileId, fileName);

      if (path != null) {
        return DriveResult.success(path);
      } else {
        return const DriveResult.failure(
          DriveFailure.downloadFailed('Download returned null path'),
        );
      }
    } catch (e, st) {
      AppLogger.e('Failed to download PDF', e, st);
      return DriveResult.failure(DriveFailure.downloadFailed(e.toString()));
    }
  }

  @override
  Future<DriveResult<Uint8List>> downloadPdfBytes(String fileId) async {
    if (!_service.isSignedIn) {
      return const DriveResult.failure(DriveFailure.notAuthenticated());
    }

    try {
      final bytes = await _service.downloadPdfBytes(fileId);

      if (bytes != null) {
        return DriveResult.success(bytes);
      } else {
        return const DriveResult.failure(
          DriveFailure.downloadFailed('Download returned null bytes'),
        );
      }
    } catch (e, st) {
      AppLogger.e('Failed to download PDF bytes', e, st);
      return DriveResult.failure(DriveFailure.downloadFailed(e.toString()));
    }
  }

  @override
  Future<void> initialize() async {
    await _service.initialize();
  }

  /// Check if the access token is expired
  bool get isTokenExpired => _service.isTokenExpired;
}
