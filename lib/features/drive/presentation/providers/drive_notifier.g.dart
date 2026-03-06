// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'drive_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$isDriveAuthenticatedHash() =>
    r'f9c9e10f5462e33f7af4d9b3df5bacf8b46e39e6';

/// Provider for Google Drive authentication status
///
/// Copied from [isDriveAuthenticated].
@ProviderFor(isDriveAuthenticated)
final isDriveAuthenticatedProvider = AutoDisposeProvider<bool>.internal(
  isDriveAuthenticated,
  name: r'isDriveAuthenticatedProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$isDriveAuthenticatedHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef IsDriveAuthenticatedRef = AutoDisposeProviderRef<bool>;
String _$isDriveDownloadingHash() =>
    r'e1e35e939ae47551d98e78de5643cc8a59321f48';

/// Provider for checking if a file is currently being downloaded
///
/// Copied from [isDriveDownloading].
@ProviderFor(isDriveDownloading)
final isDriveDownloadingProvider = AutoDisposeProvider<bool>.internal(
  isDriveDownloading,
  name: r'isDriveDownloadingProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$isDriveDownloadingHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef IsDriveDownloadingRef = AutoDisposeProviderRef<bool>;
String _$driveDownloadingFileNameHash() =>
    r'90d828702d25dbd0e50662e4beab147f78040c37';

/// Provider for getting the current downloading file name
///
/// Copied from [driveDownloadingFileName].
@ProviderFor(driveDownloadingFileName)
final driveDownloadingFileNameProvider = AutoDisposeProvider<String?>.internal(
  driveDownloadingFileName,
  name: r'driveDownloadingFileNameProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$driveDownloadingFileNameHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef DriveDownloadingFileNameRef = AutoDisposeProviderRef<String?>;
String _$driveNotifierHash() => r'a546d8ec76235696e654e4c245ff2fd68ab309d8';

/// Notifier for Google Drive state management
///
/// Copied from [DriveNotifier].
@ProviderFor(DriveNotifier)
final driveNotifierProvider =
    AutoDisposeNotifierProvider<DriveNotifier, DriveState>.internal(
      DriveNotifier.new,
      name: r'driveNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$driveNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$DriveNotifier = AutoDisposeNotifier<DriveState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
