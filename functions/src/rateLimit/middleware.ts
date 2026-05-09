/**
 * Rate limiting middleware for Firebase Functions
 * Checks per-user quotas and request intervals before allowing requests
 */

import { HttpsError } from 'firebase-functions/v2/https';
import { FunctionType, RateLimitResult } from './types';
import { getRateLimits, isRateLimitingEnabled } from './remoteConfig';
import {
  incrementCounter,
  getCountInWindow,
  getLastRequestTime,
  updateLastRequestTime,
} from './distributedCounter';
import { isOpen } from './circuitBreaker';

// Indonesian error messages
const ERROR_MESSAGES = {
  UNAUTHENTICATED: '🔐 Anda harus login terlebih dahulu\n\nSilakan sign in dengan Google untuk menggunakan fitur AI.',
  RATE_LIMIT_HOURLY: '⏱️ Batas permintaan per jam terlampaui\n\nSilakan tunggu hingga jam berikutnya untuk mencoba lagi.',
  RATE_LIMIT_DAILY: '⏱️ Batas permintaan per hari terlampaui\n\nSilakan tunggu hingga besok untuk mencoba lagi.',
  RATE_LIMIT_INTERVAL: '⏱️ Permintaan terlalu cepat\n\nMohon tunggu beberapa detik sebelum mencoba lagi.',
  CIRCUIT_BREAKER_OPEN: '⚠️ Layanan AI sedang sibuk\n\nSilakan coba lagi dalam beberapa saat.',
};

/**
 * Check rate limits for a user request
 * This is the main middleware function to be called in each Firebase Function
 *
 * @param userId - User's Firebase UID
 * @param functionName - The function type being called
 * @returns RateLimitResult indicating if request is allowed
 * @throws HttpsError if rate limit is exceeded
 */
export async function checkRateLimit(
  userId: string,
  functionName: FunctionType
): Promise<RateLimitResult> {
  const startTime = Date.now();
  console.log(`🔍 Checking rate limits for user ${userId} on ${functionName}`);

  try {
    // Check if rate limiting is enabled
    const isEnabled = await isRateLimitingEnabled();
    if (!isEnabled) {
      console.log('⚠️ Rate limiting is DISABLED - allowing request');
      return { allowed: true };
    }

    // Check circuit breaker first
    const circuitOpen = await isOpen();
    if (circuitOpen) {
      console.log('⛔ Circuit breaker is OPEN - rejecting request');
      throw new HttpsError('resource-exhausted', ERROR_MESSAGES.CIRCUIT_BREAKER_OPEN);
    }

    // Get rate limit configuration
    const config = await getRateLimits(functionName);
    console.log(`📊 Config: hourly=${config.hourlyLimit}, daily=${config.dailyLimit}, interval=${config.minRequestInterval}ms`);

    // Check minimum request interval
    const lastRequestTime = await getLastRequestTime(userId, functionName);
    const timeSinceLastRequest = Date.now() - lastRequestTime;

    if (lastRequestTime > 0 && timeSinceLastRequest < config.minRequestInterval) {
      const waitTime = config.minRequestInterval - timeSinceLastRequest;
      console.log(`⏱️ Request interval check failed: ${timeSinceLastRequest}ms < ${config.minRequestInterval}ms`);

      throw new HttpsError(
        'resource-exhausted',
        ERROR_MESSAGES.RATE_LIMIT_INTERVAL,
        { retryAfter: waitTime }
      );
    }

    // Check hourly limit
    const hourlyCount = await getCountInWindow(userId, functionName, 'hour');
    if (hourlyCount >= config.hourlyLimit) {
      console.log(`⏱️ Hourly limit exceeded: ${hourlyCount}/${config.hourlyLimit}`);

      // Calculate time until next hour
      const now = Date.now();
      const nextHour = Math.ceil(now / (60 * 60 * 1000)) * (60 * 60 * 1000);
      const retryAfter = nextHour - now;

      throw new HttpsError(
        'resource-exhausted',
        ERROR_MESSAGES.RATE_LIMIT_HOURLY,
        { retryAfter }
      );
    }

    // Check daily limit
    const dailyCount = await getCountInWindow(userId, functionName, 'day');
    if (dailyCount >= config.dailyLimit) {
      console.log(`⏱️ Daily limit exceeded: ${dailyCount}/${config.dailyLimit}`);

      // Calculate time until next day (midnight UTC)
      const now = new Date();
      const tomorrow = new Date(now);
      tomorrow.setUTCDate(tomorrow.getUTCDate() + 1);
      tomorrow.setUTCHours(0, 0, 0, 0);
      const retryAfter = tomorrow.getTime() - now.getTime();

      throw new HttpsError(
        'resource-exhausted',
        ERROR_MESSAGES.RATE_LIMIT_DAILY,
        { retryAfter }
      );
    }

    // All checks passed - increment counters and update last request time
    const newHourlyCount = await incrementCounter(userId, functionName, 'hour');
    const newDailyCount = await incrementCounter(userId, functionName, 'day');
    await updateLastRequestTime(userId, functionName);

    const elapsed = Date.now() - startTime;
    console.log(
      `✅ Rate limit check passed (${elapsed}ms): ` +
      `hourly=${newHourlyCount}/${config.hourlyLimit}, ` +
      `daily=${newDailyCount}/${config.dailyLimit}`
    );

    return {
      allowed: true,
    };
  } catch (error: any) {
    // Re-throw HttpsError as-is
    if (error instanceof HttpsError) {
      throw error;
    }

    // Log unexpected errors but allow request (fail open)
    console.error('❌ Error in rate limit check:', error?.message || error);
    console.log('⚠️ FAILING OPEN - allowing request due to rate limit check error');

    return {
      allowed: true,
    };
  }
}

/**
 * Get current usage statistics for a user
 * Useful for displaying quota remaining in UI
 *
 * @param userId - User's Firebase UID
 * @param functionName - The function type
 * @returns Object with current usage and limits
 */
export async function getUserUsage(
  userId: string,
  functionName: FunctionType
): Promise<{
  hourlyUsed: number;
  hourlyLimit: number;
  dailyUsed: number;
  dailyLimit: number;
  canRequest: boolean;
  retryAfter?: number;
}> {
  try {
    const config = await getRateLimits(functionName);
    const hourlyUsed = await getCountInWindow(userId, functionName, 'hour');
    const dailyUsed = await getCountInWindow(userId, functionName, 'day');

    const canRequest =
      hourlyUsed < config.hourlyLimit && dailyUsed < config.dailyLimit;

    return {
      hourlyUsed,
      hourlyLimit: config.hourlyLimit,
      dailyUsed,
      dailyLimit: config.dailyLimit,
      canRequest,
    };
  } catch (error: any) {
    console.error('❌ Error getting user usage:', error?.message || error);
    throw error;
  }
}

/**
 * Reset rate limits for a specific user (admin function)
 *
 * @param userId - User's Firebase UID
 */
export async function resetUserRateLimits(userId: string): Promise<void> {
  const { resetUserCounters } = await import('./distributedCounter');
  await resetUserCounters(userId);
  console.log(`✅ Rate limits reset for user ${userId}`);
}

/**
 * Get rate limit status for monitoring
 *
 * @returns Object with rate limiting status
 */
export async function getRateLimitStatus(): Promise<{
  enabled: boolean;
  circuitBreakerOpen: boolean;
}> {
  const [enabled, circuitOpen] = await Promise.all([
    isRateLimitingEnabled(),
    isOpen(),
  ]);

  return {
    enabled,
    circuitBreakerOpen: circuitOpen,
  };
}
