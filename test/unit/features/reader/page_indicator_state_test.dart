import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_reader_app/core/data/models/pdf_document.dart';
import 'package:pdf_reader_app/features/reader/presentation/providers/pdf_reader_notifier.dart';

void main() {
  group('Page Indicator State Tests', () {
    group('PdfDocument State', () {
      test('should store current page correctly', () {
        // Arrange
        final progress = ReadingProgress(
          documentId: 'test-pdf-1',
          currentPage: 5,
          lastReadAt: DateTime.now(),
        );

        final pdf = PdfDocument(
          id: 'test-pdf-1',
          title: 'Test PDF',
          filePath: '/path/to/test.pdf',
          fileSize: 1024 * 1024,
          createdAt: DateTime.now(),
          lastOpenedAt: DateTime.now(),
          totalPages: 10,
          progress: progress,
        );

        // Assert
        expect(pdf.progress?.currentPage, 5);
        expect(pdf.totalPages, 10);
      });

      test('should calculate progress percentage correctly', () {
        // Arrange
        final progress = ReadingProgress(
          documentId: 'test-pdf-2',
          currentPage: 5,
          lastReadAt: DateTime.now(),
        );

        final pdf = PdfDocument(
          id: 'test-pdf-2',
          title: 'Test PDF',
          filePath: '/path/to/test.pdf',
          fileSize: 1024 * 1024,
          createdAt: DateTime.now(),
          lastOpenedAt: DateTime.now(),
          totalPages: 10,
          progress: progress,
        );

        // Act & Assert
        expect(pdf.progressPercentage, 0.5); // 5/10 = 50%
      });

      test('should handle zero total pages gracefully', () {
        // Arrange
        final pdf = PdfDocument(
          id: 'test-pdf-3',
          title: 'Empty PDF',
          filePath: '/path/to/empty.pdf',
          fileSize: 0,
          createdAt: DateTime.now(),
          lastOpenedAt: DateTime.now(),
          totalPages: 0,
          progress: null,
        );

        // Act & Assert
        expect(pdf.progressPercentage, 0.0);
      });
    });

    group('Slider Position Calculation', () {
      test('should map page 1 to slider value 0.0', () {
        // Arrange
        const currentPage = 1;
        const totalPages = 8;

        // Act
        final scrollPosition = totalPages > 1
            ? (currentPage - 1) / (totalPages - 1)
            : 0.0;

        // Assert
        expect(scrollPosition, 0.0);
      });

      test('should map middle page to correct slider value', () {
        // Arrange
        const currentPage = 4;
        const totalPages = 8;

        // Act
        final scrollPosition = totalPages > 1
            ? (currentPage - 1) / (totalPages - 1)
            : 0.0;

        // Assert
        // (4-1)/(8-1) = 3/7 = ~0.428
        expect(scrollPosition, closeTo(0.428, 0.001));
      });

      test('should map last page to slider value 1.0', () {
        // Arrange
        const currentPage = 8;
        const totalPages = 8;

        // Act
        final scrollPosition = totalPages > 1
            ? (currentPage - 1) / (totalPages - 1)
            : 0.0;

        // Assert
        // (8-1)/(8-1) = 7/7 = 1.0
        expect(scrollPosition, 1.0);
      });

      test('should handle single page PDF', () {
        // Arrange
        const currentPage = 1;
        const totalPages = 1;

        // Act
        final scrollPosition = totalPages > 1
            ? (currentPage - 1) / (totalPages - 1)
            : 0.0;

        // Assert
        // Division by zero prevented by condition
        expect(scrollPosition, 0.0);
      });
    });

    group('Inverse Calculation (Slider to Page)', () {
      test('should map slider value 0.0 to page 1', () {
        // Arrange
        const sliderValue = 0.0;
        const totalPages = 8;

        // Act
        final newPage = (sliderValue * (totalPages - 1)).round() + 1;

        // Assert
        expect(newPage, 1);
      });

      test('should map slider value 0.43 to page 4', () {
        // Arrange
        const sliderValue = 0.43; // ~3/7 for page 4
        const totalPages = 8;

        // Act
        final newPage = (sliderValue * (totalPages - 1)).round() + 1;

        // Assert
        // (0.43 * 7).round() + 1 = 3.round() + 1 = 4
        expect(newPage, 4);
      });

      test('should map slider value 1.0 to last page', () {
        // Arrange
        const sliderValue = 1.0;
        const totalPages = 8;

        // Act
        final newPage = (sliderValue * (totalPages - 1)).round() + 1;

        // Assert
        // (1.0 * 7).round() + 1 = 8
        expect(newPage, 8);
      });

      test('should clamp page number to valid range', () {
        // Arrange
        const sliderValue = 1.5; // Beyond maximum
        const totalPages = 8;

        // Act
        final rawPage = (sliderValue * (totalPages - 1)).round() + 1;
        final clampedPage = rawPage.clamp(1, totalPages);

        // Assert
        // (1.5 * 7).round() + 1 = 11 → clamped to 8
        expect(clampedPage, 8);
      });

      test('should clamp minimum page number', () {
        // Arrange
        const sliderValue = -0.5; // Below minimum
        const totalPages = 8;

        // Act
        final rawPage = (sliderValue * (totalPages - 1)).round() + 1;
        final clampedPage = rawPage.clamp(1, totalPages);

        // Assert
        // (-0.5 * 7).round() + 1 = -3 → clamped to 1
        expect(clampedPage, 1);
      });
    });

    group('PdfReaderState State Changes', () {
      test('should track state transitions', () {
        // Arrange
        const initialState = PdfReaderState.loading();

        // Assert
        expect(initialState, isA<PdfReaderState>());
        expect(
          initialState.maybeWhen(
            loading: () => true,
            orElse: () => false,
          ),
          true,
        );
      });

      test('should store loaded PDF with progress', () {
        // Arrange
        final progress = ReadingProgress(
          documentId: 'test-loaded',
          currentPage: 3,
          lastReadAt: DateTime.now(),
        );

        final pdf = PdfDocument(
          id: 'test-loaded',
          title: 'Loaded PDF',
          filePath: '/path/to/loaded.pdf',
          fileSize: 2048 * 1024,
          createdAt: DateTime.now(),
          lastOpenedAt: DateTime.now(),
          totalPages: 15,
          progress: progress,
        );

        final loadedState = PdfReaderState.loaded(pdf);

        // Assert
        expect(
          loadedState.maybeWhen(
            loaded: (p) => p.id == 'test-loaded',
            orElse: () => false,
          ),
          true,
        );

        loadedState.when(
          loaded: (p) {
            expect(p.progress?.currentPage, 3);
            expect(p.totalPages, 15);
          },
          loading: () => fail('Should be loaded state'),
          notFound: () => fail('Should be loaded state'),
          fileNotFound: (_) => fail('Should be loaded state'),
          error: (_) => fail('Should be loaded state'),
        );
      });
    });

    group('Round-trip Consistency', () {
      test('should maintain consistency: page → slider → page', () {
        // Test all pages from 1 to 8
        for (int page = 1; page <= 8; page++) {
          // Forward: page to slider
          final scrollPosition = (8 > 1)
              ? (page - 1) / (8 - 1)
              : 0.0;

          // Inverse: slider to page
          final calculatedPage = (scrollPosition * (8 - 1)).round() + 1;

          // Assert
          expect(calculatedPage, page,
              reason: 'Page $page should round-trip correctly');
        }
      });

      test('should handle all common page counts', () {
        // Test with different page counts
        final pageCounts = [1, 2, 5, 10, 50, 100];

        for (final totalPages in pageCounts) {
          for (int page = 1; page <= totalPages; page++) {
            final scrollPosition = totalPages > 1
                ? (page - 1) / (totalPages - 1)
                : 0.0;

            final calculatedPage = (scrollPosition * (totalPages - 1)).round() + 1;

            expect(calculatedPage, page,
                reason: 'Failed for $totalPages pages, page $page');
          }
        }
      });
    });
  });
}
