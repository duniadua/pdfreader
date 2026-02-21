import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/data/models/pdf_document.dart';
import '../../../../core/data/providers/repository_providers.dart';
import '../../../../core/data/repositories/pdf_repository.dart';
import '../../../../core/utils/exceptions.dart';
import '../../../../core/utils/logger.dart';
import '../library_screen.dart';

part 'library_notifier.g.dart';
part 'library_notifier.freezed.dart';

/// Library state
@freezed
class LibraryState with _$LibraryState {
  const factory LibraryState({
    required List<PdfDocument> allPdfs,
    required List<PdfDocument> recentPdfs,
    required List<PdfDocument> favoritePdfs,
    required bool isLoading,
    required AppFailure? failure,
  }) = _LibraryState;

  factory LibraryState.initial() => const LibraryState(
        allPdfs: [],
        recentPdfs: [],
        favoritePdfs: [],
        isLoading: true,
        failure: null,
      );
}

/// Library state notifier
@riverpod
class LibraryNotifier extends _$LibraryNotifier {
  late final PdfRepository _repository;

  @override
  LibraryState build() {
    // Get repository from provider
    _repository = ref.read(sharedPreferencesPdfRepositoryProvider);

    // Load initial data
    loadLibrary();

    ref.onDispose(() {
      // Cleanup if needed
    });

    return LibraryState.initial();
  }

  /// Load all library data
  Future<void> loadLibrary() async {
    state = state.copyWith(isLoading: true, failure: null);

    final results = await Future.wait([
      _repository.getAllPdfs(),
      _repository.getRecentPdfs(limit: 10),
      _repository.getFavoritePdfs(),
    ]);

    final allResult = results[0];
    final recentResult = results[1];
    final favoriteResult = results[2];

    state = allResult.when(
      success: (allPdfs) {
        return recentResult.when(
          success: (recentPdfs) {
            return favoriteResult.when(
              success: (favoritePdfs) {
                return state.copyWith(
                  allPdfs: allPdfs,
                  recentPdfs: recentPdfs,
                  favoritePdfs: favoritePdfs,
                  isLoading: false,
                  failure: null,
                );
              },
              failure: (error, stackTrace) {
                return state.copyWith(
                  allPdfs: allPdfs,
                  recentPdfs: recentPdfs,
                  favoritePdfs: [],
                  isLoading: false,
                  failure: _handleAppFailure(error, stackTrace),
                );
              },
            );
          },
          failure: (error, stackTrace) {
            return favoriteResult.when(
              success: (favoritePdfs) {
                return state.copyWith(
                  allPdfs: allPdfs,
                  recentPdfs: [],
                  favoritePdfs: favoritePdfs,
                  isLoading: false,
                  failure: _handleAppFailure(error, stackTrace),
                );
              },
              failure: (error2, stackTrace2) {
                return state.copyWith(
                  allPdfs: allPdfs,
                  recentPdfs: [],
                  favoritePdfs: [],
                  isLoading: false,
                  failure: _handleAppFailure(error, stackTrace),
                );
              },
            );
          },
        );
      },
      failure: (error, stackTrace) {
        return state.copyWith(
          allPdfs: [],
          recentPdfs: [],
          favoritePdfs: [],
          isLoading: false,
          failure: _handleAppFailure(error, stackTrace),
        );
      },
    );
  }

  /// Toggle favorite status
  Future<void> toggleFavorite(String pdfId) async {
    final result = await _repository.toggleFavorite(pdfId);
    result.when(
      failure: (error, stackTrace) {
        AppLogger.e('Toggle favorite failed', error, stackTrace);
        state = state.copyWith(failure: _handleAppFailure(error, stackTrace));
      },
      success: (_) => loadLibrary(),
    );
  }

  /// Delete a PDF
  Future<void> deletePdf(String pdfId) async {
    final result = await _repository.deletePdf(pdfId);
    result.when(
      failure: (error, stackTrace) {
        AppLogger.e('Delete PDF failed', error, stackTrace);
        state = state.copyWith(failure: _handleAppFailure(error, stackTrace));
      },
      success: (_) => loadLibrary(),
    );
  }

  /// Dismiss any failure
  void dismissFailure() {
    state = state.copyWith(failure: null);
  }

  /// Mark a PDF as opened (updates lastOpenedAt for timeline)
  Future<void> markAsOpened(String pdfId) async {
    final result = await _repository.getPdfById(pdfId);
    result.when(
      success: (pdf) async {
        if (pdf == null) return;
        final updated = pdf.copyWith(lastOpenedAt: DateTime.now());
        await _repository.updatePdf(updated);
        // Refresh library data to update timeline
        await loadLibrary();
      },
      failure: (error, stackTrace) {
        AppLogger.e('Failed to mark PDF as opened', error, stackTrace);
      },
    );
  }

  /// Import a PDF file from device storage
  Future<void> importPdf() async {
    state = state.copyWith(isLoading: true, failure: null);

    try {
      // Use FilePicker to select PDF file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        // User cancelled
        state = state.copyWith(isLoading: false);
        return;
      }

      final file = result.files.first;
      if (file.path == null) {
        state = state.copyWith(
          isLoading: false,
          failure: const AppFailure(
            message: 'Unable to access selected file',
          ),
        );
        return;
      }

      // Get file info
      final filePath = file.path!;
      final fileName = file.name ?? 'Unknown PDF';
      final fileSize = File(filePath).lengthSync();

      // Validate file is a PDF
      if (!filePath.toLowerCase().endsWith('.pdf')) {
        state = state.copyWith(
          isLoading: false,
          failure: const AppFailure(
            message: 'Selected file is not a PDF',
          ),
        );
        return;
      }

      // Create new PDF document with default page count
      // Note: Page count will be updated when PDF is first opened
      final pdfDocument = PdfDocument(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: fileName.replaceAll('.pdf', ''),
        filePath: filePath,
        fileSize: fileSize,
        createdAt: DateTime.now(),
        lastOpenedAt: DateTime.now(),
        totalPages: 0, // Will be updated on first open
      );

      // Add to repository
      final addResult = await _repository.addPdf(pdfDocument);

      addResult.when(
        failure: (error, stackTrace) {
          AppLogger.e('Failed to import PDF', error, stackTrace);
          state = state.copyWith(
            isLoading: false,
            failure: _handleAppFailure(error, stackTrace),
          );
        },
        success: (_) {
          AppLogger.i('Successfully imported PDF: $fileName');
          loadLibrary();
        },
      );
    } catch (e, st) {
      AppLogger.e('Error importing PDF', e, st);
      state = state.copyWith(
        isLoading: false,
        failure: AppFailure(
          message: 'Failed to import PDF: ${e.toString()}',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  AppFailure? _handleAppFailure(Object error, StackTrace? stackTrace) {
    if (error is AppException) {
      return AppFailure.fromException(error);
    }
    return AppFailure(
      message: error.toString(),
      cause: error,
      stackTrace: stackTrace,
    );
  }
}

/// Provider for the current library tab
@riverpod
class LibraryTabNotifier extends _$LibraryTabNotifier {
  @override
  LibraryTab build() => LibraryTab.library;

  void setTab(LibraryTab tab) => state = tab;
}

/// Provider for search query
@riverpod
class SearchQueryNotifier extends _$SearchQueryNotifier {
  @override
  String build() => '';

  void setQuery(String query) => state = query;

  void clear() => state = '';
}
