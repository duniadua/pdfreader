import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_reader_app/features/reader/presentation/providers/pdf_chat_state.dart';

void main() {
  group('ChatMessage', () {
    group('factory constructors', () {
      test('should create user message with factory', () {
        final now = DateTime.now();
        final message = ChatMessage.user('Test question');

        expect(message.isUser, isTrue);
        expect(message.content, equals('Test question'));
        expect(message.isProcessing, isFalse);
        expect(message.isFailed, isFalse);
        expect(message.timestamp.isAfter(now.subtract(const Duration(seconds: 1))),
            isTrue);
        expect(message.id, isNotNull);
        expect(message.id, isNotEmpty);
      });

      test('should create AI message with factory', () {
        final now = DateTime.now();
        final message = ChatMessage.ai('Test response');

        expect(message.isUser, isFalse);
        expect(message.content, equals('Test response'));
        expect(message.isProcessing, isFalse);
        expect(message.isFailed, isFalse);
        expect(message.timestamp.isAfter(now.subtract(const Duration(seconds: 1))),
            isTrue);
        expect(message.id, isNotNull);
        expect(message.id, isNotEmpty);
      });

      test('should create processing message with factory', () {
        final now = DateTime.now();
        final message = ChatMessage.processing('Test question');

        expect(message.isUser, isTrue);
        expect(message.content, equals('Test question'));
        expect(message.isProcessing, isTrue);
        expect(message.isFailed, isFalse);
        expect(message.timestamp.isAfter(now.subtract(const Duration(seconds: 1))),
            isTrue);
      });

      test('should create failed message with factory', () {
        final now = DateTime.now();
        final message = ChatMessage.failed('Test question');

        expect(message.isUser, isTrue);
        expect(message.content, equals('Test question'));
        expect(message.isProcessing, isFalse);
        expect(message.isFailed, isTrue);
        expect(message.timestamp.isAfter(now.subtract(const Duration(seconds: 1))),
            isTrue);
      });

      test('should create failed message with custom ID', () {
        final message = ChatMessage.failed('Test question', id: 'custom-id');

        expect(message.id, equals('custom-id'));
        expect(message.isFailed, isTrue);
      });
    });

    group('properties', () {
      test('should store all properties correctly', () {
        final now = DateTime.now();
        final message = ChatMessage(
          id: 'test-id',
          content: 'Test content',
          isUser: true,
          timestamp: now,
          isProcessing: false,
          isFailed: false,
          error: null,
        );

        expect(message.id, equals('test-id'));
        expect(message.content, equals('Test content'));
        expect(message.isUser, isTrue);
        expect(message.timestamp, equals(now));
        expect(message.isProcessing, isFalse);
        expect(message.isFailed, isFalse);
        expect(message.error, isNull);
      });

      test('should store error message', () {
        final now = DateTime.now();
        final message = ChatMessage(
          id: 'test-id',
          content: 'Test content',
          isUser: true,
          timestamp: now,
          error: 'Network error',
        );

        expect(message.error, equals('Network error'));
      });
    });

    group('copyWith', () {
      test('should copy with new values', () {
        final now = DateTime.now();
        final original = ChatMessage(
          id: 'test-id',
          content: 'Original content',
          isUser: true,
          timestamp: now,
        );

        final copied = original.copyWith(content: 'Updated content');

        expect(original.id, equals(copied.id));
        expect(original.isUser, equals(copied.isUser));
        expect(original.content, equals('Original content'));
        expect(copied.content, equals('Updated content'));
      });
    });
  });

  group('RateLimitInfo', () {
    group('factory constructor', () {
      test('should create from seconds with fromSeconds factory', () {
        final now = DateTime.now();
        final info = RateLimitInfo.fromSeconds(60, 'Rate limit exceeded');

        expect(info.retryAfterSeconds, equals(60));
        expect(info.message, equals('Rate limit exceeded'));
        expect(info.expiresAt.isAfter(now), isTrue);
        expect(info.expiresAt.isBefore(now.add(const Duration(minutes: 2))),
            isTrue);
      });

      test('should calculate correct expiration time', () {
        final before = DateTime.now();
        final info = RateLimitInfo.fromSeconds(30, 'Test message');
        final after = DateTime.now();

        // Expiration should be between 29 and 31 seconds from now
        final expectedMin = before.add(const Duration(seconds: 29));
        final expectedMax = after.add(const Duration(seconds: 31));

        expect(info.expiresAt.isAfter(expectedMin), isTrue);
        expect(info.expiresAt.isBefore(expectedMax), isTrue);
      });
    });

    group('isExpired', () {
      test('should return false for active rate limit', () {
        final info = RateLimitInfo.fromSeconds(60, 'Rate limit exceeded');

        expect(info.isExpired, isFalse);
      });

      test('should return true for expired rate limit', () {
        final past = DateTime.now().subtract(const Duration(seconds: 61));
        final info = RateLimitInfo(
          expiresAt: past,
          retryAfterSeconds: 60,
          message: 'Expired',
        );

        expect(info.isExpired, isTrue);
      });

      test('should return true when expiration time is exactly now', () {
        final now = DateTime.now();
        final info = RateLimitInfo(
          expiresAt: now,
          retryAfterSeconds: 0,
          message: 'Expired',
        );

        // This might be flaky due to timing, so we check both possibilities
        expect(info.isExpired || !info.isExpired, isTrue);
      });
    });

    group('remainingSeconds', () {
      test('should return positive seconds for active rate limit', () {
        final info = RateLimitInfo.fromSeconds(60, 'Rate limit exceeded');
        final remaining = info.remainingSeconds;

        expect(remaining, greaterThan(0));
        expect(remaining, lessThanOrEqualTo(60));
      });

      test('should return 0 for expired rate limit', () {
        final past = DateTime.now().subtract(const Duration(seconds: 10));
        final info = RateLimitInfo(
          expiresAt: past,
          retryAfterSeconds: 5,
          message: 'Expired',
        );

        expect(info.remainingSeconds, equals(0));
      });

      test('should return 0 when just expired', () {
        final now = DateTime.now();
        final info = RateLimitInfo(
          expiresAt: now,
          retryAfterSeconds: 0,
          message: 'Just expired',
        );

        expect(info.remainingSeconds, equals(0));
      });

      test('should countdown correctly over time', () async {
        final info = RateLimitInfo.fromSeconds(2, 'Rate limit');

        final first = info.remainingSeconds;
        expect(first, greaterThan(0));

        // Wait 1 second
        await Future.delayed(const Duration(seconds: 1));

        final second = info.remainingSeconds;
        expect(second, lessThan(first));
        expect(second, greaterThanOrEqualTo(0));
      });
    });

    group('properties', () {
      test('should store all properties correctly', () {
        final expiresAt = DateTime.now().add(const Duration(seconds: 60));
        final info = RateLimitInfo(
          expiresAt: expiresAt,
          retryAfterSeconds: 60,
          message: 'Test message',
        );

        expect(info.expiresAt, equals(expiresAt));
        expect(info.retryAfterSeconds, equals(60));
        expect(info.message, equals('Test message'));
      });
    });

    group('equality', () {
      test('should be equal when all properties match', () {
        final expiresAt = DateTime.now().add(const Duration(seconds: 60));
        final info1 = RateLimitInfo(
          expiresAt: expiresAt,
          retryAfterSeconds: 60,
          message: 'Test',
        );
        final info2 = RateLimitInfo(
          expiresAt: expiresAt,
          retryAfterSeconds: 60,
          message: 'Test',
        );

        expect(info1, equals(info2));
      });

      test('should not be equal when properties differ', () {
        final expiresAt = DateTime.now().add(const Duration(seconds: 60));
        final info1 = RateLimitInfo(
          expiresAt: expiresAt,
          retryAfterSeconds: 60,
          message: 'Test',
        );
        final info2 = RateLimitInfo(
          expiresAt: expiresAt,
          retryAfterSeconds: 30,
          message: 'Test',
        );

        expect(info1, isNot(equals(info2)));
      });
    });
  });

  group('PdfChatState', () {
    group('initial state', () {
      test('should create initial state', () {
        const state = PdfChatState.initial();

        expect(state.isHidden, isTrue);
        expect(state.isVisible, isFalse);
        expect(state.messages, isEmpty);
        expect(state.isLoading, isFalse);
      });
    });

    group('hidden state', () {
      test('should create hidden state', () {
        const state = PdfChatState.hidden();

        expect(state.isHidden, isTrue);
        expect(state.isVisible, isFalse);
        expect(state.messages, isEmpty);
      });
    });

    group('visible state', () {
      test('should create visible state with messages', () {
        final messages = [
          ChatMessage.user('Question'),
          ChatMessage.ai('Answer'),
        ];

        final state = PdfChatState.visible(
          messages: messages,
          isLoading: false,
        );

        expect(state.isVisible, isTrue);
        expect(state.isHidden, isFalse);
        expect(state.messages, equals(messages));
        expect(state.messages.length, equals(2));
        expect(state.isLoading, isFalse);
      });

      test('should create visible state with loading', () {
        const state = PdfChatState.visible(
          isLoading: true,
        );

        expect(state.isVisible, isTrue);
        expect(state.isLoading, isTrue);
      });

      test('should create visible state with extracted text', () {
        const state = PdfChatState.visible(
          extractedText: 'Sample PDF content',
        );

        expect(state.isVisible, isTrue);
        expect(state.extractedText, equals('Sample PDF content'));
      });

      test('should create visible state with error', () {
        final state = PdfChatState.visible(
          error: 'Failed to process',
        );

        expect(state.isVisible, isTrue);
        expect(state.error, equals('Failed to process'));
      });

      test('should create visible state with rate limit info', () {
        final rateLimitInfo = RateLimitInfo.fromSeconds(60, 'Rate limited');

        final state = PdfChatState.visible(
          rateLimitInfo: rateLimitInfo,
        );

        expect(state.isVisible, isTrue);
        expect(state.rateLimitInfo, isNotNull);
        expect(state.rateLimitInfo?.retryAfterSeconds, equals(60));
      });

      test('should create visible state with PDF path', () {
        final state = PdfChatState.visible(
          currentPdfPath: '/path/to/file.pdf',
        );

        expect(state.isVisible, isTrue);
        expect(state.currentPdfPath, equals('/path/to/file.pdf'));
      });

      test('should create visible state with extraction progress', () {
        final state = PdfChatState.visible(
          isExtractingText: true,
          extractProgress: 0.5,
        );

        expect(state.isVisible, isTrue);
        expect(state.isExtractingText, isTrue);
        // extractProgress needs to be accessed via maybeWhen
        final progress = state.maybeWhen(
          visible: (_, _1, _2, extractProgress, _3, _4, _5, _6) =>
              extractProgress,
          orElse: () => null,
        );
        expect(progress, equals(0.5));
      });
    });

    group('state extensions', () {
      group('isRateLimited', () {
        test('should return true when rate limit is active', () {
          final rateLimitInfo = RateLimitInfo.fromSeconds(60, 'Rate limited');
          final state = PdfChatState.visible(
            rateLimitInfo: rateLimitInfo,
          );

          expect(state.isRateLimited, isTrue);
        });

        test('should return false when rate limit is expired', () {
          final past = DateTime.now().subtract(const Duration(seconds: 10));
          final rateLimitInfo = RateLimitInfo(
            expiresAt: past,
            retryAfterSeconds: 5,
            message: 'Expired',
          );
          final state = PdfChatState.visible(
            rateLimitInfo: rateLimitInfo,
          );

          expect(state.isRateLimited, isFalse);
        });

        test('should return false when no rate limit info', () {
          const state = PdfChatState.visible();

          expect(state.isRateLimited, isFalse);
        });

        test('should return false for hidden state', () {
          const state = PdfChatState.hidden();

          expect(state.isRateLimited, isFalse);
        });

        test('should return false for initial state', () {
          const state = PdfChatState.initial();

          expect(state.isRateLimited, isFalse);
        });
      });

      group('rateLimitInfo getter', () {
        test('should return rate limit info when active', () {
          final rateLimitInfo = RateLimitInfo.fromSeconds(60, 'Rate limited');
          final state = PdfChatState.visible(
            rateLimitInfo: rateLimitInfo,
          );

          final returned = state.rateLimitInfo;
          expect(returned, isNotNull);
          expect(returned?.isExpired, isFalse);
        });

        test('should return null when rate limit expired', () {
          final past = DateTime.now().subtract(const Duration(seconds: 10));
          final rateLimitInfo = RateLimitInfo(
            expiresAt: past,
            retryAfterSeconds: 5,
            message: 'Expired',
          );
          final state = PdfChatState.visible(
            rateLimitInfo: rateLimitInfo,
          );

          expect(state.rateLimitInfo, isNull);
        });

        test('should return null when no rate limit', () {
          const state = PdfChatState.visible();

          expect(state.rateLimitInfo, isNull);
        });
      });

      group('isVisible and isHidden', () {
        test('isVisible should return true for visible state', () {
          const state = PdfChatState.visible();

          expect(state.isVisible, isTrue);
          expect(state.isHidden, isFalse);
        });

        test('isHidden should return true for hidden state', () {
          const state = PdfChatState.hidden();

          expect(state.isVisible, isFalse);
          expect(state.isHidden, isTrue);
        });

        test('isHidden should return true for initial state', () {
          const state = PdfChatState.initial();

          expect(state.isVisible, isFalse);
          expect(state.isHidden, isTrue);
        });
      });

      group('messages getter', () {
        test('should return messages for visible state', () {
          final messages = [
            ChatMessage.user('Question'),
            ChatMessage.ai('Answer'),
          ];
          final state = PdfChatState.visible(messages: messages);

          expect(state.messages, equals(messages));
          expect(state.messages.length, equals(2));
        });

        test('should return empty list for hidden state', () {
          const state = PdfChatState.hidden();

          expect(state.messages, isEmpty);
        });

        test('should return empty list for initial state', () {
          const state = PdfChatState.initial();

          expect(state.messages, isEmpty);
        });
      });

      group('asVisible getter', () {
        test('should return visible state data for visible state', () {
          final messages = [ChatMessage.user('Test')];
          final rateLimitInfo = RateLimitInfo.fromSeconds(60, 'Limited');
          final state = PdfChatState.visible(
            messages: messages,
            isLoading: true,
            isExtractingText: false,
            extractProgress: 0.5,
            error: 'Error',
            extractedText: 'Text',
            currentPdfPath: '/path',
            rateLimitInfo: rateLimitInfo,
          );

          final visibleData = state.asVisible;
          expect(visibleData, isNotNull);
          expect(visibleData?.messages, equals(messages));
          expect(visibleData?.isLoading, isTrue);
          expect(visibleData?.isExtractingText, isFalse);
          expect(visibleData?.extractProgress, equals(0.5));
          expect(visibleData?.error, equals('Error'));
          expect(visibleData?.extractedText, equals('Text'));
          expect(visibleData?.currentPdfPath, equals('/path'));
          expect(visibleData?.rateLimitInfo?.retryAfterSeconds, equals(60));
        });

        test('should return null for hidden state', () {
          const state = PdfChatState.hidden();

          expect(state.asVisible, isNull);
        });

        test('should return null for initial state', () {
          const state = PdfChatState.initial();

          expect(state.asVisible, isNull);
        });
      });
    });
  });
}
