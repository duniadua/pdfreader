import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../utils/exceptions.dart';
import '../../utils/logger.dart';
import '../../utils/result.dart';
import '../models/pdf_document.dart';
import '../../services/thumbnail_service.dart';

/// Repository interface for PDF document operations
abstract class PdfRepository {
  /// Get all PDF documents
  Future<Result<List<PdfDocument>>> getAllPdfs();

  /// Get a PDF by ID
  Future<Result<PdfDocument?>> getPdfById(String id);

  /// Get recent PDFs
  Future<Result<List<PdfDocument>>> getRecentPdfs({int limit = 10});

  /// Get favorite PDFs
  Future<Result<List<PdfDocument>>> getFavoritePdfs();

  /// Add a PDF document
  Future<Result<PdfDocument>> addPdf(PdfDocument document);

  /// Update a PDF document
  Future<Result<PdfDocument>> updatePdf(PdfDocument document);

  /// Delete a PDF document
  Future<Result<void>> deletePdf(String id);

  /// Toggle favorite status
  Future<Result<PdfDocument>> toggleFavorite(String id);

  /// Update reading progress
  Future<Result<void>> updateProgress(String documentId, int page, int scrollOffset);

  /// Generate and save thumbnail for a PDF
  Future<Result<String?>> generateThumbnail(String pdfId);

  /// Update thumbnail path for a PDF
  Future<Result<PdfDocument>> updateThumbnail(String pdfId, String? thumbnailPath);
}

/// Implementation of PdfRepository using SharedPreferences
class SharedPreferencesPdfRepository implements PdfRepository {
  SharedPreferencesPdfRepository({
    required SharedPreferences prefs,
    ThumbnailService? thumbnailService,
  })  : _prefs = prefs, _thumbnailService = thumbnailService ?? ThumbnailService();

  final SharedPreferences _prefs;
  final ThumbnailService _thumbnailService;

  static const String _pdfsKey = 'pdfs';

