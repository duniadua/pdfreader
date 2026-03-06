import '../../data/repositories/drive_repository.dart';

/// Use case for checking Google Drive authentication status
class CheckDriveAuthUseCase {
  const CheckDriveAuthUseCase(this._repository);

  final DriveRepository _repository;

  /// Check if user is authenticated with Google Drive
  Future<bool> call() async {
    return await _repository.isAuthenticated();
  }

  /// Get current authenticated user's email
  String? getCurrentUserEmail() {
    return _repository.getCurrentUserEmail();
  }
}
