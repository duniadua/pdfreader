import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/cache/cache_config.dart';
import '../../../../core/cache/cache_manager.dart';
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
    required bool isLoadingMore,
    required AppFailure? failure,
    required bool hasMore,
  }) = _LibraryState;

  factory LibraryState.initial() => const LibraryState(
    allPdfs: [],
    recentPdfs: [],
    favoritePdfs: [],
    isLoading: true,
    isLoadingMore: false,
    failure: null,
    hasMore: true,
  );
}

/// Library state notifier
@riverpod
class LibraryNotifier extends _$LibraryNotifier {
  late final PdfRepository _repository;
  late final CacheManager _cache;
  int _currentOffset = 0;
  bool _isLoadingFromBuild = false;

  @override
  LibraryState build() {
    // Get repository from provider - SharedPreferences is now pre-initialized in main()
    _repository = ref.read(sharedPreferencesPdfRepositoryProvider);
    _cache = CacheManager.instance;

    // Set up progress save callback
    _cache.setProgressSaveCallback((documentId, page, scrollOffset) {
      return _repository.updateProgress(documentId, page, scrollOffset);
    });

    // Load initial data asynchronously after build completes
    // Mark that we're loading from build so loadLibrary won't try to update state prematurely
    _isLoadingFromBuild = true;
    loadLibrary().then((_) {
      _isLoadingFromBuild = false;
    });

    ref.onDispose(() {
      // Cleanup if needed
    });

    return LibraryState.initial();
  }

  /// Load initial library data with pagination
  Future<void> loadLibrary() async {
    // If called from build(), don't update state yet (will be done after build completes)
    if (!_isLoadingFromBuild) {
      state = state.copyWith(isLoading: true, failure: null);
    }
    _currentOffset = 0;

    // Fetch all data in parallel
    final paginatedResult = await _repository.getPagedPdfs(
      offset: 0,
      limit: CacheConfig.initialPageSize,
    );
    final recentResult = await _repository.getRecentPdfs(
      limit: CacheConfig.recentCount,
    );
    final favoriteResult = await _repository.getFavoritePdfs();

    final newState = paginatedResult.when(
      success: (paginated) {
        // Cache loaded PDFs
        _cache.cachePdfDocuments(paginated.pdfs);

        return recentResult.when(
          success: (recentPdfs) {
            return favoriteResult.when(
              success: (favoritePdfs) {
                final resultState = state.copyWith(
                  allPdfs: paginated.pdfs,
                  recentPdfs: recentPdfs,
                  favoritePdfs: favoritePdfs,
                  isLoading: false,
                  failure: null,
                  hasMore: paginated.hasMore,
                );
                AppLogger.i(
                  'Created new state with isLoading=${resultState.isLoading}, allPdfs=${resultState.allPdfs.length}',
                );
                return resultState;
              },
              failure: (error, stackTrace) {
                return state.copyWith(
                  allPdfs: paginated.pdfs,
                  recentPdfs: recentPdfs,
                  favoritePdfs: [],
                  isLoading: false,
                  failure: _handleAppFailure(error, stackTrace),
                  hasMore: paginated.hasMore,
                );
              },
            );
          },
          failure: (error, stackTrace) {
            return favoriteResult.when(
              success: (favoritePdfs) {
                return state.copyWith(
                  allPdfs: paginated.pdfs,
                  recentPdfs: [],
                  favoritePdfs: favoritePdfs,
                  isLoading: false,
                  failure: _handleAppFailure(error, stackTrace),
                  hasMore: paginated.hasMore,
                );
              },
              failure: (error2, stackTrace2) {
                return state.copyWith(
                  allPdfs: paginated.pdfs,
                  recentPdfs: [],
                  favoritePdfs: [],
                  isLoading: false,
                  failure: _handleAppFailure(error, stackTrace),
                  hasMore: paginated.hasMore,
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
          hasMore: false,
        );
      },
    );
    state = newState;
    AppLogger.i(
      'Assigned new state, isLoading=${state.isLoading}, allPdfs=${state.allPdfs.length}',
    );
  }

  /// Load more PDFs (pagination)
  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true);

    final result = await _repository.getPagedPdfs(
      offset: _currentOffset + CacheConfig.initialPageSize,
      limit: CacheConfig.pageSize,
    );

    result.when(
      success: (paginated) {
        _currentOffset = paginated.nextOffset;
        _cache.cachePdfDocuments(paginated.pdfs);

        state = state.copyWith(
          allPdfs: [...state.allPdfs, ...paginated.pdfs],
          hasMore: paginated.hasMore,
          isLoadingMore: false,
        );
      },
      failure: (error, stackTrace) {
        AppLogger.e('Failed to load more PDFs', error, stackTrace);
        state = state.copyWith(
          isLoadingMore: false,
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
    // Invalidate cache first
    _cache.invalidatePdf(pdfId);

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
    // Check cache first
    var pdf = _cache.getPdfDocument(pdfId);

    if (pdf == null) {
      final result = await _repository.getPdfById(pdfId);
      await result.when(
        success: (fetchedPdf) async {
          if (fetchedPdf == null) return;
          await _updateOpenedTimestamp(fetchedPdf);
        },
        failure: (error, stackTrace) {
          AppLogger.e('Failed to mark PDF as opened', error, stackTrace);
        },
      );
    } else {
      await _updateOpenedTimestamp(pdf);
    }
  }

  Future<void> _updateOpenedTimestamp(PdfDocument pdf) async {
    final updated = pdf.copyWith(lastOpenedAt: DateTime.now());
    await _repository.updatePdf(updated);
    // Update cache
    _cache.cachePdfDocument(updated);
    // Refresh recent PDFs only (not full library reload)
    _refreshRecentPdfs();
  }

  Future<void> _refreshRecentPdfs() async {
    final result = await _repository.getRecentPdfs(
      limit: CacheConfig.recentCount,
    );
    result.when(
      success: (recentPdfs) {
        state = state.copyWith(recentPdfs: recentPdfs);
      },
      failure: (error, stackTrace) {
        AppLogger.e('Failed to refresh recent PDFs', error, stackTrace);
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
          failure: const AppFailure(message: 'Unable to access selected file'),
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
          failure: const AppFailure(message: 'Selected file is not a PDF'),
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
        success: (addedPdf) async {
          AppLogger.i('Successfully imported PDF: $fileName');
          // Generate thumbnail in background
          _repository.generateThumbnail(addedPdf.id).then((result) {
            result.when(
              success: (thumbnailPath) {
                if (thumbnailPath != null) {
                  AppLogger.i('Thumbnail generated: $thumbnailPath');
                  // Refresh library to show thumbnail
                  loadLibrary();
                } else {
                  AppLogger.w(
                    'Thumbnail generation returned null for ${addedPdf.title}',
                  );
                }
              },
              failure: (error, stackTrace) {
                AppLogger.e('Failed to generate thumbnail', error, stackTrace);
                // Still load library even if thumbnail failed
                loadLibrary();
              },
            );
          });
          // Load library immediately without waiting for thumbnail
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
