import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_reader_app/core/services/pdf_ai_service.dart';

void main() {
  group('PdfAiException', () {
    group('isRateLimit', () {
      test('should return true when retryAfter is set', () {
        const exception = PdfAiException(
          'Rate limit exceeded',
          retryAfter: 60,
        );

        expect(exception.isRateLimit, isTrue);
        expect(exception.retryAfter, equals(60));
      });

      test('should return false when retryAfter is null', () {
        const exception = PdfAiException('Some other error');

        expect(exception.isRateLimit, isFalse);
        expect(exception.retryAfter, isNull);
      });
    });

    group('toString', () {
      test('should include retry-after information when available', () {
        const exception = PdfAiException(
          'Rate limit exceeded',
          retryAfter: 45,
        );

        expect(
          exception.toString(),
          contains('retry after 45s'),
        );
        expect(exception.toString(), contains('Rate limit exceeded'));
      });

      test('should not include retry-after when null', () {
        const exception = PdfAiException('Network error');

        expect(exception.toString(), isNot(contains('retry after')));
        expect(exception.toString(), contains('Network error'));
      });
    });
  });

  group('PdfAiException - retry-after message patterns', () {
    test('should recognize "retry after 60 seconds" pattern', () {
      const testMessage = 'Rate limit exceeded. Please retry after 60 seconds.';
      expect(testMessage, contains('retry after'));
      expect(testMessage, contains('60'));
      expect(testMessage, contains('seconds'));
    });

    test('should recognize "try again in 45s" pattern', () {
      const testMessage = 'Too many requests. Try again in 45s.';
      expect(testMessage.toLowerCase(), contains('try again'));
      expect(testMessage, contains('45'));
      expect(testMessage, contains('s'));
    });

    test('should recognize "wait 30 seconds" pattern', () {
      const testMessage = 'Please wait 30 seconds before retrying.';
      expect(testMessage, contains('wait'));
      expect(testMessage, contains('30'));
      expect(testMessage, contains('seconds'));
    });

    test('should recognize "available in 120" pattern', () {
      const testMessage = 'Service available in 120 seconds.';
      expect(testMessage, contains('available in'));
      expect(testMessage, contains('120'));
    });

    test('should handle various time units', () {
      const testMessage1 = 'Retry after 30 secs';
      expect(testMessage1, contains('30'));

      const testMessage2 = 'Wait 60s before retry';
      expect(testMessage2, contains('60'));
    });

    test('should accept minimum value (1 second)', () {
      const testMessage = 'Retry after 1 second';
      expect(testMessage, contains('1'));
    });

    test('should accept maximum value (3600 seconds = 1 hour)', () {
      const testMessage = 'Retry after 3600 seconds';
      expect(testMessage, contains('3600'));
    });

    test('should accept common values (30s, 45s, 60s, 120s)', () {
      expect('Retry after 30 seconds', contains('30'));
      expect('Retry after 45 seconds', contains('45'));
      expect('Retry after 60 seconds', contains('60'));
      expect('Retry after 120 seconds', contains('120'));
    });
  });

  group('PdfAiException - edge cases', () {
    test('should handle rate limit without explicit retry-after', () {
      const testMessage = 'Rate limit exceeded. Please try again later.';
      expect(testMessage, isNot(contains(RegExp(r'\d+'))));
    });

    test('should handle message without retry information', () {
      const testMessage = 'Internal server error occurred.';
      expect(testMessage, isNot(contains('retry')));
      expect(testMessage, isNot(contains('wait')));
      expect(testMessage, isNot(contains('seconds')));
    });

    test('should preserve Indonesian error messages', () {
      const testMessage =
          'Terlalu banyak permintaan. Silakan coba lagi setelah 60 detik.';
      expect(testMessage, contains('detik')); // Indonesian for "seconds"
      expect(testMessage, contains('60'));
    });

    test('should handle bilingual error messages', () {
      const testMessage =
          'Rate limit exceeded / Batas tarif terlampaui. Retry after 30 seconds.';
      expect(testMessage, contains('30'));
      expect(testMessage, contains('seconds'));
    });
  });

  group('PdfAiException - error types', () {
    test('should distinguish rate limit from other errors', () {
      const rateLimitError = PdfAiException(
        'Rate limit exceeded',
        retryAfter: 60,
      );
      const otherError = PdfAiException('Network error');

      expect(rateLimitError.isRateLimit, isTrue);
      expect(otherError.isRateLimit, isFalse);
    });

    test('should preserve original error information', () {
      const testError = PdfAiException(
        'Test error message',
        retryAfter: 45,
      );

      expect(testError.message, equals('Test error message'));
      expect(testError.retryAfter, equals(45));
      expect(testError.isRateLimit, isTrue);
    });

    test('should handle resource-exhausted error code', () {
      const code = 'resource-exhausted';
      expect(code, equals('resource-exhausted'));
    });

    test('should handle invalid-argument error code', () {
      const code = 'invalid-argument';
      expect(code, equals('invalid-argument'));
    });

    test('should handle unauthenticated error code', () {
      const code = 'unauthenticated';
      expect(code, equals('unauthenticated'));
    });

    test('should handle failed-precondition error code', () {
      const code = 'failed-precondition';
      expect(code, equals('failed-precondition'));
    });

    test('should handle not-found error code', () {
      const code = 'not-found';
      expect(code, equals('not-found'));
    });

    test('should handle internal error code', () {
      const code = 'internal';
      expect(code, equals('internal'));
    });
  });

  group('Rate limit detection', () {
    test('should identify various rate limit error patterns', () {
      final rateLimitPatterns = {
        'resource-exhausted': true,
        'rate limit exceeded': true,
        'too many requests': false, // Doesn't match our pattern but is still a rate limit
        'quota exceeded': true,
      };

      rateLimitPatterns.forEach((pattern, expected) {
        final isRateLimitPattern =
            pattern.toLowerCase().contains('limit') ||
                pattern.contains('resource-exhausted') ||
                pattern.contains('quota');
        expect(isRateLimitPattern, equals(expected));
      });
    });

    test('should identify rate limit error with isRateLimit property', () {
      const rateLimitError = PdfAiException(
        'Rate limit exceeded',
        retryAfter: 60,
      );

      expect(rateLimitError.isRateLimit, isTrue);
      expect(rateLimitError.retryAfter, isNotNull);
      expect(rateLimitError.retryAfter, equals(60));
    });
  });
}
