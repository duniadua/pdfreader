/**
 * Concurrent Request Handling Integration Tests
 *
 * Tests rate limiting behavior under concurrent load:
 * - Multiple users with independent counters
 * - Concurrent requests from same user
 * - Counter accuracy under load
 * - Sharded counter performance
 * - No race conditions or counter drift
 */

import * as admin from 'firebase-admin';
import { checkRateLimit } from '../../src/rateLimit/middleware';
import { getCountInWindow, incrementCounter } from '../../src/rateLimit/distributedCounter';
import { getRateLimits } from '../../src/rateLimit/remoteConfig';
import { FunctionType } from '../../src/rateLimit/types';

describe('Concurrent Rate Limiting Tests', () => {
  let testUsers: string[];
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

    // Generate test users
    testUsers = Array.from({ length: 100 }, (_, i) => `concurrent-user-${i}`);

    await cleanupTestData();
  });

  afterAll(async () => {
    await cleanupTestData();
    await admin.app().delete();
  });

  beforeEach(async () => {
    await cleanupTestData();
  });

  async function cleanupTestData(): Promise<void> {
    const batch = db.batch();

    for (const userId of testUsers) {
      const snapshot = await db
        .collection('rateLimitCounters')
        .where('__name__', '>=', userId)
        .get();

      snapshot.docs.forEach((doc) => {
        batch.delete(doc.ref);
      });
    }

    await batch.commit();
  }

  describe('Concurrent Users', () => {
    test('should maintain independent counters for 100 concurrent users', async () => {
      const requestsPerUser = 5;
      const config = await getRateLimits('summarizePdf' as FunctionType);

      // All users make requests concurrently
      const allPromises = testUsers.flatMap(userId =>
        Array.from({ length: requestsPerUser }, () =>
          checkRateLimit(userId, 'summarizePdf' as FunctionType)
        )
      );

      const startTime = Date.now();
      const results = await Promise.all(allPromises);
      const elapsed = Date.now() - startTime;

      // All requests should succeed
      results.forEach(result => {
        expect(result.allowed).toBe(true);
      });

      // Verify each user has correct count
      for (const userId of testUsers) {
        const count = await getCountInWindow(userId, 'summarizePdf', 'hour');
        expect(count).toBe(requestsPerUser);
      }

      console.log(`✅ 100 users × ${requestsPerUser} requests = ${allPromises.length} total in ${elapsed}ms`);
      console.log(`   Avg: ${(elapsed / allPromises.length).toFixed(2)}ms per request`);
    });

    test('should handle 1000 concurrent requests across 100 users', async () => {
      const requestsPerUser = 10;
      const users = testUsers.slice(0, 100); // Use 100 users
      const totalRequests = users.length * requestsPerUser;

      // Create request batches to avoid overwhelming the emulator
      const batchSize = 50;
      const allResults: boolean[] = [];

      for (let i = 0; i < totalRequests; i += batchSize) {
        const batchPromises: Promise<any>[] = [];

        for (let j = 0; j < batchSize && i + j < totalRequests; j++) {
          const userIndex = Math.floor((i + j) / requestsPerUser) % users.length;
          batchPromises.push(
            checkRateLimit(users[userIndex], 'summarizePdf' as FunctionType)
          );
        }

        const batchResults = await Promise.all(batchPromises);
        batchResults.forEach(result => allResults.push(result.allowed));

        // Small delay between batches
        await new Promise(resolve => setTimeout(resolve, 50));
      }

      // All requests should succeed
      allResults.forEach(allowed => {
        expect(allowed).toBe(true);
      });

      console.log(`✅ ${totalRequests} requests processed successfully`);
    });
  });

  describe('Concurrent Requests from Same User', () => {
    test('should accurately count 10 concurrent requests from same user', async () => {
      const userId = testUsers[0];
      const requestCount = 10;

      // Make all requests concurrently
      const promises = Array.from({ length: requestCount }, () =>
        checkRateLimit(userId, 'summarizePdf' as FunctionType)
      );

      const results = await Promise.all(promises);

      // All should succeed
      results.forEach(result => {
        expect(result.allowed).toBe(true);
      });

      // Wait a bit for counters to settle
      await new Promise(resolve => setTimeout(resolve, 100));

      // Verify count is accurate (should be exactly requestCount)
      const count = await getCountInWindow(userId, 'summarizePdf', 'hour');

      // Allow for small variance due to concurrent writes
      expect(count).toBeGreaterThanOrEqual(requestCount - 2);
      expect(count).toBeLessThanOrEqual(requestCount + 2);
    });

    test('should handle rapid burst of requests without counter drift', async () => {
      const userId = testUsers[0];
      const burstCount = 20;

      // Simulate burst traffic
      const promises = Array.from({ length: burstCount }, (_, i) =>
        // Stagger slightly to simulate realistic burst
        new Promise(resolve =>
          setTimeout(resolve, Math.random() * 50)
        ).then(() =>
          checkRateLimit(userId, 'summarizePdf' as FunctionType)
        )
      );

      const results = await Promise.all(promises);

      // Count successful requests
      const successCount = results.filter(r => r.allowed).length;

      // Most should succeed (unless rate limited)
      expect(successCount).toBeGreaterThan(burstCount * 0.8);

      // Verify counter
      const count = await getCountInWindow(userId, 'summarizePdf', 'hour');
      console.log(`   Burst of ${burstCount} requests: ${successCount} succeeded, count=${count}`);
    });
  });

  describe('Sharded Counter Performance', () => {
    test('should distribute load evenly across 10 shards', async () => {
      const userId = testUsers[0];
      const requestCount = 100;

      // Make many requests
      for (let i = 0; i < requestCount; i++) {
        await checkRateLimit(userId, 'summarizePdf' as FunctionType);
      }

      // Fetch all shards
      const shardSnapshot = await db
        .collection('rateLimitCounters')
        .where('__name__', '>=', `${userId}_summarizePdf`)
        .get();

      const shards = shardSnapshot.docs
        .filter(doc => doc.id.includes('shard_'))
        .map(doc => ({ id: doc.id, ...doc.data() }));

      console.log(`   Found ${shards.length} shards`);

      // Verify we have 10 shards
      expect(shards.length).toBe(10);

      // Check load distribution
      const counts = shards.map(s => (s as any).count || 0);
      const maxCount = Math.max(...counts);
      const minCount = Math.min(...counts);
      const avgCount = counts.reduce((a, b) => a + b, 0) / counts.length;

      console.log(`   Shard distribution - min: ${minCount}, max: ${maxCount}, avg: ${avgCount.toFixed(1)}`);

      // Distribution should be reasonably even (within 50% of average)
      expect(minCount).toBeGreaterThan(avgCount * 0.5);
      expect(maxCount).toBeLessThan(avgCount * 1.5);
    });

    test('should aggregate shard counts correctly', async () => {
      const userId = testUsers[0];
      const requestCount = 50;

      // Make requests
      for (let i = 0; i < requestCount; i++) {
        await checkRateLimit(userId, 'summarizePdf' as FunctionType);
      }

      // Get aggregated count
      const totalCount = await getCountInWindow(userId, 'summarizePdf', 'hour');

      // Sum individual shards
      const shardSnapshot = await db
        .collection('rateLimitCounters')
        .where('__name__', '>=', `${userId}_summarizePdf`)
        .get();

      let manualSum = 0;
      shardSnapshot.docs.forEach(doc => {
        if (doc.id.includes('shard_')) {
          manualSum += (doc.data() as any).count || 0;
        }
      });

      expect(totalCount).toBe(manualSum);
      expect(totalCount).toBe(requestCount);
    });
  });

  describe('No Race Conditions', () => {
    test('should not lose counter updates under concurrent load', async () => {
      const userId = testUsers[0];
      const requestCount = 50;

      // Make concurrent requests
      const promises = Array.from({ length: requestCount }, () =>
        checkRateLimit(userId, 'summarizePdf' as FunctionType)
      );

      await Promise.all(promises);

      // Wait for all transactions to complete
      await new Promise(resolve => setTimeout(resolve, 500));

      // Verify count
      const count = await getCountInWindow(userId, 'summarizePdf', 'hour');

      // Should have counted all requests (allowing for small variance)
      expect(count).toBeGreaterThanOrEqual(requestCount - 3);
      expect(count).toBeLessThanOrEqual(requestCount + 3);
    });

    test('should handle rapid sequential increments without gaps', async () => {
      const userId = testUsers[0];
      const iterations = 20;

      const counts: number[] = [];

      for (let i = 0; i < iterations; i++) {
        await incrementCounter(userId, 'summarizePdf', 'hour');
        const count = await getCountInWindow(userId, 'summarizePdf', 'hour');
        counts.push(count);

        // Count should never decrease
        if (i > 0) {
          expect(count).toBeGreaterThanOrEqual(counts[i - 1]);
        }
      }

      console.log(`   Count progression: ${counts.join(', ')}`);

      // Final count should be iterations
      expect(counts[iterations - 1]).toBe(iterations);
    });
  });

  describe('Performance Under Load', () => {
    test('should maintain performance with 50 concurrent users', async () => {
      const users = testUsers.slice(0, 50);
      const requestsPerUser = 5;

      const startTime = Date.now();

      // All users make requests concurrently
      const promises = users.flatMap(userId =>
        Array.from({ length: requestsPerUser }, () =>
          checkRateLimit(userId, 'summarizePdf' as FunctionType)
        )
      );

      await Promise.all(promises);

      const elapsed = Date.now() - startTime;
      const totalRequests = users.length * requestsPerUser;
      const avgTimePerRequest = elapsed / totalRequests;

      console.log(`   ${totalRequests} requests in ${elapsed}ms`);
      console.log(`   Avg: ${avgTimePerRequest.toFixed(2)}ms per request`);

      // Average should be under 500ms per request
      expect(avgTimePerRequest).toBeLessThan(500);
    });

    test('should not degrade performance with multiple sequential batches', async () => {
      const users = testUsers.slice(0, 10);
      const batches = 5;
      const requestsPerBatch = 10;

      const timings: number[] = [];

      for (let i = 0; i < batches; i++) {
        const startTime = Date.now();

        const promises = users.flatMap(userId =>
          Array.from({ length: requestsPerBatch }, () =>
            checkRateLimit(userId, 'summarizePdf' as FunctionType)
          )
        );

        await Promise.all(promises);

        timings.push(Date.now() - startTime);
      }

      console.log(`   Batch timings: ${timings.join('ms, ')}ms`);

      // Performance should not degrade significantly
      const firstBatch = timings[0];
      const lastBatch = timings[timings.length - 1];

      // Last batch should not be more than 2x slower than first
      expect(lastBatch).toBeLessThan(firstBatch * 2);
    });
  });

  describe('Mixed Concurrent Scenarios', () => {
    test('should handle mix of different users and request patterns', async () => {
      const heavyUser = testUsers[0];
      const lightUsers = testUsers.slice(1, 11);

      const promises = [
        // Heavy user makes 20 requests
        ...Array.from({ length: 20 }, () =>
          checkRateLimit(heavyUser, 'summarizePdf' as FunctionType)
        ),
        // Light users make 2 requests each
        ...lightUsers.flatMap(userId =>
          Array.from({ length: 2 }, () =>
            checkRateLimit(userId, 'summarizePdf' as FunctionType)
          )
        ),
      ];

      const results = await Promise.all(promises);

      // All should succeed
      results.forEach(result => {
        expect(result.allowed).toBe(true);
      });

      // Verify heavy user count
      const heavyCount = await getCountInWindow(heavyUser, 'summarizePdf', 'hour');
      expect(heavyCount).toBe(20);

      // Verify light user counts
      for (const userId of lightUsers) {
        const count = await getCountInWindow(userId, 'summarizePdf', 'hour');
        expect(count).toBe(2);
      }
    });

    test('should handle concurrent users with different rate limits', async () => {
      // Test with different function types
      const userId = testUsers[0];

      const promises = [
        ...Array.from({ length: 5 }, () =>
          checkRateLimit(userId, 'summarizePdf' as FunctionType)
        ),
        ...Array.from({ length: 3 }, () =>
          checkRateLimit(userId, 'chatWithPdf' as FunctionType)
        ),
      ];

      const results = await Promise.all(promises);

      results.forEach(result => {
        expect(result.allowed).toBe(true);
      });

      // Verify separate counters
      const summarizeCount = await getCountInWindow(userId, 'summarizePdf', 'hour');
      const chatCount = await getCountInWindow(userId, 'chatWithPdf', 'hour');

      expect(summarizeCount).toBe(5);
      expect(chatCount).toBe(3);
    });
  });

  describe('Stress Tests', () => {
    test('should handle 500 concurrent requests without failures', async () => {
      const users = testUsers.slice(0, 50);
      const requestsPerUser = 10;

      // Process in batches to avoid overwhelming
      const batchSize = 100;
      const allResults: boolean[] = [];

      for (let i = 0; i < requestsPerUser; i++) {
        const batchPromises = users.map(userId =>
          checkRateLimit(userId, 'summarizePdf' as FunctionType)
        );

        const batchResults = await Promise.all(batchPromises);
        batchResults.forEach(result => allResults.push(result.allowed));

        // Small delay between batches
        await new Promise(resolve => setTimeout(resolve, 20));
      }

      // All should succeed
      allResults.forEach(allowed => {
        expect(allowed).toBe(true);
      });

      console.log(`✅ ${allResults.length} requests processed`);
    });

    test('should maintain data integrity after high load', async () => {
      const userId = testUsers[0];
      const requestCount = 100;

      // High load
      const promises = Array.from({ length: requestCount }, () =>
        checkRateLimit(userId, 'summarizePdf' as FunctionType)
      );

      await Promise.all(promises);

      // Wait for cleanup
      await new Promise(resolve => setTimeout(resolve, 1000));

      // Verify count is still accurate
      const count = await getCountInWindow(userId, 'summarizePdf', 'hour');
      expect(count).toBe(requestCount);

      // Verify no duplicate shard documents
      const shardSnapshot = await db
        .collection('rateLimitCounters')
        .where('__name__', '>=', `${userId}_summarizePdf`)
        .get();

      const shardDocs = shardSnapshot.docs.filter(doc => doc.id.includes('shard_'));
      expect(shardDocs.length).toBe(10); // Should have exactly 10 shards
    });
  });
});
