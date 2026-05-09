/**
 * Scheduled Firebase Functions
 *
 * This module exports all scheduled (cron) functions that run on a timer.
 * Functions are organized by purpose and include comprehensive logging
 * and error handling.
 *
 * Scheduled Functions:
 * - cleanupOldCounters: Daily cleanup of old rate limit counter documents
 * - refreshRemoteConfig: Every 5 minutes, fetches latest Remote Config
 */

export { cleanupOldCounters } from "./cleanupOldCounters";
export { refreshRemoteConfig } from "./refreshRemoteConfig";
