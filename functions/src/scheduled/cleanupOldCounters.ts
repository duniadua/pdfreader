/**
 * Scheduled function to clean up old rate limit counter documents.
 *
 * Runs daily to delete Firestore counter documents older than 25 hours.
 * Uses collectionGroup to query across all users' rate_limits collections.
 *
 * Schedule: Daily at 2 AM Singapore time (Asia/Singapore timezone)
 * Region: asia-southeast1
 * Memory: 256MiB
 */

import * as functions from "firebase-functions/v2";
import * as admin from "firebase-admin";
import { logger } from "firebase-functions";

/**
 * Cleanup old rate limit counter documents.
 *
 * Deletes all documents in the rate_limits collectionGroup where
 * the timestamp is older than 25 hours. This prevents unbounded
 * growth of counter documents while ensuring the sliding window
 * rate limiting has sufficient data (24h window + 1h buffer).
 *
 * Process:
 * 1. Query rate_limits collectionGroup for documents with timestamp < 25 hours ago
 * 2. Delete documents in batches of up to 500
 * 3. Log total number of documents deleted
 *
 * @returns Promise that resolves when cleanup is complete
 */
export const cleanupOldCounters = functions.scheduler.onSchedule(
  {
    schedule: "0 2 * * *", // Daily at 2 AM
    timeZone: "Asia/Singapore",
    region: "asia-southeast1",
    memory: "256MiB",
  },
  async () => {
    const startTime = Date.now();
    logger.info("Starting cleanup of old rate limit counters");

    try {
      const db = admin.firestore();
      const cutoffTime = Date.now() - 25 * 60 * 60 * 1000; // 25 hours ago

      // Query all rate_limits documents across all users
      const snapshot = await db
        .collectionGroup("rate_limits")
        .where("timestamp", "<", cutoffTime)
        .get();

      const totalDocs = snapshot.size;
      logger.info(
        `Found ${totalDocs} rate limit documents older than 25 hours`
      );

      if (totalDocs === 0) {
        logger.info("No documents to delete");
        return;
      }

      // Delete in batches of up to 500
      const batchSize = 500;
      const batches: Promise<unknown>[] = [];

      for (let i = 0; i < totalDocs; i += batchSize) {
        const batch = db.batch();
        const end = Math.min(i + batchSize, totalDocs);

        for (let j = i; j < end; j++) {
          const doc = snapshot.docs[j];
          batch.delete(doc.ref);
        }

        batches.push(batch.commit());
      }

      await Promise.all(batches);

      const elapsed = Date.now() - startTime;
      logger.info(
        `Successfully deleted ${totalDocs} old rate limit documents in ${elapsed}ms`
      );
    } catch (error) {
      const elapsed = Date.now() - startTime;
      logger.error(
        `Error cleaning up old counters after ${elapsed}ms:`,
        error
      );
      throw error; // Re-throw to trigger retry on failure
    }
  }
);
