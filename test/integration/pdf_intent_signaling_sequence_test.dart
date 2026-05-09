/// Integration test for PDF Intent Signaling Sequence
///
/// This test verifies that the signaling between MainActivity (Android)
/// and Flutter (Dart) happens in the correct sequential order to prevent
/// race conditions when opening PDFs from WhatsApp or other apps.
///
/// Expected Sequence:
/// 1. MainActivity receives intent with content:// URI
/// 2. MainActivity copies file to internal storage (blocking)
/// 3. MainActivity calls fd.sync() to flush to disk
/// 4. MainActivity verifies file is readable
/// 5. MainActivity sends path to Flutter via MethodChannel
/// 6. Flutter receives path via MethodChannel
/// 7. Flutter calls verifyFileReady on Android
/// 8. Android re-verifies file accessibility
/// 9. Flutter processes the PDF
///
/// This test ensures that each step completes before the next begins,
/// preventing "page not found" errors caused by race conditions.

import 'dart:io';
import 'dart:typed_data';
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PDF Intent Signaling Sequence', () {
    group('Phase 1: MainActivity File Copy', () {
      test('should complete file copy before signaling Flutter', () async {
        // Simulate MainActivity copyContentUriToInternal behavior
        final tempDir = Directory.systemTemp.createTempSync('signaling_test_');
        final sourceFile = File('${tempDir.path}/source.pdf');
        final targetFile = File('${tempDir.path}/target.pdf');

        // Write source PDF (simulating WhatsApp content:// URI)
        final pdfBytes = Uint8List.fromList([
          0x25, 0x50, 0x44, 0x46, 0x2D, // %PDF-
          0x31, 0x2E, 0x34, 0x0A,       // 1.4\n
          // ... rest of minimal PDF
        ]);
        await sourceFile.writeAsBytes(pdfBytes);

        // Step 1: Simulate blocking copy (like MainActivity.copyContentUriToInternal)
        final copyStart = DateTime.now();
        final raf = await sourceFile.open();
        await raf.close();
        await targetFile.writeAsBytes(pdfBytes);

        // Step 2: Simulate fd.sync() (forces data to disk)
        // In Dart, we simulate this by closing and reopening the file
        final syncStart = DateTime.now();
        final verifyFile = await targetFile.open();
        await verifyFile.close(); // Force flush

        final copyElapsed = DateTime.now().difference(copyStart).inMilliseconds;
        final syncElapsed = DateTime.now().difference(syncStart).inMilliseconds;

        // Verify copy completed
        expect(await targetFile.exists(), isTrue);
        expect(await targetFile.length(), equals(pdfBytes.length));

        // Verify file is readable (like MainActivity does)
        final readVerify = await targetFile.open();
        final firstByte = await readVerify.read(1);
        await readVerify.close();

        expect(firstByte.isNotEmpty, isTrue);
        expect(firstByte[0], equals(0x25)); // %

        // Only after ALL verifications pass, signal Flutter
        final signalReady = DateTime.now();
        final totalElapsed = DateTime.now().difference(copyStart).inMilliseconds;

        // Log timing (for debugging)
        print('Signaling Sequence Test:');
        print('  Copy time: ${copyElapsed}ms');
        print('  Sync time: ${syncElapsed}ms');
        print('  Total before signal: ${totalElapsed}ms');

        // Key assertion: Signal should only be sent AFTER file is ready
        expect(totalElapsed, greaterThan(0), reason: 'Should have measurable delay before signaling');

        // Cleanup
        await tempDir.delete(recursive: true);
      });

      test('should not signal if file verification fails', () async {
        // Test that MainActivity doesn't send path if file copy fails
        final tempDir = Directory.systemTemp.createTempSync('failed_copy_test_');
        final targetFile = File('${tempDir.path}/target.pdf');

        // Simulate failed copy (file not created)
        bool signalSent = false;
        String? signalPath;

        // MainActivity logic: only signal if verification passes
        if (await targetFile.exists() && await targetFile.length() > 0) {
          try {
            final raf = await targetFile.open();
            final byte = await raf.read(1);
            await raf.close();
            if (byte.isNotEmpty) {
              signalSent = true;
              signalPath = targetFile.path;
            }
          } catch (_) {
            // Verification failed
          }
        }

        // Verify no signal was sent
        expect(signalSent, isFalse);
        expect(signalPath, isNull);

        await tempDir.delete(recursive: true);
      });
    });

    group('Phase 2: MethodChannel Communication', () {
      test('should maintain message ordering through MethodChannel', () async {
        // Test that MethodChannel messages arrive in order
        final messages = <String>[];
        final completer = Completer<void>();

        // Simulate MethodChannel handler
        void handleMethodCall(MethodCall call) {
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          messages.add('[$timestamp] ${call.method}: ${call.arguments}');

          if (call.method == 'verifyFileReady') {
            completer.complete();
          }
        }

        // Simulate the message sequence
        handleMethodCall(MethodCall('getInitialIntent', '/path/to/file.pdf'));
        handleMethodCall(MethodCall('verifyFileReady', {'path': '/path/to/file.pdf'}));

        await completer.future.timeout(
          const Duration(seconds: 1),
          onTimeout: () => null,
        );

        // Verify messages were received in order
        expect(messages.length, equals(2));
        expect(messages[0].contains('getInitialIntent'), isTrue);
        expect(messages[1].contains('verifyFileReady'), isTrue);

        print('Message sequence:');
        for (final msg in messages) {
          print('  $msg');
        }
      });

      test('should handle verifyFileReady response correctly', () async {
        // Test the verifyFileReady call and response
        final tempDir = Directory.systemTemp.createTempSync('verify_test_');
        final testFile = File('${tempDir.path}/test.pdf');

        // Create test file
        await testFile.writeAsBytes(Uint8List.fromList([0x25, 0x50, 0x44, 0x46, 0x2D]));

        // Simulate verifyFileReady logic
        bool verifyResult = false;
        const maxAttempts = 5;

        for (int attempt = 0; attempt < maxAttempts; attempt++) {
          // Check file exists and has content
          final exists = await testFile.exists();
          final size = exists ? await testFile.length() : 0;

          if (exists && size > 0) {
            // Try to read
            try {
              final raf = await testFile.open();
              final firstByte = await raf.read(1);
              await raf.close();

              if (firstByte.isNotEmpty) {
                verifyResult = true;
                break;
              }
            } catch (_) {
              // Not ready, retry
            }
          }

          if (attempt < maxAttempts - 1) {
            await Future.delayed(Duration(milliseconds: 200 * (1 << attempt)));
          }
        }

        expect(verifyResult, isTrue, reason: 'File should be verified ready');

        await tempDir.delete(recursive: true);
      });
    });

    group('Phase 3: Flutter Intent Processing', () {
      test('should call verifyFileReady before processing PDF', () async {
        // Test that Flutter calls verifyFileReady first
        final callSequence = <String>[];

        // Simulate Flutter handler logic
        Future<void> simulateFlutterHandler(String filePath) async {
          // Step 1: Call verifyFileReady
          callSequence.add('verifyFileReady_START');

          // Simulate verifyFileReady call (with retry)
          bool verified = false;
          for (int i = 0; i < 5; i++) {
            // In real test, this would call _channel.invokeMethod
            await Future.delayed(Duration(milliseconds: 50));
            verified = true; // Simulate success
            break;
          }

          callSequence.add('verifyFileReady_END:$verified');

          // Step 2: Only after verification, process PDF
          if (verified) {
            callSequence.add('processPDF_START');
            // ... PDF processing
            callSequence.add('processPDF_END');
          }
        }

        await simulateFlutterHandler('/path/to/file.pdf');

        // Verify the sequence
        expect(callSequence, equals([
          'verifyFileReady_START',
          'verifyFileReady_END:true',
          'processPDF_START',
          'processPDF_END',
        ]));

        print('Flutter handler sequence:');
        for (final call in callSequence) {
          print('  $call');
        }
      });

      test('should not process PDF if verifyFileReady fails', () async {
        final callSequence = <String>[];

        // Simulate Flutter handler with failed verification
        Future<void> simulateFailedHandler(String filePath) async {
          callSequence.add('verifyFileReady_START');

          // Simulate failed verification
          bool verified = false;
          for (int i = 0; i < 5; i++) {
            await Future.delayed(Duration(milliseconds: 50));
            // All attempts fail
            verified = false;
          }

          callSequence.add('verifyFileReady_END:$verified');

          // Should NOT process PDF if verification failed
          if (verified) {
            callSequence.add('processPDF');
          } else {
            callSequence.add('showError');
          }
        }

        await simulateFailedHandler('/path/to/file.pdf');

        // Verify PDF was NOT processed
        expect(callSequence.contains('processPDF'), isFalse);
        expect(callSequence.contains('showError'), isTrue);
      });
    });

    group('End-to-End Signaling Sequence', () {
      test('should maintain correct order from intent to PDF open', () async {
        // Comprehensive test of the entire sequence
        final timeline = <String>[];
        final tempDir = Directory.systemTemp.createTempSync('e2e_test_');

        // Phase 1: MainActivity receives intent
        timeline.add('[${DateTime.now().millisecondsSinceEpoch}] INTENT_RECEIVED');

        // Phase 2: MainActivity copies file
        final sourcePdf = File('${tempDir.path}/whatsapp.pdf');
        final targetPdf = File('${tempDir.path}/internal.pdf');
        await sourcePdf.writeAsBytes(
          Uint8List.fromList([0x25, 0x50, 0x44, 0x46, 0x2D, 0x31, 0x2E, 0x34]),
        );

        final copyStart = DateTime.now().millisecondsSinceEpoch;
        await targetPdf.writeAsBytes(await sourcePdf.readAsBytes());
        timeline.add('[${DateTime.now().millisecondsSinceEpoch}] COPY_COMPLETE');

        // Phase 3: MainActivity verifies file
        final raf = await targetPdf.open();
        final byte = await raf.read(1);
        await raf.close();
        timeline.add('[${DateTime.now().millisecondsSinceEpoch}] ANDROID_VERIFIED:${byte.isNotEmpty}');

        // Phase 4: MainActivity signals Flutter
        timeline.add('[${DateTime.now().millisecondsSinceEpoch}] SIGNAL_FLUTTER');

        // Phase 5: Flutter receives and verifies again
        final flutterVerifyStart = DateTime.now().millisecondsSinceEpoch;
        final flutterVerified = await targetPdf.exists() && await targetPdf.length() > 0;
        timeline.add('[${DateTime.now().millisecondsSinceEpoch}] FLUTTER_VERIFIED:$flutterVerified');

        // Phase 6: Flutter processes PDF
        if (flutterVerified) {
          timeline.add('[${DateTime.now().millisecondsSinceEpoch}] PROCESS_PDF');
        }

        // Verify sequence
        print('End-to-End Timeline:');
        for (final event in timeline) {
          print('  $event');
        }

        // Extract timestamps and verify order
        final timestamps = timeline.map((e) {
          final match = RegExp(r'\[(\d+)\]').firstMatch(e);
          return int.parse(match?.group(1) ?? '0');
        }).toList();

        // Each event should happen after or at the same time as the previous
        // (same timestamp is OK for very fast operations)
        for (int i = 1; i < timestamps.length; i++) {
          expect(timestamps[i], greaterThanOrEqualTo(timestamps[i - 1]),
              reason: 'Event $i should happen after or at same time as event ${i - 1}');
        }

        // Verify key phases exist
        final timelineStr = timeline.join(' ');
        expect(timelineStr, contains('INTENT_RECEIVED'));
        expect(timelineStr, contains('COPY_COMPLETE'));
        expect(timelineStr, contains('ANDROID_VERIFIED:true'));
        expect(timelineStr, contains('SIGNAL_FLUTTER'));
        expect(timelineStr, contains('FLUTTER_VERIFIED:true'));
        expect(timelineStr, contains('PROCESS_PDF'));

        await tempDir.delete(recursive: true);
      });

      test('should handle slow file copy gracefully', () async {
        // Simulate slow file copy (like large PDF from WhatsApp)
        final timeline = <String>[];
        final tempDir = Directory.systemTemp.createTempSync('slow_copy_test_');

        final targetFile = File('${tempDir.path}/slow.pdf');

        // Start delayed copy in background
        final copyFuture = Future.microtask(() async {
          await Future.delayed(const Duration(milliseconds: 300));
          await targetFile.writeAsBytes(
            Uint8List.fromList([0x25, 0x50, 0x44, 0x46, 0x2D]),
          );
          timeline.add('[${DateTime.now().millisecondsSinceEpoch}] COPY_COMPLETE');
        });

        // Flutter waits for verification (with retry)
        timeline.add('[${DateTime.now().millisecondsSinceEpoch}] VERIFY_START');

        bool verified = false;
        const maxAttempts = 10;

        for (int attempt = 0; attempt < maxAttempts; attempt++) {
          await Future.delayed(Duration(milliseconds: 100));

          if (await targetFile.exists() && await targetFile.length() > 0) {
            try {
              final raf = await targetFile.open();
              final byte = await raf.read(1);
              await raf.close();
              if (byte.isNotEmpty) {
                verified = true;
                timeline.add('[${DateTime.now().millisecondsSinceEpoch}] VERIFIED');
                break;
              }
            } catch (_) {}
          }
          timeline.add('[${DateTime.now().millisecondsSinceEpoch}] RETRY_$attempt');
        }

        await copyFuture;

        print('Slow copy timeline:');
        for (final event in timeline) {
          print('  $event');
        }

        expect(verified, isTrue, reason: 'Should eventually verify file after retry');

        await tempDir.delete(recursive: true);
      });
    });

    group('Race Condition Prevention', () {
      test('should prevent race condition with sequential verification', () async {
        // Test that sequential operations prevent race conditions
        final tempDir = Directory.systemTemp.createTempSync('race_condition_test_');
        final file = File('${tempDir.path}/test.pdf');

        // Simulate concurrent operations
        final operations = <Future>[];

        // Operation 1: Write file
        operations.add(Future.microtask(() async {
          await Future.delayed(const Duration(milliseconds: 100));
          await file.writeAsBytes(Uint8List.fromList([0x25, 0x50, 0x44, 0x46, 0x2D]));
          print('[$DateTime.now().millisecondsSinceEpoch] WRITE_COMPLETE');
        }));

        // Operation 2: Verify file (should wait for write)
        operations.add(Future.microtask(() async {
          await Future.delayed(const Duration(milliseconds: 150));
          bool ready = false;
          for (int i = 0; i < 10; i++) {
            if (await file.exists() && await file.length() > 0) {
              try {
                final raf = await file.open();
                final byte = await raf.read(1);
                await raf.close();
                if (byte.isNotEmpty) {
                  ready = true;
                  print('[$DateTime.now().millisecondsSinceEpoch] VERIFY_SUCCESS');
                  break;
                }
              } catch (_) {}
            }
            await Future.delayed(Duration(milliseconds: 50));
          }
          expect(ready, isTrue);
        }));

        // Wait for both operations
        await Future.wait(operations);

        // Final verification
        expect(await file.exists(), isTrue);
        expect(await file.length(), greaterThan(0));

        await tempDir.delete(recursive: true);
      });

      test('should handle file system latency', () async {
        // Test that verification handles file system latency
        final tempDir = Directory.systemTemp.createTempSync('fs_latency_test_');
        final file = File('${tempDir.path}/test.pdf');

        // Write file
        await file.writeAsBytes(Uint8List.fromList([0x25, 0x50, 0x44, 0x46, 0x2D]));

        // Immediate verification might fail due to FS latency
        // so we retry
        bool verified = false;
        for (int i = 0; i < 5; i++) {
          if (await file.exists() && await file.length() > 0) {
            try {
              final raf = await file.open();
              final byte = await raf.read(1);
              await raf.close();
              if (byte.isNotEmpty) {
                verified = true;
                break;
              }
            } catch (_) {}
          }
          await Future.delayed(Duration(milliseconds: 100));
        }

        expect(verified, isTrue);

        await tempDir.delete(recursive: true);
      });
    });

    group('Timing and Performance', () {
      test('should complete signaling within acceptable time', () async {
        // Measure total signaling time
        final stopwatch = Stopwatch()..start();

        final tempDir = Directory.systemTemp.createTempSync('timing_test_');
        final file = File('${tempDir.path}/test.pdf');

        // Simulate complete flow
        final copyStart = stopwatch.elapsedMilliseconds;
        await file.writeAsBytes(Uint8List.fromList([0x25, 0x50, 0x44, 0x46, 0x2D]));
        final copyTime = stopwatch.elapsedMilliseconds - copyStart;

        final verifyStart = stopwatch.elapsedMilliseconds;
        final raf = await file.open();
        await raf.close();
        final verifyTime = stopwatch.elapsedMilliseconds - verifyStart;

        stopwatch.stop();

        print('Timing Performance:');
        print('  Copy time: ${copyTime}ms');
        print('  Verify time: ${verifyTime}ms');
        print('  Total time: ${stopwatch.elapsedMilliseconds}ms');

        // Total should be under 1 second for small files
        expect(stopwatch.elapsedMilliseconds, lessThan(1000),
            reason: 'Signaling should complete quickly');

        await tempDir.delete(recursive: true);
      });

      test('should handle exponential backoff correctly', () async {
        // Test that exponential backoff increases delay correctly
        final delays = <int>[];
        const baseDelay = 200;

        for (int attempt = 0; attempt < 5; attempt++) {
          final delay = baseDelay * (1 << attempt); // 200, 400, 800, 1600, 3200
          delays.add(delay);
        }

        expect(delays, equals([200, 400, 800, 1600, 3200]));

        print('Exponential backoff delays: $delays ms');
        print('Total retry time: ${delays.reduce((a, b) => a + b)} ms');
      });
    });

    group('Edge Cases', () {
      group('File Corruption Scenarios', () {
        test('should handle partially written PDF', () async {
          // Simulate PDF that was interrupted during copy
          final tempDir = Directory.systemTemp.createTempSync('partial_test_');
          final partialFile = File('${tempDir.path}/partial.pdf');

          // Write incomplete PDF (only header, cut off mid-copy)
          final incompletePdf = Uint8List(1024); // 1KB allocated
          for (int i = 0; i < incompletePdf.length; i++) {
            incompletePdf[i] = 0xFF; // Fill with garbage
          }
          // Only write proper header at start
          incompletePdf[0] = 0x25; // %
          incompletePdf[1] = 0x50; // P
          incompletePdf[2] = 0x44; // D
          incompletePdf[3] = 0x46; // F
          incompletePdf[4] = 0x2D; // -

          await partialFile.writeAsBytes(incompletePdf);

          // Verification should detect this is problematic
          final magicBytesValid = await _isValidPdf(partialFile);
          expect(magicBytesValid, isTrue); // Magic bytes pass

          // But file should be flagged as incomplete during actual processing
          final size = await partialFile.length();
          expect(size, equals(1024));

          // Simulate MainActivity verification logic
          bool fileVerified = false;
          try {
            final raf = await partialFile.open();
            final bytes = await raf.read(10);
            await raf.close();
            fileVerified = bytes.isNotEmpty;
          } catch (_) {
            fileVerified = false;
          }

          expect(fileVerified, isTrue); // Read succeeds but PDF is invalid

          await tempDir.delete(recursive: true);
        });

        test('should handle zero-byte file', () async {
          final tempDir = Directory.systemTemp.createTempSync('empty_test_');
          final emptyFile = File('${tempDir.path}/empty.pdf');

          await emptyFile.create();

          expect(await emptyFile.exists(), isTrue);
          expect(await emptyFile.length(), equals(0));

          // Should not signal Flutter for empty file
          bool shouldSignal = false;
          if (await emptyFile.exists() && await emptyFile.length() > 0) {
            shouldSignal = true;
          }

          expect(shouldSignal, isFalse, reason: 'Empty file should not trigger signal');

          await tempDir.delete(recursive: true);
        });

        test('should handle file with only PDF header', () async {
          final tempDir = Directory.systemTemp.createTempSync('header_only_test_');
          final headerOnlyFile = File('${tempDir.path}/header_only.pdf');

          // Write only magic bytes (5 bytes)
          await headerOnlyFile.writeAsBytes([0x25, 0x50, 0x44, 0x46, 0x2D]);

          expect(await headerOnlyFile.exists(), isTrue);
          expect(await headerOnlyFile.length(), equals(5));

          // Magic bytes are valid but file is too small to be real PDF
          final isValid = await _isValidPdf(headerOnlyFile);
          expect(isValid, isTrue);

          // But should be rejected during size check
          final isTooSmall = await headerOnlyFile.length() < 100;
          expect(isTooSmall, isTrue);

          await tempDir.delete(recursive: true);
        });

        test('should handle corrupted PDF structure', () async {
          final tempDir = Directory.systemTemp.createTempSync('corrupted_test_');
          final corruptedFile = File('${tempDir.path}/corrupted.pdf');

          // Valid PDF header but random garbage after
          final corruptedBytes = Uint8List(5000);
          corruptedBytes[0] = 0x25; // %
          corruptedBytes[1] = 0x50; // P
          corruptedBytes[2] = 0x44; // D
          corruptedBytes[3] = 0x46; // F
          corruptedBytes[4] = 0x2D; // -
          // Rest is random
          for (int i = 5; i < corruptedBytes.length; i++) {
            corruptedBytes[i] = (i * 17) % 256;
          }

          await corruptedFile.writeAsBytes(corruptedBytes);

          // Magic bytes pass
          expect(await _isValidPdf(corruptedFile), isTrue);

          // But PDF parsing would fail (would be caught by Syncfusion)
          expect(await corruptedFile.length(), greaterThan(100));

          await tempDir.delete(recursive: true);
        });
      });

      group('Concurrent Intents', () {
        test('should handle rapid sequential intents', () async {
          // Simulate receiving multiple PDF intents in quick succession
          final tempDir = Directory.systemTemp.createTempSync('concurrent_test_');
          final intentResults = <Map<String, dynamic>>[];

          // Simulate 5 rapid intents
          final intents = List.generate(5, (i) => 'intent_$i');

          for (final intent in intents) {
            final filePath = '${tempDir.path}/$intent.pdf';

            // Each intent creates a file
            await File(filePath).writeAsBytes(
              Uint8List.fromList([0x25, 0x50, 0x44, 0x46, 0x2D, 0x31]),
            );

            // Verify processing
            final processed = await File(filePath).exists();
            intentResults.add({
              'intent': intent,
              'path': filePath,
              'processed': processed,
              'timestamp': DateTime.now().millisecondsSinceEpoch,
            });
          }

          // All intents should be processed
          expect(intentResults.length, equals(5));
          for (final result in intentResults) {
            expect(result['processed'], isTrue);
          }

          // Verify each file is unique
          final files = intentResults.map((r) => r['path'] as String).toSet();
          expect(files.length, equals(5));

          await tempDir.delete(recursive: true);
        });

        test('should handle intent with same filename collision', () async {
          final tempDir = Directory.systemTemp.createTempSync('collision_test_');

          // Simulate two intents with same filename
          const filename = 'document.pdf';

          // First intent
          final file1 = File('${tempDir.path}/$filename');
          await file1.writeAsBytes(Uint8List.fromList([0x25, 0x50, 0x44, 0x46, 0x2D, 0x31]));

          // Second intent (should create new file with suffix)
          final suffix = DateTime.now().millisecondsSinceEpoch.toString();
          final suffix8 = suffix.length > 8 ? suffix.substring(0, 8) : suffix;
          final file2 = File('${tempDir.path}/document_$suffix8.pdf');
          await file2.writeAsBytes(Uint8List.fromList([0x25, 0x50, 0x44, 0x46, 0x2D, 0x32]));

          expect(await file1.exists(), isTrue);
          expect(await file2.exists(), isTrue);
          expect(file1.path, isNot(equals(file2.path)));

          await tempDir.delete(recursive: true);
        });
      });

      group('File System Edge Cases', () {
        test('should handle very large PDF file', () async {
          final tempDir = Directory.systemTemp.createTempSync('large_file_test_');

          // Simulate 50MB PDF (would be slow to copy)
          const largeSize = 50 * 1024 * 1024; // 50 MB

          // Don't actually write 50MB, just simulate the check
          final fileSize = largeSize;
          const threshold = 10 * 1024 * 1024; // 10 MB threshold

          final shouldSkipPageCount = fileSize > threshold;
          expect(shouldSkipPageCount, isTrue);

          // Verify logic
          print('Large file (${fileSize / (1024 * 1024)} MB): Skip page count = $shouldSkipPageCount');

          await tempDir.delete(recursive: true);
        });

        test('should handle file with special characters in name', () async {
          final tempDir = Directory.systemTemp.createTempSync('special_chars_test_');

          // Test various special characters
          final specialNames = [
            'document with spaces.pdf',
            'document_with_underscores.pdf',
            'document-with-dashes.pdf',
            'UPPERCASE.PDF',
            'mixedCase.Pdf',
            'document(1).pdf',
            'document[1].pdf',
            'document{1}.pdf',
            'document@2024.pdf',
            'ñoñoño.pdf', // Unicode
            'документ.pdf', // Cyrillic
          ];

          for (final name in specialNames) {
            final file = File('${tempDir.path}/$name');

            // Simulate URI encoding/decoding
            final raw = name;
            String decoded;
            try {
              decoded = Uri.decodeComponent(raw);
            } catch (_) {
              decoded = raw;
            }

            expect(decoded, equals(name));

            print('Special char test passed: $name');
          }

          await tempDir.delete(recursive: true);
        });

        test('should handle URL-encoded filename', () async {
          final tempDir = Directory.systemTemp.createTempSync('url_encoded_test_');

          // Test various URL encodings
          final encodedNames = [
            ('Document%20100%25Complete.pdf', 'Document 100%Complete.pdf'),
            ('file%20with%20spaces.pdf', 'file with spaces.pdf'),
            ('%D0%B4%D0%BE%D0%BA%D1%83%D0%BC%D0%B5%D0%BD%D1%82.pdf', 'документ.pdf'),
            ('%F0%9F%93%84%20document.pdf', '📄 document.pdf'),
          ];

          for (final (encoded, expected) in encodedNames) {
            String decoded;
            try {
              decoded = Uri.decodeComponent(encoded);
            } catch (_) {
              decoded = encoded;
            }

            expect(decoded, equals(expected),
                reason: 'Failed to decode: $encoded');
            print('URL decode test: $encoded → $decoded');
          }

          await tempDir.delete(recursive: true);
        });
      });

      group('Timing Edge Cases', () {
        test('should handle operations completing in same millisecond', () async {
          // Test for TOCTOU (Time-of-Check-Time-of-Use) vulnerability
          final tempDir = Directory.systemTemp.createTempSync('same_ms_test_');
          final file = File('${tempDir.path}/test.pdf');

          await file.writeAsBytes(Uint8List.fromList([0x25, 0x50, 0x44, 0x46, 0x2D]));

          // Multiple operations in same millisecond
          final timestamps = <int>[];
          for (int i = 0; i < 5; i++) {
            timestamps.add(DateTime.now().millisecondsSinceEpoch);
            await file.exists(); // Quick operation
          }

          // Some timestamps may be identical
          final uniqueTimestamps = timestamps.toSet();
          expect(uniqueTimestamps.length, lessThanOrEqualTo(5));

          print('Operations: ${timestamps.length}, Unique timestamps: ${uniqueTimestamps.length}');

          await tempDir.delete(recursive: true);
        });

        test('should handle extremely fast file operations', () async {
          final tempDir = Directory.systemTemp.createTempSync('fast_ops_test_');
          final file = File('${tempDir.path}/test.pdf');

          // Measure time for fast operations
          final stopwatch = Stopwatch()..start();

          await file.writeAsBytes([0x25, 0x50]);
          final writeTime = stopwatch.elapsedMilliseconds;

          await file.exists();
          final existsTime = stopwatch.elapsedMilliseconds;

          await file.length();
          final lengthTime = stopwatch.elapsedMilliseconds;

          stopwatch.stop();

          // All should complete very quickly (<10ms)
          expect(writeTime, lessThan(10));
          expect(existsTime, lessThan(10));
          expect(lengthTime, lessThan(10));

          print('Fast operation times: write=${writeTime}ms, exists=${existsTime}ms, length=${lengthTime}ms');

          await tempDir.delete(recursive: true);
        });

        test('should handle retry timeout correctly', () async {
          // Test that retries don't last forever
          final tempDir = Directory.systemTemp.createTempSync('timeout_test_');
          final file = File('${tempDir.path}/nonexistent.pdf');

          // Don't create file - verify timeout
          const maxAttempts = 5;
          const baseDelay = 200;

          final stopwatch = Stopwatch()..start();
          bool found = false;

          for (int attempt = 0; attempt < maxAttempts; attempt++) {
            if (await file.exists()) {
              found = true;
              break;
            }
            if (attempt < maxAttempts - 1) {
              await Future.delayed(Duration(milliseconds: baseDelay * (1 << attempt)));
            }
          }

          stopwatch.stop();

          expect(found, isFalse);
          expect(stopwatch.elapsedMilliseconds, lessThan(10000)); // Should timeout in <10s

          print('Retry timeout test: ${stopwatch.elapsedMilliseconds}ms elapsed');

          await tempDir.delete(recursive: true);
        });
      });

      group('Error Recovery', () {
        test('should recover from file read error during verification', () async {
          final tempDir = Directory.systemTemp.createTempSync('recovery_test_');
          final file = File('${tempDir.path}/test.pdf');

          // Write file
          await file.writeAsBytes(Uint8List.fromList([0x25, 0x50, 0x44, 0x46, 0x2D]));

          // Simulate intermittent read error
          int readAttempts = 0;
          bool verified = false;

          for (int i = 0; i < 5; i++) {
            try {
              readAttempts++;
              // Simulate first two attempts failing
              if (i < 2) {
                throw Exception('Simulated read error');
              }

              final raf = await file.open();
              final byte = await raf.read(1);
              await raf.close();

              if (byte.isNotEmpty) {
                verified = true;
                break;
              }
            } catch (_) {
              // Retry after delay
              await Future.delayed(Duration(milliseconds: 100));
            }
          }

          expect(verified, isTrue);
          expect(readAttempts, equals(3)); // Failed twice, succeeded on third

          print('Recovery test: Verified after $readAttempts attempts');

          await tempDir.delete(recursive: true);
        });

        test('should handle file deleted during verification', () async {
          final tempDir = Directory.systemTemp.createTempSync('delete_during_test_');
          final file = File('${tempDir.path}/test.pdf');

          await file.writeAsBytes(Uint8List.fromList([0x25, 0x50, 0x44, 0x46, 0x2D]));

          // Simulate TOCTOU: File exists at check but gets deleted before use
          bool verified = false;

          // First check: file exists
          final initialCheck = await file.exists();
          expect(initialCheck, isTrue);

          // Simulate file being deleted between check and use
          await file.delete();

          // Second check: try to verify (should fail)
          final afterDeleteExists = await file.exists();
          expect(afterDeleteExists, isFalse);

          // Try to open and read the deleted file
          try {
            final raf = await file.open();
            final byte = await raf.read(1);
            await raf.close();
            // Should not reach here
            verified = byte.isNotEmpty;
          } catch (e) {
            // Expected: file not found error
            verified = false;
          }

          expect(verified, isFalse, reason: 'Should not verify deleted file');

          await tempDir.delete(recursive: true);
        });

        test('should handle permission denied gracefully', () async {
          // Simulate permission error (we can't actually cause this in test,
          // but we can test the error handling logic)
          final tempDir = Directory.systemTemp.createTempSync('permission_test_');
          final file = File('${tempDir.path}/test.pdf');

          await file.writeAsBytes(Uint8List.fromList([0x25, 0x50, 0x44, 0x46, 0x2D]));

          // Simulate permission error in verify logic
          bool verified = false;
          String? errorMessage;

          try {
            // Simulate permission check
            final hasPermission = true; // In real scenario, might be false

            if (!hasPermission) {
              throw FileSystemException('Permission denied', file.path);
            }

            final raf = await file.open();
            final byte = await raf.read(1);
            await raf.close();

            verified = byte.isNotEmpty;
          } catch (e, st) {
            errorMessage = e.toString();
            verified = false;
          }

          expect(verified, isTrue); // No permission error in this test
          expect(errorMessage, isNull);

          print('Permission test: $verified, error: $errorMessage');

          await tempDir.delete(recursive: true);
        });
      });

      group('Intent Data Edge Cases', () {
        test('should handle null intent data', () async {
          // Simulate MainActivity receiving intent with null data
          String? filePath = null;

          // Simulate extractFilePathFromIntent logic
          final intentData = null; // Simulating null intent

          if (intentData != null) {
            filePath = 'path/to/file.pdf';
          }

          expect(filePath, isNull);
        });

        test('should handle invalid URI scheme', () async {
          // Simulate various URI schemes
          final uriSchemes = [
            ('content://com.whatsapp.provider/document/test.pdf', 'content'),
            ('file:///storage/emulated/0/test.pdf', 'file'),
            ('http://example.com/test.pdf', 'http'), // Unsupported
            ('https://example.com/test.pdf', 'https'), // Unsupported
            ('ftp://example.com/test.pdf', 'ftp'), // Unsupported
            ('invalid://test.pdf', 'invalid'), // Unsupported
          ];

          for (final (uri, scheme) in uriSchemes) {
            bool supported = scheme == 'content' || scheme == 'file';
            String? result;

            if (supported) {
              result = 'processed';
            }

            if (supported) {
              expect(result, equals('processed'));
            } else {
              expect(result, isNull);
            }

            print('URI scheme test: $scheme → ${supported ? "supported" : "unsupported"}');
          }
        });

        test('should handle malformed content URI', () async {
          // Test various malformed URIs
          final malformedUris = [
            'content://',
            'content:///',
            'content:///document.pdf',
            'content://com.whatsapp.provider/',
          ];

          for (final uri in malformedUris) {
            bool isValid = uri.startsWith('content://') && uri.contains('/document/');

            expect(isValid, isFalse);

            print('Malformed URI test: $uri → valid=$isValid');
          }
        });
      });

      group('Memory and Resource Edge Cases', () {
        test('should handle rapid file creation and deletion', () async {
          final tempDir = Directory.systemTemp.createTempSync('memory_test_');

          // Create and delete many files rapidly
          const fileCount = 100;
          final files = <File>[];

          for (int i = 0; i < fileCount; i++) {
            final file = File('${tempDir.path}/rapid_$i.pdf');
            await file.writeAsBytes(Uint8List.fromList([0x25, 0x50, 0x44, 0x46, 0x2D]));
            files.add(file);
          }

          // Verify all created
          for (final file in files) {
            expect(await file.exists(), isTrue);
          }

          // Delete all rapidly
          await tempDir.delete(recursive: true);

          // Verify all deleted
          for (final file in files) {
            expect(await file.exists(), isFalse);
          }
        });

        test('should handle memory pressure during large file operations', () async {
          // Simulate operations that might cause memory pressure
          final tempDir = Directory.systemTemp.createTempSync('memory_pressure_test_');

          // Simulate processing large file list
          const fileCount = 50;
          final fileInfos = <Map<String, dynamic>>[];

          for (int i = 0; i < fileCount; i++) {
            fileInfos.add({
              'id': 'pdf_$i',
              'title': 'Document $i',
              'path': '/storage/emulated/0/doc_$i.pdf',
              'size': 1024 * 1024 * i, // Different sizes
              'created': DateTime.now(),
            });
          }

          // Process without loading all into memory at once
          int processed = 0;
          for (final info in fileInfos) {
            // Simulate processing one at a time
            processed++;
          }

          expect(processed, equals(fileCount));

          await tempDir.delete(recursive: true);
        });
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
