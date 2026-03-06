import '../../data/models/drive_file.dart';
import '../../data/repositories/drive_repository.dart';

/// Use case for getting PDF files from Google Drive
class GetDriveFilesUseCase {
  const GetDriveFilesUseCase(this._repository);

  final DriveRepository _repository;

  /// Execute the use case
  /// Returns a result containing list of Drive files or a failure
  Future<DriveResult<List<DriveFileModel>>> call() async {
    if (!await _repository.isAuthenticated()) {
      return const DriveResult.failure(
        DriveFailure.notAuthenticated(),
      );
    }

    return await _repository.getPdfFiles();
  }
}
