import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf_reader_app/core/data/repositories/pdf_repository.dart';
import 'package:pdf_reader_app/core/data/models/pdf_document.dart';

@GenerateMocks([SharedPreferences])
import 'pdf_repository_test.mocks.dart';

void main() {
  late SharedPreferencesPdfRepository repository;
  late MockSharedPreferences mockPrefs;

  setUp(() {
    mockPrefs = MockSharedPreferences();
    repository = SharedPreferencesPdfRepository(prefs: mockPrefs);
  });

  group('SharedPreferencesPdfRepository', () {
    final testPdf = PdfDocument(
      id: 'test-id-1',
      title: 'Test PDF',
      filePath: '/path/to/test.pdf',
      fileSize: 1024 * 1024,
      createdAt: DateTime(2024, 1, 15),
      lastOpenedAt: DateTime(2024, 1, 15),
      totalPages: 100,
    );

    final testPdfJsonArray = json.encode([
      {
        'id': 'test-id-1',
        'title': 'Test PDF',
        'filePath': '/path/to/test.pdf',
        'fileSize': 1024 * 1024,
        'totalPages': 100,
        'createdAt': DateTime(2024, 1, 15).toIso8601String(),
        'lastOpenedAt': DateTime(2024, 1, 15).toIso8601String(),
        'thumbnailPath': null,
        'isFavorite': false,
        'progress': null,
      }
    ]);

    group('getAllPdfs', () {
      test('should return empty list when no PDFs exist', () async {
        when(mockPrefs.getString('pdfs')).thenReturn(null);

        final result = await repository.getAllPdfs();

        result.when(
          success: (pdfs) => expect(pdfs, isEmpty),
          failure: (_, __) => fail('Should not return failure'),
        );
      });

      test('should return all PDFs sorted by last opened', () async {
        final pdfs = [
          testPdf.toJson(),
          PdfDocument(
            id: 'test-id-2',
            title: 'Recent PDF',
            filePath: '/path/to/recent.pdf',
            fileSize: 2048 * 1024,
            createdAt: DateTime(2024, 1, 11),
            lastOpenedAt: DateTime(2024, 1, 16),
            totalPages: 50,
            isFavorite: true,
          ).toJson(),
        ];

        when(mockPrefs.getString('pdfs')).thenReturn(json.encode(pdfs));

        final result = await repository.getAllPdfs();

        result.when(
          success: (pdfList) {
            expect(pdfList.length, 2);
            expect(pdfList.first.id, 'test-id-2'); // Most recent first
            expect(pdfList.last.id, 'test-id-1');
          },
          failure: (_, __) => fail('Should not return failure'),
        );
      });
    });

    group('getPdfById', () {
      test('should return PDF when found', () async {
        when(mockPrefs.getString('pdfs')).thenReturn(testPdfJsonArray);

        final result = await repository.getPdfById('test-id-1');

        result.when(
          success: (pdf) {
            expect(pdf, isNotNull);
            expect(pdf!.id, 'test-id-1');
            expect(pdf.title, 'Test PDF');
          },
          failure: (_, __) => fail('Should not return failure'),
        );
      });

      test('should return null when not found', () async {
        when(mockPrefs.getString('pdfs')).thenReturn(testPdfJsonArray);

        final result = await repository.getPdfById('non-existent');

        result.when(
          success: (pdf) => expect(pdf, isNull),
          failure: (_, __) => fail('Should not return failure'),
        );
      });
    });

    group('getRecentPdfs', () {
      test('should return recent PDFs with limit', () async {
        final pdfs = List.generate(
          15,
          (i) => PdfDocument(
            id: 'pdf-$i',
            title: 'PDF $i',
            filePath: '/path/to/$i.pdf',
            fileSize: 1024 * 1024,
            createdAt: DateTime(2024, 1, 1),
            lastOpenedAt: DateTime(2024, 1, 15 + i),
            totalPages: 10,
          ).toJson(),
        );

        when(mockPrefs.getString('pdfs')).thenReturn(json.encode(pdfs));

        final result = await repository.getRecentPdfs(limit: 10);

        result.when(
          success: (pdfList) {
            expect(pdfList.length, 10);
            expect(pdfList.first.id, 'pdf-14'); // Most recent
          },
          failure: (_, __) => fail('Should not return failure'),
        );
      });
    });

    group('getFavoritePdfs', () {
      test('should return only favorite PDFs', () async {
        final pdfs = [
          testPdf.toJson(),
          PdfDocument(
            id: 'fav-id',
            title: 'Favorite PDF',
            filePath: '/path/to/fav.pdf',
            fileSize: 1024 * 1024,
            createdAt: DateTime(2024, 1, 10),
            lastOpenedAt: DateTime(2024, 1, 15),
            totalPages: 50,
            isFavorite: true,
          ).toJson(),
        ];

        when(mockPrefs.getString('pdfs')).thenReturn(json.encode(pdfs));

        final result = await repository.getFavoritePdfs();

        result.when(
          success: (pdfList) {
            expect(pdfList.length, 1);
            expect(pdfList.first.id, 'fav-id');
            expect(pdfList.first.isFavorite, true);
          },
          failure: (_, __) => fail('Should not return failure'),
        );
      });
    });

    group('addPdf', () {
      test('should add PDF successfully', () async {
        when(mockPrefs.getString('pdfs')).thenReturn(null);
        when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);

        final result = await repository.addPdf(testPdf);

        result.when(
          success: (_) => verify(mockPrefs.setString('pdfs', any)).called(1),
          failure: (_, __) => fail('Should not return failure'),
        );
      });

      test('should prevent duplicate PDFs by file path', () async {
        when(mockPrefs.getString('pdfs')).thenReturn(testPdfJsonArray);

        final duplicate = PdfDocument(
          id: 'different-id',
          title: 'Different Title',
          filePath: '/path/to/test.pdf', // Same path
          fileSize: 2048,
          createdAt: DateTime(2024, 1, 10),
          lastOpenedAt: DateTime(2024, 1, 10),
          totalPages: 20,
        );

        final result = await repository.addPdf(duplicate);

        result.when(
          success: (_) => fail('Should return failure'),
          failure: (error, __) {
            expect(error.toString(), contains('already exists'));
          },
        );
      });
    });

    group('updatePdf', () {
      test('should update existing PDF', () async {
        when(mockPrefs.getString('pdfs')).thenReturn(testPdfJsonArray);
        when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);

        final updated = testPdf.copyWith(
          title: 'Updated Title',
          isFavorite: true,
        );

        final result = await repository.updatePdf(updated);

        result.when(
          success: (_) => verify(mockPrefs.setString('pdfs', any)).called(1),
          failure: (_, __) => fail('Should not return failure'),
        );
      });
    });

    group('deletePdf', () {
      test('should delete existing PDF', () async {
        when(mockPrefs.getString('pdfs')).thenReturn(testPdfJsonArray);
        when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);

        final result = await repository.deletePdf('test-id-1');

        result.when(
          success: (_) => verify(mockPrefs.setString('pdfs', any)).called(1),
          failure: (_, __) => fail('Should not return failure'),
        );
      });
    });

    group('toggleFavorite', () {
      test('should toggle favorite from false to true', () async {
        when(mockPrefs.getString('pdfs')).thenReturn(testPdfJsonArray);
        when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);

        final result = await repository.toggleFavorite('test-id-1');

        result.when(
          success: (pdf) => expect(pdf.isFavorite, true),
          failure: (_, __) => fail('Should not return failure'),
        );
      });
    });

    group('updateProgress', () {
      test('should update reading progress', () async {
        when(mockPrefs.getString('pdfs')).thenReturn(testPdfJsonArray);
        when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);

        final result = await repository.updateProgress('test-id-1', 50, 100);

        result.when(
          success: (_) => verify(mockPrefs.setString('pdfs', any)).called(1),
          failure: (_, __) => fail('Should not return failure'),
        );
      });
    });
  });
}
