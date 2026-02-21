import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_reader_app/core/data/models/pdf_document.dart';
import 'package:pdf_reader_app/core/utils/exceptions.dart';
import 'package:pdf_reader_app/features/reader/presentation/providers/pdf_reader_notifier.dart';

// Simple model tests
void main() {
  group('PDF Reader - Model Tests', () {
    test('PdfDocument should have correct properties', () {
      final pdf = PdfDocument(
        id: 'test-1',
        title: 'Test.pdf',
        filePath: '/path/Test.pdf',
        fileSize: 1024000,
        createdAt: DateTime(2025, 1, 1),
        lastOpenedAt: DateTime(2025, 1, 15),
        totalPages: 10,
      );

      expect(pdf.id, 'test-1');
      expect(pdf.title, 'Test.pdf');
      expect(pdf.totalPages, 10);
      expect(pdf.isFavorite, false);
    });

    test('PdfDocument should format file size', () {
      final pdf1 = PdfDocument(
        id: 'test-1',
        title: 'Test.pdf',
        filePath: '/path/Test.pdf',
        fileSize: 500,
        createdAt: DateTime(2025, 1, 1),
        lastOpenedAt: DateTime(2025, 1, 15),
        totalPages: 10,
      );

      expect(pdf1.formattedFileSize, '500 B');

      final pdf2 = PdfDocument(
        id: 'test-2',
        title: 'Test.pdf',
        filePath: '/path/Test.pdf',
        fileSize: 1024 * 500,
        createdAt: DateTime(2025, 1, 1),
        lastOpenedAt: DateTime(2025, 1, 15),
        totalPages: 10,
      );

      expect(pdf2.formattedFileSize.contains('KB'), true);
    });

    test('PdfDocument should copy with changes', () {
      final pdf = PdfDocument(
        id: 'test-1',
        title: 'Test.pdf',
        filePath: '/path/Test.pdf',
        fileSize: 1000,
        createdAt: DateTime(2025, 1, 1),
        lastOpenedAt: DateTime(2025, 1, 15),
        totalPages: 10,
      );

      final updated = pdf.copyWith(isFavorite: true);

      expect(updated.id, pdf.id);
      expect(updated.isFavorite, true);
    });

    test('PdfReaderState should have correct state types', () {
      // Loading state
      final loading = PdfReaderState.loading();
      loading.maybeWhen(
        loading: () => expect(true, true),
        orElse: () => fail('Expected loading'),
      );

      // Loaded state
      final pdf = PdfDocument(
        id: 'test-1',
        title: 'Test.pdf',
        filePath: '/path/Test.pdf',
        fileSize: 1000,
        createdAt: DateTime(2025, 1, 1),
        lastOpenedAt: DateTime(2025, 1, 15),
        totalPages: 10,
      );
      final loaded = PdfReaderState.loaded(pdf);
      loaded.maybeWhen(
        loaded: (p) => expect(p.id, 'test-1'),
        orElse: () => fail('Expected loaded'),
      );

      // NotFound state
      final notFound = PdfReaderState.notFound();
      notFound.maybeWhen(
        notFound: () => expect(true, true),
        orElse: () => fail('Expected notFound'),
      );

      // FileNotFound state
      final fileNotFound = PdfReaderState.fileNotFound('/path/file.pdf');
      fileNotFound.maybeWhen(
        fileNotFound: (p) => expect(p, '/path/file.pdf'),
        orElse: () => fail('Expected fileNotFound'),
      );

      // Error state
      final error = PdfReaderState.error('Error message');
      error.maybeWhen(
        error: (msg) => expect(msg, 'Error message'),
        orElse: () => fail('Expected error'),
      );
    });

    test('AppException should have correct types', () {
      const storage = StorageException('Storage error');
      const file = FileException('File error');
      const pdf = PdfException('PDF error');

      expect(storage.message, 'Storage error');
      expect(file.message, 'File error');
      expect(pdf.message, 'PDF error');

      expect(storage, isA<AppException>());
      expect(file, isA<AppException>());
      expect(pdf, isA<AppException>());
    });
  });
}
