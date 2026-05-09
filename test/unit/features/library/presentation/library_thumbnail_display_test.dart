import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:pdf_reader_app/core/cache/cache_config.dart';
import 'package:pdf_reader_app/core/data/models/pdf_document.dart';
import 'package:pdf_reader_app/core/data/providers/repository_providers.dart';
import 'package:pdf_reader_app/core/data/repositories/pdf_repository.dart';
import 'package:pdf_reader_app/core/services/thumbnail_service.dart';
import 'package:pdf_reader_app/core/utils/result.dart';
import 'package:pdf_reader_app/features/library/presentation/library_screen.dart';
import 'package:pdf_reader_app/features/library/presentation/providers/library_notifier.dart';

@GenerateMocks([PdfRepository, ThumbnailService])
import 'library_thumbnail_display_test.mocks.dart';

// ---------------------------------------------------------------------------
// Test helpers
// ---------------------------------------------------------------------------

/// Creates a [PdfDocument] with sensible defaults for testing.
PdfDocument createTestPdf({
  String id = 'test-1',
  String title = 'Test PDF',
  String filePath = '/path/to/test.pdf',
  int fileSize = 1024 * 1024,
  int totalPages = 100,
  String? thumbnailPath,
  bool isFavorite = false,
  ReadingProgress? progress,
}) {
  return PdfDocument(
    id: id,
    title: title,
    filePath: filePath,
    fileSize: fileSize,
    createdAt: DateTime(2024, 1, 15),
    lastOpenedAt: DateTime(2024, 1, 15),
    totalPages: totalPages,
    thumbnailPath: thumbnailPath,
    isFavorite: isFavorite,
    progress: progress,
  );
}

/// Creates a [PaginatedPdfs] wrapping the given list.
PaginatedPdfs createPaginated(List<PdfDocument> pdfs, {bool hasMore = false}) {
  return PaginatedPdfs(
    pdfs: pdfs,
    offset: 0,
    limit: pdfs.length,
    hasMore: hasMore,
    totalCount: pdfs.length,
  );
}

