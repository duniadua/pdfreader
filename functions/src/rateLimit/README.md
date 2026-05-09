# Rate Limiting Module

Comprehensive rate limiting for Firebase Functions AI operations using Firestore distributed counters and Remote Config.

## Overview

This module provides production-ready rate limiting for AI functions (summarizeFlow, chatFlow, extractFlow) with:

- **Per-user quotas** - Hourly and daily limits per function
- **Request interval** - Minimum time between requests
- **Circuit breaker** - Prevents cascading AI failures
- **Remote Config** - Centralized configuration with 1-minute cache
- **Sharded counters** - Distributed Firestore pattern for scalability
- **Graceful degradation** - Falls back to defaults on errors

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Firebase Function                        │
│                  (summarizeFlow, etc.)                      │
└───────────────────────────┬─────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                   Middleware Layer                          │
│  checkRateLimit(userId, functionType)                       │
│  - Validates authentication                                 │
│  - Checks circuit breaker                                   │
│  - Enforces rate limits                                     │
└───────────────────────────┬─────────────────────────────────┘
                            │
            ┌───────────────┼───────────────┐
            ▼               ▼               ▼
    ┌──────────────┐ ┌──────────────┐ ┌──────────────┐
    │   Remote     │ │ Distributed  │ │  Circuit     │
    │   Config     │ │   Counters   │ │  Breaker     │
    └──────────────┘ └──────────────┘ └──────────────┘
```

## File Structure

```
rateLimit/
├── types.ts              # Type definitions
├── remoteConfig.ts       # Remote Config integration
├── distributedCounter.ts # Firestore sharded counters
├── circuitBreaker.ts     # Circuit breaker pattern
├── middleware.ts         # Main rate limiting logic
├── index.ts             # Public API exports
└── README.md            # This file
```

## Usage

### Basic Integration

```typescript
import { checkRateLimit } from './rateLimit/middleware';

export const myFunction = onCall(
  { secrets: [API_KEY] },
  async (request) => {
    // Check authentication
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'You must be logged in');
    }

    // Check rate limits
    await checkRateLimit(request.auth.uid, 'summarizeFlow');

    // Your function logic here...
    return { result: 'success' };
  }
);
```

### With Circuit Breaker

```typescript
import { checkRateLimit, recordSuccess, recordFailure } from './rateLimit';

