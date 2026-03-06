import 'package:freezed_annotation/freezed_annotation.dart';
import 'user_profile.dart';

part 'auth_state.freezed.dart';

/// Authentication state representing the current auth status.
@freezed
class AuthState with _$AuthState {
  /// Initial state before auth check completes
  const factory AuthState.initial() = _Initial;

  /// User is successfully authenticated
  const factory AuthState.authenticated(UserProfile user) = _Authenticated;

  /// User is not authenticated (guest mode)
  const factory AuthState.unauthenticated() = _Unauthenticated;

  /// Authentication operation is in progress
  const factory AuthState.loading() = _Loading;

  /// Authentication error occurred
  const factory AuthState.error(String message) = _Error;
}
