/**
 * Distributed counter using Firestore sharded counter pattern
 * Prevents counter contention by distributing counts across 10 shards
 */

import * as admin from 'firebase-admin';
import { CounterShard } from './types';

const SHARD_COUNT = 10;
const COLLECTION_NAME = 'rateLimitCounters';

/**
 * Get the shard document ID for a specific user and shard number
 */
function getShardId(userId: string, functionType: string, shardIndex: number): string {
  return `${userId}_${functionType}_shard_${shardIndex}`;
}

/**
 * Get all shard IDs for a user and function
 */
function getShardIds(userId: string, functionType: string): string[] {
  return Array.from({ length: SHARD_COUNT }, (_, i) =>
    getShardId(userId, functionType, i)
  );
}

/**
 * Increment the counter for a specific user and time window
 * Uses Firestore transaction for atomic increment
 *
 * @param userId - User's Firebase UID
 * @param functionType - Type of function being called
 * @param window - Time window ('hour' | 'day')
 * @returns The new count after increment
 */
export async function incrementCounter(
  userId: string,
  functionType: string,
  window: 'hour' | 'day'
): Promise<number> {
  const db = admin.firestore();
  const now = Date.now();

  // Calculate window start time
  const windowStart = window === 'hour'
    ? now - (now % (60 * 60 * 1000)) // Start of current hour
    : now - (now % (24 * 60 * 60 * 1000)); // Start of current day

  // Select a random shard to distribute writes
  const shardIndex = Math.floor(Math.random() * SHARD_COUNT);
  const shardId = getShardId(userId, functionType, shardIndex);
  const shardRef = db.collection(COLLECTION_NAME).doc(shardId);

  try {
    await db.runTransaction(async (transaction) => {
      const shardDoc = await transaction.get(shardRef);

      if (!shardDoc.exists) {
        // Create new shard
        const newShard: CounterShard = {
          count: 1,
          lastUpdated: now,
        };
        transaction.set(shardRef, newShard);
      } else {
        // Increment existing shard
        const data = shardDoc.data() as CounterShard;

        // Reset count if we're in a new time window
        if (data.lastUpdated < windowStart) {
          transaction.update(shardRef, {
            count: 1,
            lastUpdated: now,
          });
        } else {
          transaction.update(shardRef, {
            count: admin.firestore.FieldValue.increment(1),
            lastUpdated: now,
          });
        }
      }
    });

    // Get total count across all shards
    const totalCount = await getCountInWindow(userId, functionType, window);
    return totalCount;
  } catch (error: any) {
    console.error('❌ Error incrementing counter:', error?.message || error);
    throw error;
  }
}

/**
 * Get the total count across all shards for a specific time window
 *
 * @param userId - User's Firebase UID
 * @param functionType - Type of function
 * @param window - Time window ('hour' | 'day')
 * @returns Total count in the specified window
 */
export async function getCountInWindow(
  userId: string,
  functionType: string,
  window: 'hour' | 'day'
): Promise<number> {
  const db = admin.firestore();
  const now = Date.now();

  // Calculate window start time
  const windowStart = window === 'hour'
    ? now - (now % (60 * 60 * 1000))
    : now - (now % (24 * 60 * 60 * 1000));

  try {
    const shardIds = getShardIds(userId, functionType);
    const shardRefs = shardIds.map((id) => db.collection(COLLECTION_NAME).doc(id));

    // Fetch all shards in parallel
    const snapshots = await Promise.all(shardRefs.map((ref) => ref.get()));

    let totalCount = 0;
    let staleShards: string[] = [];

    for (let i = 0; i < snapshots.length; i++) {
      const snapshot = snapshots[i];
      if (snapshot.exists) {
        const data = snapshot.data() as CounterShard;

        // Only count if updated within current window
        if (data.lastUpdated >= windowStart) {
          totalCount += data.count;
        } else {
          // Mark stale shards for cleanup
          staleShards.push(shardIds[i]);
        }
      }
    }

    // Clean up stale shards in background (don't await)
    if (staleShards.length > 0) {
      cleanupStaleShards(staleShards).catch((error) => {
        console.error('❌ Error cleaning up stale shards:', error);
      });
    }

    return totalCount;
  } catch (error: any) {
    console.error('❌ Error getting count:', error?.message || error);
    return 0;
  }
}

/**
 * Get the timestamp of the last request for a user
 * Used to enforce minimum request interval
 *
 * @param userId - User's Firebase UID
 * @param functionType - Type of function
 * @returns Timestamp of last request, or 0 if no previous request
 */
export async function getLastRequestTime(
  userId: string,
  functionType: string
): Promise<number> {
  const db = admin.firestore();
  const lastRequestRef = db
    .collection(COLLECTION_NAME)
    .doc(`${userId}_${functionType}_lastRequest`);

  try {
    const doc = await lastRequestRef.get();
    if (doc.exists) {
      const data = doc.data() as { timestamp: number };
      return data.timestamp || 0;
    }
    return 0;
  } catch (error: any) {
    console.error('❌ Error getting last request time:', error?.message || error);
    return 0;
  }
}

/**
 * Update the last request timestamp for a user
 *
 * @param userId - User's Firebase UID
 * @param functionType - Type of function
 */
export async function updateLastRequestTime(
  userId: string,
  functionType: string
): Promise<void> {
  const db = admin.firestore();
  const lastRequestRef = db
    .collection(COLLECTION_NAME)
    .doc(`${userId}_${functionType}_lastRequest`);

  try {
    await lastRequestRef.set({
      timestamp: Date.now(),
    });
  } catch (error: any) {
    console.error('❌ Error updating last request time:', error?.message || error);
    // Don't throw - this is not critical
  }
}

/**
 * Clean up stale shard documents
 * Runs in background to keep counters clean
 *
 * @param shardIds - Array of shard document IDs to delete
 */
async function cleanupStaleShards(shardIds: string[]): Promise<void> {
  if (shardIds.length === 0) return;

  const db = admin.firestore();
  const batch = db.batch();

  for (const shardId of shardIds) {
    const ref = db.collection(COLLECTION_NAME).doc(shardId);
    batch.delete(ref);
  }

  try {
    await batch.commit();
    console.log(`🗑️ Cleaned up ${shardIds.length} stale shards`);
  } catch (error: any) {
    console.error('❌ Error in batch delete:', error?.message || error);
    // Don't throw - cleanup is not critical
  }
}

/**
 * Reset all counters for a specific user (admin function)
 *
 * @param userId - User's Firebase UID
 */
export async function resetUserCounters(userId: string): Promise<void> {
  const db = admin.firestore();

  try {
    // Get all documents for this user
    const snapshot = await db
      .collection(COLLECTION_NAME)
      .where('__name__', '>=', userId)
      .where('__name__', '<', `${userId}`)
      .get();

    if (snapshot.empty) {
      console.log(`ℹ️ No counters found for user ${userId}`);
      return;
    }

    // Delete in batches (max 500 operations per batch)
    const batchSize = 500;
    for (let i = 0; i < snapshot.docs.length; i += batchSize) {
      const batch = db.batch();
      const chunk = snapshot.docs.slice(i, i + batchSize);

      for (const doc of chunk) {
        batch.delete(doc.ref);
      }

      await batch.commit();
      console.log(`🗑️ Deleted ${chunk.length} counters for user ${userId}`);
    }
  } catch (error: any) {
    console.error('❌ Error resetting user counters:', error?.message || error);
    throw error;
  }
}
