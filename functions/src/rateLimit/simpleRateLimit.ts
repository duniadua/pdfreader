/**
 * Simple Rate Limiter for Firebase Functions
 *
 * This implementation uses in-memory counting with configurable limits.
 * It's designed to work without database dependencies.
 *
 * Limitations:
 * - Counts are per-instance (not distributed)
 * - Resets when function instance restarts
 * - Suitable for basic rate limiting, not high-traffic scenarios
 *
 * For production distributed rate limiting, integrate with:
 * - Redis (Cloud Memorystore)
 * - Firestore Native Mode
 * - Realtime Database
 */

interface RateLimitConfig {
  hourlyLimit: number;
  dailyLimit: number;
  minIntervalMs: number;
}

interface UserRequestRecord {
  count: number;
  lastRequestTime: number;
  windowStart: number;
}

// In-memory store for rate limiting (per function instance)
const rateLimitStore = new Map<string, UserRequestRecord>();

/**
 * Fetches rate limit configuration
 *
 * Returns hardcoded defaults for each function.
 * For production, consider moving to environment variables or Remote Config.
 */
function getRateLimitConfig(functionName: string): RateLimitConfig {
  // Default configurations per function
  const defaults: Record<string, RateLimitConfig> = {
    chatFlow: {
      hourlyLimit: 30,
      dailyLimit: 200,
      minIntervalMs: 2000,
    },
    summarizeFlow: {
      hourlyLimit: 10,
      dailyLimit: 50,
      minIntervalMs: 5000,
    },
    extractFlow: {
      hourlyLimit: 15,
      dailyLimit: 75,
      minIntervalMs: 3000,
    },
    healthCheck: {
      hourlyLimit: 1000,
      dailyLimit: 10000,
      minIntervalMs: 100,
    },
  };

  const config = defaults[functionName] || defaults.chatFlow;
  console.log(`📊 Rate limits for ${functionName}: hourly=${config.hourlyLimit}, daily=${config.dailyLimit}, interval=${config.minIntervalMs}ms`);
  return config;
}

/**
 * Cleans up old records from the in-memory store
 * Should be called periodically to prevent memory leaks
 */
function cleanupOldRecords(): void {
  const now = Date.now();
  const maxAge = 24 * 60 * 60 * 1000; // 24 hours

  for (const [key, record] of rateLimitStore.entries()) {
    if (now - record.windowStart > maxAge) {
      rateLimitStore.delete(key);
    }
  }
}

/**
 * Checks if a request should be rate limited
 *
 * @param userId - The user's Firebase Auth UID
 * @param functionName - The name of the function being called
 * @returns Object with 'allowed' boolean and optional 'retryAfter' number (seconds)
 */
export async function checkRateLimit(
  userId: string,
  functionName: string
): Promise<{ allowed: boolean; retryAfter?: number }> {
  const now = Date.now();
  const key = `${userId}_${functionName}`;

  console.log(`🔍 Checking rate limits for user ${userId} on ${functionName}`);

  // Periodic cleanup
  if (Math.random() < 0.01) { // 1% chance per call
    cleanupOldRecords();
  }

  // Get rate limit configuration
  const config = getRateLimitConfig(functionName);

  // Get or create user record
  let record = rateLimitStore.get(key);

  if (!record) {
    // First request
    record = {
      count: 1,
      lastRequestTime: now,
      windowStart: now,
    };
    rateLimitStore.set(key, record);
    console.log(`✅ First request for ${userId} on ${functionName}, allowing`);
    return { allowed: true };
  }

  // Check minimum interval
  const timeSinceLastRequest = now - record.lastRequestTime;
  if (timeSinceLastRequest < config.minIntervalMs) {
    const retryAfter = Math.ceil((config.minIntervalMs - timeSinceLastRequest) / 1000);
    console.log(`⏱️ Request interval check failed: ${timeSinceLastRequest}ms < ${config.minIntervalMs}ms`);
    console.log(`⏱️ Rate limit exceeded, retry after ${retryAfter}s`);
    return { allowed: false, retryAfter };
  }

  // Check if we need to reset the window (hourly)
  const hourInMs = 60 * 60 * 1000;
  if (now - record.windowStart > hourInMs) {
    record.count = 0;
    record.windowStart = now;
    console.log(`🔄 Resetting hourly window for ${userId} on ${functionName}`);
  }

  // Check hourly limit
  if (record.count >= config.hourlyLimit) {
    const retryAfter = Math.ceil(((record.windowStart + hourInMs) - now) / 1000);
    console.log(`⏱️ Hourly limit exceeded: ${record.count} >= ${config.hourlyLimit}`);
    console.log(`⏱️ Rate limit exceeded, retry after ${retryAfter}s`);
    return { allowed: false, retryAfter };
  }

  // Update record
  record.count++;
  record.lastRequestTime = now;
  rateLimitStore.set(key, record);

  console.log(`✅ Rate limit check passed for ${userId} on ${functionName}`);
  console.log(`📊 Request count: ${record.count}/${config.hourlyLimit} (hourly)`);

  return { allowed: true };
}

/**
 * Manually resets rate limit for a user (for testing or admin actions)
 */
export function resetRateLimit(userId: string, functionName: string): void {
  const key = `${userId}_${functionName}`;
  rateLimitStore.delete(key);
  console.log(`🔄 Reset rate limit for ${userId} on ${functionName}`);
}

/**
 * Gets current rate limit statistics for monitoring
 */
export function getRateLimitStats(): { totalUsers: number; stats: Array<{ key: string; count: number }> } {
  const stats = Array.from(rateLimitStore.entries()).map(([key, record]) => ({
    key,
    count: record.count,
  }));

  return {
    totalUsers: rateLimitStore.size,
    stats: stats.slice(0, 10), // Return first 10 for monitoring
  };
}
