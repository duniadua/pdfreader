/**
 * Circuit Breaker Integration Tests
 *
 * Tests complete circuit breaker lifecycle:
 * - Circuit opening after failures
 * - Auto-recovery after timeout
 * - Half-open state handling
 * - Circuit closing on success
 * - Integration with rate limiting
 */

import * as admin from 'firebase-admin';
import { HttpsError } from 'firebase-functions/v2/https';
import { checkRateLimit } from '../../src/rateLimit/middleware';
import { isOpen, recordSuccess, recordFailure } from '../../src/rateLimit/circuitBreaker';
import { FunctionType } from '../../src/rateLimit/types';

describe('Circuit Breaker Integration Tests', () => {
  let testUser: string;
  let db: admin.firestore.Firestore;
  const CIRCUIT_COLLECTION = 'circuitBreaker';
  const CIRCUIT_DOC = 'aiService';

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
    testUser = 'circuit-breaker-test-user';

    await resetCircuit();
  });

  afterAll(async () => {
    await resetCircuit();
    await admin.app().delete();
  });

  beforeEach(async () => {
    await resetCircuit();
  });

  async function resetCircuit(): Promise<void> {
    await db.collection(CIRCUIT_COLLECTION).doc(CIRCUIT_DOC).set({
      isOpen: false,
      lastFailureTime: 0,
      failureCount: 0,
    });
  }

  async function getCircuitState(): Promise<{
    isOpen: boolean;
    failureCount: number;
    lastFailureTime: number;
  }> {
    const doc = await db.collection(CIRCUIT_COLLECTION).doc(CIRCUIT_DOC).get();
    return doc.data() as any;
  }

  describe('Circuit Opening', () => {
    test('should open circuit after 5 consecutive failures', async () => {
      // Record 5 failures
      for (let i = 0; i < 5; i++) {
        await recordFailure();
      }

      // Circuit should now be open
      const isCircuitOpen = await isOpen();
      expect(isCircuitOpen).toBe(true);

      const state = await getCircuitState();
      expect(state.isOpen).toBe(true);
      expect(state.failureCount).toBe(5);
      expect(state.lastFailureTime).toBeGreaterThan(0);
    });

    test('should not open circuit before threshold', async () => {
      // Record only 4 failures (below threshold)
      for (let i = 0; i < 4; i++) {
        await recordFailure();
      }

      // Circuit should still be closed
      const isCircuitOpen = await isOpen();
      expect(isCircuitOpen).toBe(false);

      const state = await getCircuitState();
      expect(state.isOpen).toBe(false);
      expect(state.failureCount).toBe(4);
    });

    test('should reset failure count on success', async () => {
      // Record 3 failures
      for (let i = 0; i < 3; i++) {
        await recordFailure();
      }

      // Record success
      await recordSuccess();

      const state = await getCircuitState();
      expect(state.failureCount).toBe(0);
      expect(state.isOpen).toBe(false);
    });

    test('should reject requests when circuit is open', async () => {
      // Open the circuit
      for (let i = 0; i < 5; i++) {
        await recordFailure();
      }

      // Verify circuit is open
      expect(await isOpen()).toBe(true);

      // Try to make a request - should be rejected
      await expect(
        checkRateLimit(testUser, 'summarizePdf' as FunctionType)
      ).rejects.toThrow(HttpsError);

      try {
        await checkRateLimit(testUser, 'summarizePdf' as FunctionType);
        fail('Should have thrown HttpsError');
      } catch (error: any) {
        expect(error).toBeInstanceOf(HttpsError);
        expect(error.code).toBe('resource-exhausted');
        expect(error.message).toContain('Layanan AI sedang sibuk');
      }
    });

    test('should close circuit after successful request', async () => {
      // Open the circuit
      for (let i = 0; i < 5; i++) {
        await recordFailure();
      }

      expect(await isOpen()).toBe(true);

      // Record success (simulating successful AI request)
      await recordSuccess();

      // Circuit should be closed
      const isCircuitOpen = await isOpen();
      expect(isCircuitOpen).toBe(false);

      const state = await getCircuitState();
      expect(state.isOpen).toBe(false);
      expect(state.failureCount).toBe(0);
    });
  });

  describe('Auto-Recovery', () => {
    test('should auto-recover after 60 seconds', async () => {
      // Open the circuit
      for (let i = 0; i < 5; i++) {
        await recordFailure();
      }

      const state1 = await getCircuitState();
      expect(state1.isOpen).toBe(true);

      // Manually set lastFailureTime to more than 60 seconds ago
      const sixtyOneSecondsAgo = Date.now() - 61000;
      await db.collection(CIRCUIT_COLLECTION).doc(CIRCUIT_DOC).update({
        lastFailureTime: sixtyOneSecondsAgo,
      });

      // Circuit should now be closed (auto-recovered)
      const isCircuitOpen = await isOpen();
      expect(isCircuitOpen).toBe(false);

      const state2 = await getCircuitState();
      expect(state2.isOpen).toBe(false);
    });

    test('should not auto-recover before 60 seconds', async () => {
      // Open the circuit
      for (let i = 0; i < 5; i++) {
        await recordFailure();
      }

      // Set lastFailureTime to 59 seconds ago (just under threshold)
      const fiftyNineSecondsAgo = Date.now() - 59000;
      await db.collection(CIRCUIT_COLLECTION).doc(CIRCUIT_DOC).update({
        lastFailureTime: fiftyNineSecondsAgo,
      });

      // Circuit should still be open
      const isCircuitOpen = await isOpen();
      expect(isCircuitOpen).toBe(true);
    });

    test('should reset failure count on auto-recovery', async () => {
      // Open the circuit with high failure count
      for (let i = 0; i < 10; i++) {
        await recordFailure();
      }

      const state1 = await getCircuitState();
      expect(state1.failureCount).toBeGreaterThanOrEqual(5);

      // Simulate time passing
      const sixtyOneSecondsAgo = Date.now() - 61000;
      await db.collection(CIRCUIT_COLLECTION).doc(CIRCUIT_DOC).update({
        lastFailureTime: sixtyOneSecondsAgo,
      });

      // Trigger auto-recovery check
      await isOpen();

      const state2 = await getCircuitState();
      expect(state2.isOpen).toBe(false);
      expect(state2.failureCount).toBe(0);
    });
  });

  describe('Half-Open State', () => {
    test('should allow single request to test service recovery', async () => {
      // Open the circuit
      for (let i = 0; i < 5; i++) {
        await recordFailure();
      }

      // Simulate time passing for auto-recovery
      const sixtyOneSecondsAgo = Date.now() - 61000;
      await db.collection(CIRCUIT_COLLECTION).doc(CIRCUIT_DOC).update({
        lastFailureTime: sixtyOneSecondsAgo,
      });

      // First request after recovery should be allowed
      const result = await checkRateLimit(testUser, 'summarizePdf' as FunctionType);
      expect(result.allowed).toBe(true);

      // Circuit should now be closed
      expect(await isOpen()).toBe(false);
    });

    test('should re-open circuit if test request fails', async () => {
      // Open the circuit
      for (let i = 0; i < 5; i++) {
        await recordFailure();
      }

      // Simulate time passing
      const sixtyOneSecondsAgo = Date.now() - 61000;
      await db.collection(CIRCUIT_COLLECTION).doc(CIRCUIT_DOC).update({
        lastFailureTime: sixtyOneSecondsAgo,
      });

      // Check circuit (this will auto-recover)
      await isOpen();

      // Immediately record another failure
      await recordFailure();

      // Circuit should open again
      const isCircuitOpen = await isOpen();
      expect(isCircuitOpen).toBe(true);

      const state = await getCircuitState();
      expect(state.isOpen).toBe(true);
      expect(state.failureCount).toBe(1);
    });
  });

  describe('Integration with Rate Limiting', () => {
    test('should check circuit breaker before rate limits', async () => {
      // Open the circuit
      for (let i = 0; i < 5; i++) {
        await recordFailure();
      }

      // Even with no rate limit usage, request should be rejected
      await expect(
        checkRateLimit(testUser, 'summarizePdf' as FunctionType)
      ).rejects.toThrow(HttpsError);
    });

    test('should allow requests when circuit is closed and under rate limit', async () => {
      // Ensure circuit is closed
      await recordSuccess();

      // Make a request
      const result = await checkRateLimit(testUser, 'summarizePdf' as FunctionType);
      expect(result.allowed).toBe(true);
    });

    test('should reset circuit on successful AI request', async () => {
      // Open the circuit
      for (let i = 0; i < 5; i++) {
        await recordFailure();
      }

      expect(await isOpen()).toBe(true);

      // Simulate successful AI request
      await recordSuccess();

      // Circuit should be closed
      expect(await isOpen()).toBe(false);

      // Requests should now be allowed
      const result = await checkRateLimit(testUser, 'summarizePdf' as FunctionType);
      expect(result.allowed).toBe(true);
    });
  });

  describe('Failure Counting', () => {
    test('should increment failure count on each failure', async () => {
      const state1 = await getCircuitState();
      expect(state1.failureCount).toBe(0);

      await recordFailure();
      const state2 = await getCircuitState();
      expect(state2.failureCount).toBe(1);

      await recordFailure();
      await recordFailure();
      const state3 = await getCircuitState();
      expect(state3.failureCount).toBe(3);
    });

    test('should track consecutive failures separately from total', async () => {
      // Record 3 failures
      for (let i = 0; i < 3; i++) {
        await recordFailure();
      }

      let state = await getCircuitState();
      expect(state.failureCount).toBe(3);

      // Record success
      await recordSuccess();

      state = await getCircuitState();
      expect(state.failureCount).toBe(0);

      // Record failures again
      for (let i = 0; i < 2; i++) {
        await recordFailure();
      }

      state = await getCircuitState();
      expect(state.failureCount).toBe(2);
    });

    test('should update lastFailureTime on each failure', async () => {
      await recordFailure();
      const state1 = await getCircuitState();
      const time1 = state1.lastFailureTime;

      // Wait a bit
      await new Promise(resolve => setTimeout(resolve, 100));

      await recordFailure();
      const state2 = await getCircuitState();
      const time2 = state2.lastFailureTime;

      expect(time2).toBeGreaterThan(time1);
    });
  });

  describe('Edge Cases', () => {
    test('should handle rapid failure/success cycles', async () => {
      // Alternate between failure and success
      for (let i = 0; i < 10; i++) {
        await recordFailure();
        await recordSuccess();

        const state = await getCircuitState();
        expect(state.isOpen).toBe(false);
        expect(state.failureCount).toBe(0);
      }
    });

    test('should handle concurrent failure records', async () => {
      // Record many failures concurrently
      const promises = Array.from({ length: 10 }, () => recordFailure());

      await Promise.all(promises);

      const state = await getCircuitState();
      expect(state.isOpen).toBe(true);
      expect(state.failureCount).toBeGreaterThanOrEqual(5);
    });

    test('should handle circuit state queries during recovery', async () => {
      // Open the circuit
      for (let i = 0; i < 5; i++) {
        await recordFailure();
      }

      // Simulate recovery time
      const sixtyOneSecondsAgo = Date.now() - 61000;
      await db.collection(CIRCUIT_COLLECTION).doc(CIRCUIT_DOC).update({
        lastFailureTime: sixtyOneSecondsAgo,
      });

      // Query circuit state multiple times
      const results = await Promise.all([
        isOpen(),
        isOpen(),
        isOpen(),
      ]);

      // All should return false (circuit closed)
      results.forEach(isOpen => {
        expect(isOpen).toBe(false);
      });
    });
  });

  describe('Performance', () => {
    test('should check circuit state quickly', async () => {
      const startTime = Date.now();

      await isOpen();

      const elapsed = Date.now() - startTime;
      expect(elapsed).toBeLessThan(50);
    });

    test('should record failures quickly', async () => {
      const startTime = Date.now();

      await recordFailure();

      const elapsed = Date.now() - startTime;
      expect(elapsed).toBeLessThan(50);
    });

    test('should handle 100 failure records without degradation', async () => {
      const timings: number[] = [];

      for (let i = 0; i < 100; i++) {
        const startTime = Date.now();
        await recordFailure();
        timings.push(Date.now() - startTime);

        // Reset after every 5 failures
        if ((i + 1) % 5 === 0) {
          await recordSuccess();
        }
      }

      // Check for performance degradation
      const firstTenAvg = timings.slice(0, 10).reduce((a, b) => a + b, 0) / 10;
      const lastTenAvg = timings.slice(-10).reduce((a, b) => a + b, 0) / 10;

      console.log(`   First 10 avg: ${firstTenAvg.toFixed(2)}ms`);
      console.log(`   Last 10 avg: ${lastTenAvg.toFixed(2)}ms`);

      // Last 10 should not be more than 2x slower
      expect(lastTenAvg).toBeLessThan(firstTenAvg * 2);
    });
  });

  describe('Real-World Scenarios', () => {
    test('should handle AI service outage scenario', async () => {
      // Simulate AI service outage (multiple failures)
      const failureCount = 10;
      for (let i = 0; i < failureCount; i++) {
        await recordFailure();
      }

      // Circuit should be open
      expect(await isOpen()).toBe(true);

      // All requests should be blocked
      for (let i = 0; i < 5; i++) {
        await expect(
          checkRateLimit(testUser, 'summarizePdf' as FunctionType)
        ).rejects.toThrow(HttpsError);
      }

      // Simulate service recovery (time passes)
      const sixtyOneSecondsAgo = Date.now() - 61000;
      await db.collection(CIRCUIT_COLLECTION).doc(CIRCUIT_DOC).update({
        lastFailureTime: sixtyOneSecondsAgo,
      });

      // First request should succeed
      const result = await checkRateLimit(testUser, 'summarizePdf' as FunctionType);
      expect(result.allowed).toBe(true);

      // Circuit should be closed
      expect(await isOpen()).toBe(false);
    });

    test('should handle intermittent failures', async () => {
      // Simulate intermittent failures
      for (let i = 0; i < 20; i++) {
        if (i % 3 === 0) {
          await recordFailure();
        } else {
          await recordSuccess();
        }
      }

      // Circuit should still be closed (never reached threshold)
      expect(await isOpen()).toBe(false);

      const state = await getCircuitState();
      expect(state.failureCount).toBeLessThan(5);
    });
  });
});
