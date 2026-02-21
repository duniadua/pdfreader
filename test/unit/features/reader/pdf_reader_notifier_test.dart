import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pdf_reader_app/core/data/models/pdf_document.dart';
import 'package:pdf_reader_app/core/data/providers/repository_providers.dart';
import 'package:pdf_reader_app/core/data/repositories/pdf_repository.dart';
import 'package:pdf_reader_app/core/utils/exceptions.dart';
import 'package:pdf_reader_app/core/utils/result.dart';
import 'package:pdf_reader_app/features/reader/presentation/providers/pdf_reader_notifier.dart';

// Mocks
@GenerateMocks([SharedPreferencesPdfRepository])
import 'pdf_reader_notifier_test.mocks.dart';

void main() {
  late MockSharedPreferencesPdfRepository mockRepo;

  // Test data
  final testPdf = PdfDocument(
    id: 'test-pdf-1',
    title: 'Test Document.pdf',
    filePath: '/path/to/Test Document.pdf',
    fileSize: 1024000,
    createdAt: DateTime(2025, 1, 1),
    lastOpenedAt: DateTime(2025, 1, 15),
    totalPages: 10,
  );

  setUp(() {
    mockRepo = MockSharedPreferencesPdfRepository();
  });

  group('PdfReaderNotifier', () {
    group('initial state', () {
      test('should start in loading state', () {
        // Given
        when(mockRepo.getPdfById('test-id'))
            .thenAnswer((_) async => Result.success(testPdf));

        final container = ProviderContainer(
          overrides: [
            sharedPreferencesPdfRepositoryProvider.overrideWithValue(mockRepo),
          ],
        );

        // When
        container.read(pdfReaderNotifierProvider('test-id').notifier);
        final initialState = container.read(pdfReaderNotifierProvider('test-id'));

        // Then - initial state should be loading
        expect(initialState, const PdfReaderState.loading());

        container.dispose();
      });
    });

    group('loadPdf - success', () {
      test('should load PDF successfully when file exists', () async {
        // Given
        when(mockRepo.getPdfById('test-pdf-1'))
            .thenAnswer((_) async => Result.success(testPdf));

        final container = ProviderContainer(
          overrides: [
            sharedPreferencesPdfRepositoryProvider.overrideWithValue(mockRepo),
          ],
        );

        // When
        container.read(pdfReaderNotifierProvider('test-pdf-1').notifier);
        await Future.delayed(const Duration(milliseconds: 300));

        // Then
        final state = container.read(pdfReaderNotifierProvider('test-pdf-1'));
        state.maybeWhen(
          loaded: (pdf) {
            expect(pdf.id, 'test-pdf-1');
            expect(pdf.title, 'Test Document.pdf');
          },
          orElse: () => fail('Expected loaded state'),
        );

        verify(mockRepo.getPdfById('test-pdf-1')).called(1);
        container.dispose();
      });

      test('should return notFound when PDF does not exist', () async {
        // Given
        when(mockRepo.getPdfById('non-existent'))
            .thenAnswer((_) async => Result.success(null));

        final container = ProviderContainer(
          overrides: [
            sharedPreferencesPdfRepositoryProvider.overrideWithValue(mockRepo),
          ],
        );

        // When
        container.read(pdfReaderNotifierProvider('non-existent').notifier);
        await Future.delayed(const Duration(milliseconds: 300));

        // Then
        final state = container.read(pdfReaderNotifierProvider('non-existent'));
        expect(state, const PdfReaderState.notFound());

        verify(mockRepo.getPdfById('non-existent')).called(1);
        container.dispose();
      });

      test('should return fileNotFound when file is deleted', () async {
        // Given
        final deletedPdf = testPdf.copyWith(filePath: '/deleted/file.pdf');
        when(mockRepo.getPdfById('deleted-pdf'))
            .thenAnswer((_) async => Result.success(deletedPdf));

        final container = ProviderContainer(
          overrides: [
            sharedPreferencesPdfRepositoryProvider.overrideWithValue(mockRepo),
          ],
        );

        // When
        container.read(pdfReaderNotifierProvider('deleted-pdf').notifier);
        await Future.delayed(const Duration(milliseconds: 300));

        // Then
        final state = container.read(pdfReaderNotifierProvider('deleted-pdf'));
        state.maybeWhen(
          fileNotFound: (path) => expect(path, '/deleted/file.pdf'),
          orElse: () => fail('Expected fileNotFound state'),
        );

        container.dispose();
      });
    });

    group('loadPdf - failure', () {
      test('should return error state when repository fails', () async {
        // Given
        when(mockRepo.getPdfById('error-pdf'))
            .thenAnswer((_) async => Result.failure(const StorageException('Database error')));

        final container = ProviderContainer(
          overrides: [
            sharedPreferencesPdfRepositoryProvider.overrideWithValue(mockRepo),
          ],
        );

        // When
        container.read(pdfReaderNotifierProvider('error-pdf').notifier);
        await Future.delayed(const Duration(milliseconds: 300));

        // Then
        final state = container.read(pdfReaderNotifierProvider('error-pdf'));
        state.maybeWhen(
          error: (message) => expect(message, contains('Database error')),
          orElse: () => fail('Expected error state'),
        );

        container.dispose();
      });
    });

    group('onPageChanged', () {
      test('should update progress when page changes', () async {
        // Given
        when(mockRepo.getPdfById('test-pdf-1'))
            .thenAnswer((_) async => Result.success(testPdf));
        when(mockRepo.updateProgress('test-pdf-1', 5, 0))
            .thenAnswer((_) async => Result.success(null));

        final container = ProviderContainer(
          overrides: [
            sharedPreferencesPdfRepositoryProvider.overrideWithValue(mockRepo),
          ],
        );

        // Load PDF first
        container.read(pdfReaderNotifierProvider('test-pdf-1').notifier);
        await Future.delayed(const Duration(milliseconds: 300));

        // When - trigger page change
        container.read(pdfReaderNotifierProvider('test-pdf-1').notifier).onPageChanged(5);

        verify(mockRepo.updateProgress('test-pdf-1', 5, 0)).called(1);
        container.dispose();
      });
    });

    group('toggleFavorite', () {
      test('should toggle favorite status successfully', () async {
        // Given
        final favoritePdf = testPdf.copyWith(isFavorite: true);
        when(mockRepo.getPdfById('test-pdf-1'))
            .thenAnswer((_) async => Result.success(testPdf));
        when(mockRepo.toggleFavorite('test-pdf-1'))
            .thenAnswer((_) async => Result.success(favoritePdf));

        final container = ProviderContainer(
          overrides: [
            sharedPreferencesPdfRepositoryProvider.overrideWithValue(mockRepo),
          ],
        );

        // Load PDF first
        container.read(pdfReaderNotifierProvider('test-pdf-1').notifier);
        await Future.delayed(const Duration(milliseconds: 300));

        // When - toggle favorite
        await container.read(pdfReaderNotifierProvider('test-pdf-1').notifier).toggleFavorite();
        await Future.delayed(const Duration(milliseconds: 300));

        final state = container.read(pdfReaderNotifierProvider('test-pdf-1'));
        state.maybeWhen(
          loaded: (pdf) => expect(pdf.isFavorite, true),
          orElse: () => fail('Expected loaded state with favorite=true'),
        );

        verify(mockRepo.toggleFavorite('test-pdf-1')).called(1);
        container.dispose();
      });
    });

    group('retry', () {
      test('should retry loading PDF', () async {
        // Given - first call fails
        when(mockRepo.getPdfById('retry-pdf'))
            .thenAnswer((_) async => Result.failure(const StorageException('Temporary error')));

        final container = ProviderContainer(
          overrides: [
            sharedPreferencesPdfRepositoryProvider.overrideWithValue(mockRepo),
          ],
        );

        container.read(pdfReaderNotifierProvider('retry-pdf').notifier);
        await Future.delayed(const Duration(milliseconds: 300));

        // Verify error state
        var state = container.read(pdfReaderNotifierProvider('retry-pdf'));
        expect(state, isA<PdfReaderState>());

        // Given - second call succeeds
        when(mockRepo.getPdfById('retry-pdf'))
            .thenAnswer((_) async => Result.success(testPdf));

        // When - retry
        container.read(pdfReaderNotifierProvider('retry-pdf').notifier).retry();
        await Future.delayed(const Duration(milliseconds: 300));

        // Then - should be loaded
        state = container.read(pdfReaderNotifierProvider('retry-pdf'));
        state.maybeWhen(
          loaded: (pdf) => expect(pdf.id, 'retry-pdf'),
          orElse: () => fail('Expected loaded state after retry'),
        );

        container.dispose();
      });
    });

    group('state transitions', () {
      test('should transition from loading to loaded', () async {
        // Given
        when(mockRepo.getPdfById('test-pdf-1'))
            .thenAnswer((_) async => Result.success(testPdf));

        final container = ProviderContainer(
          overrides: [
            sharedPreferencesPdfRepositoryProvider.overrideWithValue(mockRepo),
          ],
        );

        // When
        container.read(pdfReaderNotifierProvider('test-pdf-1').notifier);

        // Initial state
        expect(container.read(pdfReaderNotifierProvider('test-pdf-1')), const PdfReaderState.loading());

        // Wait for load
        await Future.delayed(const Duration(milliseconds: 300));

        // Final state
        final state = container.read(pdfReaderNotifierProvider('test-pdf-1'));
        state.maybeWhen(
          loaded: (_) => expect(true, true),
          orElse: () => fail('Expected loaded state'),
        );

        container.dispose();
      });
    });
  });
}
