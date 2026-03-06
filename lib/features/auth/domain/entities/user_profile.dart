/// User profile entity representing an authenticated user.
class UserProfile {
  const UserProfile({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.isEmailVerified = false,
  });

  /// Unique user ID from Firebase Auth
  final String id;

  /// User's email address
  final String email;

  /// User's display name (may be null)
  final String? displayName;

  /// URL to user's profile photo (may be null)
  final String? photoUrl;

  /// Whether the user's email has been verified
  final bool isEmailVerified;

  /// Display name to show in UI, falls back to email prefix
  String get displayTitle {
    if (displayName != null && displayName!.isNotEmpty) {
      return displayName!;
    }
    // Use email prefix before @ as fallback
    return email.split('@')[0];
  }

  /// Creates a copy with modified fields
  UserProfile copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    bool? isEmailVerified,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UserProfile &&
        other.id == id &&
        other.email == email &&
        other.displayName == displayName &&
        other.photoUrl == photoUrl &&
        other.isEmailVerified == isEmailVerified;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        email.hashCode ^
        displayName.hashCode ^
        photoUrl.hashCode ^
        isEmailVerified.hashCode;
  }

  @override
  String toString() {
    return 'UserProfile(id: $id, email: $email, displayName: $displayName, '
        'photoUrl: $photoUrl, isEmailVerified: $isEmailVerified)';
  }
}
