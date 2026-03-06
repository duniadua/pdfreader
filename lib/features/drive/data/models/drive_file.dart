import 'package:freezed_annotation/freezed_annotation.dart';

part 'drive_file.freezed.dart';
part 'drive_file.g.dart';

/// Drive file model representing a PDF in Google Drive
@freezed
class DriveFileModel with _$DriveFileModel {
  const factory DriveFileModel({
    required String id,
    required String name,
    required int size,
    required DateTime createdTime,
    String? thumbnailLink,
    String? webViewLink,
  }) = _DriveFileModel;

  factory DriveFileModel.fromJson(Map<String, dynamic> json) =>
      _$DriveFileModelFromJson(json);
}

/// Extension for Drive file display utilities
extension DriveFileModelExtension on DriveFileModel {
  /// Format file size for display
  String get formattedSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) {
      return '${(size / 1024).toStringAsFixed(1)} KB';
    }
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Get display name (without .pdf extension if present)
  String get displayName {
    if (name.toLowerCase().endsWith('.pdf')) {
      return name.substring(0, name.length - 4);
    }
    return name;
  }

  /// Check if file is a PDF
  bool get isPdf {
    return name.toLowerCase().endsWith('.pdf');
  }
}