  List<PdfDocument> _decodePdfs(String jsonString) {
    try {
      final List<dynamic> decoded = json.decode(jsonString);
      return decoded
          .map((item) => PdfDocument.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      AppLogger.e('Failed to decode PDFs', e, st);
      return [];
    }
  }

  String _encodePdfs(List<PdfDocument> pdfs) {
    return json.encode(pdfs.map((p) => p.toJson()).toList());
  }

  List<PdfDocument> _getPdfs() {
    final jsonString = _prefs.getString(_pdfsKey);
    if (jsonString == null || jsonString.isEmpty) return [];
    return _decodePdfs(jsonString);
  }

  Future<void> _savePdfs(List<PdfDocument> pdfs) async {
    await _prefs.setString(_pdfsKey, _encodePdfs(pdfs));
  }

  @override
  Future<Result<List<PdfDocument>>> getAllPdfs() async {
    try {
      final pdfs = _getPdfs();
      // Sort by last opened
      pdfs.sort((a, b) => b.lastOpenedAt.compareTo(a.lastOpenedAt));
      return Result.success(pdfs);
    } catch (e, st) {
      AppLogger.e('Failed to get all PDFs', e, st);
      return Result.failure(const StorageException('Failed to load PDFs'), st);
    }
  }

  @override
  Future<Result<PdfDocument?>> getPdfById(String id) async {
    try {
      final pdfs = _getPdfs();
      final pdf = pdfs.cast<PdfDocument?>().firstWhere(
        (p) => p?.id == id,
        orElse: () => null,
      );
      return Result.success(pdf);
    } catch (e, st) {
      AppLogger.e('Failed to get PDF by ID', e, st);
      return Result.failure(const StorageException('PDF not found'), st);
    }
  }

  @override
  Future<Result<List<PdfDocument>>> getRecentPdfs({int limit = 10}) async {
    try {
      final pdfs = _getPdfs();
      pdfs.sort((a, b) => b.lastOpenedAt.compareTo(a.lastOpenedAt));
      final recent = pdfs.take(limit).toList();
      return Result.success(recent);
    } catch (e, st) {
      AppLogger.e('Failed to get recent PDFs', e, st);
      return Result.failure(const StorageException('Failed to load recent PDFs'), st);
    }
  }

  @override
  Future<Result<List<PdfDocument>>> getFavoritePdfs() async {
    try {
      final pdfs = _getPdfs();
      final favorites = pdfs.where((p) => p.isFavorite).toList();
      favorites.sort((a, b) => b.lastOpenedAt.compareTo(a.lastOpenedAt));
      return Result.success(favorites);
    } catch (e, st) {
      AppLogger.e('Failed to get favorite PDFs', e, st);
      return Result.failure(const StorageException('Failed to load favorites'), st);
    }
  }

  @override
  Future<Result<PdfDocument>> addPdf(PdfDocument document) async {
    try {
      final pdfs = _getPdfs();
      // Check for duplicates by file path
      if (pdfs.any((p) => p.filePath == document.filePath)) {
        return Result.failure(
          const StorageException('PDF already exists in library'),
        );
      }
      pdfs.add(document);
      await _savePdfs(pdfs);
      AppLogger.i('Added PDF: ${document.title}');
      return Result.success(document);
    } catch (e, st) {
      AppLogger.e('Failed to add PDF', e, st);
      return Result.failure(const StorageException('Failed to add PDF'), st);
    }
  }

  @override
  Future<Result<PdfDocument>> updatePdf(PdfDocument document) async {
    try {
      final pdfs = _getPdfs();
      final index = pdfs.indexWhere((p) => p.id == document.id);
      if (index == -1) {
        return Result.failure(
          const StorageException('PDF not found'),
        );
      }
      pdfs[index] = document;
      await _savePdfs(pdfs);
      AppLogger.i('Updated PDF: ${document.title}');
      return Result.success(document);
    } catch (e, st) {
      AppLogger.e('Failed to update PDF', e, st);
      return Result.failure(const StorageException('Failed to update PDF'), st);
    }
  }

  @override
  Future<Result<void>> deletePdf(String id) async {
    try {
      final pdfs = _getPdfs();
      final initialLength = pdfs.length;
      pdfs.removeWhere((p) => p.id == id);
      if (pdfs.length == initialLength) {
        return Result.failure(
          const StorageException('PDF not found'),
        );
      }
      await _savePdfs(pdfs);
      AppLogger.i('Deleted PDF: $id');
      return Result.success(null);
    } catch (e, st) {
      AppLogger.e('Failed to delete PDF', e, st);
      return Result.failure(const StorageException('Failed to delete PDF'), st);
    }
  }

  @override
  Future<Result<PdfDocument>> toggleFavorite(String id) async {
    try {
      final pdfResult = await getPdfById(id);
      return pdfResult.mapDataAsync((pdf) async {
        if (pdf == null) {
          throw const StorageException('PDF not found');
        }
        final updated = pdf.copyWith(isFavorite: !pdf.isFavorite);
        await updatePdf(updated);
        return updated;
      });
    } catch (e, st) {
      AppLogger.e('Failed to toggle favorite', e, st);
      return Result.failure(const StorageException('Failed to toggle favorite'), st);
    }
  }

  @override
  Future<Result<void>> updateProgress(String documentId, int page, int scrollOffset) async {
    try {
      final pdfs = _getPdfs();
      final index = pdfs.indexWhere((p) => p.id == documentId);
      if (index == -1) {
        return Result.failure(
          const StorageException('PDF not found'),
        );
      }
      final pdf = pdfs[index];
      final progress = ReadingProgress(
        documentId: documentId,
        currentPage: page,
        lastReadAt: DateTime.now(),
        scrollOffset: scrollOffset,
      );
      pdfs[index] = pdf.copyWith(
        progress: progress,
        lastOpenedAt: DateTime.now(),
      );
      await _savePdfs(pdfs);
      return Result.success(null);
    } catch (e, st) {
      AppLogger.e('Failed to update progress', e, st);
      return Result.failure(const StorageException('Failed to update progress'), st);
    }
  }

  @override
  Future<Result<String?>> generateThumbnail(String pdfId) async {
    try {
      final pdfs = _getPdfs();
      final index = pdfs.indexWhere((p) => p.id == pdfId);
      if (index == -1) {
        return Result.failure(
          const StorageException('PDF not found'),
        );
      }
      final pdf = pdfs[index];

      // Generate thumbnail
      final thumbnailPath = await _thumbnailService.generateThumbnail(pdf.filePath);
      if (thumbnailPath != null) {
        // Update PDF with thumbnail path
        pdfs[index] = pdf.copyWith(thumbnailPath: thumbnailPath);
        await _savePdfs(pdfs);
        return Result.success(thumbnailPath);
      }
      return Result.success(null); // Thumbnail generation failed but no error
    } catch (e, st) {
      AppLogger.e('Failed to generate thumbnail', e, st);
      return Result.failure(const StorageException('Failed to generate thumbnail'), st);
    }
  }

  @override
  Future<Result<PdfDocument>> updateThumbnail(String pdfId, String? thumbnailPath) async {
    try {
      final pdfs = _getPdfs();
      final index = pdfs.indexWhere((p) => p.id == pdfId);
      if (index == -1) {
        return Result.failure(
          const StorageException('PDF not found'),
        );
      }
      final pdf = pdfs[index];
      final updated = pdf.copyWith(thumbnailPath: thumbnailPath);
      pdfs[index] = updated;
      await _savePdfs(pdfs);
      return Result.success(updated);
    } catch (e, st) {
      AppLogger.e('Failed to update thumbnail', e, st);
      return Result.failure(const StorageException('Failed to update thumbnail'), st);
    }
  }
}
