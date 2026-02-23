import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';

import '../utils/logger.dart';

/// Service for generating PDF thumbnails
class ThumbnailService {
  static const String _cacheDir = 'pdf_thumbnails';

  /// Generate thumbnail from first page of PDF
  ///
  /// Returns the path to the generated thumbnail image, or null if generation fails.
  Future<String?> generateThumbnail(
    String pdfPath, {
    int width = 200,
    int height = 280,
  }) async {
    try {
      // Get cache directory
      final cacheDir = await getApplicationCacheDirectory();
      final thumbnailsDir = Directory('${cacheDir.path}/$_cacheDir');
      if (!await thumbnailsDir.exists()) {
        await thumbnailsDir.create(recursive: true);
      }

      // Generate unique filename from PDF path hash
      final hash = pdfPath.hashCode;
      final fileName = 'thumb_$hash.png';
      final thumbnailPath = '${thumbnailsDir.path}/$fileName';

      // Check if thumbnail already exists
      final thumbnailFile = File(thumbnailPath);
      if (await thumbnailFile.exists()) {
        AppLogger.i('Thumbnail cache hit: $thumbnailPath');
        return thumbnailPath;
      }

      AppLogger.i('Generating thumbnail for: $pdfPath');
      // Generate new thumbnail
      final pdf = await PdfDocument.openFile(pdfPath);
      final page = await pdf.getPage(1); // First page (1-indexed)

      final image = await page.render(
        width: width.toDouble(),
        height: height.toDouble(),
        format: PdfPageImageFormat.png,
      );

      if (image == null) {
        AppLogger.w('Failed to render PDF page for thumbnail: $pdfPath');
        await pdf.close();
        return null;
      }

      await thumbnailFile.writeAsBytes(image.bytes);
      await pdf.close();

      AppLogger.i('Thumbnail generated successfully: $thumbnailPath');
      return thumbnailPath;
    } catch (e, st) {
      AppLogger.e('Failed to generate thumbnail for $pdfPath', e, st);
      return null;
    }
  }

  /// Generate small thumbnail for list items (56x56)
  Future<String?> generateSmallThumbnail(String pdfPath) async {
    return generateThumbnail(pdfPath, width: 112, height: 112);
  }

  /// Generate large thumbnail for cards (160x213)
  Future<String?> generateLargeThumbnail(String pdfPath) async {
    return generateThumbnail(pdfPath, width: 320, height: 426);
  }

  /// Clear all cached thumbnails
  Future<void> clearCache() async {
    try {
      final cacheDir = await getApplicationCacheDirectory();
      final thumbnailsDir = Directory('${cacheDir.path}/$_cacheDir');
      if (await thumbnailsDir.exists()) {
        await thumbnailsDir.delete(recursive: true);
      }
    } catch (e) {
      // Ignore errors when clearing cache
    }
  }

  /// Check if a thumbnail exists for the given PDF path
  Future<bool> hasThumbnail(String pdfPath) async {
    try {
      final cacheDir = await getApplicationCacheDirectory();
      final hash = pdfPath.hashCode;
      final fileName = 'thumb_$hash.png';
      final thumbnailPath = '${cacheDir.path}/$_cacheDir/$fileName';
      final thumbnailFile = File(thumbnailPath);
      return await thumbnailFile.exists();
    } catch (e) {
      return false;
    }
  }

  /// Get thumbnail path for a PDF (without generating)
  Future<String?> getThumbnailPath(String pdfPath) async {
    try {
      final cacheDir = await getApplicationCacheDirectory();
      final hash = pdfPath.hashCode;
      final fileName = 'thumb_$hash.png';
      final thumbnailPath = '${cacheDir.path}/$_cacheDir/$fileName';
      final thumbnailFile = File(thumbnailPath);
      if (await thumbnailFile.exists()) {
        return thumbnailPath;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
