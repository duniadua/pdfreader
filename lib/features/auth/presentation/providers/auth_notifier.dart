import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../features/auth/data/auth_repository_provider.dart';
import '../../domain/entities/auth_state.dart';

part 'auth_notifier.g.dart';

/// Notifier for managing authentication state.
@riverpod
class AuthNotifier extends _$AuthNotifier {
  @override
  AuthState build() {
    // Initialize by checking current user
    _initAuth();

    return AuthState.initial();
  }

  /// Initializes authentication state by checking current user
  /// and listening to auth state changes.
  void _initAuth() {
    final repository = ref.read(firebaseAuthRepositoryProvider);

    // Check current user
    final userProfile = repository.getCurrentUserProfile();
    if (userProfile != null) {
      state = AuthState.authenticated(userProfile);
    } else {
      state = AuthState.unauthenticated();
    }

    // Listen to auth state changes
    repository.authStateChanges.listen((user) {
      if (user == null) {
        state = AuthState.unauthenticated();
      } else {
        final profile = repository.getCurrentUserProfile();
        if (profile != null) {
          state = AuthState.authenticated(profile);
        }
      }
    });
  }

  /// Signs in the user using Google Sign-In.
  Future<void> signInWithGoogle() async {
    state = AuthState.loading();

    final repository = ref.read(firebaseAuthRepositoryProvider);

    try {
      // Check if Google Sign-In is available
      if (!repository.isGoogleSignInAvailable) {
        state = const AuthState.error(
          'Google Sign-In is not available on this platform',
        );
        return;
      }

      final userProfile = await repository.signInWithGoogle();
      state = AuthState.authenticated(userProfile);
    } on Exception catch (e) {
      state = AuthState.error(e.toString().replaceAll('Exception: ', ''));
    }
  }

  /// Signs out the current user.
  Future<void> signOut() async {
    state = AuthState.loading();

    final repository = ref.read(firebaseAuthRepositoryProvider);

    try {
      await repository.signOut();
      state = AuthState.unauthenticated();
    } on Exception catch (e) {
      state = AuthState.error(e.toString().replaceAll('Exception: ', ''));
    }
  }

  /// Dismisses the current error state.
  void dismissError() {
    // Revert to unauthenticated state on error dismiss
    state = AuthState.unauthenticated();
  }
}
