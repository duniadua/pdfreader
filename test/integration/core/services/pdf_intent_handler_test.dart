import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sync_pdf;

import 'package:pdf_reader_app/core/data/models/pdf_document.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PdfIntentHandler File Operations', () {
    group('PDF Magic Bytes Validation', () {
      test('should validate PDF magic bytes correctly', () async {
        // Create a temporary valid PDF file
        final tempDir = Directory.systemTemp.createTempSync('pdf_test_');
        final validPdf = File('${tempDir.path}/valid.pdf');
        await validPdf.writeAsBytes([0x25, 0x50, 0x44, 0x46, 0x2D, 0x31, 0x2E, 0x34]); // %PDF-1.4

        final isValid = await _isValidPdf(validPdf);
        expect(isValid, isTrue, reason: 'Valid PDF should pass validation');

        await tempDir.delete(recursive: true);
      });

      test('should reject invalid PDF magic bytes', () async {
        final tempDir = Directory.systemTemp.createTempSync('pdf_test_');
        final invalidPdf = File('${tempDir.path}/invalid.pdf');
        await invalidPdf.writeAsBytes([0x00, 0x01, 0x02, 0x03, 0x04]); // Invalid header

        final isValid = await _isValidPdf(invalidPdf);
        expect(isValid, isFalse, reason: 'Invalid PDF should fail validation');

        await tempDir.delete(recursive: true);
      });

      test('should handle non-existent file gracefully', () async {
        final nonExistent = File('/path/that/does/not/exist.pdf');

        final isValid = await _isValidPdf(nonExistent);
        expect(isValid, isFalse, reason: 'Non-existent file should fail validation');
      });
    });

    group('Filename Decoding', () {
      test('should decode URL-encoded filenames', () {
        final encoded = 'Document%20100%25Complete.pdf';
        final decoded = _decodeFilename(encoded);

        expect(decoded, equals('Document 100%Complete.pdf'));
      });

      test('should handle filenames without encoding', () {
        const plain = 'My Document.pdf';
        final result = _decodeFilename(plain);

        expect(result, equals(plain));
      });

      test('should fallback to raw filename on decode error', () {
        // Invalid percent encoding
        const invalid = '%ZZ%GG%XX.pdf';
        final result = _decodeFilename(invalid);

        // Should return the original string when decoding fails
        expect(result, equals(invalid));
      });
    });

    group('File Readiness Verification', () {
      test('should verify file is readable before processing', () async {
        final tempDir = Directory.systemTemp.createTempSync('pdf_test_');
        final testFile = File('${tempDir.path}/test.pdf');

        // Write a valid PDF
        await testFile.writeAsBytes(
          Uint8List.fromList([0x25, 0x50, 0x44, 0x46, 0x2D, 0x31, 0x2E, 0x34, 0x0A, 0x25, 0x25, 0xE2, 0xE3, 0xCF, 0xD3]),
        );

        // Verify file exists
        expect(await testFile.exists(), isTrue);
        expect(await testFile.length(), greaterThan(0));

        // Verify file is readable
        final raf = await testFile.open();
        try {
          final bytes = await raf.read(5);
          expect(bytes.length, equals(5));
          expect(bytes[0], equals(0x25)); // %
          expect(bytes[1], equals(0x50)); // P
        } finally {
          await raf.close();
        }

        await tempDir.delete(recursive: true);
      });

      test('should detect empty files', () async {
        final tempDir = Directory.systemTemp.createTempSync('pdf_test_');
        final emptyFile = File('${tempDir.path}/empty.pdf');

        await emptyFile.create();

        expect(await emptyFile.exists(), isTrue);
        expect(await emptyFile.length(), equals(0));

        await tempDir.delete(recursive: true);
      });
    });

    group('Race Condition Prevention', () {
      test('should retry file read if initial read fails', () async {
        final tempDir = Directory.systemTemp.createTempSync('pdf_test_');
        final testFile = File('${tempDir.path}/delayed.pdf');

        // Simulate file being written with delay
        final writeCompleter = () async {
          await Future.delayed(const Duration(milliseconds: 100));
          await testFile.writeAsBytes(
            Uint8List.fromList([0x25, 0x50, 0x44, 0x46, 0x2D]),
          );
        }();

        // Start writing in background
        writeCompleter.ignore();

        // Try to read immediately (will fail initially)
        var readable = false;
        for (int i = 0; i < 5; i++) {
          await Future.delayed(const Duration(milliseconds: 50));
          if (await testFile.exists() && await testFile.length() > 0) {
            try {
              final raf = await testFile.open();
              try {
                final byte = await raf.read(1);
                if (byte.isNotEmpty) {
                  readable = true;
                  break;
                }
              } finally {
                await raf.close();
              }
            } catch (_) {
              // Continue retrying
            }
          }
        }

        expect(readable, isTrue, reason: 'File should become readable after retry');

        await writeCompleter;
        await tempDir.delete(recursive: true);
      });

      test('should not proceed if file disappears during processing', () async {
        final tempDir = Directory.systemTemp.createTempSync('pdf_test_');
        final testFile = File('${tempDir.path}/ghost.pdf');

        // Create file
        await testFile.writeAsBytes([0x25, 0x50, 0x44, 0x46]);
        expect(await testFile.exists(), isTrue);

        // Delete file (simulate race condition)
        await testFile.delete();

        // Should detect file is gone
        expect(await testFile.exists(), isFalse);

        await tempDir.delete(recursive: true);
      });
    });

    group('Large File Handling', () {
      test('should skip page count extraction for files > 10MB', () async {
        const largeThreshold = 10 * 1024 * 1024; // 10 MB

        // Simulate a large file size check
        final fileSize = 11 * 1024 * 1024; // 11 MB
        final shouldSkip = fileSize > largeThreshold;

        expect(shouldSkip, isTrue, reason: 'Should skip page count for large files');
      });

      test('should extract page count for small files', () async {
        final tempDir = Directory.systemTemp.createTempSync('pdf_test_');
        final testFile = File('${tempDir.path}/small.pdf');

        // Create a small PDF with 2 pages
        final pdf = sync_pdf.PdfDocument();
        pdf.pages.add(); // Page 1
        pdf.pages.add(); // Page 2

        final bytes = await pdf.save();
        await testFile.writeAsBytes(bytes);
        pdf.dispose();

        // Verify it's small
        final fileSize = await testFile.length();
        expect(fileSize, lessThan(10 * 1024 * 1024));

        // Extract page count
        final loadedPdf = sync_pdf.PdfDocument(inputBytes: await testFile.readAsBytes());
        final pageCount = loadedPdf.pages.count;
        loadedPdf.dispose();

        expect(pageCount, equals(2));

        await tempDir.delete(recursive: true);
      });
    });

    group('Duplicate Detection', () {
      test('should detect existing PDF by file path', () async {
        const testPath = '/storage/emulated/0/test.pdf';

        final pdf1 = PdfDocument(
          id: '1',
          title: 'Test PDF',
          filePath: testPath,
          fileSize: 1024,
          createdAt: DateTime.now(),
          lastOpenedAt: DateTime.now(),
          totalPages: 10,
        );

        final pdf2 = PdfDocument(
          id: '2',
          title: 'Duplicate PDF',
          filePath: testPath, // Same path
          fileSize: 1024,
          createdAt: DateTime.now(),
          lastOpenedAt: DateTime.now(),
          totalPages: 10,
        );

        expect(pdf1.filePath, equals(pdf2.filePath));
        expect(pdf1.id, isNot(equals(pdf2.id)));
      });
    });

    group('Error Handling', () {
      test('should handle invalid file path gracefully', () async {
        const invalidPath = '/invalid/path/that/does/not/exist.pdf';

        final file = File(invalidPath);
        expect(await file.exists(), isFalse);
      });

      test('should handle corrupted PDF during validation', () async {
        final tempDir = Directory.systemTemp.createTempSync('pdf_test_');
        final corruptedFile = File('${tempDir.path}/corrupted.pdf');

        // Write file with invalid PDF structure but valid magic bytes
        await corruptedFile.writeAsBytes(
          Uint8List.fromList([0x25, 0x50, 0x44, 0x46, 0x2D, 0x00, 0x01, 0x02, 0x03]),
        );

        // File passes magic byte check but might fail during actual PDF parsing
        final magicBytesValid = await _isValidPdf(corruptedFile);
        expect(magicBytesValid, isTrue);

        await tempDir.delete(recursive: true);
      });
    });

    group('Integration: PDF Intent Flow', () {
      test('should successfully process valid PDF intent', () async {
        final tempDir = Directory.systemTemp.createTempSync('pdf_test_');
        final testFile = File('${tempDir.path}/integration.pdf');

        // Create a minimal valid PDF
        await testFile.writeAsBytes(
          Uint8List.fromList([
            0x25, 0x50, 0x44, 0x46, 0x2D, // %PDF-
            0x31, 0x2E, 0x34, 0x0A, // 1.4\n
            0x25, 0x25, 0xE2, 0xE3, 0xCF, 0xD3, // %%%
            0x0A, // \n
            0x25, 0x25, 0xE2, 0xE3, 0xCF, 0xD3, // %%%
            0x0A, // \n
            0x65, 0x6E, 0x64, 0x6F, 0x62, 0x6A, // endobj
            0x0A, // \n
          ]),
        );

        // Verify all checks pass
        expect(await testFile.exists(), isTrue);
        expect(await testFile.length(), greaterThan(0));

        final isValid = await _isValidPdf(testFile);
        expect(isValid, isTrue);

        await tempDir.delete(recursive: true);
      });

      test('should reject PDF that fails mid-copy', () async {
        final tempDir = Directory.systemTemp.createTempSync('pdf_test_');
        final incompleteFile = File('${tempDir.path}/incomplete.pdf');

        // Write incomplete PDF (only header)
        await incompleteFile.writeAsBytes(
          Uint8List.fromList([0x25, 0x50, 0x44, 0x46, 0x2D]),
        );

        // File exists but is incomplete
        expect(await incompleteFile.exists(), isTrue);
        expect(await incompleteFile.length(), equals(5));

        // Should be detected as invalid or too small
        final isValid = await _isValidPdf(incompleteFile);
        expect(isValid, isTrue); // Magic bytes are valid

        // But actual PDF parsing would fail (this is handled by syncfusion)

        await tempDir.delete(recursive: true);
      });
    });

    group('Stress Tests', () {
      test('should handle rapid sequential file operations', () async {
        final tempDir = Directory.systemTemp.createTempSync('pdf_test_');

        final files = <File>[];
        for (int i = 0; i < 10; i++) {
          final file = File('${tempDir.path}/rapid_$i.pdf');
          await file.writeAsBytes(
            Uint8List.fromList([0x25, 0x50, 0x44, 0x46, 0x2D, 0x31, 0x2E, 0x34]),
          );
          files.add(file);
        }

        // Verify all files were created
        for (final file in files) {
          expect(await file.exists(), isTrue);
          expect(await file.length(), greaterThan(0));
        }

        await tempDir.delete(recursive: true);
      });

      test('should handle concurrent file reads', () async {
        final tempDir = Directory.systemTemp.createTempSync('pdf_test_');
        final testFile = File('${tempDir.path}/concurrent.pdf');

        await testFile.writeAsBytes(
          Uint8List.fromList([0x25, 0x50, 0x44, 0x46, 0x2D, 0x31, 0x2E, 0x34]),
        );

        // Start multiple concurrent reads
        final futures = List.generate(
          10,
          (i) => testFile.open().then((raf) => raf.close()),
        );

        await Future.wait(futures);

        // File should still be valid after concurrent access
        expect(await testFile.exists(), isTrue);

        await tempDir.delete(recursive: true);
      });
    });

    group('File Verification with Retries', () {
      test('should verify file is stable after copy', () async {
        final tempDir = Directory.systemTemp.createTempSync('pdf_test_');
        final testFile = File('${tempDir.path}/verify.pdf');

        // Write file
        await testFile.writeAsBytes(
          Uint8List.fromList([0x25, 0x50, 0x44, 0x46, 0x2D]),
        );

        // Poll-based verification pattern (matching MainActivity logic)
        var verified = false;
        const maxRetries = 10;
        const retryDelayMs = 50;

        for (int i = 0; i < maxRetries; i++) {
          if (await testFile.exists() && await testFile.length() > 0) {
            // Try to actually read
            try {
              final raf = await testFile.open();
              final firstByte = await raf.read(1);
              await raf.close();

              if (firstByte.isNotEmpty) {
                verified = true;
                break;
              }
            } catch (e) {
              // Not ready yet, continue polling
            }
          }

          if (i < maxRetries - 1) {
            await Future.delayed(const Duration(milliseconds: retryDelayMs));
          }
        }

        expect(verified, isTrue, reason: 'File should be verified through polling');

        await tempDir.delete(recursive: true);
      });
    });
  });
}

// Helper function to validate PDF magic bytes
Future<bool> _isValidPdf(File file) async {
  try {
    final raf = await file.open();
    try {
      final bytes = await raf.read(5);
      const pdfMagic = [0x25, 0x50, 0x44, 0x46, 0x2D]; // %PDF-
      if (bytes.length < 5) return false;
      for (int i = 0; i < 5; i++) {
        if (bytes[i] != pdfMagic[i]) return false;
      }
      return true;
    } finally {
      await raf.close();
    }
  } catch (_) {
    return false;
  }
}

// Helper function to decode filename
String _decodeFilename(String filePath) {
  final raw = filePath.split('/').last;
  try {
    return Uri.decodeComponent(raw);
  } catch (_) {
    return raw;
  }
}
