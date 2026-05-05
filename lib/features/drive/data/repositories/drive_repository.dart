import 'dart:typed_data';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../models/drive_file.dart';

part 'drive_repository.freezed.dart';

/// Cache strategy for Drive file operations
enum DriveCacheStrategy {
  /// Check cache first, then fetch from network if not found
  cacheFirst,

  /// Force refresh from network, ignoring cache
  forceRefresh,

  /// Fetch from network only, don't use cache
  networkOnly,
}

/// Result type for repository operations
@freezed
class DriveResult<T> with _$DriveResult {
  const factory DriveResult.success(
    T data, {

    /// Indicates if the data is from cache
    @Default(false) bool isFromCache,
  }) = DriveSuccess<T>;
  const factory DriveResult.failure(DriveFailure failure) =
      DriveFailureResult<T>;
}

/// Drive-specific failures
@freezed
class DriveFailure with _$DriveFailure {
  const factory DriveFailure.notAuthenticated() = DriveNotAuthenticated;
  const factory DriveFailure.networkError(String message) = DriveNetworkError;
  const factory DriveFailure.downloadFailed(String message) =
      DriveDownloadFailed;
  const factory DriveFailure.unknown(String message) = DriveUnknown;
}

/// Abstract repository for Google Drive operations
abstract class DriveRepository {
  /// Check if user is authenticated with Google Drive
  Future<bool> isAuthenticated();

  /// Get current authenticated user's email
  String? getCurrentUserEmail();

  /// Sign in to Google Drive
  /// Returns true if successful
  Future<DriveResult<bool>> signIn();

  /// Sign out from Google Drive
  Future<void> signOut();

  /// Set credentials from external OAuth flow
  Future<DriveResult<bool>> setCredentials({
    required String accessToken,
    required String refreshToken,
    required DateTime expiry,
  });

  /// List all PDF files from Google Drive
  /// Use [strategy] to control cache behavior
  // TODO: Define DriveCacheStrategy enum/class (currently undefined)
  // - Error: Undefined class 'DriveCacheStrategy' at line 57
  // - Fix: Create DriveCacheStrategy enum with values: cacheFirst, forceRefresh, networkOnly
  Future<DriveResult<List<DriveFileModel>>> getPdfFiles([
    DriveCacheStrategy strategy = DriveCacheStrategy.cacheFirst,
  ]);

  /// Refresh PDF files from Google Drive (force fetch from API)
  Future<DriveResult<List<DriveFileModel>>> refreshPdfFiles();

  /// Clear the Drive file cache
  Future<void> clearCache();

  /// Download a PDF file from Google Drive
  /// Returns the local path where the file was saved
  Future<DriveResult<String>> downloadPdf(String fileId, String fileName);

  /// Download a PDF file as bytes
  Future<DriveResult<Uint8List>> downloadPdfBytes(String fileId);

  /// Initialize the repository and restore session
  Future<void> initialize();
}
