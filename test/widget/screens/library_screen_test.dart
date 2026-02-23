import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_reader_app/features/library/presentation/library_screen.dart';
import 'package:pdf_reader_app/features/library/presentation/providers/library_notifier.dart';
import 'package:pdf_reader_app/core/data/models/pdf_document.dart';

void main() {
  group('LibraryScreen Widget Tests', () {
    testWidgets('should render without errors', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: const MaterialApp(
            home: LibraryScreen(),
          ),
        ),
      );

      // Just check it doesn't crash
      await tester.pump();
      expect(find.byType(LibraryScreen), findsOneWidget);
    });
  });

  group('LibraryState Unit Tests', () {
    test('should create initial state', () {
      final state = LibraryState.initial();

      expect(state.allPdfs, isEmpty);
      expect(state.recentPdfs, isEmpty);
      expect(state.favoritePdfs, isEmpty);
      expect(state.isLoading, true);
      expect(state.failure, isNull);
    });

    test('copyWith should update specific fields', () {
      final initial = LibraryState.initial();
      final pdfs = [
        PdfDocument(
          id: 'test-1',
          title: 'Test PDF',
          filePath: '/path/to/test.pdf',
          fileSize: 1024,
          createdAt: DateTime(2024, 1, 1),
          lastOpenedAt: DateTime(2024, 1, 1),
          totalPages: 10,
        ),
      ];

      final updated = initial.copyWith(
        allPdfs: pdfs,
        isLoading: false,
      );

      expect(updated.allPdfs, pdfs);
      expect(updated.isLoading, false);
      expect(updated.favoritePdfs, isEmpty);
    });
  });

  group('LibraryTab', () {
    test('should have all expected values', () {
      expect(LibraryTab.library, isNotNull);
      expect(LibraryTab.favorites, isNotNull);
      expect(LibraryTab.timeline, isNotNull);
      expect(LibraryTab.cloud, isNotNull);
    });

    test('enum values should be distinct', () {
      expect(LibraryTab.library == LibraryTab.favorites, false);
      expect(LibraryTab.library == LibraryTab.timeline, false);
      expect(LibraryTab.library == LibraryTab.cloud, false);
    });
  });
}