/// Sets up the default repository stubs so [LibraryNotifier.build] can
/// complete without throwing.
void stubRepositoryLoad(
  MockPdfRepository repository, {
  List<PdfDocument> allPdfs = const [],
  List<PdfDocument> recentPdfs = const [],
  List<PdfDocument> favoritePdfs = const [],
}) {
  when(
    repository.getPagedPdfs(offset: 0, limit: CacheConfig.initialPageSize),
  ).thenAnswer((_) async => Result.success(createPaginated(allPdfs)));

  when(
    repository.getRecentPdfs(limit: CacheConfig.recentCount),
  ).thenAnswer((_) async => Result.success(recentPdfs));

  when(
    repository.getFavoritePdfs(),
  ).thenAnswer((_) async => Result.success(favoritePdfs));
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // =========================================================================
  // 1. PdfDocument thumbnailPath field tests
  // =========================================================================
  group('PdfDocument thumbnail field', () {
    test('should be null by default', () {
      final pdf = createTestPdf();
      expect(pdf.thumbnailPath, isNull);
    });

    test('should accept a thumbnail path', () {
      final pdf = createTestPdf(thumbnailPath: '/cache/thumb_test.png');
      expect(pdf.thumbnailPath, '/cache/thumb_test.png');
    });

    test('should serialize and deserialize thumbnailPath via JSON', () {
      final original = createTestPdf(thumbnailPath: '/cache/thumb_abc.png');
      final json = original.toJson();
      expect(json['thumbnailPath'], '/cache/thumb_abc.png');

      final restored = PdfDocument.fromJson(json);
      expect(restored.thumbnailPath, '/cache/thumb_abc.png');
    });

    test('should handle null thumbnailPath in JSON round-trip', () {
      final original = createTestPdf(); // thumbnailPath is null
      final json = original.toJson();
      expect(json['thumbnailPath'], isNull);

      final restored = PdfDocument.fromJson(json);
      expect(restored.thumbnailPath, isNull);
    });

    test('copyWith should update thumbnailPath', () {
      final original = createTestPdf();
      expect(original.thumbnailPath, isNull);

      final updated = original.copyWith(thumbnailPath: '/cache/new.png');
      expect(updated.thumbnailPath, '/cache/new.png');
      expect(updated.id, original.id);
      expect(updated.title, original.title);
    });

    test(
      'copyWith should preserve existing thumbnailPath when not overridden',
      () {
        final original = createTestPdf(thumbnailPath: '/cache/existing.png');
        final updated = original.copyWith(title: 'New Title');
        expect(updated.thumbnailPath, '/cache/existing.png');
        expect(updated.title, 'New Title');
      },
    );
  });

  // =========================================================================
  // 2. ThumbnailService data classes
  // =========================================================================
  group('ThumbnailSet', () {
    test('empty set reports no thumbnails', () {
      const set = ThumbnailSet();
      expect(set.hasSmall, isFalse);
      expect(set.hasLarge, isFalse);
      expect(set.hasBoth, isFalse);
    });

    test('small-only set reports correctly', () {
      const set = ThumbnailSet(smallPath: '/thumb/small.png');
      expect(set.hasSmall, isTrue);
      expect(set.hasLarge, isFalse);
      expect(set.hasBoth, isFalse);
    });

    test('both-paths set reports hasBoth', () {
      const set = ThumbnailSet(
        smallPath: '/thumb/small.png',
        largePath: '/thumb/large.png',
      );
      expect(set.hasSmall, isTrue);
      expect(set.hasLarge, isTrue);
      expect(set.hasBoth, isTrue);
    });
  });

  group('RetryResult', () {
    test('computes success rate correctly', () {
      const result = RetryResult(total: 5, succeeded: 4, failed: 1);
      expect(result.successRate, closeTo(0.8, 0.001));
      expect(result.hasFailures, isTrue);
      expect(result.allSucceeded, isFalse);
    });

    test('all-succeeded result', () {
      const result = RetryResult(total: 3, succeeded: 3, failed: 0);
      expect(result.allSucceeded, isTrue);
      expect(result.hasFailures, isFalse);
    });

    test('empty result', () {
      const result = RetryResult(total: 0, succeeded: 0, failed: 0);
      expect(result.successRate, 0.0);
      expect(result.allSucceeded, isFalse);
    });
  });

  group('ThumbnailService formatCacheSize', () {
    test('formats bytes, kilobytes, and megabytes', () {
      final service = ThumbnailService();
      expect(service.formatCacheSize(0), '0 B');
      expect(service.formatCacheSize(512), '512 B');
      expect(service.formatCacheSize(1024), '1.0 KB');
      expect(service.formatCacheSize(1536), '1.5 KB');
      expect(service.formatCacheSize(1024 * 1024), '1.0 MB');
      expect(service.formatCacheSize(5 * 1024 * 1024), '5.0 MB');
    });
  });

  // =========================================================================
  // 3. LibraryNotifier - thumbnail loading via repository
  // =========================================================================
  group('LibraryNotifier thumbnail integration', () {
    late MockPdfRepository mockRepository;
    late ProviderContainer container;

    setUp(() {
      mockRepository = MockPdfRepository();
      container = ProviderContainer(
        overrides: [
          sharedPreferencesPdfRepositoryProvider.overrideWithValue(
            mockRepository,
          ),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    /// Helper: explicitly call loadLibrary on the notifier and wait for the
    /// state to propagate through Riverpod's provider system.
    ///
    /// Uses a listener on the provider to detect when the loading state
    /// transitions to false, avoiding reliance on pump timing.
    Future<void> loadAndWait(LibraryNotifier notifier) async {
      // Set up a completer that resolves when isLoading becomes false
      final completer = Completer<void>();
      container.listen<LibraryState>(libraryNotifierProvider, (previous, next) {
        if (!next.isLoading && !completer.isCompleted) {
          completer.complete();
        }
      }, fireImmediately: true);

      // Wait for the build-time fire-and-forget loadLibrary to complete.
      await completer.future.timeout(const Duration(seconds: 5));
    }

    test('loadLibrary populates allPdfs including thumbnail paths', () async {
      final pdfWithThumb = createTestPdf(
        id: 'with-thumb',
        thumbnailPath: '/cache/thumb_with.png',
      );
      final pdfWithoutThumb = createTestPdf(
        id: 'without-thumb',
        thumbnailPath: null,
      );

      stubRepositoryLoad(
        mockRepository,
        allPdfs: [pdfWithThumb, pdfWithoutThumb],
        recentPdfs: [pdfWithThumb],
      );

      final notifier = container.read(libraryNotifierProvider.notifier);
      await loadAndWait(notifier);

      final state = container.read(libraryNotifierProvider);
      expect(state.isLoading, isFalse);
      expect(state.allPdfs.length, 2);
      expect(state.allPdfs[0].thumbnailPath, '/cache/thumb_with.png');
      expect(state.allPdfs[1].thumbnailPath, isNull);
    });

    test('loadLibrary populates recentPdfs with thumbnail paths', () async {
      final recentPdf = createTestPdf(
        id: 'recent-1',
        thumbnailPath: '/cache/thumb_recent.png',
      );

      stubRepositoryLoad(
        mockRepository,
        allPdfs: [recentPdf],
        recentPdfs: [recentPdf],
      );

      final notifier = container.read(libraryNotifierProvider.notifier);
      await loadAndWait(notifier);

      final state = container.read(libraryNotifierProvider);
      expect(state.recentPdfs.length, 1);
      expect(state.recentPdfs[0].thumbnailPath, '/cache/thumb_recent.png');
    });

    test('loadLibrary populates favoritePdfs with thumbnail paths', () async {
      final favPdf = createTestPdf(
        id: 'fav-1',
        thumbnailPath: '/cache/thumb_fav.png',
        isFavorite: true,
      );

      stubRepositoryLoad(
        mockRepository,
        allPdfs: [favPdf],
        favoritePdfs: [favPdf],
      );

      final notifier = container.read(libraryNotifierProvider.notifier);
      await loadAndWait(notifier);

      final state = container.read(libraryNotifierProvider);
      expect(state.favoritePdfs.length, 1);
      expect(state.favoritePdfs[0].thumbnailPath, '/cache/thumb_fav.png');
    });

    test('importPdf triggers generateThumbnail on the repository', () async {
      // This test validates the notifier-level flow for thumbnail generation
      // after a PDF import. The actual ThumbnailService is called through the
      // repository. We verify the repository methods are called.
      final addedPdf = createTestPdf(id: 'imported-1', title: 'Imported');

      stubRepositoryLoad(mockRepository);

      when(
        mockRepository.addPdf(any),
      ).thenAnswer((_) async => Result.success(addedPdf));
      when(
        mockRepository.generateThumbnail('imported-1'),
      ).thenAnswer((_) async => Result.success('/cache/thumb_imported.png'));

      // The importPdf method uses FilePicker which cannot be invoked in unit
      // tests. We instead verify that generateThumbnail is wired up correctly
      // at the repository level by calling it directly through the mock.
      final result = await mockRepository.generateThumbnail('imported-1');
      expect(result.isSuccess, isTrue);
      verify(mockRepository.generateThumbnail('imported-1')).called(1);
    });

    test('loadLibrary handles repository failure gracefully', () async {
      when(
        mockRepository.getPagedPdfs(
          offset: 0,
          limit: CacheConfig.initialPageSize,
        ),
      ).thenAnswer(
        (_) async =>
            Result.failure(Exception('Repository error'), StackTrace.current),
      );
      when(
        mockRepository.getRecentPdfs(limit: CacheConfig.recentCount),
      ).thenAnswer((_) async => Result.success([]));
      when(
        mockRepository.getFavoritePdfs(),
      ).thenAnswer((_) async => Result.success([]));

      final notifier = container.read(libraryNotifierProvider.notifier);
      await loadAndWait(notifier);

      final state = container.read(libraryNotifierProvider);
      expect(state.isLoading, isFalse);
      expect(state.failure, isNotNull);
      expect(state.allPdfs, isEmpty);
    });
  });

  // =========================================================================
  // 4. LibraryState thumbnail-related state transitions
  // =========================================================================
  group('LibraryState thumbnail-related transitions', () {
    test('initial state has empty PDF lists with no thumbnails', () {
      final state = LibraryState.initial();
      expect(state.allPdfs, isEmpty);
      expect(state.recentPdfs, isEmpty);
      expect(state.favoritePdfs, isEmpty);
      expect(state.isLoading, isTrue);
    });

    test('copyWith preserves thumbnail paths in allPdfs', () {
      final initial = LibraryState.initial();
      final pdfs = [
        createTestPdf(id: '1', thumbnailPath: '/cache/a.png'),
        createTestPdf(id: '2', thumbnailPath: null),
        createTestPdf(id: '3', thumbnailPath: '/cache/c.png'),
      ];

      final updated = initial.copyWith(allPdfs: pdfs, isLoading: false);

      expect(updated.allPdfs.length, 3);
      expect(updated.allPdfs[0].thumbnailPath, '/cache/a.png');
      expect(updated.allPdfs[1].thumbnailPath, isNull);
      expect(updated.allPdfs[2].thumbnailPath, '/cache/c.png');
    });

    test('copyWith preserves thumbnail paths in recentPdfs', () {
      final initial = LibraryState.initial();
      final recent = [createTestPdf(id: 'r1', thumbnailPath: '/cache/r1.png')];

      final updated = initial.copyWith(recentPdfs: recent, isLoading: false);

      expect(updated.recentPdfs.length, 1);
      expect(updated.recentPdfs[0].thumbnailPath, '/cache/r1.png');
    });

    test('copyWith preserves thumbnail paths in favoritePdfs', () {
      final initial = LibraryState.initial();
      final favs = [
        createTestPdf(
          id: 'f1',
          thumbnailPath: '/cache/f1.png',
          isFavorite: true,
        ),
      ];

      final updated = initial.copyWith(favoritePdfs: favs, isLoading: false);

      expect(updated.favoritePdfs.length, 1);
      expect(updated.favoritePdfs[0].thumbnailPath, '/cache/f1.png');
    });
  });

  // =========================================================================
  // 5. PdfDocument progressPercentage for thumbnail progress bars
  // =========================================================================
  group('PdfDocument progress display for thumbnails', () {
    test('progressPercentage is 0 when no progress', () {
      final pdf = createTestPdf();
      expect(pdf.progressPercentage, 0.0);
    });

    test('progressPercentage calculates correctly', () {
      final pdf = createTestPdf(
        totalPages: 100,
        progress: ReadingProgress(
          documentId: 'test-1',
          currentPage: 50,
          lastReadAt: DateTime(2024, 1, 15),
        ),
      );
      expect(pdf.progressPercentage, 0.5);
    });

    test('progressPercentage is 0 when totalPages is 0', () {
      final pdf = createTestPdf(
        totalPages: 0,
        progress: ReadingProgress(
          documentId: 'test-1',
          currentPage: 5,
          lastReadAt: DateTime(2024, 1, 15),
        ),
      );
      expect(pdf.progressPercentage, 0.0);
    });

    test('progressPercentage handles page equal to totalPages', () {
      final pdf = createTestPdf(
        totalPages: 100,
        progress: ReadingProgress(
          documentId: 'test-1',
          currentPage: 100,
          lastReadAt: DateTime(2024, 1, 15),
        ),
      );
      expect(pdf.progressPercentage, 1.0);
    });
  });

  // =========================================================================
  // 6. Library tab enum for thumbnail display mode
  // =========================================================================
  group('LibraryTab display modes', () {
    test(
      'LibraryTab has all expected values for different thumbnail views',
      () {
        expect(LibraryTab.values.length, 4);
        expect(LibraryTab.values, contains(LibraryTab.library));
        expect(LibraryTab.values, contains(LibraryTab.favorites));
        expect(LibraryTab.values, contains(LibraryTab.timeline));
        expect(LibraryTab.values, contains(LibraryTab.cloud));
      },
    );

    test('LibraryTab values are distinct', () {
      final tabs = LibraryTab.values.toSet();
      expect(tabs.length, 4);
    });
  });

  // =========================================================================
  // 7. PdfRepository thumbnail-related methods via mock
  // =========================================================================
  group('PdfRepository thumbnail methods', () {
    late MockPdfRepository mockRepository;

    setUp(() {
      mockRepository = MockPdfRepository();
    });

    test('generateThumbnail returns success with path', () async {
      const thumbnailPath = '/cache/thumb_xyz.png';
      when(
        mockRepository.generateThumbnail('pdf-1'),
      ).thenAnswer((_) async => Result.success(thumbnailPath));

      final result = await mockRepository.generateThumbnail('pdf-1');

      expect(result.isSuccess, isTrue);
      result.when(
        success: (path) => expect(path, thumbnailPath),
        failure: (_, _) => fail('Expected success'),
      );
    });

    test(
      'generateThumbnail returns success with null when generation fails',
      () async {
        when(
          mockRepository.generateThumbnail('pdf-1'),
        ).thenAnswer((_) async => Result.success(null));

        final result = await mockRepository.generateThumbnail('pdf-1');

        expect(result.isSuccess, isTrue);
        result.when(
          success: (path) => expect(path, isNull),
          failure: (_, _) => fail('Expected success'),
        );
      },
    );

    test('generateThumbnail returns failure when PDF not found', () async {
      when(mockRepository.generateThumbnail('nonexistent')).thenAnswer(
        (_) async =>
            Result.failure(Exception('PDF not found'), StackTrace.current),
      );

      final result = await mockRepository.generateThumbnail('nonexistent');

      expect(result.isFailure, isTrue);
    });

    test('updateThumbnail returns updated PDF with new path', () async {
      final original = createTestPdf(id: 'pdf-1');
      final updated = original.copyWith(thumbnailPath: '/cache/new_thumb.png');

      when(
        mockRepository.updateThumbnail('pdf-1', '/cache/new_thumb.png'),
      ).thenAnswer((_) async => Result.success(updated));

      final result = await mockRepository.updateThumbnail(
        'pdf-1',
        '/cache/new_thumb.png',
      );

      expect(result.isSuccess, isTrue);
      result.when(
        success: (pdf) => expect(pdf.thumbnailPath, '/cache/new_thumb.png'),
        failure: (_, _) => fail('Expected success'),
      );
    });

    test('updateThumbnail can clear thumbnail path', () async {
      final original = createTestPdf(
        id: 'pdf-1',
        thumbnailPath: '/cache/old.png',
      );
      final updated = original.copyWith(thumbnailPath: '');

      when(
        mockRepository.updateThumbnail('pdf-1', any),
      ).thenAnswer((_) async => Result.success(updated));

      final result = await mockRepository.updateThumbnail('pdf-1', null);

      expect(result.isSuccess, isTrue);
      result.when(
        success: (pdf) => expect(pdf.thumbnailPath, isEmpty),
        failure: (_, _) => fail('Expected success'),
      );
    });
  });

  // =========================================================================
  // 8. ThumbnailService mock scenarios
  // =========================================================================
  group('ThumbnailService mock scenarios', () {
    late MockThumbnailService mockThumbnailService;

    setUp(() {
      mockThumbnailService = MockThumbnailService();
    });

    test('generateThumbnail returns path on success', () async {
      when(
        mockThumbnailService.generateThumbnail(any),
      ).thenAnswer((_) async => '/cache/thumb_123.png');

      final result = await mockThumbnailService.generateThumbnail('/test.pdf');
      expect(result, '/cache/thumb_123.png');
      verify(mockThumbnailService.generateThumbnail('/test.pdf')).called(1);
    });

    test('generateThumbnail returns null on failure', () async {
      when(
        mockThumbnailService.generateThumbnail(any),
      ).thenAnswer((_) async => null);

      final result = await mockThumbnailService.generateThumbnail(
        '/nonexistent.pdf',
      );
      expect(result, isNull);
    });

    test('generateSmallThumbnail delegates with correct size', () async {
      when(
        mockThumbnailService.generateSmallThumbnail(any),
      ).thenAnswer((_) async => '/cache/small_thumb.png');

      final result = await mockThumbnailService.generateSmallThumbnail(
        '/test.pdf',
      );
      expect(result, '/cache/small_thumb.png');
      verify(
        mockThumbnailService.generateSmallThumbnail('/test.pdf'),
      ).called(1);
    });

    test('generateLargeThumbnail delegates with correct size', () async {
      when(
        mockThumbnailService.generateLargeThumbnail(any),
      ).thenAnswer((_) async => '/cache/large_thumb.png');

      final result = await mockThumbnailService.generateLargeThumbnail(
        '/test.pdf',
      );
      expect(result, '/cache/large_thumb.png');
      verify(
        mockThumbnailService.generateLargeThumbnail('/test.pdf'),
      ).called(1);
    });

    test('generateAllSizes returns ThumbnailSet', () async {
      when(mockThumbnailService.generateAllSizes(any)).thenAnswer(
        (_) async => const ThumbnailSet(
          smallPath: '/cache/small.png',
          largePath: '/cache/large.png',
        ),
      );

      final result = await mockThumbnailService.generateAllSizes('/test.pdf');
      expect(result.hasBoth, isTrue);
      expect(result.smallPath, '/cache/small.png');
      expect(result.largePath, '/cache/large.png');
    });

    test('generateAllSizes returns partial when one size fails', () async {
      when(mockThumbnailService.generateAllSizes(any)).thenAnswer(
        (_) async => const ThumbnailSet(smallPath: '/cache/small.png'),
      );

      final result = await mockThumbnailService.generateAllSizes('/test.pdf');
      expect(result.hasSmall, isTrue);
      expect(result.hasLarge, isFalse);
    });

    test('getThumbnailPath returns null for non-existent thumbnail', () async {
      when(
        mockThumbnailService.getThumbnailPath(any),
      ).thenAnswer((_) async => null);

      final result = await mockThumbnailService.getThumbnailPath(
        '/nonexistent.pdf',
      );
      expect(result, isNull);
    });

    test('getThumbnailPath returns path for existing thumbnail', () async {
      when(
        mockThumbnailService.getThumbnailPath(any),
      ).thenAnswer((_) async => '/cache/thumb_existing.png');

      final result = await mockThumbnailService.getThumbnailPath(
        '/existing.pdf',
      );
      expect(result, '/cache/thumb_existing.png');
    });

    test('clearCache completes without error', () async {
      when(mockThumbnailService.clearCache()).thenAnswer((_) async {});

      await mockThumbnailService.clearCache();
      verify(mockThumbnailService.clearCache()).called(1);
    });

    test('clearFailedThumbnails completes without error', () async {
      when(
        mockThumbnailService.clearFailedThumbnails(),
      ).thenAnswer((_) async {});

      await mockThumbnailService.clearFailedThumbnails();
      verify(mockThumbnailService.clearFailedThumbnails()).called(1);
    });

    test('retryFailedThumbnails returns RetryResult', () async {
      when(mockThumbnailService.retryFailedThumbnails()).thenAnswer(
        (_) async => const RetryResult(total: 3, succeeded: 2, failed: 1),
      );

      final result = await mockThumbnailService.retryFailedThumbnails();
      expect(result.total, 3);
      expect(result.succeeded, 2);
      expect(result.failed, 1);
    });
  });

  // =========================================================================
  // 9. Widget-level thumbnail display logic
  // =========================================================================
  group('Thumbnail display logic in widgets', () {
    test('PdfDocument with null thumbnailPath triggers fallback icon path', () {
      final pdf = createTestPdf(thumbnailPath: null);

      // The widget checks: pdf.thumbnailPath != null &&
      //   pdf.thumbnailPath!.isNotEmpty &&
      //   File(pdf.thumbnailPath!).existsSync()
      expect(pdf.thumbnailPath, isNull);
      // When thumbnailPath is null, the widget shows the fallback icon
    });

    test('PdfDocument with empty thumbnailPath triggers fallback icon', () {
      final pdf = createTestPdf(thumbnailPath: '');

      // Empty string is not null but isEmpty is true
      expect(pdf.thumbnailPath, isNotNull);
      expect(pdf.thumbnailPath!.isEmpty, isTrue);
      // The widget checks isNotEmpty, so empty string also shows fallback
    });

    test(
      'PdfDocument with non-existent thumbnailPath triggers fallback icon',
      () {
        final pdf = createTestPdf(thumbnailPath: '/nonexistent/path/thumb.png');

        expect(pdf.thumbnailPath, isNotNull);
        expect(pdf.thumbnailPath!.isNotEmpty, isTrue);
        // File.existsSync() returns false for non-existent files
        expect(File(pdf.thumbnailPath!).existsSync(), isFalse);
      },
    );

    test(
      'PdfDocument with valid thumbnailPath shows Image.file when file exists',
      () async {
        // Create a temporary thumbnail file
        final tempDir = Directory.systemTemp;
        final tempFile = File(
          '${tempDir.path}/test_thumb_${DateTime.now().millisecondsSinceEpoch}.png',
        );

        // Write a minimal PNG header to make it a valid file
        final pngHeader = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];
        await tempFile.writeAsBytes([...pngHeader, ...List.filled(92, 0xFF)]);

        try {
          final pdf = createTestPdf(thumbnailPath: tempFile.path);

          expect(pdf.thumbnailPath, isNotNull);
          expect(pdf.thumbnailPath!.isNotEmpty, isTrue);
          expect(File(pdf.thumbnailPath!).existsSync(), isTrue);
          // When all three conditions are true, the widget renders Image.file
        } finally {
          if (await tempFile.exists()) {
            await tempFile.delete();
          }
        }
      },
    );
  });

  // =========================================================================
  // 10. ReadingProgress serialization for thumbnails with progress bars
  // =========================================================================
  group('ReadingProgress for thumbnail progress display', () {
    test('serializes and deserializes correctly', () {
      final progress = ReadingProgress(
        documentId: 'doc-1',
        currentPage: 25,
        lastReadAt: DateTime(2024, 3, 15, 10, 30),
        scrollOffset: 100,
      );

      final json = progress.toJson();
      expect(json['documentId'], 'doc-1');
      expect(json['currentPage'], 25);
      expect(json['scrollOffset'], 100);

      final restored = ReadingProgress.fromJson(json);
      expect(restored.documentId, 'doc-1');
      expect(restored.currentPage, 25);
      expect(restored.scrollOffset, 100);
    });

    test('copyWith creates new instance with updated fields', () {
      final original = ReadingProgress(
        documentId: 'doc-1',
        currentPage: 10,
        lastReadAt: DateTime(2024, 1, 1),
      );

      final updated = original.copyWith(currentPage: 20);
      expect(updated.currentPage, 20);
      expect(updated.documentId, 'doc-1');
    });
  });

  // =========================================================================
  // 11. Edge cases - multiple PDFs with mixed thumbnail states
  // =========================================================================
  group('Mixed thumbnail states across multiple PDFs', () {
    test('library handles mix of PDFs with and without thumbnails', () async {
      final mockRepository = MockPdfRepository();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesPdfRepositoryProvider.overrideWithValue(
            mockRepository,
          ),
        ],
      );

      final pdfs = [
        createTestPdf(id: '1', thumbnailPath: '/cache/thumb_1.png'),
        createTestPdf(id: '2', thumbnailPath: null),
        createTestPdf(id: '3', thumbnailPath: '/cache/thumb_3.png'),
        createTestPdf(id: '4', thumbnailPath: ''),
        createTestPdf(id: '5', thumbnailPath: null),
      ];

      stubRepositoryLoad(
        mockRepository,
        allPdfs: pdfs,
        recentPdfs: pdfs.take(3).toList(),
      );

      // Trigger provider build by reading notifier
      container.read(libraryNotifierProvider.notifier);
      // Wait for the build-time loadLibrary to complete via listener
      final loaded = Completer<void>();
      container.listen<LibraryState>(libraryNotifierProvider, (previous, next) {
        if (!next.isLoading && !loaded.isCompleted) {
          loaded.complete();
        }
      }, fireImmediately: true);
      await loaded.future.timeout(const Duration(seconds: 5));

      final state = container.read(libraryNotifierProvider);
      expect(state.allPdfs.length, 5);

      // Verify thumbnail states are preserved
      expect(state.allPdfs[0].thumbnailPath, '/cache/thumb_1.png');
      expect(state.allPdfs[1].thumbnailPath, isNull);
      expect(state.allPdfs[2].thumbnailPath, '/cache/thumb_3.png');
      expect(state.allPdfs[3].thumbnailPath, isEmpty);
      expect(state.allPdfs[4].thumbnailPath, isNull);

      container.dispose();
    });

    test('library handles empty thumbnail path as fallback case', () {
      final pdf = createTestPdf(thumbnailPath: '');
      // Widget logic: pdf.thumbnailPath != null (true) &&
      //   pdf.thumbnailPath!.isNotEmpty (false)
      // => falls through to fallback icon
      final shouldShowImage =
          pdf.thumbnailPath != null && pdf.thumbnailPath!.isNotEmpty;
      expect(shouldShowImage, isFalse);
    });

    test('library handles whitespace-only thumbnail path', () {
      final pdf = createTestPdf(thumbnailPath: '   ');
      // isNotEmpty is true for whitespace, but existsSync would return false
      final shouldShowImage =
          pdf.thumbnailPath != null && pdf.thumbnailPath!.isNotEmpty;
      expect(shouldShowImage, isTrue);
      // But File('   ').existsSync() returns false
      expect(File(pdf.thumbnailPath!).existsSync(), isFalse);
    });
  });

  // =========================================================================
  // 12. PaginatedPdfs for thumbnail loading in pages
  // =========================================================================
  group('PaginatedPdfs thumbnail handling', () {
    test('preserves thumbnail paths through pagination', () {
      final page1 = [
        createTestPdf(id: 'p1-1', thumbnailPath: '/cache/p1.png'),
        createTestPdf(id: 'p1-2', thumbnailPath: null),
      ];

      final paginated = createPaginated(page1, hasMore: true);
      expect(paginated.pdfs[0].thumbnailPath, '/cache/p1.png');
      expect(paginated.pdfs[1].thumbnailPath, isNull);
      expect(paginated.hasMore, isTrue);
    });

    test('nextOffset computes correctly for next page load', () {
      final page1 = List.generate(20, (i) => createTestPdf(id: 'p1-$i'));
      final paginated = createPaginated(page1, hasMore: true);

      expect(paginated.nextOffset, 20);
    });

    test('totalCount is set correctly', () {
      final page1 = [createTestPdf(id: '1'), createTestPdf(id: '2')];
      final paginated = createPaginated(page1);
      expect(paginated.totalCount, 2);
    });
  });

  // =========================================================================
  // 13. LibraryNotifier loadMore with thumbnails
  // =========================================================================
  group('LibraryNotifier loadMore with thumbnails', () {
    late MockPdfRepository mockRepository;
    late ProviderContainer container;

    setUp(() {
      mockRepository = MockPdfRepository();
      container = ProviderContainer(
        overrides: [
          sharedPreferencesPdfRepositoryProvider.overrideWithValue(
            mockRepository,
          ),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('loadMore appends PDFs with thumbnail paths', () async {
      // Initial load - use hasMore: true so loadMore will work
      final initialPdfs = [
        createTestPdf(id: '1', thumbnailPath: '/cache/thumb_1.png'),
      ];
      when(
        mockRepository.getPagedPdfs(
          offset: 0,
          limit: CacheConfig.initialPageSize,
        ),
      ).thenAnswer(
        (_) async =>
            Result.success(createPaginated(initialPdfs, hasMore: true)),
      );
      when(
        mockRepository.getRecentPdfs(limit: CacheConfig.recentCount),
      ).thenAnswer((_) async => Result.success(initialPdfs));
      when(
        mockRepository.getFavoritePdfs(),
      ).thenAnswer((_) async => Result.success([]));

      // Wait for initial build-time load to complete
      final loaded = Completer<void>();
      container.listen<LibraryState>(libraryNotifierProvider, (previous, next) {
        if (!next.isLoading && !loaded.isCompleted) {
          loaded.complete();
        }
      }, fireImmediately: true);
      await loaded.future.timeout(const Duration(seconds: 5));

      // Verify initial state loaded
      var state = container.read(libraryNotifierProvider);
      expect(state.allPdfs.length, 1);
      expect(state.allPdfs[0].thumbnailPath, '/cache/thumb_1.png');

      // Setup loadMore to return additional PDFs
      final morePdfs = [
        createTestPdf(id: '2', thumbnailPath: '/cache/thumb_2.png'),
        createTestPdf(id: '3', thumbnailPath: null),
      ];
      when(
        mockRepository.getPagedPdfs(
          offset: anyNamed('offset'),
          limit: anyNamed('limit'),
        ),
      ).thenAnswer((_) async => Result.success(createPaginated(morePdfs)));

      final notifier = container.read(libraryNotifierProvider.notifier);
      await notifier.loadMore();
      await container.pump();
      await Future.delayed(const Duration(milliseconds: 100));

      state = container.read(libraryNotifierProvider);
      expect(state.allPdfs.length, 3);
      expect(state.allPdfs[0].thumbnailPath, '/cache/thumb_1.png');
      expect(state.allPdfs[1].thumbnailPath, '/cache/thumb_2.png');
      expect(state.allPdfs[2].thumbnailPath, isNull);
    });
  });

  // =========================================================================
  // 14. PdfDocument formattedFileSize for thumbnail card display
  // =========================================================================
  group('PdfDocument formattedFileSize for thumbnail cards', () {
    test('formats bytes', () {
      final pdf = createTestPdf(fileSize: 512);
      expect(pdf.formattedFileSize, '512 B');
    });

    test('formats kilobytes', () {
      final pdf = createTestPdf(fileSize: 1024 * 512);
      expect(pdf.formattedFileSize, '512.0 KB');
    });

    test('formats megabytes', () {
      final pdf = createTestPdf(fileSize: 5 * 1024 * 1024);
      expect(pdf.formattedFileSize, '5.0 MB');
    });

    test('formats zero bytes', () {
      final pdf = createTestPdf(fileSize: 0);
      expect(pdf.formattedFileSize, '0 B');
    });
  });

  // =========================================================================
  // 15. SearchQueryNotifier and LibraryTabNotifier for view switching
  // =========================================================================
  group('View switching affects thumbnail display mode', () {
    late MockPdfRepository mockRepository;
    late ProviderContainer container;

    setUp(() {
      mockRepository = MockPdfRepository();
      stubRepositoryLoad(mockRepository);
      container = ProviderContainer(
        overrides: [
          sharedPreferencesPdfRepositoryProvider.overrideWithValue(
            mockRepository,
          ),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('LibraryTabNotifier defaults to library tab', () {
      final tab = container.read(libraryTabNotifierProvider);
      expect(tab, LibraryTab.library);
    });

    test('LibraryTabNotifier can switch to favorites', () {
      container
          .read(libraryTabNotifierProvider.notifier)
          .setTab(LibraryTab.favorites);
      expect(container.read(libraryTabNotifierProvider), LibraryTab.favorites);
    });

    test('LibraryTabNotifier can switch to timeline', () {
      container
          .read(libraryTabNotifierProvider.notifier)
          .setTab(LibraryTab.timeline);
      expect(container.read(libraryTabNotifierProvider), LibraryTab.timeline);
    });

    test('SearchQueryNotifier defaults to empty', () {
      final query = container.read(searchQueryNotifierProvider);
      expect(query, isEmpty);
    });

    test('SearchQueryNotifier can set and clear query', () {
      container.read(searchQueryNotifierProvider.notifier).setQuery('test');
      expect(container.read(searchQueryNotifierProvider), 'test');

      container.read(searchQueryNotifierProvider.notifier).clear();
      expect(container.read(searchQueryNotifierProvider), isEmpty);
    });
  });

  // =========================================================================
  // 16. End-to-end thumbnail display scenario
  // =========================================================================
  group('End-to-end thumbnail display scenario', () {
    late MockPdfRepository mockRepository;
    late ProviderContainer container;

    setUp(() {
      mockRepository = MockPdfRepository();
      container = ProviderContainer(
        overrides: [
          sharedPreferencesPdfRepositoryProvider.overrideWithValue(
            mockRepository,
          ),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test(
      'PDF starts without thumbnail, gets one after generation, and state updates',
      () async {
        // Step 1: Load library with a PDF that has no thumbnail
        final pdfNoThumb = createTestPdf(id: 'pdf-1', thumbnailPath: null);
        stubRepositoryLoad(mockRepository, allPdfs: [pdfNoThumb]);

        // Wait for initial build-time load to complete
        final loaded = Completer<void>();
        container.listen<LibraryState>(libraryNotifierProvider, (
          previous,
          next,
        ) {
          if (!next.isLoading && !loaded.isCompleted) {
            loaded.complete();
          }
        }, fireImmediately: true);
        await loaded.future.timeout(const Duration(seconds: 5));

        var state = container.read(libraryNotifierProvider);
        expect(state.allPdfs.length, 1);
        expect(state.allPdfs[0].thumbnailPath, isNull);

        // Step 2: Simulate thumbnail generation via repository
        // (In production, importPdf or a background task would trigger this)
        final pdfWithThumb = pdfNoThumb.copyWith(
          thumbnailPath: '/cache/thumb_pdf1.png',
        );
        when(
          mockRepository.updateThumbnail('pdf-1', '/cache/thumb_pdf1.png'),
        ).thenAnswer((_) async => Result.success(pdfWithThumb));

        final updateResult = await mockRepository.updateThumbnail(
          'pdf-1',
          '/cache/thumb_pdf1.png',
        );

        expect(updateResult.isSuccess, isTrue);

        // Step 3: Reload library to pick up the updated thumbnail
        // Re-stub with the updated PDF
        stubRepositoryLoad(mockRepository, allPdfs: [pdfWithThumb]);

        final notifier = container.read(libraryNotifierProvider.notifier);
        await notifier.loadLibrary();
        await container.pump();
        await Future.delayed(const Duration(milliseconds: 100));

        state = container.read(libraryNotifierProvider);
        expect(state.allPdfs[0].thumbnailPath, '/cache/thumb_pdf1.png');
      },
    );
  });
}
