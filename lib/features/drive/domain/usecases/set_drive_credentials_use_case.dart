import '../../data/repositories/drive_repository.dart';

/// Use case for setting credentials from external OAuth flow
class SetDriveCredentialsUseCase {
  const SetDriveCredentialsUseCase(this._repository);

  final DriveRepository _repository;

  /// Set credentials from external OAuth flow (e.g., from google_sign_in)
  Future<DriveResult<bool>> call({
    required String accessToken,
    required String refreshToken,
    required DateTime expiry,
  }) async {
    return await _repository.setCredentials(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiry: expiry,
    );
  }
}
