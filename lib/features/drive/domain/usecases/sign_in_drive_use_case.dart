import '../../data/repositories/drive_repository.dart';

/// Use case for signing in to Google Drive
class SignInDriveUseCase {
  const SignInDriveUseCase(this._repository);

  final DriveRepository _repository;

  /// Sign in to Google Drive
  /// Returns true if successful
  Future<DriveResult<bool>> call() async {
    return await _repository.signIn();
  }
}
