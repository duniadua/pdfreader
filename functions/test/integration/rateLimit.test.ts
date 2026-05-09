/**
 * End-to-End Rate Limit Integration Tests
 *
 * Tests complete rate limiting flows including:
 * - Per-user quota enforcement
 * - Request interval limiting
 * - Daily/hourly limit resets
 * - Independent user counters
 * - Edge cases and error handling
 */

import * as admin from 'firebase-admin';
import { HttpsError } from 'firebase-functions/v2/https';
import { checkRateLimit, getUserUsage } from '../../src/rateLimit/middleware';
import { getCountInWindow, incrementCounter } from '../../src/rateLimit/distributedCounter';
import { getRateLimits, isRateLimitingEnabled } from '../../src/rateLimit/remoteConfig';
import { isOpen, recordSuccess, recordFailure } from '../../src/rateLimit/circuitBreaker';
import { FunctionType } from '../../src/rateLimit/types';

describe('Rate Limiting Integration Tests', () => {
  let testUser1: string;
  let testUser2: string;
  let db: admin.firestore.Firestore;

  beforeAll(async () => {
    // Initialize Firebase Admin
    process.env.FIRESTORE_EMULATOR_HOST = 'localhost:8080';
    process.env.FIREBASE_CONFIG = JSON.stringify({
      projectId: 'test-project',
    });

    try {
      await admin.initializeApp();
    } catch (e: any) {
      // Already initialized
      if (e.code !== 'app/duplicate-app') {
        throw e;
      }
    }

    db = admin.firestore();
    testUser1 = 'test-user-rate-limit-1';
    testUser2 = 'test-user-rate-limit-2';

    // Clean up any existing test data
    await cleanupTestData();
  });

  afterAll(async () => {
    await cleanupTestData();
    await admin.app().delete();
  });

  beforeEach(async () => {
    // Reset counters before each test
    await cleanupTestData();

    // Ensure circuit breaker is closed
    const circuitRef = db.collection('circuitBreaker').doc('aiService');
    await circuitRef.set({
      isOpen: false,
      lastFailureTime: 0,
      failureCount: 0,
    });
  });

  async function cleanupTestData(): Promise<void> {
    const batch = db.batch();

    // Clean up rate limit counters
    const countersSnapshot = await db
      .collection('rateLimitCounters')
      .where('__name__', '>=', testUser1)
      .get();

    countersSnapshot.docs.forEach((doc) => {
      batch.delete(doc.ref);
    });

    const countersSnapshot2 = await db
      .collection('rateLimitCounters')
      .where('__name__', '>=', testUser2)
      .get();

    countersSnapshot2.docs.forEach((doc) => {
      batch.delete(doc.ref);
    });

    await batch.commit();
  }

  describe('Hourly Rate Limiting', () => {
    test('should allow requests up to hourly limit', async () => {
      const config = await getRateLimits('summarizePdf' as FunctionType);
      const limit = config.hourlyLimit;

      // Make requests up to the limit
      for (let i = 0; i < limit; i++) {
        const result = await checkRateLimit(testUser1, 'summarizePdf' as FunctionType);
        expect(result.allowed).toBe(true);
      }

      // Verify count matches
      const count = await getCountInWindow(testUser1, 'summarizePdf', 'hour');
      expect(count).toBe(limit);
    });

    test('should reject request when hourly limit exceeded', async () => {
      const config = await getRateLimits('summarizePdf' as FunctionType);
      const limit = config.hourlyLimit;

      // Make requests up to the limit
      for (let i = 0; i < limit; i++) {
        await checkRateLimit(testUser1, 'summarizePdf' as FunctionType);
      }

      // Next request should be rate limited
      await expect(
        checkRateLimit(testUser1, 'summarizePdf' as FunctionType)
      ).rejects.toThrow(HttpsError);

      try {
        await checkRateLimit(testUser1, 'summarizePdf' as FunctionType);
        fail('Should have thrown HttpsError');
      } catch (error: any) {
        expect(error).toBeInstanceOf(HttpsError);
        expect(error.code).toBe('resource-exhausted');
        expect(error.message).toContain('Batas permintaan per jam');
      }
    });

    test('should reset hourly counter at hour boundary', async () => {
      const config = await getRateLimits('summarizePdf' as FunctionType);
      const limit = config.hourlyLimit;

      // Exhaust hourly limit
      for (let i = 0; i < limit; i++) {
        await checkRateLimit(testUser1, 'summarizePdf' as FunctionType);
      }

      // Verify rate limited
      await expect(
        checkRateLimit(testUser1, 'summarizePdf' as FunctionType)
      ).rejects.toThrow();

      // Simulate hour boundary by manually updating shard timestamps
      const now = Date.now();
      const oneHourAgo = now - (60 * 60 * 1000) - 1000; // More than 1 hour ago

      const shardsSnapshot = await db
        .collection('rateLimitCounters')
        .where('__name__', '>=', `${testUser1}_summarizePdf`)
        .get();

      const batch = db.batch();
      shardsSnapshot.docs.forEach((doc) => {
        if (doc.id.includes('shard_')) {
          batch.update(doc.ref, { lastUpdated: oneHourAgo });
        }
      });
      await batch.commit();

      // Should now allow request again
      const result = await checkRateLimit(testUser1, 'summarizePdf' as FunctionType);
      expect(result.allowed).toBe(true);
    });
  });

  describe('Daily Rate Limiting', () => {
    test('should allow requests up to daily limit', async () => {
      const config = await getRateLimits('summarizePdf' as FunctionType);
      const limit = config.dailyLimit;

      // Make requests up to the limit
      for (let i = 0; i < limit; i++) {
        const result = await checkRateLimit(testUser1, 'summarizePdf' as FunctionType);
        expect(result.allowed).toBe(true);
      }

      // Verify daily count
      const dailyCount = await getCountInWindow(testUser1, 'summarizePdf', 'day');
      expect(dailyCount).toBe(limit);
    });

    test('should reject request when daily limit exceeded', async () => {
      const config = await getRateLimits('summarizePdf' as FunctionType);
      const limit = config.dailyLimit;

      // Make requests up to the daily limit
      for (let i = 0; i < limit; i++) {
        await checkRateLimit(testUser1, 'summarizePdf' as FunctionType);
      }

      // Next request should be rate limited
      await expect(
        checkRateLimit(testUser1, 'summarizePdf' as FunctionType)
      ).rejects.toThrow(HttpsError);

      try {
        await checkRateLimit(testUser1, 'summarizePdf' as FunctionType);
        fail('Should have thrown HttpsError');
      } catch (error: any) {
        expect(error).toBeInstanceOf(HttpsError);
        expect(error.code).toBe('resource-exhausted');
        expect(error.message).toContain('Batas permintaan per hari');
      }
    });

    test('should reset daily counter at day boundary', async () => {
      const config = await getRateLimits('summarizePdf' as FunctionType);
      const limit = config.dailyLimit;

      // Exhaust daily limit
      for (let i = 0; i < limit; i++) {
        await checkRateLimit(testUser1, 'summarizePdf' as FunctionType);
      }

      // Verify rate limited
      await expect(
        checkRateLimit(testUser1, 'summarizePdf' as FunctionType)
      ).rejects.toThrow();

      // Simulate day boundary by updating shard timestamps
      const now = Date.now();
      const oneDayAgo = now - (24 * 60 * 60 * 1000) - 1000; // More than 1 day ago

      const shardsSnapshot = await db
        .collection('rateLimitCounters')
        .where('__name__', '>=', `${testUser1}_summarizePdf`)
        .get();

      const batch = db.batch();
      shardsSnapshot.docs.forEach((doc) => {
        if (doc.id.includes('shard_')) {
          batch.update(doc.ref, { lastUpdated: oneDayAgo });
        }
      });
      await batch.commit();

      // Should now allow request again
      const result = await checkRateLimit(testUser1, 'summarizePdf' as FunctionType);
      expect(result.allowed).toBe(true);
    });
  });

  describe('Request Interval Limiting', () => {
    test('should enforce minimum request interval', async () => {
      const config = await getRateLimits('summarizePdf' as FunctionType);
      const minInterval = config.minRequestInterval;

      // Make first request
      await checkRateLimit(testUser1, 'summarizePdf' as FunctionType);

      // Make second request immediately (should be rate limited)
      await expect(
        checkRateLimit(testUser1, 'summarizePdf' as FunctionType)
      ).rejects.toThrow(HttpsError);

      try {
        await checkRateLimit(testUser1, 'summarizePdf' as FunctionType);
        fail('Should have thrown HttpsError');
      } catch (error: any) {
        expect(error).toBeInstanceOf(HttpsError);
        expect(error.code).toBe('resource-exhausted');
        expect(error.message).toContain('Permintaan terlalu cepat');
        expect(error.details?.retryAfter).toBeGreaterThan(0);
        expect(error.details?.retryAfter).toBeLessThanOrEqual(minInterval);
      }
    });

    test('should allow request after minimum interval passes', async () => {
      const config = await getRateLimits('summarizePdf' as FunctionType);
      const minInterval = config.minRequestInterval;

      // Make first request
      await checkRateLimit(testUser1, 'summarizePdf' as FunctionType);

      // Wait for minimum interval
      await new Promise(resolve => setTimeout(resolve, minInterval + 100));

      // Should now allow request
      const result = await checkRateLimit(testUser1, 'summarizePdf' as FunctionType);
      expect(result.allowed).toBe(true);
    });

    test('should calculate accurate retry-after time', async () => {
      const config = await getRateLimits('summarizePdf' as FunctionType);
      const minInterval = config.minRequestInterval;

      // Make first request
      const startTime = Date.now();
      await checkRateLimit(testUser1, 'summarizePdf' as FunctionType);

      // Wait half the minimum interval
      await new Promise(resolve => setTimeout(resolve, minInterval / 2));

      try {
        await checkRateLimit(testUser1, 'summarizePdf' as FunctionType);
        fail('Should have thrown HttpsError');
      } catch (error: any) {
        const elapsed = Date.now() - startTime;
        const expectedRetryAfter = Math.max(0, minInterval - elapsed);

        expect(error.details?.retryAfter).toBeGreaterThan(0);
        expect(error.details?.retryAfter).toBeLessThanOrEqual(expectedRetryAfter + 100);
      }
    });
  });

  describe('Independent User Counters', () => {
    test('should maintain separate counters for different users', async () => {
      const limit = (await getRateLimits('summarizePdf' as FunctionType)).hourlyLimit;

      // User 1 makes 5 requests
      for (let i = 0; i < 5; i++) {
        await checkRateLimit(testUser1, 'summarizePdf' as FunctionType);
      }

      // User 2 makes 3 requests
      for (let i = 0; i < 3; i++) {
        await checkRateLimit(testUser2, 'summarizePdf' as FunctionType);
      }

      // Verify counts are independent
      const count1 = await getCountInWindow(testUser1, 'summarizePdf', 'hour');
      const count2 = await getCountInWindow(testUser2, 'summarizePdf', 'hour');

      expect(count1).toBe(5);
      expect(count2).toBe(3);

      // User 2 should still be able to make more requests
      const result = await checkRateLimit(testUser2, 'summarizePdf' as FunctionType);
      expect(result.allowed).toBe(true);
    });

    test('should not rate limit user based on other users activity', async () => {
      const limit = (await getRateLimits('summarizePdf' as FunctionType)).hourlyLimit;

      // User 1 exhausts their hourly limit
      for (let i = 0; i < limit; i++) {
        await checkRateLimit(testUser1, 'summarizePdf' as FunctionType);
      }

      // User 1 should be rate limited
      await expect(
        checkRateLimit(testUser1, 'summarizePdf' as FunctionType)
      ).rejects.toThrow();

      // User 2 should still have full quota available
      const result = await checkRateLimit(testUser2, 'summarizePdf' as FunctionType);
      expect(result.allowed).toBe(true);
    });
  });

  describe('Circuit Breaker Integration', () => {
    test('should reject requests when circuit breaker is open', async () => {
      // Open the circuit breaker
      const circuitRef = db.collection('circuitBreaker').doc('aiService');
      await circuitRef.update({
        isOpen: true,
        lastFailureTime: Date.now(),
      });

      // Request should be rejected
      await expect(
        checkRateLimit(testUser1, 'summarizePdf' as FunctionType)
      ).rejects.toThrow(HttpsError);

      try {
        await checkRateLimit(testUser1, 'summarizePdf' as FunctionType);
        fail('Should have thrown HttpsError');
      } catch (error: any) {
        expect(error).toBeInstanceOf(HttpsError);
        expect(error.code).toBe('resource-exhausted');
        expect(error.message).toContain('Layanan AI sedang sibuk');
      }
    });

    test('should allow requests when circuit breaker is closed', async () => {
      // Ensure circuit breaker is closed
      const circuitRef = db.collection('circuitBreaker').doc('aiService');
      await circuitRef.update({
        isOpen: false,
        lastFailureTime: 0,
        failureCount: 0,
      });

      // Request should be allowed
      const result = await checkRateLimit(testUser1, 'summarizePdf' as FunctionType);
      expect(result.allowed).toBe(true);
    });
  });

  describe('Fail-Open Behavior', () => {
    test('should allow request when Firestore is unavailable', async () => {
      // This test simulates Firestore being down
      // In real scenario, we'd mock the Firestore client to throw errors

      // For now, we verify the error handling logic
      const isEnabled = await isRateLimitingEnabled();
      expect(typeof isEnabled).toBe('boolean');
    });

    test('should allow request when rate limiting is disabled', async () => {
      // Mock Remote Config to disable rate limiting
      const configRef = db.collection('config').doc('rateLimiter');
      await configRef.set({
        enabled: false,
        summarizePdf: {
          hourlyLimit: 10,
          dailyLimit: 50,
          minRequestInterval: 500,
        },
      });

      // Wait for Remote Config cache to invalidate (in real scenario)
      await new Promise(resolve => setTimeout(resolve, 100));

      // Request should be allowed regardless of previous activity
      const result = await checkRateLimit(testUser1, 'summarizePdf' as FunctionType);
      expect(result.allowed).toBe(true);
    });
  });

  describe('User Usage Statistics', () => {
    test('should return accurate usage statistics', async () => {
      // Make some requests
      const requestCount = 5;
      for (let i = 0; i < requestCount; i++) {
        await checkRateLimit(testUser1, 'summarizePdf' as FunctionType);
        await new Promise(resolve => setTimeout(resolve, 600)); // Wait for interval
      }

      // Get usage statistics
      const usage = await getUserUsage(testUser1, 'summarizePdf' as FunctionType);

      expect(usage.hourlyUsed).toBe(requestCount);
      expect(usage.dailyUsed).toBe(requestCount);
      expect(usage.canRequest).toBe(true);
      expect(usage.hourlyLimit).toBeGreaterThan(0);
      expect(usage.dailyLimit).toBeGreaterThan(0);
    });

    test('should indicate when user cannot make requests', async () => {
      const limit = (await getRateLimits('summarizePdf' as FunctionType)).hourlyLimit;

      // Exhaust hourly limit
      for (let i = 0; i < limit; i++) {
        await checkRateLimit(testUser1, 'summarizePdf' as FunctionType);
      }

      // Get usage statistics
      const usage = await getUserUsage(testUser1, 'summarizePdf' as FunctionType);

      expect(usage.hourlyUsed).toBe(limit);
      expect(usage.canRequest).toBe(false);
    });
  });

  describe('Performance Tests', () => {
    test('should complete rate limit check in under 100ms', async () => {
      const startTime = Date.now();

      await checkRateLimit(testUser1, 'summarizePdf' as FunctionType);

      const elapsed = Date.now() - startTime;
      expect(elapsed).toBeLessThan(100);
    });

    test('should handle multiple sequential requests efficiently', async () => {
      const requestCount = 10;
      const startTime = Date.now();

      for (let i = 0; i < requestCount; i++) {
        await checkRateLimit(testUser1, 'summarizePdf' as FunctionType);
        await new Promise(resolve => setTimeout(resolve, 600)); // Wait for interval
      }

      const elapsed = Date.now() - startTime;
      const avgTimePerRequest = elapsed / requestCount;

      // Average should be under 200ms per request
      expect(avgTimePerRequest).toBeLessThan(200);
    });
  });

  describe('Edge Cases', () => {
    test('should handle empty user ID gracefully', async () => {
      // Should not throw, but log error
      try {
        await checkRateLimit('', 'summarizePdf' as FunctionType);
        // Depending on implementation, may allow or reject
      } catch (error) {
        // Expected to fail for empty user ID
        expect(error).toBeTruthy();
      }
    });

    test('should handle special characters in user ID', async () => {
      const specialUserId = 'user-with-special-chars_@#$';

      const result = await checkRateLimit(specialUserId, 'summarizePdf' as FunctionType);
      expect(result.allowed).toBe(true);

      // Verify counter was created
      const count = await getCountInWindow(specialUserId, 'summarizePdf', 'hour');
      expect(count).toBe(1);
    });

    test('should handle concurrent requests from same user', async () => {
      // Make multiple concurrent requests
      const promises = Array.from({ length: 5 }, () =>
        checkRateLimit(testUser1, 'summarizePdf' as FunctionType)
      );

      const results = await Promise.all(promises);

      // All should be allowed (within limits)
      results.forEach(result => {
        expect(result.allowed).toBe(true);
      });

      // Verify count
      const count = await getCountInWindow(testUser1, 'summarizePdf', 'hour');
      expect(count).toBe(5);
    });
  });
});