export const myFunction = onCall(async (request) => {
  try {
    await checkRateLimit(request.auth.uid, 'chatFlow');

    // Call AI API
    const result = await ai.generate(prompt);

    // Record success
    await recordSuccess();

    return result;
  } catch (error) {
    // Record failure for circuit breaker
    await recordFailure();
    throw error;
  }
});
```

## Configuration

### Default Rate Limits

| Function    | Hourly | Daily | Interval |
|-------------|--------|-------|----------|
| summarizeFlow | 10    | 50    | 5000ms   |
| chatFlow     | 30    | 200   | 2000ms   |
| extractFlow  | 15    | 75    | 3000ms   |

### Remote Config Setup

To override defaults via Firebase Remote Config:

1. Go to Firebase Console → Remote Config
2. Create parameters:

**rate_limit_enabled** (Boolean)
- Default: `true`
- Description: Enable/disable rate limiting globally

**rate_limit_summarizeFlow** (JSON)
```json
{
  "hourlyLimit": 10,
  "dailyLimit": 50,
  "minRequestInterval": 5000
}
```

**rate_limit_chatFlow** (JSON)
```json
{
  "hourlyLimit": 30,
  "dailyLimit": 200,
  "minRequestInterval": 2000
}
```

**rate_limit_extractFlow** (JSON)
```json
{
  "hourlyLimit": 15,
  "dailyLimit": 75,
  "minRequestInterval": 3000
}
```

## API Reference

### Main Functions

#### `checkRateLimit(userId: string, functionType: FunctionType): Promise<RateLimitResult>`

Checks if a request is allowed under rate limits.

**Throws:** `HttpsError('resource-exhausted', message)` if limit exceeded

**Example:**
```typescript
try {
  await checkRateLimit(userId, 'chatFlow');
  // Proceed with request
} catch (error) {
  if (error.code === 'resource-exhausted') {
    // Rate limit exceeded, show error to user
  }
}
```

#### `getUserUsage(userId: string, functionType: FunctionType): Promise<UsageStats>`

Get current usage statistics for display in UI.

**Returns:**
```typescript
{
  hourlyUsed: number,
  hourlyLimit: number,
  dailyUsed: number,
  dailyLimit: number,
  canRequest: boolean
}
```

#### `resetUserRateLimits(userId: string): Promise<void>`

Reset all counters for a specific user (admin function).

#### `getRateLimitStatus(): Promise<Status>`

Get global rate limiting status (for monitoring).

**Returns:**
```typescript
{
  enabled: boolean,
  circuitBreakerOpen: boolean
}
```

### Circuit Breaker Functions

#### `recordSuccess(): Promise<void>`

Record successful AI call. Resets failure count.

#### `recordFailure(): Promise<void>`

Record failed AI call. Opens circuit after threshold.

#### `isOpen(): Promise<boolean>`

Check if circuit is currently open (blocking requests).

#### `getCircuitBreakerStatus(): Promise<CircuitStatus>`

Get detailed circuit breaker status.

**Returns:**
```typescript
{
  state: 'closed' | 'open' | 'half-open',
  failureCount: number,
  lastFailureTime: number,
  lastStateChange: number,
  timeUntilRecovery?: number
}
```

### Distributed Counter Functions

#### `incrementCounter(userId: string, functionType: string, window: 'hour' | 'day'): Promise<number>`

Increment counter and return new total.

#### `getCountInWindow(userId: string, functionType: string, window: 'hour' | 'day'): Promise<number>`

Get total count in time window.

#### `getLastRequestTime(userId: string, functionType: string): Promise<number>`

Get timestamp of last request.

### Remote Config Functions

#### `getRateLimits(functionType: FunctionType): Promise<RateLimitConfig>`

Get rate limit configuration (with 1-minute cache).

#### `isRateLimitingEnabled(): Promise<boolean>`

Check if rate limiting is enabled globally.

#### `initializeRemoteConfig(): Promise<void>`

Initialize Remote Config (call during deployment).

## Firestore Collections

### `rateLimitCounters`

Stores sharded counter data.

**Document ID format:** `{userId}_{functionType}_shard_{shardIndex}`

**Example:** `abc123_summarizeFlow_shard_5`

**Schema:**
```typescript
{
  count: number,        // Current count
  lastUpdated: number   // Timestamp
}
```

### `system`

Stores circuit breaker state.

**Document ID:** `circuitBreakerState`

**Schema:**
```typescript
{
  state: 'closed' | 'open' | 'half-open',
  failureCount: number,
  lastFailureTime: number,
  lastStateChange: number,
  config: CircuitBreakerConfig
}
```

## Error Messages (Indonesian)

All error messages are in Indonesian as per app requirements:

- **Unauthenticated:** "🔐 Anda harus login terlebih dahulu"
- **Hourly Limit:** "⏱️ Batas permintaan per jam terlampaui"
- **Daily Limit:** "⏱️ Batas permintaan per hari terlampaui"
- **Interval:** "⏱️ Permintaan terlalu cepat"
- **Circuit Breaker:** "⚠️ Layanan AI sedang sibuk"

## Performance

### Sharded Counter Pattern

- **10 shards** per user/function to distribute load
- **Random shard selection** on each write
- **Automatic cleanup** of stale shards
- **Transaction safety** with Firestore transactions

### Caching

- **Remote Config:** 1-minute cache
- **Circuit state:** Real-time from Firestore
- **Counter reads:** Parallel fetch of all shards

### Latency

Typical operation times (on cold start):
- `checkRateLimit`: ~200-400ms
- `incrementCounter`: ~100-200ms
- `getCountInWindow`: ~150-300ms

## Testing

```typescript
import * as admin from 'firebase-admin';
import { checkRateLimit, resetUserRateLimits } from './rateLimit';

describe('Rate Limiting', () => {
  const testUserId = 'test-user-123';

  beforeEach(async () => {
    await resetUserRateLimits(testUserId);
  });

  test('should allow request within limits', async () => {
    const result = await checkRateLimit(testUserId, 'chatFlow');
    expect(result.allowed).toBe(true);
  });

  test('should block request exceeding hourly limit', async () => {
    // Make 30 requests (hourly limit for chatFlow)
    for (let i = 0; i < 30; i++) {
      await checkRateLimit(testUserId, 'chatFlow');
    }

    // 31st request should fail
    await expect(
      checkRateLimit(testUserId, 'chatFlow')
    ).rejects.toThrow('resource-exhausted');
  });
});
```

## Monitoring

### Metrics to Track

1. **Rate limit hit rate** - What % of requests are blocked?
2. **Circuit breaker opens** - How often does AI fail?
3. **Average request interval** - Are users being rate limited?
4. **Per-user usage distribution** - Power users vs casual users

### Logging

All functions include comprehensive logging:

```typescript
console.log('🔍 Checking rate limits for user', userId);
console.log('📊 Config: hourly=', config.hourlyLimit);
console.log('✅ Rate limit check passed');
console.log('⏱️ Hourly limit exceeded');
```

## Troubleshooting

### Issue: Rate limits not working

**Check:**
1. Firestore is enabled in Firebase project
2. User is authenticated (request.auth.uid exists)
3. Remote Config is initialized
4. Check logs for errors

### Issue: Circuit breaker always open

**Check:**
1. AI API key is valid
2. AI service is actually failing (check function logs)
3. Reset circuit breaker: `await resetCircuitBreaker()`

### Issue: Counters not incrementing

**Check:**
1. Firestore permissions allow writes
2. Counter documents exist in `rateLimitCounters` collection
3. Check for transaction conflicts in logs

## License

MIT
