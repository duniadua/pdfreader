/**
 * Circuit breaker pattern for AI failures
 * Prevents cascading failures when AI service is experiencing issues
 */

import * as admin from 'firebase-admin';
import { CircuitState, CircuitBreakerConfig } from './types';

const CIRCUIT_BREAKER_DOC = 'circuitBreakerState';

// Default circuit breaker configuration
const DEFAULT_CONFIG: CircuitBreakerConfig = {
  failureThreshold: 5, // Open circuit after 5 failures
  failureWindow: 60 * 1000, // Within 1 minute
  recoveryTimeout: 60 * 1000, // Retry after 60 seconds
};

/**
 * Get current circuit breaker state from Firestore
 */
async function getCircuitState(): Promise<{
  state: CircuitState;
  failureCount: number;
  lastFailureTime: number;
  lastStateChange: number;
}> {
  try {
    const db = admin.firestore();
    const docRef = db.collection('system').doc(CIRCUIT_BREAKER_DOC);
    const doc = await docRef.get();

    if (!doc.exists) {
      // Initialize circuit breaker in closed state
      const initialState = {
        state: 'closed' as CircuitState,
        failureCount: 0,
        lastFailureTime: 0,
        lastStateChange: Date.now(),
        config: DEFAULT_CONFIG,
      };

      await docRef.set(initialState);
      return initialState;
    }

    const data = doc.data() as any;
    return {
      state: data.state || 'closed',
      failureCount: data.failureCount || 0,
      lastFailureTime: data.lastFailureTime || 0,
      lastStateChange: data.lastStateChange || Date.now(),
    };
  } catch (error: any) {
    console.error('❌ Error getting circuit state:', error?.message || error);
    // Default to closed state on error (Firebase unavailable, etc.)
    return {
      state: 'closed',
      failureCount: 0,
      lastFailureTime: 0,
      lastStateChange: Date.now(),
    };
  }
}

/**
 * Update circuit breaker state in Firestore
 */
async function updateCircuitState(
  state: CircuitState,
  failureCount: number,
  lastFailureTime?: number
): Promise<void> {
  try {
    const db = admin.firestore();
    const docRef = db.collection('system').doc(CIRCUIT_BREAKER_DOC);

    await docRef.set(
      {
        state,
        failureCount,
        lastFailureTime: lastFailureTime || 0,
        lastStateChange: Date.now(),
        config: DEFAULT_CONFIG,
      },
      { merge: true }
    );
  } catch (error: any) {
    console.error('❌ Error updating circuit state:', error?.message || error);
    // Don't throw - circuit breaker should not break the app
  }
}

/**
 * Record a successful AI call
 * Resets failure count and closes circuit if in half-open state
 */
export async function recordSuccess(): Promise<void> {
  const currentState = await getCircuitState();

  console.log(`✅ Circuit breaker: Recording success (current state: ${currentState.state})`);

  if (currentState.state === 'half-open') {
    // Success in half-open state -> close circuit
    console.log('🔌 Circuit breaker: Closing circuit after successful retry');
    await updateCircuitState('closed', 0, 0);
  } else if (currentState.state === 'closed') {
    // Reset failure count on success in closed state
    if (currentState.failureCount > 0) {
      await updateCircuitState('closed', 0, 0);
    }
  }
}

/**
 * Record a failed AI call
 * Increments failure count and potentially opens circuit
 */
export async function recordFailure(): Promise<void> {
  const currentState = await getCircuitState();
  const now = Date.now();
  const config = DEFAULT_CONFIG;

  console.log(`❌ Circuit breaker: Recording failure (current state: ${currentState.state})`);

  // Reset failure count if we're outside the failure window
  let failureCount = currentState.failureCount;
  if (now - currentState.lastFailureTime > config.failureWindow) {
    failureCount = 0;
  }

  failureCount++;

  // Check if we should open the circuit
  if (
    currentState.state === 'closed' &&
    failureCount >= config.failureThreshold
  ) {
    console.log(
      `⚠️ Circuit breaker: Opening circuit after ${failureCount} failures`
    );
    await updateCircuitState('open', failureCount, now);
  } else if (currentState.state === 'half-open') {
    // Failure in half-open state -> re-open circuit
    console.log('⚠️ Circuit breaker: Failure in half-open state, re-opening circuit');
    await updateCircuitState('open', failureCount, now);
  } else {
    await updateCircuitState(currentState.state, failureCount, now);
  }
}

/**
 * Check if the circuit is currently open
 * Returns true if requests should be blocked
 */
export async function isOpen(): Promise<boolean> {
  const currentState = await getCircuitState();
  const now = Date.now();
  const config = DEFAULT_CONFIG;

  if (currentState.state === 'open') {
    // Check if recovery timeout has elapsed
    if (now - currentState.lastStateChange >= config.recoveryTimeout) {
      // Transition to half-open state
      console.log('🔄 Circuit breaker: Transitioning to half-open state');
      await updateCircuitState('half-open', currentState.failureCount);
      return false; // Allow one request to test
    }

    console.log('⛔ Circuit breaker: Circuit is OPEN, blocking requests');
    return true;
  }

  return false;
}

/**
 * Get current circuit breaker state (for monitoring)
 */
export async function getCircuitBreakerStatus(): Promise<{
  state: CircuitState;
  failureCount: number;
  lastFailureTime: number;
  lastStateChange: number;
  timeUntilRecovery?: number;
}> {
  const currentState = await getCircuitState();
  const now = Date.now();
  const config = DEFAULT_CONFIG;

  const result = {
    ...currentState,
    timeUntilRecovery: undefined as number | undefined,
  };

  if (currentState.state === 'open') {
    const timeSinceOpen = now - currentState.lastStateChange;
    const remaining = config.recoveryTimeout - timeSinceOpen;
    result.timeUntilRecovery = remaining > 0 ? remaining : 0;
  }

  return result;
}

/**
 * Manually reset the circuit breaker (admin function)
 */
export async function resetCircuitBreaker(): Promise<void> {
  console.log('🔧 Circuit breaker: Manual reset requested');
  await updateCircuitState('closed', 0, 0);
  console.log('✅ Circuit breaker: Reset to closed state');
}

/**
 * Get remaining time until circuit can be retried
 */
export async function getRetryAfter(): Promise<number | null> {
  const currentState = await getCircuitState();
  const now = Date.now();
  const config = DEFAULT_CONFIG;

  if (currentState.state === 'open') {
    const timeSinceOpen = now - currentState.lastStateChange;
    const remaining = config.recoveryTimeout - timeSinceOpen;
    return remaining > 0 ? remaining : 0;
  }

  return null;
}
