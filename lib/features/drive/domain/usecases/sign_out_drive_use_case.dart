import '../../data/repositories/drive_repository.dart';

/// Use case for signing out from Google Drive
class SignOutDriveUseCase {
  const SignOutDriveUseCase(this._repository);

  final DriveRepository _repository;

  /// Sign out from Google Drive
  Future<void> call() async {
    await _repository.signOut();
  }
}
