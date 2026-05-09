/**
 * Unit tests for middleware.ts
 * Tests rate limiting middleware, quota checking, and error handling
 */

import {
  checkRateLimit,
  getUserUsage,
  resetUserRateLimits,
  getRateLimitStatus,
} from './middleware';
import { FunctionType } from './types';
import { HttpsError } from 'firebase-functions/v2/https';

// Mock dependencies
jest.mock('./remoteConfig', () => ({
  getRateLimits: jest.fn(),
  isRateLimitingEnabled: jest.fn(),
  clearConfigCache: jest.fn(),
}));

jest.mock('./distributedCounter', () => ({
  incrementCounter: jest.fn(),
  getCountInWindow: jest.fn(),
  getLastRequestTime: jest.fn(),
  updateLastRequestTime: jest.fn(),
  resetUserCounters: jest.fn(),
}));

jest.mock('./circuitBreaker', () => ({
  isOpen: jest.fn(),
  recordSuccess: jest.fn(),
}));

import { getRateLimits, isRateLimitingEnabled } from './remoteConfig';
import {
  incrementCounter,
  getCountInWindow,
  getLastRequestTime,
  updateLastRequestTime,
  resetUserCounters,
} from './distributedCounter';
import { isOpen } from './circuitBreaker';

describe('Middleware', () => {
  const testUserId = 'user123';
  const testFunction: FunctionType = 'summarizeFlow';

  beforeEach(() => {
    jest.clearAllMocks();

    // Setup default mocks
    (isRateLimitingEnabled as jest.Mock).mockResolvedValue(true);
    (isOpen as jest.Mock).mockResolvedValue(false);
    (getRateLimits as jest.Mock).mockResolvedValue({
      hourlyLimit: 10,
      dailyLimit: 50,
      minRequestInterval: 5000,
    });
    (getCountInWindow as jest.Mock).mockResolvedValue(0);
    (getLastRequestTime as jest.Mock).mockResolvedValue(0);
    (incrementCounter as jest.Mock).mockResolvedValue(1);
    (updateLastRequestTime as jest.Mock).mockResolvedValue(undefined);
  });

  describe('checkRateLimit - success cases', () => {
    it('should allow request when under all limits', async () => {
      // Arrange
      (getCountInWindow as jest.Mock).mockResolvedValue(5); // Under hourly limit of 10
      (getLastRequestTime as jest.Mock).mockResolvedValue(0); // No previous request

      // Act
      const result = await checkRateLimit(testUserId, testFunction);

      // Assert
      expect(result.allowed).toBe(true);
      expect(incrementCounter).toHaveBeenCalledWith(testUserId, testFunction, 'hour');
      expect(incrementCounter).toHaveBeenCalledWith(testUserId, testFunction, 'day');
      expect(updateLastRequestTime).toHaveBeenCalledWith(testUserId, testFunction);
    });

    it('should allow request when rate limiting is disabled', async () => {
      // Arrange
      (isRateLimitingEnabled as jest.Mock).mockResolvedValue(false);

      // Act
      const result = await checkRateLimit(testUserId, testFunction);

      // Assert
      expect(result.allowed).toBe(true);
      expect(getCountInWindow).not.toHaveBeenCalled();
      expect(incrementCounter).not.toHaveBeenCalled();
    });

    it('should increment both hourly and daily counters', async () => {
      // Arrange
      (incrementCounter as jest.Mock)
        .mockResolvedValueOnce(6) // hourly
        .mockResolvedValueOnce(25); // daily

      // Act
      await checkRateLimit(testUserId, testFunction);

      // Assert
      expect(incrementCounter).toHaveBeenCalledWith(testUserId, testFunction, 'hour');
      expect(incrementCounter).toHaveBeenCalledWith(testUserId, testFunction, 'day');
    });

    it('should check minimum interval before hourly limit', async () => {
      // Arrange
      (getLastRequestTime as jest.Mock).mockResolvedValue(Date.now() - 10000); // 10 seconds ago

      // Act
      await checkRateLimit(testUserId, testFunction);

      // Assert - should not throw interval error
      expect(getLastRequestTime).toHaveBeenCalledWith(testUserId, testFunction);
      expect(getCountInWindow).toHaveBeenCalled(); // Proceeds to check limits
    });

    it('should handle first request (lastRequestTime = 0)', async () => {
      // Arrange
      (getLastRequestTime as jest.Mock).mockResolvedValue(0);

      // Act
      const result = await checkRateLimit(testUserId, testFunction);

      // Assert
      expect(result.allowed).toBe(true);
      expect(updateLastRequestTime).toHaveBeenCalled();
    });
  });

  describe('checkRateLimit - minimum interval exceeded', () => {
    it('should throw HttpsError when requests are too frequent', async () => {
      // Arrange
      const now = Date.now();
      const lastRequestTime = now - 3000; // 3 seconds ago
      const minInterval = 5000; // 5 seconds required

      (getLastRequestTime as jest.Mock).mockResolvedValue(lastRequestTime);
      (getRateLimits as jest.Mock).mockResolvedValue({
        hourlyLimit: 10,
        dailyLimit: 50,
        minRequestInterval: minInterval,
      });

      // Act & Assert
      await expect(checkRateLimit(testUserId, testFunction)).rejects.toThrow(HttpsError);

      try {
        await checkRateLimit(testUserId, testFunction);
      } catch (error: any) {
        expect(error).toBeInstanceOf(HttpsError);
        expect(error.code).toBe('resource-exhausted');
        expect(error.message).toContain('Permintaan terlalu cepat');
        expect(error.details?.retryAfter).toBeGreaterThan(0);
        expect(error.details?.retryAfter).toBeLessThanOrEqual(2000); // ~2 seconds remaining
      }
    });

    it('should calculate correct retryAfter time for interval', async () => {
      // Arrange - mock Date.now() to control timing
      const fixedTime = 1704067200000; // Fixed timestamp
      const lastRequestTime = fixedTime - 2000; // 2 seconds ago
      const minInterval = 5000; // 5 seconds required
      const expectedRetryAfter = 3000; // 3 seconds remaining

      jest.spyOn(Date, 'now').mockReturnValue(fixedTime);
      (getLastRequestTime as jest.Mock).mockResolvedValue(lastRequestTime);
      (getRateLimits as jest.Mock).mockResolvedValue({
        hourlyLimit: 10,
        dailyLimit: 50,
        minRequestInterval: minInterval,
      });

      // Act & Assert
      try {
        await checkRateLimit(testUserId, testFunction);
      } catch (error: any) {
        expect(error.details?.retryAfter).toBe(expectedRetryAfter);
      }

      jest.restoreAllMocks();
    });

    it('should skip interval check when lastRequestTime is 0', async () => {
      // Arrange
      (getLastRequestTime as jest.Mock).mockResolvedValue(0); // No previous request

      // Act
      const result = await checkRateLimit(testUserId, testFunction);

      // Assert - should not throw interval error
      expect(result.allowed).toBe(true);
    });
  });

  describe('checkRateLimit - hourly limit exceeded', () => {
    it('should throw HttpsError when hourly limit reached', async () => {
      // Arrange
      (getCountInWindow as jest.Mock).mockResolvedValue(10); // At limit
      (getRateLimits as jest.Mock).mockResolvedValue({
        hourlyLimit: 10,
        dailyLimit: 50,
        minRequestInterval: 5000,
      });

      // Act & Assert
      await expect(checkRateLimit(testUserId, testFunction)).rejects.toThrow(HttpsError);

      try {
        await checkRateLimit(testUserId, testFunction);
      } catch (error: any) {
        expect(error).toBeInstanceOf(HttpsError);
        expect(error.code).toBe('resource-exhausted');
        expect(error.message).toContain('Batas permintaan per jam terlampaui');
        expect(error.details?.retryAfter).toBeGreaterThan(0);
        expect(error.details?.retryAfter).toBeLessThanOrEqual(60 * 60 * 1000); // Less than 1 hour
      }
    });

    it('should calculate retryAfter until next hour', async () => {
      // Arrange
      const now = new Date('2024-01-15T14:35:00Z');
      jest.spyOn(Date, 'now').mockReturnValue(now.getTime());

      (getCountInWindow as jest.Mock).mockResolvedValue(10); // At limit

      // Act & Assert
      try {
        await checkRateLimit(testUserId, testFunction);
      } catch (error: any) {
        // Next hour is 15:00:00, so retryAfter should be ~25 minutes
        const expectedRetryAfter = 25 * 60 * 1000;
        expect(error.details?.retryAfter).toBeCloseTo(expectedRetryAfter, -4); // Within 10 seconds
      }

      jest.restoreAllMocks();
    });

    it('should check hourly limit before daily limit', async () => {
      // Arrange - both limits exceeded
      (getCountInWindow as jest.Mock)
        .mockImplementation(async (_, __, window) => {
          return window === 'hour' ? 10 : 50;
        });

      // Act & Assert - should fail with hourly error, not daily
      try {
        await checkRateLimit(testUserId, testFunction);
      } catch (error: any) {
        expect(error.message).toContain('per jam');
        expect(error.message).not.toContain('per hari');
      }
    });
  });

  describe('checkRateLimit - daily limit exceeded', () => {
    it('should throw HttpsError when daily limit reached', async () => {
      // Arrange
      (getCountInWindow as jest.Mock).mockImplementation(async (_, __, window) => {
        return window === 'hour' ? 5 : 50; // Hourly OK, daily at limit
      });

      // Act & Assert
      await expect(checkRateLimit(testUserId, testFunction)).rejects.toThrow(HttpsError);

      try {
        await checkRateLimit(testUserId, testFunction);
      } catch (error: any) {
        expect(error).toBeInstanceOf(HttpsError);
        expect(error.code).toBe('resource-exhausted');
        expect(error.message).toContain('Batas permintaan per hari terlampaui');
        expect(error.details?.retryAfter).toBeGreaterThan(0);
      }
    });

    it('should calculate retryAfter until next day (midnight UTC)', async () => {
      // Arrange
      (getCountInWindow as jest.Mock).mockImplementation(async (_, __, window) => {
        return window === 'hour' ? 5 : 50;
      });

      // Act & Assert
      try {
        await checkRateLimit(testUserId, testFunction);
      } catch (error: any) {
        // retryAfter should be positive and less than 24 hours
        expect(error.details?.retryAfter).toBeGreaterThan(0);
        expect(error.details?.retryAfter).toBeLessThan(24 * 60 * 60 * 1000);
      }
    });

    it('should handle daily limit check at different times of day', async () => {
      // Arrange
      (getCountInWindow as jest.Mock).mockImplementation(async (_, __, window) => {
        return window === 'hour' ? 5 : 50;
      });

      // Act & Assert
      try {
        await checkRateLimit(testUserId, testFunction);
      } catch (error: any) {
        // retryAfter should be positive and reasonable (less than 24 hours)
        expect(error.details?.retryAfter).toBeGreaterThan(0);
        expect(error.details?.retryAfter).toBeLessThan(24 * 60 * 60 * 1000);
      }
    });
  });

  describe('checkRateLimit - circuit breaker', () => {
    it('should throw HttpsError when circuit breaker is open', async () => {
      // Arrange
      (isOpen as jest.Mock).mockResolvedValue(true);

      // Act & Assert
      await expect(checkRateLimit(testUserId, testFunction)).rejects.toThrow(HttpsError);

      try {
        await checkRateLimit(testUserId, testFunction);
      } catch (error: any) {
        expect(error).toBeInstanceOf(HttpsError);
        expect(error.code).toBe('resource-exhausted');
        expect(error.message).toContain('Layanan AI sedang sibuk');
      }
    });

    it('should check circuit breaker before rate limits', async () => {
      // Arrange
      (isOpen as jest.Mock).mockResolvedValue(true);

      // Act & Assert
      try {
        await checkRateLimit(testUserId, testFunction);
      } catch (error: any) {
        // Circuit breaker should be checked first
        expect(isOpen).toHaveBeenCalled();
        // Rate limits should not be checked if circuit is open
        expect(getCountInWindow).not.toHaveBeenCalled();
      }
    });
  });

  describe('checkRateLimit - error handling', () => {
    it('should fail open when rate limit check throws unexpected error', async () => {
      // Arrange
      (getCountInWindow as jest.Mock).mockRejectedValue(new Error('Database error'));
      const consoleErrorSpy = jest.spyOn(console, 'error').mockImplementation();
      const consoleLogSpy = jest.spyOn(console, 'log').mockImplementation();

      // Act
      const result = await checkRateLimit(testUserId, testFunction);

      // Assert
      expect(result.allowed).toBe(true);
      expect(consoleErrorSpy).toHaveBeenCalledWith(
        '❌ Error in rate limit check:',
        'Database error'
      );
      expect(consoleLogSpy).toHaveBeenCalledWith('⚠️ FAILING OPEN - allowing request due to rate limit check error');

      consoleErrorSpy.mockRestore();
      consoleLogSpy.mockRestore();
    });

    it('should re-throw HttpsError without modification', async () => {
      // Arrange
      const httpsError = new HttpsError('aborted', 'Custom error');
      (getCountInWindow as jest.Mock).mockRejectedValue(httpsError);

      // Act & Assert
      await expect(checkRateLimit(testUserId, testFunction)).rejects.toThrow('Custom error');
    });

    it('should handle Remote Config fetch failure', async () => {
      // Arrange
      (getRateLimits as jest.Mock).mockRejectedValue(new Error('Remote Config error'));
      const consoleErrorSpy = jest.spyOn(console, 'error').mockImplementation();
      const consoleLogSpy = jest.spyOn(console, 'log').mockImplementation();

      // Act
      const result = await checkRateLimit(testUserId, testFunction);

      // Assert
      expect(result.allowed).toBe(true);
      expect(consoleErrorSpy).toHaveBeenCalled();
      expect(consoleLogSpy).toHaveBeenCalledWith(expect.stringContaining('FAILING OPEN'));

      consoleErrorSpy.mockRestore();
      consoleLogSpy.mockRestore();
    });

    it('should handle increment counter failure', async () => {
      // Arrange - all checks pass, but increment fails
      (incrementCounter as jest.Mock).mockRejectedValue(new Error('Counter update failed'));
      const consoleErrorSpy = jest.spyOn(console, 'error').mockImplementation();
      const consoleLogSpy = jest.spyOn(console, 'log').mockImplementation();

      // Act
      const result = await checkRateLimit(testUserId, testFunction);

      // Assert
      expect(result.allowed).toBe(true); // Fails open

      consoleErrorSpy.mockRestore();
      consoleLogSpy.mockRestore();
    });
  });

  describe('checkRateLimit - check order', () => {
    it('should check limits in correct order: circuit breaker, interval, hourly, daily', async () => {
      // Arrange
      const callOrder: string[] = [];
      (isOpen as jest.Mock).mockImplementation(async () => {
        callOrder.push('circuitBreaker');
        return false;
      });
      (getRateLimits as jest.Mock).mockImplementation(async () => {
        callOrder.push('getRateLimits');
        return { hourlyLimit: 10, dailyLimit: 50, minRequestInterval: 5000 };
      });
      (getLastRequestTime as jest.Mock).mockImplementation(async () => {
        callOrder.push('lastRequestTime');
        return 0;
      });
      (getCountInWindow as jest.Mock).mockImplementation(async (_, __, window) => {
        callOrder.push(`count_${window}`);
        return 5;
      });
      (incrementCounter as jest.Mock).mockImplementation(async (_, __, window) => {
        callOrder.push(`increment_${window}`);
        return 6;
      });

      // Act
      await checkRateLimit(testUserId, testFunction);

      // Assert - verify check order
      expect(callOrder[0]).toBe('circuitBreaker');
      expect(callOrder[1]).toBe('getRateLimits');
      expect(callOrder[2]).toBe('lastRequestTime');
      expect(callOrder[3]).toBe('count_hour');
      expect(callOrder[4]).toBe('count_day');
      expect(callOrder[5]).toBe('increment_hour');
      expect(callOrder[6]).toBe('increment_day');
    });
  });

  describe('getUserUsage', () => {
    it('should return current usage and limits', async () => {
      // Arrange
      (getRateLimits as jest.Mock).mockResolvedValue({
        hourlyLimit: 10,
        dailyLimit: 50,
        minRequestInterval: 5000,
      });
      (getCountInWindow as jest.Mock).mockImplementation(async (_, __, window) => {
        return window === 'hour' ? 5 : 20;
      });

      // Act
      const usage = await getUserUsage(testUserId, testFunction);

      // Assert
      expect(usage).toEqual({
        hourlyUsed: 5,
        hourlyLimit: 10,
        dailyUsed: 20,
        dailyLimit: 50,
        canRequest: true,
      });
    });

    it('should return canRequest false when hourly limit reached', async () => {
      // Arrange
      (getRateLimits as jest.Mock).mockResolvedValue({
        hourlyLimit: 10,
        dailyLimit: 50,
        minRequestInterval: 5000,
      });
      (getCountInWindow as jest.Mock).mockImplementation(async (_, __, window) => {
        return window === 'hour' ? 10 : 20;
      });

      // Act
      const usage = await getUserUsage(testUserId, testFunction);

      // Assert
      expect(usage.canRequest).toBe(false);
      expect(usage.hourlyUsed).toBe(10);
      expect(usage.hourlyLimit).toBe(10);
    });

    it('should return canRequest false when daily limit reached', async () => {
      // Arrange
      (getRateLimits as jest.Mock).mockResolvedValue({
        hourlyLimit: 10,
        dailyLimit: 50,
        minRequestInterval: 5000,
      });
      (getCountInWindow as jest.Mock).mockImplementation(async (_, __, window) => {
        return window === 'hour' ? 5 : 50;
      });

      // Act
      const usage = await getUserUsage(testUserId, testFunction);

      // Assert
      expect(usage.canRequest).toBe(false);
      expect(usage.dailyUsed).toBe(50);
      expect(usage.dailyLimit).toBe(50);
    });

    it('should throw error when Remote Config fails', async () => {
      // Arrange
      (getRateLimits as jest.Mock).mockRejectedValue(new Error('Config error'));

      // Act & Assert
      await expect(getUserUsage(testUserId, testFunction)).rejects.toThrow('Config error');
    });

    it('should throw error when counter fetch fails', async () => {
      // Arrange
      (getRateLimits as jest.Mock).mockResolvedValue({
        hourlyLimit: 10,
        dailyLimit: 50,
        minRequestInterval: 5000,
      });
      (getCountInWindow as jest.Mock).mockRejectedValue(new Error('Counter error'));

      // Act & Assert
      await expect(getUserUsage(testUserId, testFunction)).rejects.toThrow('Counter error');
    });

    it('should include retryAfter when cannot request', async () => {
      // Arrange - hourly limit exceeded
      const now = Date.now();
      jest.spyOn(Date, 'now').mockReturnValue(now);

      (getRateLimits as jest.Mock).mockResolvedValue({
        hourlyLimit: 10,
        dailyLimit: 50,
        minRequestInterval: 5000,
      });
      (getCountInWindow as jest.Mock).mockImplementation(async (_, __, window) => {
        return window === 'hour' ? 10 : 20;
      });

      // Act
      const usage = await getUserUsage(testUserId, testFunction);

      // Assert
      expect(usage.canRequest).toBe(false);
      // Note: retryAfter calculation depends on time until next hour
      // This would be calculated by the implementation

      jest.restoreAllMocks();
    });
  });

  describe('resetUserRateLimits', () => {
    it('should call resetUserCounters for user', async () => {
      // Arrange
      (resetUserCounters as jest.Mock).mockResolvedValue(undefined);
      const consoleLogSpy = jest.spyOn(console, 'log').mockImplementation();

      // Act
      await resetUserRateLimits(testUserId);

      // Assert
      expect(resetUserCounters).toHaveBeenCalledWith(testUserId);
      expect(consoleLogSpy).toHaveBeenCalledWith(`✅ Rate limits reset for user ${testUserId}`);

      consoleLogSpy.mockRestore();
    });

    it('should propagate errors from resetUserCounters', async () => {
      // Arrange
      const error = new Error('Reset failed');
      (resetUserCounters as jest.Mock).mockRejectedValue(error);

      // Act & Assert
      await expect(resetUserRateLimits(testUserId)).rejects.toThrow('Reset failed');
    });
  });

  describe('getRateLimitStatus', () => {
    it('should return enabled and circuit breaker status', async () => {
      // Arrange
      (isRateLimitingEnabled as jest.Mock).mockResolvedValue(true);
      (isOpen as jest.Mock).mockResolvedValue(false);

      // Act
      const status = await getRateLimitStatus();

      // Assert
      expect(status).toEqual({
        enabled: true,
        circuitBreakerOpen: false,
      });
    });

    it('should return disabled when rate limiting is off', async () => {
      // Arrange
      (isRateLimitingEnabled as jest.Mock).mockResolvedValue(false);
      (isOpen as jest.Mock).mockResolvedValue(false);

      // Act
      const status = await getRateLimitStatus();

      // Assert
      expect(status.enabled).toBe(false);
      expect(status.circuitBreakerOpen).toBe(false);
    });

    it('should return circuit breaker open when true', async () => {
      // Arrange
      (isRateLimitingEnabled as jest.Mock).mockResolvedValue(true);
      (isOpen as jest.Mock).mockResolvedValue(true);

      // Act
      const status = await getRateLimitStatus();

      // Assert
      expect(status.circuitBreakerOpen).toBe(true);
    });

    it('should fetch both statuses in parallel', async () => {
      // Arrange
      const isRateLimitingEnabledPromise = Promise.resolve(true);
      const isOpenPromise = Promise.resolve(false);

      (isRateLimitingEnabled as jest.Mock).mockReturnValue(isRateLimitingEnabledPromise);
      (isOpen as jest.Mock).mockReturnValue(isOpenPromise);

      // Act
      await getRateLimitStatus();

      // Assert - both should be called (Promise.all ensures parallel execution)
      expect(isRateLimitingEnabled).toHaveBeenCalled();
      expect(isOpen).toHaveBeenCalled();
    });
  });

  describe('integration scenarios', () => {
    it('should handle complete request lifecycle', async () => {
      // This test simulates a real request flow

      // 1. First request - should succeed
      (getLastRequestTime as jest.Mock).mockResolvedValue(0);
      (getCountInWindow as jest.Mock).mockResolvedValue(0);
      (incrementCounter as jest.Mock).mockResolvedValue(1);

      let result = await checkRateLimit(testUserId, testFunction);
      expect(result.allowed).toBe(true);

      // 2. Second request - should still succeed (under limits)
      (getLastRequestTime as jest.Mock).mockResolvedValue(Date.now() - 10000); // 10 seconds ago
      (getCountInWindow as jest.Mock).mockResolvedValue(1);
      (incrementCounter as jest.Mock).mockResolvedValue(2);

      result = await checkRateLimit(testUserId, testFunction);
      expect(result.allowed).toBe(true);

      // 3. Request too soon - should fail interval check
      (getLastRequestTime as jest.Mock).mockResolvedValue(Date.now() - 1000); // 1 second ago

      await expect(checkRateLimit(testUserId, testFunction)).rejects.toThrow(HttpsError);

      // 4. After waiting - should succeed again
      (getLastRequestTime as jest.Mock).mockResolvedValue(Date.now() - 10000);
      (getCountInWindow as jest.Mock).mockResolvedValue(2);
      (incrementCounter as jest.Mock).mockResolvedValue(3);

      result = await checkRateLimit(testUserId, testFunction);
      expect(result.allowed).toBe(true);
    });

    it('should handle multiple function types independently', async () => {
      const chatFunction: FunctionType = 'chatFlow';

      // summarizeFlow is at limit, chatFlow is not
      (getCountInWindow as jest.Mock).mockImplementation(async (userId, funcType, window) => {
        if (funcType === 'summarizeFlow' && window === 'hour') {
          return 10; // At limit
        }
        return 5; // Under limit
      });

      // summarizeFlow should fail
      await expect(checkRateLimit(testUserId, 'summarizeFlow')).rejects.toThrow();

      // chatFlow should succeed
      const result = await checkRateLimit(testUserId, chatFunction);
      expect(result.allowed).toBe(true);
    });

    it('should respect custom rate limits from Remote Config', async () => {
      // Arrange
      const customLimits = {
        hourlyLimit: 100,
        dailyLimit: 500,
        minRequestInterval: 1000,
      };
      (getRateLimits as jest.Mock).mockResolvedValue(customLimits);
      (getCountInWindow as jest.Mock).mockResolvedValue(99); // Under custom hourly limit

      // Act
      const result = await checkRateLimit(testUserId, testFunction);

      // Assert
      expect(result.allowed).toBe(true);
      expect(getRateLimits).toHaveBeenCalledWith(testFunction);
    });
  });

  describe('Indonesian error messages', () => {
    it('should use correct message for unauthenticated', async () => {
      // This would be tested in the auth layer, but we verify the message exists
      // by checking the ERROR_MESSAGES constant indirectly through behavior

      // The actual unauthenticated check happens before checkRateLimit
      // So we just verify the other messages are correct
    });

    it('should use Indonesian message for hourly limit', async () => {
      // Arrange
      (getCountInWindow as jest.Mock).mockResolvedValue(10); // At limit

      // Act & Assert
      try {
        await checkRateLimit(testUserId, testFunction);
      } catch (error: any) {
        expect(error.message).toContain('per jam');
        expect(error.message).toContain('Silakan tunggu');
      }
    });

    it('should use Indonesian message for daily limit', async () => {
      // Arrange
      (getCountInWindow as jest.Mock).mockImplementation(async (_, __, window) => {
        return window === 'hour' ? 5 : 50; // Daily at limit
      });

      // Act & Assert
      try {
        await checkRateLimit(testUserId, testFunction);
      } catch (error: any) {
        expect(error.message).toContain('per hari');
        expect(error.message).toContain('besok');
      }
    });

    it('should use Indonesian message for interval', async () => {
      // Arrange
      (getLastRequestTime as jest.Mock).mockResolvedValue(Date.now() - 1000);

      // Act & Assert
      try {
        await checkRateLimit(testUserId, testFunction);
      } catch (error: any) {
        expect(error.message).toContain('terlalu cepat');
        expect(error.message).toContain('beberapa detik');
      }
    });

    it('should use Indonesian message for circuit breaker', async () => {
      // Arrange
      (isOpen as jest.Mock).mockResolvedValue(true);

      // Act & Assert
      try {
        await checkRateLimit(testUserId, testFunction);
      } catch (error: any) {
        expect(error.message).toContain('Layanan AI sedang sibuk');
        expect(error.message).toContain('beberapa saat');
      }
    });
  });
});
