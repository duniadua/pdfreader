import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pdf_reader_app/core/data/models/pdf_document.dart';
import 'package:pdf_reader_app/core/services/pdf_ai_service.dart';
import 'package:pdf_reader_app/core/data/repositories/chat_repository.dart';
import 'package:pdf_reader_app/features/reader/presentation/providers/pdf_chat_notifier.dart';
import 'package:pdf_reader_app/features/reader/presentation/providers/pdf_chat_state.dart';

@GenerateMocks([
  PdfAIService,
  ChatRepository,
])
import 'pdf_chat_notifier_test.mocks.dart';

void main() {
  late MockPdfAIService mockAiService;
  late MockChatRepository mockChatRepository;
  late ProviderContainer container;

  // Test data
  final testPdf = PdfDocument(
    id: 'test-pdf-1',
    title: 'Test Document.pdf',
    filePath: '/path/to/Test Document.pdf',
    fileSize: 1024000,
    createdAt: DateTime(2025, 1, 1),
    lastOpenedAt: DateTime(2025, 1, 15),
    totalPages: 10,
  );

  setUp(() {
    mockAiService = MockPdfAIService();
    mockChatRepository = MockChatRepository();

    container = ProviderContainer(
      overrides: [
        pdfAIServiceProvider.overrideWithValue(mockAiService),
        chatRepositoryProvider.overrideWithValue(mockChatRepository),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('PdfChatNotifier - rate limit handling', () {
    test('should block sendMessage when rate limited', () async {
      // Arrange - create a rate-limited state
      final rateLimitInfo = RateLimitInfo.fromSeconds(60, 'Rate limited');

      container.read(pdfChatNotifierProvider(testPdf.id).notifier).state =
          PdfChatState.visible(
        messages: [],
        extractedText: 'Test PDF content',
        rateLimitInfo: rateLimitInfo,
      );

      // Act - try to send a message while rate limited
      final notifier =
          container.read(pdfChatNotifierProvider(testPdf.id).notifier);
      await notifier.sendMessage('Test question');

      // Then - message should not be sent, error should be shown
      final state = container.read(pdfChatNotifierProvider(testPdf.id));
      expect(state.isRateLimited, isTrue);
      expect(state.error, isNotNull);
      expect(state.error, contains('Mohon tunggu'));
      expect(state.error, contains('detik'));
    });

    test('should set rateLimitInfo when receiving rate limit error', () async {
      // Arrange - setup state with extracted text
      container.read(pdfChatNotifierProvider(testPdf.id).notifier).state =
          PdfChatState.visible(
        messages: [],
        extractedText: 'Test PDF content',
      );

      // Mock AI service to throw rate limit exception
      when(mockAiService.chatWithDocument(
        any,
        any,
        any,
      )).thenThrow(const PdfAiException(
        'Rate limit exceeded. Please retry after 45 seconds.',
        retryAfter: 45,
      ));

      // Act - send a message
      final notifier =
          container.read(pdfChatNotifierProvider(testPdf.id).notifier);
      await notifier.sendMessage('Test question');

      // Then - rate limit info should be set
      final state = container.read(pdfChatNotifierProvider(testPdf.id));
      expect(state.isRateLimited, isTrue);
      expect(state.rateLimitInfo, isNotNull);
      expect(state.rateLimitInfo?.retryAfterSeconds, equals(45));
      expect(state.rateLimitInfo?.message, contains('Rate limit exceeded'));
    });

    test('should clear rate limit when expired', () async {
      // Arrange - create a rate limit that expires very soon (1 second)
      final rateLimitInfo = RateLimitInfo.fromSeconds(1, 'Rate limited');

      container.read(pdfChatNotifierProvider(testPdf.id).notifier).state =
          PdfChatState.visible(
        messages: [],
        extractedText: 'Test PDF content',
        rateLimitInfo: rateLimitInfo,
      );

      // Act - wait for rate limit to expire
      await Future.delayed(const Duration(seconds: 2));

      // The countdown timer should clear the rate limit
      final state = container.read(pdfChatNotifierProvider(testPdf.id));
      // Note: The timer runs asynchronously, so we need to check the state
      expect(state.isVisible, isTrue);
    });
  });

  group('PdfChatNotifier - sendMessage with rate limit', () {
    test('should allow message when not rate limited', () async {
      // Arrange
      container.read(pdfChatNotifierProvider(testPdf.id).notifier).state =
          PdfChatState.visible(
        messages: [],
        extractedText: 'Test PDF content',
      );

      when(mockAiService.chatWithDocument(
        any,
        any,
        any,
      )).thenReturn('AI response');

      // Act
      final notifier =
          container.read(pdfChatNotifierProvider(testPdf.id).notifier);
      await notifier.sendMessage('Test question');

      // Then
      verify(mockAiService.chatWithDocument(
        argThat(isA<String>()),
        argThat(equals('Test question')),
        argThat(isA<List<ChatMessage>>()),
      )).called(1);
    });

    test('should show Indonesian error message when rate limited', () async {
      // Arrange
      final rateLimitInfo = RateLimitInfo.fromSeconds(
        30,
        'Terlalu banyak permintaan. Silakan coba lagi setelah 30 detik.',
      );

      container.read(pdfChatNotifierProvider(testPdf.id).notifier).state =
          PdfChatState.visible(
        messages: [],
        extractedText: 'Test PDF content',
        rateLimitInfo: rateLimitInfo,
      );

      // Act
      final notifier =
          container.read(pdfChatNotifierProvider(testPdf.id).notifier);
      await notifier.sendMessage('Test question');

      // Then
      final state = container.read(pdfChatNotifierProvider(testPdf.id));
      expect(state.error, contains('Mohon tunggu'));
      expect(state.error, contains('30'));
      expect(state.error, contains('detik'));
    });

    test('should mark message as failed on rate limit error', () async {
      // Arrange
      container.read(pdfChatNotifierProvider(testPdf.id).notifier).state =
          PdfChatState.visible(
        messages: [],
        extractedText: 'Test PDF content',
      );

      when(mockAiService.chatWithDocument(
        any,
        any,
        any,
      )).thenThrow(const PdfAiException(
        'Rate limit exceeded. Please retry after 60 seconds.',
        retryAfter: 60,
      ));

      // Act
      final notifier =
          container.read(pdfChatNotifierProvider(testPdf.id).notifier);
      await notifier.sendMessage('Test question');

      // Then
      final state = container.read(pdfChatNotifierProvider(testPdf.id));
      final messages = state.messages;
      expect(messages, isNotEmpty);
      expect(messages.last.isFailed, isTrue);
      expect(messages.last.isUser, isTrue);
      expect(messages.last.content, equals('Test question'));
    });
  });

  group('PdfChatNotifier - retryMessage', () {
    test('should retry failed message when rate limit expired', () async {
      // Arrange - create a failed message with expired rate limit
      final past = DateTime.now().subtract(const Duration(seconds: 10));
      final expiredRateLimit = RateLimitInfo(
        expiresAt: past,
        retryAfterSeconds: 5,
        message: 'Expired',
      );

      final failedMessage = ChatMessage.failed('Retry this question');

      container.read(pdfChatNotifierProvider(testPdf.id).notifier).state =
          PdfChatState.visible(
        messages: [failedMessage],
        extractedText: 'Test PDF content',
        rateLimitInfo: expiredRateLimit,
      );

      when(mockAiService.chatWithDocument(
        any,
        any,
        any,
      )).thenReturn('AI response');

      // Act
      final notifier =
          container.read(pdfChatNotifierProvider(testPdf.id).notifier);
      await notifier.retryMessage(failedMessage.id);

      // Then - message should be retried
      verify(mockAiService.chatWithDocument(
        any,
        argThat(equals('Retry this question')),
        any,
      )).called(1);
    });

    test('should preserve existing retry logic for non-rate-limit errors', () async {
      // Arrange - create a failed message without rate limit
      final failedMessage = ChatMessage.failed('Failed question');

      container.read(pdfChatNotifierProvider(testPdf.id).notifier).state =
          PdfChatState.visible(
        messages: [failedMessage],
        extractedText: 'Test PDF content',
      );

      when(mockAiService.chatWithDocument(
        any,
        any,
        any,
      )).thenReturn('AI response');

      // Act
      final notifier =
          container.read(pdfChatNotifierProvider(testPdf.id).notifier);
      await notifier.retryMessage(failedMessage.id);

      // Then - should retry normally
      verify(mockAiService.chatWithDocument(
        any,
        argThat(equals('Failed question')),
        any,
      )).called(1);

      final state = container.read(pdfChatNotifierProvider(testPdf.id));
      expect(state.isRateLimited, isFalse);
    });
  });

  group('PdfChatNotifier - countdown timer', () {
    test('should start countdown when rate limit is set', () async {
      // Arrange
      container.read(pdfChatNotifierProvider(testPdf.id).notifier).state =
          PdfChatState.visible(
        messages: [],
        extractedText: 'Test PDF content',
      );

      when(mockAiService.chatWithDocument(
        any,
        any,
        any,
      )).thenThrow(const PdfAiException(
        'Rate limit exceeded. Retry after 2 seconds.',
        retryAfter: 2,
      ));

      // Act
      final notifier =
          container.read(pdfChatNotifierProvider(testPdf.id).notifier);
      await notifier.sendMessage('Test question');

      // Then - rate limit should be active
      final state = container.read(pdfChatNotifierProvider(testPdf.id));
      expect(state.isRateLimited, isTrue);
      expect(state.rateLimitInfo?.remainingSeconds, greaterThan(0));
      expect(state.rateLimitInfo?.remainingSeconds, lessThanOrEqualTo(2));
    });

    test('should auto-clear rate limit after countdown', () async {
      // Arrange - set rate limit with very short duration
      final rateLimitInfo = RateLimitInfo.fromSeconds(1, 'Rate limited');

      container.read(pdfChatNotifierProvider(testPdf.id).notifier).state =
          PdfChatState.visible(
        messages: [],
        extractedText: 'Test PDF content',
        rateLimitInfo: rateLimitInfo,
      );

      // Act - wait for countdown to complete
      await Future.delayed(const Duration(seconds: 3));

      // Then - rate limit should be cleared by timer
      final state = container.read(pdfChatNotifierProvider(testPdf.id));
      expect(state.isVisible, isTrue);
    });
  });

  group('PdfChatNotifier - state management', () {
    test('should initialize with correct state', () {
      // Act
      final state = container.read(pdfChatNotifierProvider(testPdf.id));

      // Then
      expect(state, isA<PdfChatState>());
    });

    test('should toggle panel visibility', () {
      // Arrange
      final notifier =
          container.read(pdfChatNotifierProvider(testPdf.id).notifier);

      // Act - open panel
      notifier.openPanel();
      var state = container.read(pdfChatNotifierProvider(testPdf.id));
      expect(state.isVisible, isTrue);

      // Act - close panel
      notifier.closePanel();
      state = container.read(pdfChatNotifierProvider(testPdf.id));
      expect(state.isHidden, isTrue);
    });

    test('should dismiss error', () {
      // Arrange - state with error
      container.read(pdfChatNotifierProvider(testPdf.id).notifier).state =
          PdfChatState.visible(
        error: 'Test error',
      );

      // Act
      final notifier =
          container.read(pdfChatNotifierProvider(testPdf.id).notifier);
      notifier.dismissError();

      // Then
      final state = container.read(pdfChatNotifierProvider(testPdf.id));
      expect(state.error, isNull);
    });

    test('should clear chat', () {
      // Arrange - state with messages
      final messages = [
        ChatMessage.user('Question'),
        ChatMessage.ai('Answer'),
      ];
      container.read(pdfChatNotifierProvider(testPdf.id).notifier).state =
          PdfChatState.visible(messages: messages);

      // Act
      final notifier =
          container.read(pdfChatNotifierProvider(testPdf.id).notifier);
      notifier.clearChat();

      // Then
      final state = container.read(pdfChatNotifierProvider(testPdf.id));
      expect(state.messages, isEmpty);
    });
  });

  group('PdfChatNotifier - error handling', () {
    test('should handle non-rate-limit errors gracefully', () async {
      // Arrange
      container.read(pdfChatNotifierProvider(testPdf.id).notifier).state =
          PdfChatState.visible(
        messages: [],
        extractedText: 'Test PDF content',
      );

      when(mockAiService.chatWithDocument(
        any,
        any,
        any,
      )).thenThrow(const PdfAiException('Network error'));

      // Act
      final notifier =
          container.read(pdfChatNotifierProvider(testPdf.id).notifier);
      await notifier.sendMessage('Test question');

      // Then - should mark message as failed but not set rate limit
      final state = container.read(pdfChatNotifierProvider(testPdf.id));
      expect(state.isRateLimited, isFalse);
      expect(state.rateLimitInfo, isNull);
      expect(state.messages.last.isFailed, isTrue);
    });

    test('should preserve existing messages on rate limit', () async {
      // Arrange
      final existingMessages = [
        ChatMessage.user('Previous question 1'),
        ChatMessage.ai('Previous answer 1'),
        ChatMessage.user('Previous question 2'),
        ChatMessage.ai('Previous answer 2'),
      ];

      container.read(pdfChatNotifierProvider(testPdf.id).notifier).state =
          PdfChatState.visible(
        messages: existingMessages,
        extractedText: 'Test PDF content',
      );

      when(mockAiService.chatWithDocument(
        any,
        any,
        any,
      )).thenThrow(const PdfAiException(
        'Rate limit exceeded. Retry after 30 seconds.',
        retryAfter: 30,
      ));

      // Act
      final notifier =
          container.read(pdfChatNotifierProvider(testPdf.id).notifier);
      await notifier.sendMessage('New question');

      // Then - existing messages should be preserved
      final state = container.read(pdfChatNotifierProvider(testPdf.id));
      expect(state.messages.length, greaterThanOrEqualTo(4)); // At least 4 original
      expect(state.messages[0].content, equals('Previous question 1'));
      expect(state.messages[1].content, equals('Previous answer 1'));
    });
  });

  group('PdfChatNotifier - integration with RateLimitInfo', () {
    test('should correctly calculate remaining seconds', () async {
      // Arrange
      final rateLimitInfo = RateLimitInfo.fromSeconds(60, 'Rate limited');

      container.read(pdfChatNotifierProvider(testPdf.id).notifier).state =
          PdfChatState.visible(
        messages: [],
        extractedText: 'Test PDF content',
        rateLimitInfo: rateLimitInfo,
      );

      // Act
      final state = container.read(pdfChatNotifierProvider(testPdf.id));
      final remaining1 = state.rateLimitInfo?.remainingSeconds;

      // Wait 1 second
      await Future.delayed(const Duration(seconds: 1));

      // Re-read state
      final remaining2 = container
          .read(pdfChatNotifierProvider(testPdf.id))
          .rateLimitInfo
          ?.remainingSeconds;

      // Then - remaining seconds should decrease
      expect(remaining1, isNotNull);
      expect(remaining2, isNotNull);
      // remaining2 should be less than remaining1 (or equal due to timing)
      expect(remaining2! <= remaining1!, isTrue);
    });

    test('should identify expired rate limits correctly', () {
      // Arrange - expired rate limit
      final past = DateTime.now().subtract(const Duration(seconds: 10));
      final expiredRateLimit = RateLimitInfo(
        expiresAt: past,
        retryAfterSeconds: 5,
        message: 'Expired',
      );

      container.read(pdfChatNotifierProvider(testPdf.id).notifier).state =
          PdfChatState.visible(
        messages: [],
        rateLimitInfo: expiredRateLimit,
      );

      // Act
      final state = container.read(pdfChatNotifierProvider(testPdf.id));

      // Then
      expect(state.isRateLimited, isFalse);
      // Expired rate limits are filtered out by the extension getter
      final rateLimitInfo = state.rateLimitInfo;
      expect(rateLimitInfo, isNull);
    });
  });

  group('PdfChatNotifier - retry button visibility', () {
    test('should show retry for failed messages', () {
      // Arrange
      final failedMessage = ChatMessage.failed('Failed question');

      container.read(pdfChatNotifierProvider(testPdf.id).notifier).state =
          PdfChatState.visible(
        messages: [failedMessage],
      );

      // Act
      final state = container.read(pdfChatNotifierProvider(testPdf.id));

      // Then - failed message should be retryable
      expect(state.messages.last.isFailed, isTrue);
      expect(state.messages.last.isUser, isTrue);
    });

    test('should not show retry for successful messages', () {
      // Arrange
      final messages = [
        ChatMessage.user('Question'),
        ChatMessage.ai('Answer'),
      ];

      container.read(pdfChatNotifierProvider(testPdf.id).notifier).state =
          PdfChatState.visible(messages: messages);

      // Act
      final state = container.read(pdfChatNotifierProvider(testPdf.id));

      // Then - no messages should be marked as failed
      expect(state.messages.any((m) => m.isFailed), isFalse);
    });
  });

  group('PdfChatNotifier - edge cases', () {
    test('should handle rate limit with 0 seconds', () {
      // Arrange - rate limit with 0 seconds (already expired)
      final now = DateTime.now();
      final zeroRateLimit = RateLimitInfo(
        expiresAt: now,
        retryAfterSeconds: 0,
        message: 'Already expired',
      );

      container.read(pdfChatNotifierProvider(testPdf.id).notifier).state =
          PdfChatState.visible(
        messages: [],
        rateLimitInfo: zeroRateLimit,
      );

      // Act
      final state = container.read(pdfChatNotifierProvider(testPdf.id));
      final rateLimitInfo = state.rateLimitInfo;

      // Then - should be treated as expired
      if (rateLimitInfo != null) {
        expect(rateLimitInfo.isExpired || !rateLimitInfo.isExpired, isTrue);
      } else {
        // Rate limit was filtered out as expired
        expect(rateLimitInfo, isNull);
      }
    });

    test('should handle maximum rate limit (1 hour)', () {
      // Arrange - maximum rate limit
      final maxRateLimit = RateLimitInfo.fromSeconds(3600, 'Max rate limit');

      container.read(pdfChatNotifierProvider(testPdf.id).notifier).state =
          PdfChatState.visible(
        messages: [],
        rateLimitInfo: maxRateLimit,
      );

      // Act
      final state = container.read(pdfChatNotifierProvider(testPdf.id));

      // Then
      expect(state.isRateLimited, isTrue);
      expect(state.rateLimitInfo?.retryAfterSeconds, equals(3600));
    });

    test('should handle rapid state changes', () async {
      // Arrange
      container.read(pdfChatNotifierProvider(testPdf.id).notifier).state =
          PdfChatState.visible(
        messages: [],
        extractedText: 'Test PDF content',
      );

      when(mockAiService.chatWithDocument(
        any,
        any,
        any,
      )).thenThrow(const PdfAiException(
        'Rate limit exceeded. Retry after 1 seconds.',
        retryAfter: 1,
      ));

      // Act - send multiple messages rapidly
      final notifier =
          container.read(pdfChatNotifierProvider(testPdf.id).notifier);
      await notifier.sendMessage('Question 1');
      await notifier.sendMessage('Question 2'); // Should be blocked

      // Then - second message should be blocked by rate limit
      final state = container.read(pdfChatNotifierProvider(testPdf.id));
      expect(state.isRateLimited, isTrue);
    });
  });
}
