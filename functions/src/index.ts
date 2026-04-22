/**
 * Cloud Functions entry point.
 *
 * Functions exported here:
 *
 * 1. getCalendar (HTTPS)
 *    - Generates a dynamic .ics file for a user's followed teams
 *
 * 2. scheduledSyncFootball (Scheduled, every 6 hours)
 *    - Fetches football fixtures from RapidAPI
 *    - Normalizes timezone, applies translation map, upserts to Firestore
 *
 * Environment variables:
 *   firebase functions:config:set apisports.key=YOUR_KEY
 */

import * as admin from "firebase-admin";
import * as functions from "firebase-functions/v1";

// Initialize Firebase Admin SDK (singleton)
admin.initializeApp();

// ── HTTPS Functions ───────────────────────────────────────────────────────────

export { getCalendar } from "./functions/getCalendar";

// ── Scheduled Functions ───────────────────────────────────────────────────────

import { syncFootballFixtures } from "./pipelines/syncFootball";

/** Sync football fixtures every 6 hours. */
export const scheduledSyncFootball = functions
  .region("asia-northeast1")
  .pubsub.schedule("every 6 hours")
  .timeZone("Asia/Tokyo")
  .onRun(async (_context: unknown) => {
    const apiSportsKey = functions.config().apisports?.key as string | undefined;
    if (!apiSportsKey) {
      console.error(
        "API_SPORTS_KEY not configured. Run: firebase functions:config:set apisports.key=YOUR_KEY"
      );
      return;
    }
    await syncFootballFixtures(apiSportsKey);
  });

/** Manual trigger for football sync (HTTPS callable — for testing/admin use). */
export const triggerFootballSync = functions
  .region("asia-northeast1")
  .https.onCall(
    async (_data: unknown, context: functions.https.CallableContext) => {
      if (!context.auth) {
        throw new functions.https.HttpsError(
          "unauthenticated",
          "Authentication required"
        );
      }

      const apiSportsKey = functions.config().apisports?.key as
        | string
        | undefined;
      if (!apiSportsKey) {
        throw new functions.https.HttpsError(
          "failed-precondition",
          "API-SPORTS key not configured"
        );
      }

      await syncFootballFixtures(apiSportsKey);
      return { success: true };
    }
  );
