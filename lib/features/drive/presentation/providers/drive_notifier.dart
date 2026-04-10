import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/services/analytics_service.dart';
import '../../../../core/utils/logger.dart';
import '../../data/repositories/drive_repository_impl.dart';
import '../../domain/repositories/drive_repository.dart';
import 'drive_state.dart';

part 'drive_notifier.g.dart';

/// Notifier for Google Drive state management
@riverpod
class DriveNotifier extends _$DriveNotifier {
  @override
  DriveState build() {
    final repository = ref.watch(driveRepositoryProvider);

    // Initialize and check auth status
    _initialize(repository);

    return DriveState.initial();
  }

  /// Initialize the Drive service and check authentication
  Future<void> _initialize(DriveRepository repository) async {
    try {
      await repository.initialize();

      final isConnected = await repository.isAuthenticated();
      final userEmail = repository.getCurrentUserEmail();

      state = state.copyWith(isConnected: isConnected, userName: userEmail);

      AppLogger.i('Drive initialized: connected=$isConnected, user=$userEmail');
    } catch (e) {
      AppLogger.e('Failed to initialize Drive', e);
    }
  }

  /// Connect to Google Drive (requires OAuth flow from google_sign_in)
  Future<bool> connect({
    required String accessToken,
    required String refreshToken,
    required DateTime expiry,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final repository = ref.read(driveRepositoryProvider);
    final result = await repository.setCredentials(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiry: expiry,
    );

    state = state.copyWith(isLoading: false);

    return result.when(
      success: (_, isFromCache) async {
        final userEmail = repository.getCurrentUserEmail();
        state = state.copyWith(isConnected: true, userName: userEmail);

        // Track connection event
        await AnalyticsService.instance.trackDriveConnect();

        // Load files after successful connection
        await loadDriveFiles();

        return true;
      },
      failure: (failure) {
        final message = _getFailureMessage(failure);
        state = state.copyWith(errorMessage: message);
        return false;
      },
    );
  }

  /// Disconnect from Google Drive
  Future<void> disconnect() async {
    final repository = ref.read(driveRepositoryProvider);
    await repository.signOut();
    state = state.copyWith(isConnected: false, userName: null, files: []);

    // Track disconnect event
    await AnalyticsService.instance.trackDriveDisconnect();
  }

  /// Load PDF files from Google Drive
  /// Use [strategy] to control cache behavior
  Future<void> loadDriveFiles([
    DriveCacheStrategy strategy = DriveCacheStrategy.cacheThenRefresh,
  ]) async {
    if (!state.isConnected) {
      state = state.copyWith(errorMessage: 'Not connected to Google Drive');
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    final repository = ref.read(driveRepositoryProvider);
    final result = await repository.getPdfFiles(strategy);

    result.when(
      success: (files, isFromCache) {
        state = state.copyWith(
          files: files,
          isLoading: false,
          isFromCache: isFromCache,
          lastSyncTime: isFromCache ? state.lastSyncTime : DateTime.now(),
        );

        // Track browse event
        AnalyticsService.instance.trackDriveBrowse(fileCount: files.length);
      },
      failure: (failure) {
        final message = _getFailureMessage(failure);
        state = state.copyWith(isLoading: false, errorMessage: message);
      },
    );
  }

  /// Refresh PDF files from Google Drive (force fetch from API)
  /// This method is used by pull-to-refresh
  Future<void> refreshDriveFiles() async {
    if (!state.isConnected) {
      state = state.copyWith(errorMessage: 'Not connected to Google Drive');
      return;
    }

    // Set refreshing state but keep current data visible
    state = state.copyWith(isRefreshing: true, errorMessage: null);

    final repository = ref.read(driveRepositoryProvider);
    final result = await repository.refreshPdfFiles();

    result.when(
      success: (files, isFromCache) {
        state = state.copyWith(
          files: files,
          isRefreshing: false,
          isFromCache: isFromCache,
          lastSyncTime: DateTime.now(),
        );

        // Track browse event
        AnalyticsService.instance.trackDriveBrowse(fileCount: files.length);
      },
      failure: (failure) {
        final message = _getFailureMessage(failure);
        state = state.copyWith(isRefreshing: false, errorMessage: message);
      },
    );
  }

  /// Download a PDF file from Google Drive
  Future<String?> downloadPdf(String fileId, String fileName) async {
    if (!state.isConnected) {
      state = state.copyWith(errorMessage: 'Not connected to Google Drive');
      return null;
    }

    state = state.copyWith(
      isDownloading: true,
      downloadingFileName: fileName,
      errorMessage: null,
    );

    final repository = ref.read(driveRepositoryProvider);
    final result = await repository.downloadPdf(fileId, fileName);

    state = state.copyWith(isDownloading: false, downloadingFileName: null);

    return result.when(
      success: (localPath, isFromCache) {
        // Track download event
        AnalyticsService.instance.trackDriveDownload(fileId, success: true);

        return localPath;
      },
      failure: (failure) {
        final message = _getFailureMessage(failure);
        state = state.copyWith(errorMessage: message);

        // Track failed download
        AnalyticsService.instance.trackDriveDownload(fileId, success: false);

        return null;
      },
    );
  }

  /// Dismiss the current error message
  void dismissError() {
    state = state.copyWith(errorMessage: null);
  }

  /// Get user-friendly error message from failure
  String _getFailureMessage(DriveFailure failure) {
    return failure.when(
      notAuthenticated: () => 'Please sign in to Google Drive',
      networkError: (msg) => 'Network error: $msg',
      downloadFailed: (msg) => 'Download failed: $msg',
      unknown: (msg) => 'An error occurred: $msg',
    );
  }

  /// Refresh connection status
  Future<void> refreshStatus() async {
    final repository = ref.read(driveRepositoryProvider);
    final isConnected = await repository.isAuthenticated();
    final userEmail = repository.getCurrentUserEmail();

    state = state.copyWith(isConnected: isConnected, userName: userEmail);
  }
}

/// Provider for Google Drive authentication status
@riverpod
bool isDriveAuthenticated(IsDriveAuthenticatedRef ref) {
  final driveState = ref.watch(driveNotifierProvider);
  return driveState.isConnected;
}

/// Provider for checking if a file is currently being downloaded
@riverpod
bool isDriveDownloading(IsDriveDownloadingRef ref) {
  final driveState = ref.watch(driveNotifierProvider);
  return driveState.isDownloading;
}

/// Provider for getting the current downloading file name
@riverpod
String? driveDownloadingFileName(DriveDownloadingFileNameRef ref) {
  final driveState = ref.watch(driveNotifierProvider);
  return driveState.downloadingFileName;
}
