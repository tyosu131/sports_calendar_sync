/**
 * Cloud Functions entry point.
 *
 * Functions exported here:
 *
 * 1. getCalendar (HTTPS)
 *    - Resolves a revocable feed token and generates a dynamic .ics file for
 *      its owner's followed teams
 *
 * 2. scheduledSyncFootball (Scheduled, every 6 hours)
 *    - Fetches and persists approved V1 football fixtures from GOAL
 *    - Normalizes timezone, applies translation map, upserts to Firestore
 *
 * Secrets:
 *   GOAL_API_KEY (Firebase Functions secret / Secret Manager)
 */

import * as admin from "firebase-admin";
import * as functions from "firebase-functions/v1";
import { defineSecret } from "firebase-functions/params";

// Initialize Firebase Admin SDK (singleton)
admin.initializeApp();

// ── HTTPS Functions ───────────────────────────────────────────────────────────

export { getCalendar } from "./functions/getCalendar";
export { ensureCalendarFeed, rotateCalendarFeed } from "./functions/calendarFeeds";

// ── Scheduled Functions ───────────────────────────────────────────────────────

import { syncGoalV1Fixtures } from "./pipelines/syncGoalV1";
import { requireAdmin } from "./functions/adminAuthorization";

const GOAL_API_KEY = defineSecret("GOAL_API_KEY");

function getGoalApiKey(): string | undefined {
  const value = GOAL_API_KEY.value();
  const trimmed = typeof value === "string" ? value.trim() : "";
  return trimmed.length > 0 ? trimmed : undefined;
}

/** Sync football fixtures every 6 hours. */
export const scheduledSyncFootball = functions
  .runWith({ secrets: [GOAL_API_KEY] })
  .region("asia-northeast1")
  .pubsub.schedule("every 6 hours")
  .timeZone("Asia/Tokyo")
  .onRun(async (_context: unknown) => {
    const goalApiKey = getGoalApiKey();
    if (!goalApiKey) {
      console.error(
        "GOAL_API_KEY secret is not configured for scheduledSyncFootball."
      );
      return;
    }
    await syncGoalV1Fixtures(goalApiKey);
  });

/** Manual trigger for football sync (HTTPS callable — for testing/admin use). */
export const triggerFootballSync = functions
  .runWith({ secrets: [GOAL_API_KEY] })
  .region("asia-northeast1")
  .https.onCall(
    async (_data: unknown, context: functions.https.CallableContext) => {
      requireAdmin(context);

      const goalApiKey = getGoalApiKey();
      if (!goalApiKey) {
        throw new functions.https.HttpsError(
          "failed-precondition",
          "GOAL API key not configured"
        );
      }

      await syncGoalV1Fixtures(goalApiKey);
      return { success: true };
    }
  );
