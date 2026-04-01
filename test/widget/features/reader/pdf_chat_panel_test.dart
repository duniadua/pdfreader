import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:pdf_reader_app/core/data/models/pdf_document.dart';
import 'package:pdf_reader_app/core/data/repositories/chat_repository.dart';
import 'package:pdf_reader_app/core/services/pdf_ai_service.dart';
import 'package:pdf_reader_app/features/reader/presentation/providers/pdf_chat_state.dart';
import 'package:pdf_reader_app/features/reader/presentation/providers/pdf_chat_notifier.dart';
import 'package:pdf_reader_app/features/reader/presentation/widgets/pdf_chat_panel.dart';

@GenerateMocks([PdfAIService, ChatRepository])
import 'pdf_chat_panel_test.mocks.dart';

void main() {
  late PdfDocument testPdf;
  late MockPdfAIService mockAiService;
  late MockChatRepository mockChatRepository;

  setUp(() {
    // Initialize test data
    final now = DateTime.now();
    testPdf = PdfDocument(
      id: 'test-pdf-1',
      title: 'Test PDF Document',
      filePath: '/path/to/test.pdf',
      fileSize: 1024 * 1024, // 1MB
      createdAt: now,
      lastOpenedAt: now,
      totalPages: 10,
    );

    // Initialize mocks
    mockAiService = MockPdfAIService();
    mockChatRepository = MockChatRepository();
  });

  group('PdfChatPanel Widget Tests', () {
    testWidgets('should render widget without errors', (tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            pdfAIServiceProvider.overrideWithValue(mockAiService),
            chatRepositoryProvider.overrideWithValue(mockChatRepository),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: PdfChatPanel(
                pdfId: testPdf.id,
                pdfPath: testPdf.filePath,
                pdfTitle: testPdf.title,
              ),
            ),
          ),
        ),
      );

      // Act
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(PdfChatPanel), findsOneWidget);
      expect(find.text('AI Assistant'), findsOneWidget);
      expect(find.text(testPdf.title), findsOneWidget);
    });

    testWidgets('should show empty state when no messages', (tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            pdfAIServiceProvider.overrideWithValue(mockAiService),
            chatRepositoryProvider.overrideWithValue(mockChatRepository),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: PdfChatPanel(
                pdfId: testPdf.id,
                pdfPath: testPdf.filePath,
                pdfTitle: testPdf.title,
              ),
            ),
          ),
        ),
      );

      // Act
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Ask anything about this PDF'), findsOneWidget);
      expect(
        find.text('Try quick actions above or type your own question'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.auto_awesome), findsWidgets);
    });

    testWidgets('should show quick action buttons', (tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            pdfAIServiceProvider.overrideWithValue(mockAiService),
            chatRepositoryProvider.overrideWithValue(mockChatRepository),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: PdfChatPanel(
                pdfId: testPdf.id,
                pdfPath: testPdf.filePath,
                pdfTitle: testPdf.title,
              ),
            ),
          ),
        ),
      );

      // Act
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Summary'), findsOneWidget);
      expect(find.text('Key Points'), findsOneWidget);
    });

    testWidgets('should show close button', (tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            pdfAIServiceProvider.overrideWithValue(mockAiService),
            chatRepositoryProvider.overrideWithValue(mockChatRepository),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: PdfChatPanel(
                pdfId: testPdf.id,
                pdfPath: testPdf.filePath,
                pdfTitle: testPdf.title,
              ),
            ),
          ),
        ),
      );

      // Act
      await tester.pumpAndSettle();

      // Assert
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('should have input field', (tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            pdfAIServiceProvider.overrideWithValue(mockAiService),
            chatRepositoryProvider.overrideWithValue(mockChatRepository),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: PdfChatPanel(
                pdfId: testPdf.id,
                pdfPath: testPdf.filePath,
                pdfTitle: testPdf.title,
              ),
            ),
          ),
        ),
      );

      // Act
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(TextField), findsOneWidget);
    });
  });
}
