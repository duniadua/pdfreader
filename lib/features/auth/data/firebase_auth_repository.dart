import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../features/auth/domain/entities/user_profile.dart';

/// Repository for Firebase Authentication operations.
/// Implements sign-in with Google, sign-out, and auth state monitoring.
class FirebaseAuthRepository {
  const FirebaseAuthRepository({
    required FirebaseAuth firebaseAuth,
    required GoogleSignIn googleSignIn,
  })  : _firebaseAuth = firebaseAuth,
        _googleSignIn = googleSignIn;

  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  /// Stream of authentication state changes
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  /// Gets the currently authenticated user, or null if not signed in
  User? get currentUser => _firebaseAuth.currentUser;

  /// Signs in the user using Google Sign-In.
  ///
  /// Returns [UserProfile] on success.
  /// Throws [Exception] with error message on failure.
  Future<UserProfile> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw Exception('Google sign-in was cancelled');
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final UserCredential userCredential =
          await _firebaseAuth.signInWithCredential(credential);

      final User? user = userCredential.user;
      if (user == null) {
        throw Exception('Failed to get user after sign-in');
      }

      return UserProfile(
        id: user.uid,
        email: user.email ?? '',
        displayName: user.displayName,
        photoUrl: user.photoURL,
        isEmailVerified: user.emailVerified,
      );
    } on FirebaseAuthException catch (e) {
      throw Exception('Firebase auth error: ${e.message}');
    } on Exception catch (e) {
      throw Exception('Sign-in error: ${e.toString()}');
    }
  }

  /// Signs out the current user.
  ///
  /// Signs out from both Firebase Auth and Google Sign-In.
  /// Throws [Exception] if sign-out fails.
  Future<void> signOut() async {
    try {
      // Sign out from Firebase
      await _firebaseAuth.signOut();

      // Sign out from Google (if signed in)
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }
    } on Exception catch (e) {
      throw Exception('Sign-out error: ${e.toString()}');
    }
  }

  /// Gets the current user profile.
  ///
  /// Returns [UserProfile] if user is signed in, null otherwise.
  UserProfile? getCurrentUserProfile() {
    final User? user = _firebaseAuth.currentUser;
    if (user == null) return null;

    return UserProfile(
      id: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      photoUrl: user.photoURL,
      isEmailVerified: user.emailVerified,
    );
  }

  /// Checks if the current platform supports Google Sign-In.
  bool get isGoogleSignInAvailable {
    if (Platform.isAndroid || Platform.isIOS) {
      return true;
    }
    return false;
  }

  /// Gets the current Google Sign-In credentials for Drive integration.
  ///
  /// Returns a map containing access token, refresh token, and expiry.
  /// Returns null if user is not signed in with Google.
  Future<Map<String, dynamic>?> getGoogleCredentials() async {
    try {
      if (!await _googleSignIn.isSignedIn()) {
        return null;
      }

      final GoogleSignInAccount? googleUser = _googleSignIn.currentUser;
      if (googleUser == null) {
        return null;
      }

      // Get fresh authentication
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Google Sign-In doesn't provide refresh token in the standard flow
      // We'll use the access token with a reasonable expiry time
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (accessToken == null) {
        return null;
      }

      // Access tokens typically expire in 1 hour
      final expiry = DateTime.now().add(const Duration(hours: 1));

      return {
        'accessToken': accessToken,
        'refreshToken': idToken ?? '', // Use idToken as backup
        'expiry': expiry,
      };
    } on Exception catch (e) {
      throw Exception('Failed to get Google credentials: ${e.toString()}');
    }
  }
}
