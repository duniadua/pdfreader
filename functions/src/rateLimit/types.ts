/**
 * Type definitions for rate limiting module
 */

/**
 * Supported function types for rate limiting
 */
export type FunctionType = 'summarizeFlow' | 'chatFlow' | 'extractFlow';

/**
 * Rate limit configuration for a specific function
 */
export interface RateLimitConfig {
  /**
   * Maximum requests allowed per hour per user
   */
  hourlyLimit: number;

  /**
   * Maximum requests allowed per day per user
   */
  dailyLimit: number;

  /**
   * Minimum interval (in milliseconds) between consecutive requests
   */
  minRequestInterval: number;
}

/**
 * Rate limit check result
 */
export interface RateLimitResult {
  /**
   * Whether the request is allowed
   */
  allowed: boolean;

  /**
   * Time in milliseconds until the user can retry (if not allowed)
   */
  retryAfter?: number;

  /**
   * Reason for rate limit denial (if not allowed)
   */
  reason?: 'hourly' | 'daily' | 'interval' | 'circuit-breaker';
}

/**
 * Counter shard for distributed counting
 */
export interface CounterShard {
  count: number;
  lastUpdated: number;
}

/**
 * Circuit breaker state
 */
export type CircuitState = 'closed' | 'open' | 'half-open';

/**
 * Circuit breaker configuration
 */
export interface CircuitBreakerConfig {
  /**
   * Number of failures to trigger circuit opening
   */
  failureThreshold: number;

  /**
   * Time window in milliseconds to count failures
   */
  failureWindow: number;

  /**
   * Time in milliseconds before attempting recovery
   */
  recoveryTimeout: number;
}
