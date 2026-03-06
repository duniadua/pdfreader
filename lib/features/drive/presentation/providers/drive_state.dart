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
    String? userName,
    String? downloadingFileName,
    String? errorMessage,
    @Default([]) List<DriveFileModel> files,
  }) = _DriveState;

  factory DriveState.initial() => const DriveState();
}
