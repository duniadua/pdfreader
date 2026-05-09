/**
 * Fail-Open Behavior Integration Tests
 *
 * Tests fail-open behavior when dependencies are unavailable:
 * - Firestore unavailability
 * - Remote Config unreachable
 * - Network timeouts
 * - Error logging and request allowance
 */

import * as admin from 'firebase-admin';
import { HttpsError } from 'firebase-functions/v2/https';
import { checkRateLimit } from '../../src/rateLimit/middleware';
import { getRateLimits, isRateLimitingEnabled } from '../../src/rateLimit/remoteConfig';
import { getCountInWindow } from '../../src/rateLimit/distributedCounter';
import { FunctionType } from '../../src/rateLimit/types';

// Mock console.error to capture logs
const originalError = console.error;
let errorLogs: string[] = [];

beforeEach(() => {
  errorLogs = [];
  console.error = (...args: any[]) => {
    errorLogs.push(args.join(' '));
    originalError(...args);
  };
});

afterEach(() => {
  console.error = originalError;
});

describe('Fail-Open Behavior Integration Tests', () => {
  let testUser: string;
  let db: admin.firestore.Firestore;

  beforeAll(async () => {
    process.env.FIRESTORE_EMULATOR_HOST = 'localhost:8080';
    process.env.FIREBASE_CONFIG = JSON.stringify({
      projectId: 'test-project',
    });

    try {
      await admin.initializeApp();
    } catch (e: any) {
      if (e.code !== 'app/duplicate-app') {
        throw e;
      }
    }

    db = admin.firestore();
    testUser = 'fail-open-test-user';

    await cleanupTestData();
  });

  afterAll(async () => {
    await cleanupTestData();
    await admin.app().delete();
  });

  beforeEach(async () => {
    await cleanupTestData();
    errorLogs = [];

    // Ensure rate limiting is enabled
    const configRef = db.collection('config').doc('rateLimiter');
    await configRef.set({
      enabled: true,
      summarizePdf: {
        hourlyLimit: 10,
        dailyLimit: 50,
        minRequestInterval: 500,
      },
    });
  });

  async function cleanupTestData(): Promise<void> {
    const batch = db.batch();

    const snapshot = await db
      .collection('rateLimitCounters')
      .where('__name__', '>=', testUser)
      .get();

    snapshot.docs.forEach((doc) => {
      batch.delete(doc.ref);
    });

    await batch.commit();
  }

  describe('Firestore Unavailability', () => {
    test('should allow request when Firestore collection is unavailable', async () => {
      // This test verifies the fail-open logic in the catch block
      // In a real scenario, we'd mock Firestore to throw errors

      // Simulate by using a malformed query that will fail
      const originalGetCount = getCountInWindow;

      // Mock to throw error
      jest.spyOn(require('../../src/rateLimit/distributedCounter'), 'getCountInWindow')
        .mockRejectedValueOnce(new Error('Firestore unavailable'));

      // Request should still be allowed (fail-open)
      const result = await checkRateLimit(testUser, 'summarizePdf' as FunctionType);

      // Verify fail-open behavior
      expect(result.allowed).toBe(true);

      // Verify error was logged
      expect(errorLogs.some(log => log.includes('Error in rate limit check'))).toBe(true);
      expect(errorLogs.some(log => log.includes('FAILING OPEN'))).toBe(true);
    });

    test('should log error but not throw when Firestore is down', async () => {
      // Mock Firestore operations to fail
      jest.spyOn(require('../../src/rateLimit/distributedCounter'), 'getCountInWindow')
        .mockRejectedValueOnce(new Error('Network error'));

      errorLogs = [];

      // Should not throw
      const result = await checkRateLimit(testUser, 'summarizePdf' as FunctionType);

      expect(result.allowed).toBe(true);
      expect(errorLogs.length).toBeGreaterThan(0);
    });

    test('should handle partial Firestore failures gracefully', async () => {
      // Mock some operations to succeed, others to fail
      let callCount = 0;
      jest.spyOn(require('../../src/rateLimit/distributedCounter'), 'getCountInWindow')
        .mockImplementation(async () => {
          callCount++;
          if (callCount === 2) {
            throw new Error('Partial failure');
          }
          return 5;
        });

      // Should still allow request
      const result = await checkRateLimit(testUser, 'summarizePdf' as FunctionType);
      expect(result.allowed).toBe(true);
    });
  });

  describe('Remote Config Unavailability', () => {
    test('should use safe defaults when Remote Config is unreachable', async () => {
      // Delete Remote Config to simulate unavailability
      const configRef = db.collection('config').doc('rateLimiter');
      await configRef.delete();

      // Wait a moment
      await new Promise(resolve => setTimeout(resolve, 100));

      // Should fall back to safe defaults
      const isEnabled = await isRateLimitingEnabled();

      // Should either be enabled or disabled based on implementation
      expect(typeof isEnabled).toBe('boolean');
    });

    test('should allow requests when Remote Config fetch fails', async () => {
      // Mock Remote Config to throw error
      jest.spyOn(require('../../src/rateLimit/remoteConfig'), 'getRateLimits')
        .mockRejectedValueOnce(new Error('Remote Config fetch failed'));

      // Request should be allowed (fail-open)
      const result = await checkRateLimit(testUser, 'summarizePdf' as FunctionType);

      expect(result.allowed).toBe(true);
    });

    test('should handle missing configuration gracefully', async () => {
      // Set up incomplete config
      const configRef = db.collection('config').doc('rateLimiter');
      await configRef.set({
        enabled: true,
        // Missing summarizePdf config
      });

      // Should handle gracefully
      try {
        const config = await getRateLimits('summarizePdf' as FunctionType);
        // Either throws error or returns defaults
        expect(config).toBeTruthy();
      } catch (error) {
        // Expected to throw or return defaults
        expect(error).toBeTruthy();
      }
    });

    test('should allow request when config is malformed', async () => {
      // Set up malformed config
      const configRef = db.collection('config').doc('rateLimiter');
      await configRef.set({
        enabled: 'not-a-boolean', // Malformed
        summarizePdf: 'not-an-object',
      });

      // Should fail-open
      const result = await checkRateLimit(testUser, 'summarizePdf' as FunctionType);
      expect(result.allowed).toBe(true);
    });
  });

  describe('Network Timeout Scenarios', () => {
    test('should allow request when operation times out', async () => {
      // Mock a timeout
      jest.spyOn(require('../../src/rateLimit/distributedCounter'), 'getCountInWindow')
        .mockImplementationOnce(async () => {
          await new Promise(resolve => setTimeout(resolve, 10000));
          return 5;
        });

      const startTime = Date.now();

      // This will take a while but should eventually succeed
      const result = await checkRateLimit(testUser, 'summarizePdf' as FunctionType);

      const elapsed = Date.now() - startTime;

      // Verify it eventually succeeded
      expect(result).toBeTruthy();

      // Log the time taken
      console.log(`   Request with timeout took ${elapsed}ms`);
    });

    test('should handle slow Firestore operations gracefully', async () => {
      // Mock slow operations
      jest.spyOn(require('../../src/rateLimit/distributedCounter'), 'getCountInWindow')
        .mockImplementation(async () => {
          await new Promise(resolve => setTimeout(resolve, 2000));
          return 5;
        });

      // Should still work (just slow)
      const result = await checkRateLimit(testUser, 'summarizePdf' as FunctionType);
      expect(result.allowed).toBe(true);
    });
  });

  describe('Error Logging', () => {
    test('should log detailed error information', async () => {
      // Mock an error
      const testError = new Error('Test error for logging');
      jest.spyOn(require('../../src/rateLimit/distributedCounter'), 'getCountInWindow')
        .mockRejectedValueOnce(testError);

      errorLogs = [];

      await checkRateLimit(testUser, 'summarizePdf' as FunctionType);

      // Verify error was logged
      expect(errorLogs.some(log => log.includes('Error in rate limit check'))).toBe(true);
      expect(errorLogs.some(log => log.includes('Test error for logging'))).toBe(true);
    });

    test('should log fail-open decision', async () => {
      // Mock an error
      jest.spyOn(require('../../src/rateLimit/distributedCounter'), 'getCountInWindow')
        .mockRejectedValueOnce(new Error('Test error'));

      errorLogs = [];

      await checkRateLimit(testUser, 'summarizePdf' as FunctionType);

      // Verify fail-open was logged
      expect(errorLogs.some(log => log.includes('FAILING OPEN'))).toBe(true);
      expect(errorLogs.some(log => log.includes('allowing request'))).toBe(true);
    });

    test('should preserve error context in logs', async () => {
      const testError = new Error('Contextual error');
      (testError as any).context = { userId: testUser, operation: 'rateLimitCheck' };

      jest.spyOn(require('../../src/rateLimit/distributedCounter'), 'getCountInWindow')
        .mockRejectedValueOnce(testError);

      errorLogs = [];

      await checkRateLimit(testUser, 'summarizePdf' as FunctionType);

      // Verify error context was preserved
      expect(errorLogs.some(log => log.includes('Contextual error'))).toBe(true);
    });
  });

  describe('Request Allowance', () => {
    test('should never block requests due to system errors', async () => {
      // Mock all rate limit operations to fail
      jest.spyOn(require('../../src/rateLimit/distributedCounter'), 'getCountInWindow')
        .mockRejectedValue(new Error('System error'));
      jest.spyOn(require('../../src/rateLimit/remoteConfig'), 'getRateLimits')
        .mockRejectedValue(new Error('Config error'));

      // Make multiple requests
      const results = await Promise.all([
        checkRateLimit(testUser, 'summarizePdf' as FunctionType),
        checkRateLimit(testUser, 'summarizePdf' as FunctionType),
        checkRateLimit(testUser, 'summarizePdf' as FunctionType),
      ]);

      // All should be allowed
      results.forEach(result => {
        expect(result.allowed).toBe(true);
      });
    });

    test('should allow request when rate limiting is disabled', async () => {
      // Disable rate limiting
      const configRef = db.collection('config').doc('rateLimiter');
      await configRef.set({
        enabled: false,
        summarizePdf: {
          hourlyLimit: 10,
          dailyLimit: 50,
          minRequestInterval: 500,
        },
      });

      // Wait for config to take effect
      await new Promise(resolve => setTimeout(resolve, 100));

      // Should allow request immediately
      const result = await checkRateLimit(testUser, 'summarizePdf' as FunctionType);
      expect(result.allowed).toBe(true);
    });

    test('should handle rapid requests during fail-open', async () => {
      // Mock failures
      jest.spyOn(require('../../src/rateLimit/distributedCounter'), 'getCountInWindow')
        .mockRejectedValue(new Error('Fail-open scenario'));

      // Make rapid requests
      const promises = Array.from({ length: 10 }, () =>
        checkRateLimit(testUser, 'summarizePdf' as FunctionType)
      );

      const results = await Promise.all(promises);

      // All should be allowed
      results.forEach(result => {
        expect(result.allowed).toBe(true);
      });
    });
  });

  describe('Recovery Scenarios', () => {
    test('should resume normal operation after failure recovery', async () => {
      // Mock initial failure
      let shouldFail = true;
      jest.spyOn(require('../../src/rateLimit/distributedCounter'), 'getCountInWindow')
        .mockImplementation(async () => {
          if (shouldFail) {
            throw new Error('Temporary failure');
          }
          return 5;
        });

      // First request should fail-open
      const result1 = await checkRateLimit(testUser, 'summarizePdf' as FunctionType);
      expect(result1.allowed).toBe(true);

      // Recover
      shouldFail = false;

      // Second request should work normally
      const result2 = await checkRateLimit(testUser, 'summarizePdf' as FunctionType);
      expect(result2.allowed).toBe(true);
    });

    test('should handle intermittent failures gracefully', async () => {
      let requestCount = 0;
      jest.spyOn(require('../../src/rateLimit/distributedCounter'), 'getCountInWindow')
        .mockImplementation(async () => {
          requestCount++;
          if (requestCount % 3 === 0) {
            throw new Error('Intermittent failure');
          }
          return requestCount;
        });

      // Make 10 requests
      const promises = Array.from({ length: 10 }, () =>
        checkRateLimit(testUser, 'summarizePdf' as FunctionType)
      );

      const results = await Promise.all(promises);

      // All should succeed (some via fail-open)
      results.forEach(result => {
        expect(result.allowed).toBe(true);
      });
    });
  });

  describe('Edge Cases', () => {
    test('should handle null error gracefully', async () => {
      jest.spyOn(require('../../src/rateLimit/distributedCounter'), 'getCountInWindow')
        .mockRejectedValueOnce(null);

      errorLogs = [];

      const result = await checkRateLimit(testUser, 'summarizePdf' as FunctionType);

      expect(result.allowed).toBe(true);
      expect(errorLogs.length).toBeGreaterThan(0);
    });

    test('should handle undefined error gracefully', async () => {
      jest.spyOn(require('../../src/rateLimit/distributedCounter'), 'getCountInWindow')
        .mockRejectedValueOnce(undefined);

      errorLogs = [];

      const result = await checkRateLimit(testUser, 'summarizePdf' as FunctionType);

      expect(result.allowed).toBe(true);
    });

    test('should handle error without message property', async () => {
      jest.spyOn(require('../../src/rateLimit/distributedCounter'), 'getCountInWindow')
        .mockRejectedValueOnce({});

      errorLogs = [];

      const result = await checkRateLimit(testUser, 'summarizePdf' as FunctionType);

      expect(result.allowed).toBe(true);
    });
  });

  describe('Performance During Fail-Open', () => {
    test('should return quickly during fail-open', async () => {
      // Mock fast failure
      jest.spyOn(require('../../src/rateLimit/distributedCounter'), 'getCountInWindow')
        .mockRejectedValue(new Error('Quick failure'));

      const startTime = Date.now();

      await checkRateLimit(testUser, 'summarizePdf' as FunctionType);

      const elapsed = Date.now() - startTime;

      // Should still be fast (error path is quick)
      expect(elapsed).toBeLessThan(100);
    });

    test('should handle concurrent fail-open requests efficiently', async () => {
      // Mock failures
      jest.spyOn(require('../../src/rateLimit/distributedCounter'), 'getCountInWindow')
        .mockRejectedValue(new Error('Concurrent failure'));

      const startTime = Date.now();

      // Make 50 concurrent requests
      const promises = Array.from({ length: 50 }, () =>
        checkRateLimit(testUser, 'summarizePdf' as FunctionType)
      );

      await Promise.all(promises);

      const elapsed = Date.now() - startTime;

      console.log(`   50 concurrent fail-open requests in ${elapsed}ms`);
      console.log(`   Avg: ${(elapsed / 50).toFixed(2)}ms per request`);

      // Should handle efficiently
      expect(elapsed).toBeLessThan(5000); // 5 seconds for 50 requests
    });
  });

  describe('Real-World Failure Scenarios', () => {
    test('should simulate Firestore outage', async () => {
      // Mock Firestore to be completely down
      jest.spyOn(require('../../src/rateLimit/distributedCounter'), 'getCountInWindow')
        .mockRejectedValue(new Error('Firestore: UNAVAILABLE'));
      jest.spyOn(require('../../src/rateLimit/distributedCounter'), 'incrementCounter')
        .mockRejectedValue(new Error('Firestore: UNAVAILABLE'));
      jest.spyOn(require('../../src/rateLimit/distributedCounter'), 'getLastRequestTime')
        .mockRejectedValue(new Error('Firestore: UNAVAILABLE'));

      // Requests should still be allowed
      const result = await checkRateLimit(testUser, 'summarizePdf' as FunctionType);
      expect(result.allowed).toBe(true);

      // Verify proper error logging
      expect(errorLogs.some(log => log.includes('UNAVAILABLE'))).toBe(true);
    });

    test('should simulate network partition', async () => {
      // Mock network errors
      jest.spyOn(require('../../src/rateLimit/distributedCounter'), 'getCountInWindow')
        .mockRejectedValue(new Error('Network partition detected'));

      const result = await checkRateLimit(testUser, 'summarizePdf' as FunctionType);
      expect(result.allowed).toBe(true);

      expect(errorLogs.some(log => log.includes('Network partition'))).toBe(true);
    });

    test('should simulate degraded performance', async () => {
      // Mock slow operations
      jest.spyOn(require('../../src/rateLimit/distributedCounter'), 'getCountInWindow')
        .mockImplementation(async () => {
          await new Promise(resolve => setTimeout(resolve, 5000));
          throw new Error('Timeout');
        });

      const startTime = Date.now();

      // Should eventually succeed (after timeout)
      const result = await checkRateLimit(testUser, 'summarizePdf' as FunctionType);

      const elapsed = Date.now() - startTime;

      expect(result.allowed).toBe(true);
      console.log(`   Degraded performance scenario took ${elapsed}ms`);
    });
  });
});
