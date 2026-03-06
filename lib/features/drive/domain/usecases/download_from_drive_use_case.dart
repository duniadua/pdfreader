import 'dart:typed_data';

import '../../data/repositories/drive_repository.dart';

/// Use case for downloading a PDF file from Google Drive
class DownloadFromDriveUseCase {
  const DownloadFromDriveUseCase(this._repository);

  final DriveRepository _repository;

  /// Download a PDF file to local storage
  /// Returns the local path where the file was saved
  Future<DriveResult<String>> call(String fileId, String fileName) async {
    if (!await _repository.isAuthenticated()) {
      return const DriveResult.failure(
        DriveFailure.notAuthenticated(),
      );
    }

    return await _repository.downloadPdf(fileId, fileName);
  }

  /// Download a PDF file as bytes (for sharing or direct viewing)
  Future<DriveResult<Uint8List>> asBytes(String fileId) async {
    if (!await _repository.isAuthenticated()) {
      return const DriveResult.failure(
        DriveFailure.notAuthenticated(),
      );
    }

    return await _repository.downloadPdfBytes(fileId);
  }
}
