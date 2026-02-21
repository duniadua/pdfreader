import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_reader_app/core/data/models/pdf_document.dart';

void main() {
  group('PdfDocument', () {
    late DateTime testDate;

    setUp(() {
      testDate = DateTime(2024, 1, 15, 10, 30);
    });

    test('should create instance with required fields', () {
      final pdf = PdfDocument(
        id: 'test-id',
        title: 'Test PDF',
        filePath: '/path/to/test.pdf',
        fileSize: 1024 * 1024, // 1MB
        createdAt: testDate,
        lastOpenedAt: testDate,
        totalPages: 100,
      );

      expect(pdf.id, 'test-id');
      expect(pdf.title, 'Test PDF');
      expect(pdf.filePath, '/path/to/test.pdf');
      expect(pdf.fileSize, 1024 * 1024);
      expect(pdf.totalPages, 100);
      expect(pdf.isFavorite, false);
    });

    test('should serialize to JSON correctly', () {
      final pdf = PdfDocument(
        id: 'test-id',
        title: 'Test PDF',
        filePath: '/path/to/test.pdf',
        fileSize: 1024 * 1024,
        createdAt: testDate,
        lastOpenedAt: testDate,
        totalPages: 100,
        isFavorite: true,
        progress: ReadingProgress(
          documentId: 'test-id',
          currentPage: 50,
          lastReadAt: testDate,
        ),
      );

      final json = pdf.toJson();

      expect(json['id'], 'test-id');
      expect(json['title'], 'Test PDF');
      expect(json['filePath'], '/path/to/test.pdf');
      expect(json['fileSize'], 1024 * 1024);
      expect(json['totalPages'], 100);
      expect(json['isFavorite'], true);
      expect(json['progress'], isNotNull);
    });

    test('should deserialize from JSON correctly', () {
      final json = {
        'id': 'test-id',
        'title': 'Test PDF',
        'filePath': '/path/to/test.pdf',
        'fileSize': 1024 * 1024,
        'totalPages': 100,
        'createdAt': testDate.toIso8601String(),
        'lastOpenedAt': testDate.toIso8601String(),
        'thumbnailPath': null,
        'isFavorite': true,
        'progress': {
          'documentId': 'test-id',
          'currentPage': 50,
          'lastReadAt': testDate.toIso8601String(),
          'scrollOffset': 100,
        },
      };

      final pdf = PdfDocument.fromJson(json);

      expect(pdf.id, 'test-id');
      expect(pdf.title, 'Test PDF');
      expect(pdf.filePath, '/path/to/test.pdf');
      expect(pdf.fileSize, 1024 * 1024);
      expect(pdf.totalPages, 100);
      expect(pdf.isFavorite, true);
      expect(pdf.progress?.currentPage, 50);
      expect(pdf.progress?.scrollOffset, 100);
    });

    test('should calculate progress percentage correctly', () {
      final pdf = PdfDocument(
        id: 'test-id',
        title: 'Test PDF',
        filePath: '/path/to/test.pdf',
        fileSize: 1024,
        createdAt: testDate,
        lastOpenedAt: testDate,
        totalPages: 100,
        progress: ReadingProgress(
          documentId: 'test-id',
          currentPage: 50,
          lastReadAt: testDate,
        ),
      );

      expect(pdf.progressPercentage, 0.5);
    });

    test('should return 0 progress when no progress data', () {
      final pdf = PdfDocument(
        id: 'test-id',
        title: 'Test PDF',
        filePath: '/path/to/test.pdf',
        fileSize: 1024,
        createdAt: testDate,
        lastOpenedAt: testDate,
        totalPages: 100,
      );

      expect(pdf.progressPercentage, 0.0);
    });

    test('should format file size correctly', () {
      final pdf1 = PdfDocument(
        id: 'test-1',
        title: 'Small PDF',
        filePath: '/path/to/small.pdf',
        fileSize: 1024,
        createdAt: DateTime(2024, 1, 1),
        lastOpenedAt: DateTime(2024, 1, 1),
        totalPages: 10,
      );

      final pdf2 = PdfDocument(
        id: 'test-2',
        title: 'Large PDF',
        filePath: '/path/to/large.pdf',
        fileSize: 1024 * 1024 * 5, // 5MB
        createdAt: DateTime(2024, 1, 1),
        lastOpenedAt: DateTime(2024, 1, 1),
        totalPages: 100,
      );

      expect(pdf1.formattedFileSize, '1.0 KB');
      expect(pdf2.formattedFileSize, '5.0 MB');
    });
  });

  group('ReadingProgress', () {
    test('should create instance with required fields', () {
      final progress = ReadingProgress(
        documentId: 'test-id',
        currentPage: 10,
        lastReadAt: DateTime(2024, 1, 15),
      );

      expect(progress.documentId, 'test-id');
      expect(progress.currentPage, 10);
      expect(progress.scrollOffset, 0);
    });

    test('should serialize and deserialize correctly', () {
      final progress = ReadingProgress(
        documentId: 'test-id',
        currentPage: 42,
        lastReadAt: DateTime(2024, 1, 15),
        scrollOffset: 150,
      );

      final json = progress.toJson();
      final deserialized = ReadingProgress.fromJson(json);

      expect(deserialized.documentId, 'test-id');
      expect(deserialized.currentPage, 42);
      expect(deserialized.scrollOffset, 150);
    });
  });
}
