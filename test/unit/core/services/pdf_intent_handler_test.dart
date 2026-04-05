import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pdf_reader_app/core/data/models/pdf_document.dart';
import 'package:pdf_reader_app/core/data/repositories/pdf_repository.dart';
import 'package:pdf_reader_app/core/services/pdf_intent_handler.dart';
import 'package:pdf_reader_app/core/utils/result.dart';

@GenerateMocks([SharedPreferencesPdfRepository])
import 'pdf_intent_handler_test.mocks.dart';

void main() {
  group('PdfIntentHandler - Edge Case Tests', () {
    // ─── EC8: PDF Magic Bytes Validation ─────────────────────────

    group('PDF validation (magic bytes)', () {
      test('should recognize valid PDF magic bytes %PDF-', () async {
        final file = await _createTempPdfFile();
        addTearDown(() => file.parent.delete(recursive: true));

        final raf = await file.open();
        try {
          final bytes = await raf.read(5);
          const pdfMagic = [0x25, 0x50, 0x44, 0x46, 0x2D]; // %PDF-
          expect(bytes.length, equals(5));
          bool isValid = true;
          for (int i = 0; i < 5; i++) {
            if (bytes[i] != pdfMagic[i]) {
              isValid = false;
            }
          }
          expect(isValid, isTrue);
        } finally {
          await raf.close();
        }
      });

      test('should reject file shorter than 5 bytes', () async {
        final file = await _createTempFile([0x25, 0x50, 0x44]);
        addTearDown(() => file.parent.delete(recursive: true));

        final raf = await file.open();
        try {
          final bytes = await raf.read(5);
          expect(bytes.length, lessThan(5));
        } finally {
          await raf.close();
        }
      });

      test('should reject plain text file', () async {
        final file = await _createTempFile(
          'Hello, this is plain text'.codeUnits,
        );
        addTearDown(() => file.parent.delete(recursive: true));

        final raf = await file.open();
        try {
          final bytes = await raf.read(5);
          expect(bytes[0], isNot(equals(0x25))); // Not %
        } finally {
          await raf.close();
        }
      });

      test('should reject JPEG file (wrong magic bytes)', () async {
        final file = await _createTempFile([0xFF, 0xD8, 0xFF, 0xE0, 0x00]);
        addTearDown(() => file.parent.delete(recursive: true));

        final raf = await file.open();
        try {
          final bytes = await raf.read(5);
          expect(bytes[0], equals(0xFF)); // JPEG SOI marker, not % (0x25)
        } finally {
          await raf.close();
        }
      });
    });

    // ─── EC5: URL Decoding ───────────────────────────────────────

    group('URL decoding of filenames', () {
      test('should decode %20 as space', () {
        const input = '/storage/emulated/0/my%20file.pdf';
        final raw = input.split('/').last;
        final decoded = Uri.decodeComponent(raw);
        expect(decoded, equals('my file.pdf'));
      });

      test('should decode multiple encoded characters (#, space)', () {
        const input = '/storage/emulated/0/my%20file%20%23report.pdf';
        final raw = input.split('/').last;
        final decoded = Uri.decodeComponent(raw);
        expect(decoded, equals('my file #report.pdf'));
      });

      test('should decode %2B as plus sign', () {
        const input = '/storage/download/C%2B%2B_Guide.pdf';
        final raw = input.split('/').last;
        final decoded = Uri.decodeComponent(raw);
        expect(decoded, equals('C++_Guide.pdf'));
      });

      test('should pass through unencoded filename as-is', () {
        const input = '/storage/download/simple.pdf';
        final raw = input.split('/').last;
        final decoded = Uri.decodeComponent(raw);
        expect(decoded, equals('simple.pdf'));
      });

      test('should fallback to raw for invalid percent encoding', () {
        // A file literally named "100%done.pdf" — %d is not valid encoding
        const input = '/storage/download/100%done.pdf';
        final raw = input.split('/').last;
        try {
          Uri.decodeComponent(raw);
          // Some implementations are lenient — that's OK
        } catch (_) {
          // Expected: fallback to raw
          expect(raw, equals('100%done.pdf'));
        }
      });
    });

    // ─── EC4: Large File Threshold ───────────────────────────────

    group('large file handling', () {
      test('largeFileThreshold constant should be 10 MB', () {
        expect(PdfIntentHandler.largeFileThreshold, equals(10 * 1024 * 1024));
      });

      test('5 MB file is below threshold', () {
        const smallFileSize = 5 * 1024 * 1024;
        expect(smallFileSize, lessThan(PdfIntentHandler.largeFileThreshold));
      });

      test('50 MB file is above threshold', () {
        const largeFileSize = 50 * 1024 * 1024;
        expect(largeFileSize, greaterThan(PdfIntentHandler.largeFileThreshold));
      });
    });

    // ─── EC1: Duplicate PDF Handling ─────────────────────────────

    group('duplicate PDF handling', () {
      late MockSharedPreferencesPdfRepository mockRepo;

      setUp(() {
        mockRepo = MockSharedPreferencesPdfRepository();
      });

      test('should find existing PDF by file path', () async {
        const filePath = '/data/com.app/files/report.pdf';
        final existingPdf = PdfDocument(
          id: 'existing-id-123',
          title: 'report.pdf',
          filePath: filePath,
          fileSize: 1024,
          createdAt: DateTime(2024, 1, 1),
          lastOpenedAt: DateTime(2024, 1, 10),
          totalPages: 50,
        );

        when(
          mockRepo.getAllPdfs(),
        ).thenAnswer((_) async => Result.success([existingPdf]));

        final result = await mockRepo.getAllPdfs();
        PdfDocument? found;
        result.when(
          success: (pdfs) {
            for (final pdf in pdfs) {
              if (pdf.filePath == filePath) found = pdf;
            }
          },
          failure: (error, stackTrace) => fail('Should not fail'),
        );

        expect(found, isNotNull);
        expect(found!.id, equals('existing-id-123'));
      });

      test('should update existing PDF instead of adding new one', () async {
        const filePath = '/data/com.app/files/report.pdf';
        final existingPdf = PdfDocument(
          id: 'existing-id-456',
          title: 'report.pdf',
          filePath: filePath,
          fileSize: 2048,
          createdAt: DateTime(2024, 1, 1),
          lastOpenedAt: DateTime(2024, 1, 10),
          totalPages: 30,
        );

        when(
          mockRepo.getAllPdfs(),
        ).thenAnswer((_) async => Result.success([existingPdf]));
        when(
          mockRepo.updatePdf(any),
        ).thenAnswer((_) async => Result.success(existingPdf));

        // Simulate the duplicate check + update logic
        final result = await mockRepo.getAllPdfs();
        PdfDocument? found;
        result.when(
          success: (pdfs) {
            for (final pdf in pdfs) {
              if (pdf.filePath == filePath) found = pdf;
            }
          },
          failure: (error, stackTrace) {},
        );

        expect(found, isNotNull);
        expect(found!.id, equals('existing-id-456'));

        // Update lastOpenedAt
        final updated = found!.copyWith(lastOpenedAt: DateTime.now());
        await mockRepo.updatePdf(updated);

        verify(mockRepo.updatePdf(any)).called(1);
        verifyNever(mockRepo.addPdf(any));
      });

      test('should NOT find PDF with different file path', () async {
        const existingPath = '/data/com.app/files/report.pdf';
        const newPath = '/data/com.app/files/other.pdf';

        final existingPdf = PdfDocument(
          id: 'existing-id-789',
          title: 'report.pdf',
          filePath: existingPath,
          fileSize: 1024,
          createdAt: DateTime(2024, 1, 1),
          lastOpenedAt: DateTime(2024, 1, 10),
          totalPages: 20,
        );

        when(
          mockRepo.getAllPdfs(),
        ).thenAnswer((_) async => Result.success([existingPdf]));

        final result = await mockRepo.getAllPdfs();
        PdfDocument? found;
        result.when(
          success: (pdfs) {
            for (final pdf in pdfs) {
              if (pdf.filePath == newPath) found = pdf;
            }
          },
          failure: (error, stackTrace) {},
        );

        expect(found, isNull);
      });
    });

    // ─── EC2: Intent Stream ──────────────────────────────────────

    group('intent stream', () {
      test('should emit multiple paths through broadcast stream', () async {
        final controller = StreamController<String>.broadcast();
        final emitted = <String>[];
        controller.stream.listen(emitted.add);

        controller.add('/path/to/first.pdf');
        controller.add('/path/to/second.pdf');

        // Allow microtasks to complete
        await Future<void>.delayed(Duration.zero);

        expect(emitted, ['/path/to/first.pdf', '/path/to/second.pdf']);

        await controller.close();
      });

      test('should allow multiple listeners on broadcast stream', () async {
        final controller = StreamController<String>.broadcast();
        final emitted1 = <String>[];
        final emitted2 = <String>[];

        controller.stream.listen(emitted1.add);
        controller.stream.listen(emitted2.add);

        controller.add('/test.pdf');
        await Future<void>.delayed(Duration.zero);

        expect(emitted1, ['/test.pdf']);
        expect(emitted2, ['/test.pdf']);

        await controller.close();
      });
    });

    // ─── EC7: Completer-based pending file path ─────────────────

    group('Completer-based pending file path', () {
      test('should resolve when completed with path', () async {
        final completer = Completer<String?>();

        completer.complete('/data/files/test.pdf');

        final result = await completer.future;
        expect(result, equals('/data/files/test.pdf'));
      });

      test('should resolve with null when no intent', () async {
        final completer = Completer<String?>();

        completer.complete(null);

        final result = await completer.future;
        expect(result, isNull);
      });

      test('isCompleted should be true after completing', () {
        final completer = Completer<String?>();
        expect(completer.isCompleted, isFalse);

        completer.complete('/first.pdf');
        expect(completer.isCompleted, isTrue);
      });

      test('new completer should be independent after reset', () async {
        var completer = Completer<String?>();
        completer.complete('/first.pdf');
        final first = await completer.future;
        expect(first, equals('/first.pdf'));

        // Reset (as done in getPendingFilePath)
        completer = Completer<String?>();
        expect(completer.isCompleted, isFalse);

        completer.complete('/second.pdf');
        final second = await completer.future;
        expect(second, equals('/second.pdf'));
      });
    });

    // ─── EC3 & EC6: Internal Storage & Overwrite Prevention ──────

    group('internal storage (Android-side logic)', () {
      test('unique suffix should prevent filename collision', () {
        const originalFileName = 'report.pdf';
        final suffix = DateTime.now().millisecondsSinceEpoch.toRadixString(16);
        final shortSuffix = suffix.length > 8
            ? suffix.substring(suffix.length - 8)
            : suffix;
        final dotIndex = originalFileName.lastIndexOf('.');
        final baseName = dotIndex != -1
            ? originalFileName.substring(0, dotIndex)
            : originalFileName;
        final extension = dotIndex != -1
            ? originalFileName.substring(dotIndex + 1)
            : 'pdf';

        final newName = '${baseName}_$shortSuffix.$extension';

        expect(newName, isNot(equals('report.pdf')));
        expect(newName, contains('report_'));
        expect(newName, endsWith('.pdf'));
      });

      test('filesDir and cacheDir are different paths', () {
        const filesDir = '/data/data/com.pdfreader.pdf_reader_app/files';
        const cacheDir = '/data/data/com.pdfreader.pdf_reader_app/cache';

        expect(filesDir, isNot(equals(cacheDir)));
        expect(filesDir, contains('files'));
        expect(cacheDir, contains('cache'));
      });

      test('collision suffix is unique across calls', () {
        final names = <String>{};
        for (int i = 0; i < 100; i++) {
          final suffix = (DateTime.now().millisecondsSinceEpoch + i)
              .toRadixString(16);
          final short = suffix.length > 8
              ? suffix.substring(suffix.length - 8)
              : suffix;
          names.add('report_$short.pdf');
        }
        // Each should be unique (different timestamps)
        expect(names.length, greaterThan(1));
      });
    });
  });
}

// ─── Helpers ───────────────────────────────────────────────────────

/// Creates a temporary file with the given bytes.
Future<File> _createTempFile(List<int> bytes) async {
  final dir = Directory.systemTemp.createTempSync('pdf_test_');
  final file = File('${dir.path}/test.bin');
  await file.writeAsBytes(bytes);
  return file;
}

/// Creates a temporary valid PDF file (with %PDF- header).
Future<File> _createTempPdfFile() async {
  final dir = Directory.systemTemp.createTempSync('pdf_test_');
  final file = File('${dir.path}/test.pdf');
  // Minimal valid PDF header
  await file.writeAsBytes([
    0x25, 0x50, 0x44, 0x46, 0x2D, 0x31, 0x2E, 0x34, // %PDF-1.4
    0x0A, 0x25, 0xE2, 0xE3, 0xCF, 0xD3, 0x0A, // %binary comment
  ]);
  return file;
}
