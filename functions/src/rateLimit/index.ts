/**
 * Rate limiting module for Firebase Functions
 *
 * This module provides comprehensive rate limiting for AI functions using:
 * - Firebase Remote Config for centralized configuration
 * - Firestore sharded counters for distributed counting
 * - Circuit breaker pattern for AI failure handling
 *
 * @module rateLimit
 */

// Type definitions
export type {
  FunctionType,
  RateLimitConfig,
  RateLimitResult,
  CounterShard,
  CircuitState,
  CircuitBreakerConfig,
} from './types';

// Main middleware functions
export {
  checkRateLimit,
  getUserUsage,
  resetUserRateLimits,
  getRateLimitStatus,
} from './middleware';

// Remote Config integration
export {
  getRateLimits,
  isRateLimitingEnabled,
  initializeRemoteConfig,
  clearConfigCache,
} from './remoteConfig';

// Distributed counter utilities
export {
  incrementCounter,
  getCountInWindow,
  getLastRequestTime,
  updateLastRequestTime,
  resetUserCounters,
} from './distributedCounter';

// Circuit breaker utilities
export {
  recordSuccess,
  recordFailure,
  isOpen,
  getCircuitBreakerStatus,
  resetCircuitBreaker,
  getRetryAfter,
} from './circuitBreaker';
