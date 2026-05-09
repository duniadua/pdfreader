/**
 * Firebase Remote Config integration for rate limiting
 * Provides centralized configuration with 1-minute caching
 */

import * as admin from 'firebase-admin';
import { FunctionType, RateLimitConfig } from './types';

// Cache for Remote Config values (1-minute TTL)
let configCache: Map<FunctionType, RateLimitConfig> | null = null;
let cacheTimestamp: number = 0;
const CACHE_TTL = 60 * 1000; // 1 minute

// Default rate limit configuration (used as fallback)
const DEFAULT_RATE_LIMITS: Record<FunctionType, RateLimitConfig> = {
  summarizeFlow: {
    hourlyLimit: 10,
    dailyLimit: 50,
    minRequestInterval: 5000, // 5 seconds
  },
  chatFlow: {
    hourlyLimit: 30,
    dailyLimit: 200,
    minRequestInterval: 2000, // 2 seconds
  },
  extractFlow: {
    hourlyLimit: 15,
    dailyLimit: 75,
    minRequestInterval: 3000, // 3 seconds
  },
};

/**
 * Validate Remote Config template exists
 * This should be called during initialization
 */
export async function initializeRemoteConfig(): Promise<void> {
  try {
    const remoteConfig = admin.remoteConfig();
    const template = await remoteConfig.getTemplate();

    console.log('✅ Remote Config template loaded successfully');
    console.log(`📊 Template version: ${template.version?.versionNumber || 'unknown'}`);

    // Check if rate limit parameters exist
    const groups = template.parameterGroups || {};
    let hasRateLimitParams = false;

    for (const groupKey in groups) {
      const group = groups[groupKey];
      const paramsArray = Object.values(group.parameters || {});
      for (const param of paramsArray) {
        if ((param as any).key?.startsWith('rate_limit_')) {
          hasRateLimitParams = true;
          break;
        }
      }
      if (hasRateLimitParams) break;
    }

    if (!hasRateLimitParams) {
      console.log('ℹ️ Remote Config: No rate limit parameters found, using defaults');
      console.log('ℹ️ To configure: Set up Remote Config parameters in Firebase Console');
    } else {
      console.log('✅ Remote Config: Rate limit parameters found');
    }
  } catch (error: any) {
    console.error('❌ Error initializing Remote Config:', error?.message || error);
    // Don't throw - allow fallback to defaults
  }
}

/**
 * Fetch rate limit configuration for a specific function
 * Uses 1-minute cache to reduce Remote Config fetches
 *
 * @param functionType - The function type to get config for
 * @returns Rate limit configuration
 */
export async function getRateLimits(
  functionType: FunctionType
): Promise<RateLimitConfig> {
  const now = Date.now();

  // Check cache validity
  if (configCache && now - cacheTimestamp < CACHE_TTL) {
    console.log(`✅ Using cached rate limits for ${functionType}`);
    return configCache.get(functionType) || DEFAULT_RATE_LIMITS[functionType];
  }

  try {
    console.log(`🔄 Fetching rate limits from Remote Config for ${functionType}...`);
    const remoteConfig = admin.remoteConfig();
    const template = await remoteConfig.getTemplate();

    // Parse rate limits from template parameters
    const newConfig = new Map<FunctionType, RateLimitConfig>();

    for (const funcType of Object.keys(DEFAULT_RATE_LIMITS) as FunctionType[]) {
      let param: any = null;

      // Search in parameter groups (object, not array)
      const groups = template.parameterGroups || {};
      for (const groupKey in groups) {
        const group = groups[groupKey];
        const paramsArray = Object.values(group.parameters || {});
        for (const p of paramsArray) {
          if ((p as any).key === `rate_limit_${funcType}`) {
            param = p;
            break;
          }
        }
        if (param) break;
      }

      if (param?.defaultValue?.value) {
        try {
          const config = JSON.parse(param.defaultValue.value) as RateLimitConfig;
          newConfig.set(funcType, config);
        } catch (parseError) {
          console.warn(
            `⚠️ Failed to parse rate limit for ${funcType}, using default`
          );
          newConfig.set(funcType, DEFAULT_RATE_LIMITS[funcType]);
        }
      } else {
        newConfig.set(funcType, DEFAULT_RATE_LIMITS[funcType]);
      }
    }

    // Update cache
    configCache = newConfig;
    cacheTimestamp = now;

    console.log(`✅ Rate limits fetched and cached for ${functionType}`);
    return newConfig.get(functionType) || DEFAULT_RATE_LIMITS[functionType];
  } catch (error: any) {
    console.error(
      '❌ Error fetching rate limits from Remote Config:',
      error?.message || error
    );
    console.log(`📋 Using default rate limits for ${functionType}`);
    return DEFAULT_RATE_LIMITS[functionType];
  }
}

/**
 * Check if rate limiting is enabled globally
 *
 * @returns true if rate limiting is enabled
 */
export async function isRateLimitingEnabled(): Promise<boolean> {
  try {
    const remoteConfig = admin.remoteConfig();
    const template = await remoteConfig.getTemplate();

    // Search in parameter groups (object, not array)
    const groups = template.parameterGroups || {};
    for (const groupKey in groups) {
      const group = groups[groupKey];
      const paramsArray = Object.values(group.parameters || {});
      for (const param of paramsArray) {
        const p = param as any;
        if (p.key === 'rate_limit_enabled' && p.defaultValue?.value) {
          return p.defaultValue.value.toLowerCase() === 'true';
        }
      }
    }

    return true; // Default to enabled if parameter not found
  } catch (error: any) {
    console.error(
      '❌ Error checking rate limit enabled status:',
      error?.message || error
    );
    return true; // Default to enabled on error
  }
}

/**
 * Clear the rate limit cache (for testing or manual refresh)
 */
export function clearConfigCache(): void {
  configCache = null;
  cacheTimestamp = 0;
  console.log('🗑️ Rate limit config cache cleared');
}
