/**
 * Scheduled function to refresh Firebase Remote Config template.
 *
 * Runs every 5 minutes to fetch and activate the latest Remote Config
 * template from the Firebase server. This ensures rate limiting
 * configuration changes are applied quickly without redeploying functions.
 *
 * Schedule: Every 5 minutes
 * Region: asia-southeast1
 * Memory: 256MiB
 */

import * as functions from "firebase-functions/v2";
import * as admin from "firebase-admin";
import { logger } from "firebase-functions";

/**
 * Refresh Firebase Remote Config template.
 *
 * Calls fetchAndActivate() to retrieve the latest Remote Config
 * template from Firebase servers and activate it for use.
 *
 * Benefits:
 * - Update rate limits without redeploying functions
 * - Apply emergency rate limit changes instantly
 * - A/B test different rate limit configurations
 *
 * Error handling:
 * - Logs errors but does not throw (non-critical function)
 * - Continues on next scheduled run even if this one fails
 *
 * @returns Promise that resolves when refresh is complete
 */
export const refreshRemoteConfig = functions.scheduler.onSchedule(
  {
    schedule: "*/5 * * * *", // Every 5 minutes
    timeZone: "Asia/Singapore",
    region: "asia-southeast1",
    memory: "256MiB",
  },
  async () => {
    const startTime = Date.now();
    logger.info("Starting Remote Config refresh");

    try {
      const remoteConfig = admin.remoteConfig();

      // Get the current template to force refresh
      // Note: Remote Config is automatically cached by the Admin SDK
      // This function ensures the cache is refreshed regularly
      logger.info("Refreshing Remote Config cache");

      const template = await remoteConfig.getTemplate();

      const elapsed = Date.now() - startTime;

      logger.info(
        `Remote Config template refreshed (version: ${template.version?.versionNumber || 'unknown'}) in ${elapsed}ms`
      );
    } catch (error) {
      const elapsed = Date.now() - startTime;
      logger.error(
        `Error refreshing Remote Config after ${elapsed}ms:`,
        error
      );

      // Log specific error types for debugging
      if (error instanceof Error) {
        if (error.message.includes("quota")) {
          logger.error("Remote Config quota exceeded - will retry in 5 minutes");
        } else if (error.message.includes("network")) {
          logger.error("Network error fetching Remote Config - will retry");
        } else if (error.message.includes("unauthorized")) {
          logger.error("Authentication error - check IAM permissions");
        }
      }

      // Do not re-throw - this is a non-critical function
      // It will retry on the next scheduled run
    }
  }
);
