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

import { createGoogleCalendarHandlers, syncAllActiveGoogleCalendars, syncService } from "./functions/googleCalendarConnection";
const GOOGLE_CALENDAR_OAUTH_CLIENT_ID = defineSecret("GOOGLE_CALENDAR_OAUTH_CLIENT_ID");
const GOOGLE_CALENDAR_OAUTH_CLIENT_SECRET = defineSecret("GOOGLE_CALENDAR_OAUTH_CLIENT_SECRET");
const GOOGLE_CALENDAR_TOKEN_ENCRYPTION_KEY = defineSecret("GOOGLE_CALENDAR_TOKEN_ENCRYPTION_KEY");
const GOOGLE_CALENDAR_OAUTH_REDIRECT_URI = defineSecret("GOOGLE_CALENDAR_OAUTH_REDIRECT_URI");
const calendarSecrets = [GOOGLE_CALENDAR_OAUTH_CLIENT_ID, GOOGLE_CALENDAR_OAUTH_CLIENT_SECRET,
  GOOGLE_CALENDAR_TOKEN_ENCRYPTION_KEY, GOOGLE_CALENDAR_OAUTH_REDIRECT_URI];
function googleHandlers() {
  return createGoogleCalendarHandlers({
    clientId: GOOGLE_CALENDAR_OAUTH_CLIENT_ID.value(),
    clientSecret: GOOGLE_CALENDAR_OAUTH_CLIENT_SECRET.value(),
    encryptionKey: GOOGLE_CALENDAR_TOKEN_ENCRYPTION_KEY.value(),
    redirectUri: GOOGLE_CALENDAR_OAUTH_REDIRECT_URI.value(),
  });
}
export const beginGoogleCalendarConnection = functions.runWith({secrets: calendarSecrets})
  .region("asia-northeast1").https.onCall((data, context) => googleHandlers().begin(data, context));
export const getGoogleCalendarConnectionStatus = functions.runWith({secrets: calendarSecrets})
  .region("asia-northeast1").https.onCall((data, context) => googleHandlers().status(data, context));
export const disconnectGoogleCalendar = functions.runWith({secrets: calendarSecrets})
  .region("asia-northeast1").https.onCall((data, context) => googleHandlers().disconnect(data, context));
export const googleCalendarOAuthCallback = functions.runWith({secrets: calendarSecrets})
  .region("asia-northeast1").https.onRequest((request, response) => googleHandlers().callback(request, response));
export const syncGoogleCalendarNow = functions.runWith({secrets: calendarSecrets})
  .region("asia-northeast1").https.onCall((data, context) => googleHandlers().sync(data, context));

/** Follow changes are decoupled from the client write; a provider failure cannot undo it. */
export const syncGoogleCalendarOnFollowChange = functions.runWith({secrets: calendarSecrets})
  .region("asia-northeast1").firestore.document("users/{uid}").onUpdate(async (change, context) => {
    const before = change.before.get("followedTeamIds");
    const after = change.after.get("followedTeamIds");
    if (JSON.stringify(before ?? []) === JSON.stringify(after ?? [])) return;
    try { await syncService({clientId: GOOGLE_CALENDAR_OAUTH_CLIENT_ID.value(), clientSecret: GOOGLE_CALENDAR_OAUTH_CLIENT_SECRET.value(),
      encryptionKey: GOOGLE_CALENDAR_TOKEN_ENCRYPTION_KEY.value(), redirectUri: GOOGLE_CALENDAR_OAUTH_REDIRECT_URI.value()}).sync(context.params.uid); }
    catch (error) { console.warn("Follow-change Google Calendar reconciliation failed", {uid: context.params.uid}); }
  });

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
  .runWith({ secrets: [GOAL_API_KEY, ...calendarSecrets] })
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
    // Canonical ingestion remains successful even when individual Google users fail.
    try { await syncAllActiveGoogleCalendars({clientId: GOOGLE_CALENDAR_OAUTH_CLIENT_ID.value(), clientSecret: GOOGLE_CALENDAR_OAUTH_CLIENT_SECRET.value(),
      encryptionKey: GOOGLE_CALENDAR_TOKEN_ENCRYPTION_KEY.value(), redirectUri: GOOGLE_CALENDAR_OAUTH_REDIRECT_URI.value()}); }
    catch (_) { console.warn("Canonical sync succeeded; Google Calendar batch could not start"); }
  });

/** Manual trigger for football sync (HTTPS callable — for testing/admin use). */
export const triggerFootballSync = functions
  .runWith({ secrets: [GOAL_API_KEY, ...calendarSecrets] })
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
      try { await syncAllActiveGoogleCalendars({clientId: GOOGLE_CALENDAR_OAUTH_CLIENT_ID.value(), clientSecret: GOOGLE_CALENDAR_OAUTH_CLIENT_SECRET.value(),
        encryptionKey: GOOGLE_CALENDAR_TOKEN_ENCRYPTION_KEY.value(), redirectUri: GOOGLE_CALENDAR_OAUTH_REDIRECT_URI.value()}); }
      catch (_) { console.warn("Canonical sync succeeded; Google Calendar batch could not start"); }
      return { success: true };
    }
  );
