import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pdf_reader_app/core/cache/cache_config.dart';
import 'package:pdf_reader_app/core/data/models/pdf_document.dart';
import 'package:pdf_reader_app/core/data/repositories/pdf_repository.dart';
import 'package:pdf_reader_app/core/data/providers/repository_providers.dart';
import 'package:pdf_reader_app/core/utils/result.dart';
import 'package:pdf_reader_app/features/library/presentation/providers/library_notifier.dart';

@GenerateMocks([PdfRepository])
import 'library_notifier_test.mocks.dart';

/// Helper to create a PaginatedPdfs result
PaginatedPdfs createPaginated(List<PdfDocument> pdfs, {bool hasMore = false}) {
  return PaginatedPdfs(
    pdfs: pdfs,
    offset: 0,
    limit: pdfs.length,
    hasMore: hasMore,
    totalCount: pdfs.length,
  );
}

void main() {
  late MockPdfRepository mockRepository;
  late ProviderContainer container;

  setUp(() {
    mockRepository = MockPdfRepository();
    container = ProviderContainer(
      overrides: [
        sharedPreferencesPdfRepositoryProvider.overrideWithValue(mockRepository),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('LibraryNotifier', () {
    test('should load PDFs from repository on init', () async {
      final testPdfs = [
        PdfDocument(
          id: '1',
          title: 'Test PDF',
          filePath: '/path/to/test.pdf',
          fileSize: 1024 * 1024,
          createdAt: DateTime(2024, 1, 15),
          lastOpenedAt: DateTime(2024, 1, 15),
          totalPages: 100,
        ),
      ];

      when(mockRepository.getPagedPdfs(offset: 0, limit: CacheConfig.initialPageSize))
          .thenAnswer((_) async => Result.success(createPaginated(testPdfs)));
      when(mockRepository.getRecentPdfs(limit: CacheConfig.recentCount))
          .thenAnswer((_) async => Result.success(testPdfs));
      when(mockRepository.getFavoritePdfs()).thenAnswer(
        (_) async => Result.success([]),
      );

      container.read(libraryNotifierProvider.notifier);
      // Wait for the async loadLibrary (called from build) to complete
      await Future.delayed(Duration(milliseconds: 300));
      await container.pump();
      await container.pump();

      final state = container.read(libraryNotifierProvider);
      expect(state.isLoading, false);
      expect(state.allPdfs.length, 1);
      verify(mockRepository.getPagedPdfs(offset: 0, limit: CacheConfig.initialPageSize))
          .called(1);
    });

    test('should load PDFs from repository on init', () async {
      final testPdfs = [
        PdfDocument(
          id: '1',
          title: 'Test PDF',
          filePath: '/path/to/test.pdf',
          fileSize: 1024 * 1024,
          createdAt: DateTime(2024, 1, 15),
          lastOpenedAt: DateTime(2024, 1, 15),
          totalPages: 100,
        ),
      ];

      when(mockRepository.getPagedPdfs(offset: 0, limit: CacheConfig.initialPageSize))
          .thenAnswer((_) async => Result.success(createPaginated(testPdfs)));
      when(mockRepository.getRecentPdfs(limit: CacheConfig.recentCount))
          .thenAnswer((_) async => Result.success(testPdfs));
      when(mockRepository.getFavoritePdfs()).thenAnswer(
        (_) async => Result.success([]),
      );

      container.read(libraryNotifierProvider.notifier);
      // Wait for the async loadLibrary (called from build) to complete
      await Future.delayed(Duration(milliseconds: 200));
      await container.pump();

      final state = container.read(libraryNotifierProvider);
      expect(state.isLoading, false);
      expect(state.allPdfs.length, 1);
      verify(mockRepository.getPagedPdfs(offset: 0, limit: CacheConfig.initialPageSize))
          .called(1);
    });

    test('should set failure state when repository fails', () async {
      when(mockRepository.getPagedPdfs(offset: 0, limit: CacheConfig.initialPageSize))
          .thenAnswer((_) async => Result.failure(Exception('Failed to load')));
      when(mockRepository.getRecentPdfs(limit: CacheConfig.recentCount))
          .thenAnswer((_) async => Result.success([]));
      when(mockRepository.getFavoritePdfs())
          .thenAnswer((_) async => Result.success([]));

      container.read(libraryNotifierProvider.notifier);
      // Wait for the async loadLibrary (called from build) to complete
      await Future.delayed(Duration(milliseconds: 200));
      await container.pump();

      final state = container.read(libraryNotifierProvider);
      expect(state.isLoading, false);
      expect(state.failure, isNotNull);
      expect(state.failure!.message, contains('Failed to load'));
    });
  });

  group('LibraryNotifier.toggleFavorite', () {
    test('should call repository toggleFavorite', () async {
      when(mockRepository.getPagedPdfs(offset: 0, limit: CacheConfig.initialPageSize))
          .thenAnswer((_) async => Result.success(createPaginated([])));
      when(mockRepository.getRecentPdfs(limit: CacheConfig.recentCount))
          .thenAnswer((_) async => Result.success([]));
      when(mockRepository.getFavoritePdfs())
          .thenAnswer((_) async => Result.success([]));
      when(mockRepository.toggleFavorite('test-id')).thenAnswer(
        (_) async => Result.success(
          PdfDocument(
            id: '1',
            title: 'Test',
            filePath: '/path/test.pdf',
            fileSize: 1024,
            createdAt: DateTime.now(),
            lastOpenedAt: DateTime.now(),
            totalPages: 10,
            isFavorite: true,
          ),
        ),
      );

      container.read(libraryNotifierProvider.notifier);
      await container.pump();
      await container.read(libraryNotifierProvider.notifier).toggleFavorite('test-id');
      await container.pump();

      verify(mockRepository.toggleFavorite('test-id')).called(1);
    });
  });

  group('LibraryNotifier.deletePdf', () {
    test('should call repository deletePdf', () async {
      when(mockRepository.getPagedPdfs(offset: 0, limit: CacheConfig.initialPageSize))
          .thenAnswer((_) async => Result.success(createPaginated([])));
      when(mockRepository.getRecentPdfs(limit: CacheConfig.recentCount))
          .thenAnswer((_) async => Result.success([]));
      when(mockRepository.getFavoritePdfs())
          .thenAnswer((_) async => Result.success([]));
      when(mockRepository.deletePdf('test-id'))
          .thenAnswer((_) async => Result.success(null));

      container.read(libraryNotifierProvider.notifier);
      await container.pump();
      await container.read(libraryNotifierProvider.notifier).deletePdf('test-id');
      await container.pump();

      verify(mockRepository.deletePdf('test-id')).called(1);
    });
  });

  group('LibraryNotifier.dismissFailure', () {
    test('should dismiss failure state', () async {
      when(mockRepository.getPagedPdfs(offset: 0, limit: CacheConfig.initialPageSize))
          .thenAnswer((_) async => Result.success(createPaginated([])));
      when(mockRepository.getRecentPdfs(limit: CacheConfig.recentCount))
          .thenAnswer((_) async => Result.success([]));
      when(mockRepository.getFavoritePdfs())
          .thenAnswer((_) async => Result.success([]));

      final notifier = container.read(libraryNotifierProvider.notifier);
      await Future.delayed(Duration(milliseconds: 100));
      await container.pump();
      notifier.dismissFailure();

      final state = container.read(libraryNotifierProvider);
      expect(state.failure, isNull);
    });
  });
}
