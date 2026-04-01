import 'package:freezed_annotation/freezed_annotation.dart';

import '../../data/models/drive_file.dart';

part 'drive_state.freezed.dart';

/// Drive state for Google Drive integration
@freezed
class DriveState with _$DriveState {
  const factory DriveState({
    @Default(false) bool isConnected,
    @Default(false) bool isLoading,
    @Default(false) bool isDownloading,
    @Default(false) bool isRefreshing,
    @Default(false) bool isFromCache,
    String? userName,
    String? downloadingFileName,
    String? errorMessage,
    @Default([]) List<DriveFileModel> files,
    DateTime? lastSyncTime,
  }) = _DriveState;

  factory DriveState.initial() => const DriveState();
}

/// Extension for DriveState utilities
extension DriveStateExtension on DriveState {
  /// Get formatted cache age string
  String? get formattedCacheAge {
    if (lastSyncTime == null) return null;

    final age = DateTime.now().difference(lastSyncTime!);
    if (age.inMinutes < 1) {
      return 'just now';
    } else if (age.inMinutes < 60) {
      return '${age.inMinutes}m ago';
    } else if (age.inHours < 24) {
      return '${age.inHours}h ago';
    } else {
      return '${age.inDays}d ago';
    }
  }

  /// Check if cache is stale (older than 1 hour)
  bool get isCacheStale {
    if (lastSyncTime == null) return true;
    return DateTime.now().difference(lastSyncTime!) > const Duration(hours: 1);
  }
}
