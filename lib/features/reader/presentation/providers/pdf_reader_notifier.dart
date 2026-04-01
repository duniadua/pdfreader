import 'dart:io';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/data/models/pdf_document.dart';
import '../../../../core/data/providers/repository_providers.dart';
import '../../../../core/data/repositories/pdf_repository.dart';
import '../../../../core/services/analytics_service.dart';

part 'pdf_reader_notifier.g.dart';
part 'pdf_reader_notifier.freezed.dart';

/// Provider for PDF reader state
@riverpod
class PdfReaderNotifier extends _$PdfReaderNotifier {
  late final PdfRepository _repository;

  @override
  PdfReaderState build(String pdfId) {
    // Get repository from provider - SharedPreferences is now pre-initialized in main()
    _repository = ref.read(sharedPreferencesPdfRepositoryProvider);
    _loadPdf();
    return const PdfReaderState.loading();
  }

  /// Load PDF document from repository
  Future<void> _loadPdf() async {
    final result = await _repository.getPdfById(pdfId);

    result.when(
      success: (pdf) {
        if (pdf == null) {
          state = const PdfReaderState.notFound();
        } else {
          // Verify file still exists on device
          final file = File(pdf.filePath);
          if (!file.existsSync()) {
            state = PdfReaderState.fileNotFound(pdf.filePath);
          } else {
            state = PdfReaderState.loaded(pdf);
            // Track PDF open
            AnalyticsService.instance.trackPdfOpen(
              pdfId: pdf.id,
              pageCount: pdf.totalPages,
              isFavorite: pdf.isFavorite,
            );
          }
        }
      },
      failure: (error, _) => state = PdfReaderState.error(error.toString()),
    );
  }

  /// Update reading progress when page changes
  void onPageChanged(int page) {
    state.maybeWhen(
      loaded: (pdf) {
        // Get current page from progress for tracking
        final currentPage = pdf.progress?.currentPage ?? 0;
        // Track page navigation
        AnalyticsService.instance.trackPageNavigation(
          pdfId: pdf.id,
          fromPage: currentPage,
          toPage: page,
          navigationType: 'unknown',
        );
        _repository.updateProgress(pdfId, page, 0);
      },
      orElse: () {},
    );
  }

  /// Toggle favorite status
  Future<void> toggleFavorite() async {
    state.maybeWhen(
      loaded: (pdf) async {
        final result = await _repository.toggleFavorite(pdf.id);
        result.when(
          success: (updated) {
            // Track favorite toggle
            AnalyticsService.instance.trackPdfFavorite(
              pdfId: pdf.id,
              isFavorite: updated.isFavorite,
            );
            state = PdfReaderState.loaded(updated);
          },
          failure: (error, _) => state = PdfReaderState.error(error.toString()),
        );
      },
      orElse: () {},
    );
  }

  /// Retry loading PDF
  void retry() {
    state = const PdfReaderState.loading();
    _loadPdf();
  }
}

/// PDF reader state
@freezed
class PdfReaderState with _$PdfReaderState {
  const factory PdfReaderState.loading() = _PdfReaderLoading;

  const factory PdfReaderState.loaded(PdfDocument pdf) = _PdfReaderLoaded;

  const factory PdfReaderState.notFound() = _PdfReaderNotFound;

  const factory PdfReaderState.fileNotFound(String filePath) =
      _PdfReaderFileNotFound;

  const factory PdfReaderState.error(String message) = _PdfReaderError;
}
