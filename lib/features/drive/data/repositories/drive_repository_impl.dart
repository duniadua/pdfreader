import 'dart:typed_data';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/services/google_drive_service.dart';
import '../../../../core/utils/logger.dart';
import '../models/drive_file.dart';
import 'drive_repository.dart';

part 'drive_repository_impl.g.dart';

/// Implementation of DriveRepository using GoogleDriveService
@riverpod
DriveRepository driveRepository(DriveRepositoryRef ref) {
  return DriveRepositoryImpl();
}

/// Implementation of DriveRepository using GoogleDriveService
/// Uses existing Google Sign-In - no separate authentication required.
class DriveRepositoryImpl implements DriveRepository {
  final GoogleDriveService _service = GoogleDriveService.instance;

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
    return const DriveResult.failure(
      DriveFailure.notAuthenticated(),
    );
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
      print('[DriveRepository] Setting credentials...');
      // Initialize the service with the access token from Google Sign-In
      await _service.initialize(accessToken: accessToken);

      print('[DriveRepository] Credentials set successfully');
      return const DriveResult.success(true);
    } catch (e, st) {
      print('[DriveRepository] Set credentials failed: $e');
      AppLogger.e('Set credentials failed', e, st);
      return DriveResult.failure(
        DriveFailure.unknown(e.toString()),
      );
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
      return DriveResult.failure(
        DriveFailure.unknown(e.toString()),
      );
    }
  }

  @override
  Future<DriveResult<List<DriveFileModel>>> getPdfFiles() async {
    print('[DriveRepository] Getting PDF files... isSignedIn: ${_service.isSignedIn}');
    if (!_service.isSignedIn) {
      print('[DriveRepository] Not signed in to Drive');
      return const DriveResult.failure(
        DriveFailure.notAuthenticated(),
      );
    }

    try {
      final driveFiles = await _service.listPdfs();
      print('[DriveRepository] Got ${driveFiles.length} files from Drive service');

      final models = driveFiles.map((file) => DriveFileModel(
        id: file.id,
        name: file.name,
        size: file.size,
        createdTime: file.createdTime,
        thumbnailLink: file.thumbnailLink,
        webViewLink: file.webViewLink,
      )).toList();

      print('[DriveRepository] Converted to ${models.length} DriveFileModel instances');
      return DriveResult.success(models);
    } catch (e, st) {
      print('[DriveRepository] Failed to get PDF files: $e');
      AppLogger.e('Failed to get PDF files', e, st);
      return DriveResult.failure(
        DriveFailure.networkError(e.toString()),
      );
    }
  }

  @override
  Future<DriveResult<String>> downloadPdf(String fileId, String fileName) async {
    if (!_service.isSignedIn) {
      return const DriveResult.failure(
        DriveFailure.notAuthenticated(),
      );
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
      return DriveResult.failure(
        DriveFailure.downloadFailed(e.toString()),
      );
    }
  }

  @override
  Future<DriveResult<Uint8List>> downloadPdfBytes(String fileId) async {
    if (!_service.isSignedIn) {
      return const DriveResult.failure(
        DriveFailure.notAuthenticated(),
      );
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
      return DriveResult.failure(
        DriveFailure.downloadFailed(e.toString()),
      );
    }
  }

  @override
  Future<void> initialize() async {
    await _service.initialize();
  }

  /// Check if the access token is expired
  bool get isTokenExpired => _service.isTokenExpired;
}
