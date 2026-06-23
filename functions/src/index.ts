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
 * Secrets:
 *   API_SPORTS_KEY (Firebase Functions secret / Secret Manager)
 */

import * as admin from "firebase-admin";
import * as functions from "firebase-functions/v1";
import { defineSecret } from "firebase-functions/params";

// Initialize Firebase Admin SDK (singleton)
admin.initializeApp();

// ── HTTPS Functions ───────────────────────────────────────────────────────────

export { getCalendar } from "./functions/getCalendar";

// ── Scheduled Functions ───────────────────────────────────────────────────────

import { syncFootballFixtures } from "./pipelines/syncFootball";

const API_SPORTS_KEY = defineSecret("API_SPORTS_KEY");

function getApiSportsKey(): string | undefined {
  const value = API_SPORTS_KEY.value();
  const trimmed = typeof value === "string" ? value.trim() : "";
  return trimmed.length > 0 ? trimmed : undefined;
}

/** Sync football fixtures every 6 hours. */
export const scheduledSyncFootball = functions
  .runWith({ secrets: [API_SPORTS_KEY] })
  .region("asia-northeast1")
  .pubsub.schedule("every 6 hours")
  .timeZone("Asia/Tokyo")
  .onRun(async (_context: unknown) => {
    const apiSportsKey = getApiSportsKey();
    if (!apiSportsKey) {
      console.error(
        "API_SPORTS_KEY secret is not configured for scheduledSyncFootball."
      );
      return;
    }
    await syncFootballFixtures(apiSportsKey);
  });

/** Manual trigger for football sync (HTTPS callable — for testing/admin use). */
export const triggerFootballSync = functions
  .runWith({ secrets: [API_SPORTS_KEY] })
  .region("asia-northeast1")
  .https.onCall(
    async (_data: unknown, context: functions.https.CallableContext) => {
      if (!context.auth) {
        throw new functions.https.HttpsError(
          "unauthenticated",
          "Authentication required"
        );
      }

      const apiSportsKey = getApiSportsKey();
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
