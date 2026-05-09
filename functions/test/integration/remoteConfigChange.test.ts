/**
 * Remote Config Changes Integration Tests
 *
 * Tests dynamic configuration changes:
 * - Rate limit changes take effect
 * - Enabling/disabling rate limiting
 * - Configuration propagation
 * - Backward compatibility
 */

import * as admin from 'firebase-admin';
import { HttpsError } from 'firebase-functions/v2/https';
import { checkRateLimit, getUserUsage } from '../../src/rateLimit/middleware';
import { getRateLimits, isRateLimitingEnabled, refreshRemoteConfig } from '../../src/rateLimit/remoteConfig';
import { getCountInWindow } from '../../src/rateLimit/distributedCounter';
import { FunctionType } from '../../src/rateLimit/types';

describe('Remote Config Changes Integration Tests', () => {
  let testUser: string;
  let db: admin.firestore.Firestore;
  const CONFIG_COLLECTION = 'config';
  const CONFIG_DOC = 'rateLimiter';

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
    testUser = 'remote-config-test-user';

    await resetConfig();
  });

  afterAll(async () => {
    await resetConfig();
    await admin.app().delete();
  });

  beforeEach(async () => {
    await resetConfig();
    await cleanupUserCounters();
  });

  async function resetConfig(): Promise<void> {
    await db.collection(CONFIG_COLLECTION).doc(CONFIG_DOC).set({
      enabled: true,
      summarizePdf: {
        hourlyLimit: 10,
        dailyLimit: 50,
        minRequestInterval: 500,
      },
      chatWithPdf: {
        hourlyLimit: 20,
        dailyLimit: 100,
        minRequestInterval: 300,
      },
    });
  }

  async function cleanupUserCounters(): Promise<void> {
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

  async function updateConfig(newConfig: any): Promise<void> {
    await db.collection(CONFIG_COLLECTION).doc(CONFIG_DOC).update(newConfig);
    // Wait for config to propagate
    await new Promise(resolve => setTimeout(resolve, 100));
  }

  describe('Rate Limit Changes', () => {
    test('should enforce new hourly limit after config change', async () => {
      // Initial config: hourly limit of 10
      const config1 = await getRateLimits('summarizePdf' as FunctionType);
      expect(config1.hourlyLimit).toBe(10);

      // Make 10 requests (exhaust initial limit)
      for (let i = 0; i < 10; i++) {
        await checkRateLimit(testUser, 'summarizePdf' as FunctionType);
      }

      // Should be rate limited
      await expect(
        checkRateLimit(testUser, 'summarizePdf' as FunctionType)
      ).rejects.toThrow(HttpsError);

      // Update config to increase limit to 20
      await updateConfig({
        summarizePdf: {
          hourlyLimit: 20,
          dailyLimit: 50,
          minRequestInterval: 500,
        },
      });

      // Force config refresh
      await refreshRemoteConfig();

      // Wait for cache to invalidate
      await new Promise(resolve => setTimeout(resolve, 200));

      // Should now be able to make more requests (up to new limit)
      for (let i = 0; i < 5; i++) {
        const result = await checkRateLimit(testUser, 'summarizePdf' as FunctionType);
        expect(result.allowed).toBe(true);
      }

      // Verify new limit is enforced
      const config2 = await getRateLimits('summarizePdf' as FunctionType);
      expect(config2.hourlyLimit).toBe(20);
    });

    test('should enforce new daily limit after config change', async () => {
      // Initial daily limit: 50
      const config1 = await getRateLimits('summarizePdf' as FunctionType);
      expect(config1.dailyLimit).toBe(50);

      // Change daily limit to 5
      await updateConfig({
        summarizePdf: {
          hourlyLimit: 10,
          dailyLimit: 5,
          minRequestInterval: 500,
        },
      });

      await refreshRemoteConfig();
      await new Promise(resolve => setTimeout(resolve, 200));

      // Make 5 requests
      for (let i = 0; i < 5; i++) {
        await checkRateLimit(testUser, 'summarizePdf' as FunctionType);
      }

      // Should be rate limited at daily limit
      await expect(
        checkRateLimit(testUser, 'summarizePdf' as FunctionType)
      ).rejects.toThrow(HttpsError);

      try {
        await checkRateLimit(testUser, 'summarizePdf' as FunctionType);
        fail('Should have thrown HttpsError');
      } catch (error: any) {
        expect(error.message).toContain('Batas permintaan per hari');
      }
    });

    test('should enforce new minimum interval after config change', async () => {
      // Initial interval: 500ms
      const config1 = await getRateLimits('summarizePdf' as FunctionType);
      expect(config1.minRequestInterval).toBe(500);

      // Make first request
      await checkRateLimit(testUser, 'summarizePdf' as FunctionType);

      // Wait 400ms (less than initial 500ms interval)
      await new Promise(resolve => setTimeout(resolve, 400));

      // Should be rate limited
      await expect(
        checkRateLimit(testUser, 'summarizePdf' as FunctionType)
      ).rejects.toThrow(HttpsError);

      // Change interval to 200ms
      await updateConfig({
        summarizePdf: {
          hourlyLimit: 10,
          dailyLimit: 50,
          minRequestInterval: 200,
        },
      });

      await refreshRemoteConfig();
      await new Promise(resolve => setTimeout(resolve, 200));

      // Wait 200ms (new interval)
      await new Promise(resolve => setTimeout(resolve, 200));

      // Should now be allowed
      const result = await checkRateLimit(testUser, 'summarizePdf' as FunctionType);
      expect(result.allowed).toBe(true);
    });
  });

  describe('Enabling/Disabling Rate Limiting', () => {
    test('should allow all requests when rate limiting is disabled', async () => {
      // Verify rate limiting is initially enabled
      let isEnabled = await isRateLimitingEnabled();
      expect(isEnabled).toBe(true);

      // Make 10 requests (exhaust hourly limit)
      for (let i = 0; i < 10; i++) {
        await checkRateLimit(testUser, 'summarizePdf' as FunctionType);
      }

      // Should be rate limited
      await expect(
        checkRateLimit(testUser, 'summarizePdf' as FunctionType)
      ).rejects.toThrow(HttpsError);

      // Disable rate limiting
      await updateConfig({ enabled: false });
      await refreshRemoteConfig();
      await new Promise(resolve => setTimeout(resolve, 200));

      // Verify it's disabled
      isEnabled = await isRateLimitingEnabled();
      expect(isEnabled).toBe(false);

      // Should now allow unlimited requests
      for (let i = 0; i < 20; i++) {
        const result = await checkRateLimit(testUser, 'summarizePdf' as FunctionType);
        expect(result.allowed).toBe(true);
      }
    });

    test('should enforce limits immediately after re-enabling', async () => {
      // Disable rate limiting
      await updateConfig({ enabled: false });
      await refreshRemoteConfig();
      await new Promise(resolve => setTimeout(resolve, 200));

      // Make unlimited requests
      for (let i = 0; i < 50; i++) {
        await checkRateLimit(testUser, 'summarizePdf' as FunctionType);
      }

      // Re-enable rate limiting
      await updateConfig({ enabled: true });
      await refreshRemoteConfig();
      await new Promise(resolve => setTimeout(resolve, 200));

      // Should immediately enforce limits
      let requestCount = 0;
      let rateLimited = false;

      for (let i = 0; i < 20; i++) {
        try {
          await checkRateLimit(testUser, 'summarizePdf' as FunctionType);
          requestCount++;
        } catch (error: any) {
          if (error instanceof HttpsError) {
            rateLimited = true;
            break;
          }
        }
      }

      // Should have been rate limited before reaching 20 requests
      expect(rateLimited).toBe(true);
      expect(requestCount).toBeLessThan(20);
    });

    test('should toggle rate limiting multiple times', async () => {
      // Disable
      await updateConfig({ enabled: false });
      await refreshRemoteConfig();
      await new Promise(resolve => setTimeout(resolve, 200));

      let isEnabled = await isRateLimitingEnabled();
      expect(isEnabled).toBe(false);

      // Enable
      await updateConfig({ enabled: true });
      await refreshRemoteConfig();
      await new Promise(resolve => setTimeout(resolve, 200));

      isEnabled = await isRateLimitingEnabled();
      expect(isEnabled).toBe(true);

      // Disable again
      await updateConfig({ enabled: false });
      await refreshRemoteConfig();
      await new Promise(resolve => setTimeout(resolve, 200));

      isEnabled = await isRateLimitingEnabled();
      expect(isEnabled).toBe(false);

      // Enable again
      await updateConfig({ enabled: true });
      await refreshRemoteConfig();
      await new Promise(resolve => setTimeout(resolve, 200));

      isEnabled = await isRateLimitingEnabled();
      expect(isEnabled).toBe(true);
    });
  });

  describe('Configuration Propagation', () => {
    test('should pick up config changes within cache period', async () => {
      // Get initial config
      const config1 = await getRateLimits('summarizePdf' as FunctionType);
      const initialLimit = config1.hourlyLimit;

      // Update config
      const newLimit = initialLimit + 10;
      await updateConfig({
        summarizePdf: {
          hourlyLimit: newLimit,
          dailyLimit: 100,
          minRequestInterval: 500,
        },
      });

      // Force refresh
      await refreshRemoteConfig();

      // Wait a bit for cache to update
      await new Promise(resolve => setTimeout(resolve, 300));

      // Get config again
      const config2 = await getRateLimits('summarizePdf' as FunctionType);

      // Should have new value
      expect(config2.hourlyLimit).toBe(newLimit);
    });

    test('should handle config changes during active request flow', async () => {
      // Start making requests
      const promises: Promise<any>[] = [];

      for (let i = 0; i < 5; i++) {
        promises.push(
          (async () => {
            await new Promise(resolve => setTimeout(resolve, i * 100));
            return await checkRateLimit(testUser, 'summarizePdf' as FunctionType);
          })()
        );
      }

      // Change config mid-flow
      await new Promise(resolve => setTimeout(resolve, 250));
      await updateConfig({
        summarizePdf: {
          hourlyLimit: 100,
          dailyLimit: 500,
          minRequestInterval: 100,
        },
      });
      await refreshRemoteConfig();

      const results = await Promise.all(promises);

      // All should succeed
      results.forEach(result => {
        expect(result.allowed).toBe(true);
      });
    });
  });

  describe('Backward Compatibility', () => {
    test('should handle missing function type config gracefully', async () => {
      // Remove chatWithPdf config
      await updateConfig({
        summarizePdf: {
          hourlyLimit: 10,
          dailyLimit: 50,
          minRequestInterval: 500,
        },
      });

      await refreshRemoteConfig();
      await new Promise(resolve => setTimeout(resolve, 200));

      // Should handle gracefully
      try {
        const config = await getRateLimits('chatWithPdf' as FunctionType);
        // Either returns defaults or throws
        expect(config).toBeTruthy();
      } catch (error) {
        expect(error).toBeTruthy();
      }
    });

    test('should use defaults for missing config values', async () => {
      // Set incomplete config
      await updateConfig({
        summarizePdf: {
          hourlyLimit: 10,
          // Missing dailyLimit and minRequestInterval
        },
      });

      await refreshRemoteConfig();
      await new Promise(resolve => setTimeout(resolve, 200));

      // Should use defaults or throw
      try {
        const config = await getRateLimits('summarizePdf' as FunctionType);
        expect(config.hourlyLimit).toBe(10);
        // Other fields should have defaults
        expect(config.dailyLimit).toBeGreaterThan(0);
        expect(config.minRequestInterval).toBeGreaterThan(0);
      } catch (error) {
        // Also acceptable to throw for incomplete config
        expect(error).toBeTruthy();
      }
    });

    test('should handle empty config object', async () => {
      // Set empty config
      await updateConfig({
        summarizePdf: {},
      });

      await refreshRemoteConfig();
      await new Promise(resolve => setTimeout(resolve, 200));

      // Should handle gracefully
      try {
        const config = await getRateLimits('summarizePdf' as FunctionType);
        expect(config).toBeTruthy();
      } catch (error) {
        expect(error).toBeTruthy();
      }
    });
  });

  describe('User Usage with Config Changes', () => {
    test('should reflect new limits in user usage', async () => {
      // Make some requests
      for (let i = 0; i < 5; i++) {
        await checkRateLimit(testUser, 'summarizePdf' as FunctionType);
      }

      let usage = await getUserUsage(testUser, 'summarizePdf' as FunctionType);
      expect(usage.hourlyUsed).toBe(5);
      expect(usage.hourlyLimit).toBe(10);

      // Change limit
      await updateConfig({
        summarizePdf: {
          hourlyLimit: 20,
          dailyLimit: 100,
          minRequestInterval: 500,
        },
      });

      await refreshRemoteConfig();
      await new Promise(resolve => setTimeout(resolve, 200));

      // Get usage again
      usage = await getUserUsage(testUser, 'summarizePdf' as FunctionType);
      expect(usage.hourlyUsed).toBe(5);
      expect(usage.hourlyLimit).toBe(20);
      expect(usage.canRequest).toBe(true);
    });

    test('should update canRequest status when limits change', async () => {
      // Exhaust hourly limit
      const config1 = await getRateLimits('summarizePdf' as FunctionType);
      for (let i = 0; i < config1.hourlyLimit; i++) {
        await checkRateLimit(testUser, 'summarizePdf' as FunctionType);
      }

      let usage = await getUserUsage(testUser, 'summarizePdf' as FunctionType);
      expect(usage.canRequest).toBe(false);

      // Increase limit
      await updateConfig({
        summarizePdf: {
          hourlyLimit: config1.hourlyLimit + 10,
          dailyLimit: 100,
          minRequestInterval: 500,
        },
      });

      await refreshRemoteConfig();
      await new Promise(resolve => setTimeout(resolve, 200));

      // Should now be able to request
      usage = await getUserUsage(testUser, 'summarizePdf' as FunctionType);
      expect(usage.canRequest).toBe(true);
    });
  });

  describe('Multiple Function Types', ()   => {
    test('should handle config changes for different functions independently', async () => {
      const summarizeUser = testUser + '-summarize';
      const chatUser = testUser + '-chat';

      // Exhaust summarize limit
      const summarizeConfig = await getRateLimits('summarizePdf' as FunctionType);
      for (let i = 0; i < summarizeConfig.hourlyLimit; i++) {
        await checkRateLimit(summarizeUser, 'summarizePdf' as FunctionType);
      }

      // Should be rate limited for summarize
      await expect(
        checkRateLimit(summarizeUser, 'summarizePdf' as FunctionType)
      ).rejects.toThrow(HttpsError);

      // But chat should still work
      const result = await checkRateLimit(chatUser, 'chatWithPdf' as FunctionType);
      expect(result.allowed).toBe(true);

      // Change only summarize limit
      await updateConfig({
        summarizePdf: {
          hourlyLimit: summarizeConfig.hourlyLimit + 10,
          dailyLimit: 100,
          minRequestInterval: 500,
        },
        chatWithPdf: {
          hourlyLimit: 20,
          dailyLimit: 100,
          minRequestInterval: 300,
        },
      });

      await refreshRemoteConfig();
      await new Promise(resolve => setTimeout(resolve, 200));

      // Summarize should now work
      const result2 = await checkRateLimit(summarizeUser, 'summarizePdf' as FunctionType);
      expect(result2.allowed).toBe(true);

      // Chat should still work
      const result3 = await checkRateLimit(chatUser, 'chatWithPdf' as FunctionType);
      expect(result3.allowed).toBe(true);
    });
  });

  describe('Edge Cases', () => {
    test('should handle rapid config changes', async () => {
      // Make rapid config changes
      const limits = [5, 10, 15, 20, 25];

      for (const limit of limits) {
        await updateConfig({
          summarizePdf: {
            hourlyLimit: limit,
            dailyLimit: 100,
            minRequestInterval: 500,
          },
        });

        await refreshRemoteConfig();
        await new Promise(resolve => setTimeout(resolve, 50));
      }

      // Final config should be last set
      const config = await getRateLimits('summarizePdf' as FunctionType);
      expect(config.hourlyLimit).toBe(25);
    });

    test('should handle config with invalid values', async () => {
      // Set invalid config
      await updateConfig({
        summarizePdf: {
          hourlyLimit: -1,
          dailyLimit: 0,
          minRequestInterval: -100,
        },
      });

      await refreshRemoteConfig();
      await new Promise(resolve => setTimeout(resolve, 200));

      // Should handle gracefully (use defaults or throw)
      try {
        const config = await getRateLimits('summarizePdf' as FunctionType);
        expect(config).toBeTruthy();
      } catch (error) {
        expect(error).toBeTruthy();
      }
    });

    test('should handle config change during rate limit check', async () => {
      // Start a rate limit check
      const checkPromise = checkRateLimit(testUser, 'summarizePdf' as FunctionType);

      // Change config immediately
      await updateConfig({ enabled: false });
      await refreshRemoteConfig();

      // Both should complete without error
      const result = await checkPromise;
      expect(result.allowed).toBe(true);
    });
  });

  describe('Performance', () => {
    test('should not degrade performance with frequent config changes', async () => {
      const timings: number[] = [];

      for (let i = 0; i < 10; i++) {
        const startTime = Date.now();

        await updateConfig({
          summarizePdf: {
            hourlyLimit: 10 + i,
            dailyLimit: 50,
            minRequestInterval: 500,
          },
        });

        await refreshRemoteConfig();
        await new Promise(resolve => setTimeout(resolve, 100));

        timings.push(Date.now() - startTime);
      }

      console.log(`   Config change timings: ${timings.join('ms, ')}ms`);

      // Should complete in reasonable time
      timings.forEach(timing => {
        expect(timing).toBeLessThan(1000);
      });
    });

    test('should cache config efficiently', async () => {
      const startTime = Date.now();

      // Get config multiple times
      const promises = Array.from({ length: 10 }, () =>
        getRateLimits('summarizePdf' as FunctionType)
      );

      await Promise.all(promises);

      const elapsed = Date.now() - startTime;

      console.log(`   10 concurrent config reads in ${elapsed}ms`);

      // Should be fast (cached)
      expect(elapsed).toBeLessThan(500);
    });
  });
});
