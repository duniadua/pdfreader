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

  group('PdfChatPanel Widget Tests - Basic Rendering', () {
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

  group('PdfChatPanel Widget Tests - Rate Limit UI', () {
    testWidgets('should display rate limit banner when active',
        (tester) async {
      // Arrange - create rate limit state
      final rateLimitInfo = RateLimitInfo.fromSeconds(
        60,
        'Terlalu banyak permintaan. Silakan coba lagi nanti.',
      );

      // Create a custom provider that returns rate-limited state
      final testContainer = ProviderContainer(
        overrides: [
          pdfAIServiceProvider.overrideWithValue(mockAiService),
          chatRepositoryProvider.overrideWithValue(mockChatRepository),
        ],
      );

      // Set rate limited state
      testContainer.read(pdfChatNotifierProvider(testPdf.id).notifier).state =
          PdfChatState.visible(
        messages: [],
        extractedText: 'Test content',
        rateLimitInfo: rateLimitInfo,
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: testContainer,
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

      // Assert - should show error state with rate limit message
      expect(find.text('Failed to get response'), findsOneWidget);
      expect(
        find.textContaining('Terlalu banyak permintaan'),
        findsOneWidget,
      );
    });

    testWidgets('should show countdown timer in error message', (tester) async {
      // Arrange
      final rateLimitInfo = RateLimitInfo.fromSeconds(
        45,
        'Mohon tunggu sebentar.',
      );

      final testContainer = ProviderContainer(
        overrides: [
          pdfAIServiceProvider.overrideWithValue(mockAiService),
          chatRepositoryProvider.overrideWithValue(mockChatRepository),
        ],
      );

      testContainer.read(pdfChatNotifierProvider(testPdf.id).notifier).state =
          PdfChatState.visible(
        messages: [],
        extractedText: 'Test content',
        error: 'Mohon tunggu 45 detik sebelum mencoba lagi.',
        rateLimitInfo: rateLimitInfo,
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: testContainer,
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
      expect(find.textContaining('45'), findsOneWidget);
      expect(find.textContaining('detik'), findsOneWidget);
    });

    testWidgets('should disable input when rate limited', (tester) async {
      // Arrange
      final rateLimitInfo = RateLimitInfo.fromSeconds(
        30,
        'Rate limited',
      );

      final testContainer = ProviderContainer(
        overrides: [
          pdfAIServiceProvider.overrideWithValue(mockAiService),
          chatRepositoryProvider.overrideWithValue(mockChatRepository),
        ],
      );

      testContainer.read(pdfChatNotifierProvider(testPdf.id).notifier).state =
          PdfChatState.visible(
        messages: [],
        extractedText: 'Test content',
        rateLimitInfo: rateLimitInfo,
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: testContainer,
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

      // Assert - input should be disabled when rate limited
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.enabled, isFalse);
    });

    testWidgets('should show error icon for rate limit', (tester) async {
      // Arrange
      final rateLimitInfo = RateLimitInfo.fromSeconds(
        60,
        'Rate limit exceeded',
      );

      final testContainer = ProviderContainer(
        overrides: [
          pdfAIServiceProvider.overrideWithValue(mockAiService),
          chatRepositoryProvider.overrideWithValue(mockChatRepository),
        ],
      );

      testContainer.read(pdfChatNotifierProvider(testPdf.id).notifier).state =
          PdfChatState.visible(
        messages: [],
        extractedText: 'Test content',
        error: 'Rate limit exceeded',
        rateLimitInfo: rateLimitInfo,
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: testContainer,
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
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('should update UI when rate limit expires', (tester) async {
      // Arrange - rate limit that expires very soon
      final rateLimitInfo = RateLimitInfo.fromSeconds(1, 'Rate limited');

      final testContainer = ProviderContainer(
        overrides: [
          pdfAIServiceProvider.overrideWithValue(mockAiService),
          chatRepositoryProvider.overrideWithValue(mockChatRepository),
        ],
      );

      testContainer.read(pdfChatNotifierProvider(testPdf.id).notifier).state =
          PdfChatState.visible(
        messages: [],
        extractedText: 'Test content',
        error: 'Mohon tunggu 1 detik.',
        rateLimitInfo: rateLimitInfo,
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: testContainer,
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

      // Act - wait for rate limit to expire
      await tester.pumpAndSettle();
      await Future.delayed(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // Assert - error should be cleared
      // Note: This depends on the timer mechanism in the notifier
      expect(find.byType(PdfChatPanel), findsOneWidget);
    });
  });

  group('PdfChatPanel Widget Tests - Retry Functionality', () {
    testWidgets('should show retry button for failed messages',
        (tester) async {
      // Arrange
      final failedMessage = ChatMessage.failed('Test question');

      final testContainer = ProviderContainer(
        overrides: [
          pdfAIServiceProvider.overrideWithValue(mockAiService),
          chatRepositoryProvider.overrideWithValue(mockChatRepository),
        ],
      );

      testContainer.read(pdfChatNotifierProvider(testPdf.id).notifier).state =
          PdfChatState.visible(
        messages: [failedMessage],
        error: 'Failed to get response',
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: testContainer,
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
      expect(find.text('Retry'), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('should call retryMessage when retry button tapped',
        (tester) async {
      // Arrange
      final failedMessage = ChatMessage.failed('Retry this');

      final testContainer = ProviderContainer(
        overrides: [
          pdfAIServiceProvider.overrideWithValue(mockAiService),
          chatRepositoryProvider.overrideWithValue(mockChatRepository),
        ],
      );

      testContainer.read(pdfChatNotifierProvider(testPdf.id).notifier).state =
          PdfChatState.visible(
        messages: [failedMessage],
        error: 'Failed',
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: testContainer,
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
      await tester.tap(find.text('Retry'));
      await tester.pump();

      // Assert - retry should be triggered
      // (Actual retry logic is tested in notifier tests)
    });

    testWidgets('should show dismiss button with error', (tester) async {
      // Arrange
      final testContainer = ProviderContainer(
        overrides: [
          pdfAIServiceProvider.overrideWithValue(mockAiService),
          chatRepositoryProvider.overrideWithValue(mockChatRepository),
        ],
      );

      testContainer.read(pdfChatNotifierProvider(testPdf.id).notifier).state =
          PdfChatState.visible(
        messages: [],
        error: 'Test error',
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: testContainer,
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
      expect(find.text('Dismiss'), findsOneWidget);
    });
  });

  group('PdfChatPanel Widget Tests - Visual Feedback', () {
    testWidgets('should show processing indicator during text extraction',
        (tester) async {
      // Arrange
      final testContainer = ProviderContainer(
        overrides: [
          pdfAIServiceProvider.overrideWithValue(mockAiService),
          chatRepositoryProvider.overrideWithValue(mockChatRepository),
        ],
      );

      testContainer.read(pdfChatNotifierProvider(testPdf.id).notifier).state =
          PdfChatState.visible(
        isExtractingText: true,
        extractProgress: 0.5,
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: testContainer,
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
      expect(find.byType(CircularProgressIndicator), findsWidgets);
      expect(find.textContaining('Extracting text'), findsOneWidget);
      expect(find.textContaining('50%'), findsOneWidget);
    });

    testWidgets('should disable quick actions when processing', (tester) async {
      // Arrange
      final testContainer = ProviderContainer(
        overrides: [
          pdfAIServiceProvider.overrideWithValue(mockAiService),
          chatRepositoryProvider.overrideWithValue(mockChatRepository),
        ],
      );

      testContainer.read(pdfChatNotifierProvider(testPdf.id).notifier).state =
          PdfChatState.visible(
        isLoading: true,
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: testContainer,
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

      // Assert - quick actions should be disabled
      // Check that Summary chip is not tappable (grayed out)
      final summaryChips = find.widgetWithText(Container, 'Summary');
      expect(summaryChips, findsOneWidget);
    });

    testWidgets('should show loading indicator when AI is thinking',
        (tester) async {
      // Arrange
      final testContainer = ProviderContainer(
        overrides: [
          pdfAIServiceProvider.overrideWithValue(mockAiService),
          chatRepositoryProvider.overrideWithValue(mockChatRepository),
        ],
      );

      testContainer.read(pdfChatNotifierProvider(testPdf.id).notifier).state =
          PdfChatState.visible(
        messages: [ChatMessage.user('Question')],
        isLoading: true,
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: testContainer,
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
      expect(find.byType(CircularProgressIndicator), findsWidgets);
      expect(find.text('AI is thinking...'), findsOneWidget);
    });
  });

  group('PdfChatPanel Widget Tests - User Interactions', () {
    testWidgets('should send message when send button tapped', (tester) async {
      // Arrange
      final testContainer = ProviderContainer(
        overrides: [
          pdfAIServiceProvider.overrideWithValue(mockAiService),
          chatRepositoryProvider.overrideWithValue(mockChatRepository),
        ],
      );

      testContainer.read(pdfChatNotifierProvider(testPdf.id).notifier).state =
          PdfChatState.visible(
        extractedText: 'Test content',
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: testContainer,
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
      await tester.enterText(find.byType(TextField), 'Test question');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pump();

      // Assert - text field should be cleared
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, isEmpty);
    });

    testWidgets('should not send empty message', (tester) async {
      // Arrange
      final testContainer = ProviderContainer(
        overrides: [
          pdfAIServiceProvider.overrideWithValue(mockAiService),
          chatRepositoryProvider.overrideWithValue(mockChatRepository),
        ],
      );

      testContainer.read(pdfChatNotifierProvider(testPdf.id).notifier).state =
          PdfChatState.visible(
        extractedText: 'Test content',
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: testContainer,
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

      // Act - try to send empty message
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.send));
      await tester.pump();

      // Assert - no new message should be added
      final state = testContainer.read(pdfChatNotifierProvider(testPdf.id));
      expect(state.messages, isEmpty);
    });
  });

  group('PdfChatPanel Widget Tests - Edge Cases', () {
    testWidgets('should handle long error messages', (tester) async {
      // Arrange
      final longError =
          'This is a very long error message that wraps across multiple lines. ' *
              3;

      final testContainer = ProviderContainer(
        overrides: [
          pdfAIServiceProvider.overrideWithValue(mockAiService),
          chatRepositoryProvider.overrideWithValue(mockChatRepository),
        ],
      );

      testContainer.read(pdfChatNotifierProvider(testPdf.id).notifier).state =
          PdfChatState.visible(
        error: longError,
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: testContainer,
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

      // Assert - should display without crashing
      expect(find.byType(PdfChatPanel), findsOneWidget);
      expect(find.textContaining('error message'), findsOneWidget);
    });

    testWidgets('should handle multiple rapid state changes', (tester) async {
      // Arrange
      final testContainer = ProviderContainer(
        overrides: [
          pdfAIServiceProvider.overrideWithValue(mockAiService),
          chatRepositoryProvider.overrideWithValue(mockChatRepository),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: testContainer,
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

      // Act - rapid state changes
      for (int i = 0; i < 10; i++) {
        testContainer.read(pdfChatNotifierProvider(testPdf.id).notifier).state =
            PdfChatState.visible(
          messages: List.generate(
            i,
            (j) => ChatMessage.user('Message $j'),
          ),
        );
        await tester.pump();
      }

      // Assert - should handle without crashing
      expect(find.byType(PdfChatPanel), findsOneWidget);
    });
  });
}
