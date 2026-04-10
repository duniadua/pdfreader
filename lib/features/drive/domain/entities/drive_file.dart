import 'package:freezed_annotation/freezed_annotation.dart';

part 'drive_file.freezed.dart';
part 'drive_file.g.dart';

/// Drive file entity representing a PDF in Google Drive
/// This is a domain entity - pure Dart with no framework dependencies
@freezed
class DriveFile with _$DriveFile {
  const factory DriveFile({
    required String id,
    required String name,
    required int size,
    required DateTime createdTime,
    String? thumbnailLink,
    String? webViewLink,
  }) = _DriveFile;

  factory DriveFile.fromJson(Map<String, dynamic> json) =>
      _$DriveFileFromJson(json);
}

/// Extension for Drive file display utilities
extension DriveFileExtension on DriveFile {
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
