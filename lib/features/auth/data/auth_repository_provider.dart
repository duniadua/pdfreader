import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'firebase_auth_repository.dart';

part 'auth_repository_provider.g.dart';

/// Provider for FirebaseAuth instance
@riverpod
FirebaseAuth firebaseAuth(Ref ref) {
  return FirebaseAuth.instance;
}

/// Provider for GoogleSignIn instance
/// Includes Google Drive scope for PDF file access
@riverpod
GoogleSignIn googleSignIn(Ref ref) {
  return GoogleSignIn.standard(
    scopes: <String>['email', 'https://www.googleapis.com/auth/drive.readonly'],
  );
}

/// Provider for FirebaseAuthRepository
@riverpod
FirebaseAuthRepository firebaseAuthRepository(Ref ref) {
  return FirebaseAuthRepository(
    firebaseAuth: ref.watch(firebaseAuthProvider),
    googleSignIn: ref.watch(googleSignInProvider),
  );
}
