"use strict";
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
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.triggerFootballSync = exports.scheduledSyncFootball = exports.syncGoogleCalendarOnFollowChange = exports.syncGoogleCalendarNow = exports.googleCalendarOAuthCallback = exports.disconnectGoogleCalendar = exports.getGoogleCalendarConnectionStatus = exports.beginGoogleCalendarConnection = exports.rotateCalendarFeed = exports.ensureCalendarFeed = exports.getCalendar = void 0;
const admin = __importStar(require("firebase-admin"));
const functions = __importStar(require("firebase-functions/v1"));
const params_1 = require("firebase-functions/params");
// Initialize Firebase Admin SDK (singleton)
admin.initializeApp();
// ── HTTPS Functions ───────────────────────────────────────────────────────────
var getCalendar_1 = require("./functions/getCalendar");
Object.defineProperty(exports, "getCalendar", { enumerable: true, get: function () { return getCalendar_1.getCalendar; } });
var calendarFeeds_1 = require("./functions/calendarFeeds");
Object.defineProperty(exports, "ensureCalendarFeed", { enumerable: true, get: function () { return calendarFeeds_1.ensureCalendarFeed; } });
Object.defineProperty(exports, "rotateCalendarFeed", { enumerable: true, get: function () { return calendarFeeds_1.rotateCalendarFeed; } });
const googleCalendarConnection_1 = require("./functions/googleCalendarConnection");
const GOOGLE_CALENDAR_OAUTH_CLIENT_ID = (0, params_1.defineSecret)("GOOGLE_CALENDAR_OAUTH_CLIENT_ID");
const GOOGLE_CALENDAR_OAUTH_CLIENT_SECRET = (0, params_1.defineSecret)("GOOGLE_CALENDAR_OAUTH_CLIENT_SECRET");
const GOOGLE_CALENDAR_TOKEN_ENCRYPTION_KEY = (0, params_1.defineSecret)("GOOGLE_CALENDAR_TOKEN_ENCRYPTION_KEY");
const GOOGLE_CALENDAR_OAUTH_REDIRECT_URI = (0, params_1.defineSecret)("GOOGLE_CALENDAR_OAUTH_REDIRECT_URI");
const calendarSecrets = [GOOGLE_CALENDAR_OAUTH_CLIENT_ID, GOOGLE_CALENDAR_OAUTH_CLIENT_SECRET,
    GOOGLE_CALENDAR_TOKEN_ENCRYPTION_KEY, GOOGLE_CALENDAR_OAUTH_REDIRECT_URI];
function googleHandlers() {
    return (0, googleCalendarConnection_1.createGoogleCalendarHandlers)({
        clientId: GOOGLE_CALENDAR_OAUTH_CLIENT_ID.value(),
        clientSecret: GOOGLE_CALENDAR_OAUTH_CLIENT_SECRET.value(),
        encryptionKey: GOOGLE_CALENDAR_TOKEN_ENCRYPTION_KEY.value(),
        redirectUri: GOOGLE_CALENDAR_OAUTH_REDIRECT_URI.value(),
    });
}
exports.beginGoogleCalendarConnection = functions.runWith({ secrets: calendarSecrets })
    .region("asia-northeast1").https.onCall((data, context) => googleHandlers().begin(data, context));
exports.getGoogleCalendarConnectionStatus = functions.runWith({ secrets: calendarSecrets })
    .region("asia-northeast1").https.onCall((data, context) => googleHandlers().status(data, context));
exports.disconnectGoogleCalendar = functions.runWith({ secrets: calendarSecrets })
    .region("asia-northeast1").https.onCall((data, context) => googleHandlers().disconnect(data, context));
exports.googleCalendarOAuthCallback = functions.runWith({ secrets: calendarSecrets })
    .region("asia-northeast1").https.onRequest((request, response) => googleHandlers().callback(request, response));
exports.syncGoogleCalendarNow = functions.runWith({ secrets: calendarSecrets })
    .region("asia-northeast1").https.onCall((data, context) => googleHandlers().sync(data, context));
/** Follow changes are decoupled from the client write; a provider failure cannot undo it. */
exports.syncGoogleCalendarOnFollowChange = functions.runWith({ secrets: calendarSecrets })
    .region("asia-northeast1").firestore.document("users/{uid}").onUpdate(async (change, context) => {
    const before = change.before.get("followedTeamIds");
    const after = change.after.get("followedTeamIds");
    if (JSON.stringify(before ?? []) === JSON.stringify(after ?? []))
        return;
    try {
        await (0, googleCalendarConnection_1.syncService)({ clientId: GOOGLE_CALENDAR_OAUTH_CLIENT_ID.value(), clientSecret: GOOGLE_CALENDAR_OAUTH_CLIENT_SECRET.value(),
            encryptionKey: GOOGLE_CALENDAR_TOKEN_ENCRYPTION_KEY.value(), redirectUri: GOOGLE_CALENDAR_OAUTH_REDIRECT_URI.value() }).sync(context.params.uid);
    }
    catch (error) {
        console.warn("Follow-change Google Calendar reconciliation failed", { uid: context.params.uid });
    }
});
// ── Scheduled Functions ───────────────────────────────────────────────────────
const syncGoalV1_1 = require("./pipelines/syncGoalV1");
const adminAuthorization_1 = require("./functions/adminAuthorization");
const GOAL_API_KEY = (0, params_1.defineSecret)("GOAL_API_KEY");
function getGoalApiKey() {
    const value = GOAL_API_KEY.value();
    const trimmed = typeof value === "string" ? value.trim() : "";
    return trimmed.length > 0 ? trimmed : undefined;
}
/** Sync football fixtures every 6 hours. */
exports.scheduledSyncFootball = functions
    .runWith({ secrets: [GOAL_API_KEY, ...calendarSecrets] })
    .region("asia-northeast1")
    .pubsub.schedule("every 6 hours")
    .timeZone("Asia/Tokyo")
    .onRun(async (_context) => {
    const goalApiKey = getGoalApiKey();
    if (!goalApiKey) {
        console.error("GOAL_API_KEY secret is not configured for scheduledSyncFootball.");
        return;
    }
    await (0, syncGoalV1_1.syncGoalV1Fixtures)(goalApiKey);
    // Canonical ingestion remains successful even when individual Google users fail.
    try {
        await (0, googleCalendarConnection_1.syncAllActiveGoogleCalendars)({ clientId: GOOGLE_CALENDAR_OAUTH_CLIENT_ID.value(), clientSecret: GOOGLE_CALENDAR_OAUTH_CLIENT_SECRET.value(),
            encryptionKey: GOOGLE_CALENDAR_TOKEN_ENCRYPTION_KEY.value(), redirectUri: GOOGLE_CALENDAR_OAUTH_REDIRECT_URI.value() });
    }
    catch (_) {
        console.warn("Canonical sync succeeded; Google Calendar batch could not start");
    }
});
/** Manual trigger for football sync (HTTPS callable — for testing/admin use). */
exports.triggerFootballSync = functions
    .runWith({ secrets: [GOAL_API_KEY, ...calendarSecrets] })
    .region("asia-northeast1")
    .https.onCall(async (_data, context) => {
    (0, adminAuthorization_1.requireAdmin)(context);
    const goalApiKey = getGoalApiKey();
    if (!goalApiKey) {
        throw new functions.https.HttpsError("failed-precondition", "GOAL API key not configured");
    }
    await (0, syncGoalV1_1.syncGoalV1Fixtures)(goalApiKey);
    try {
        await (0, googleCalendarConnection_1.syncAllActiveGoogleCalendars)({ clientId: GOOGLE_CALENDAR_OAUTH_CLIENT_ID.value(), clientSecret: GOOGLE_CALENDAR_OAUTH_CLIENT_SECRET.value(),
            encryptionKey: GOOGLE_CALENDAR_TOKEN_ENCRYPTION_KEY.value(), redirectUri: GOOGLE_CALENDAR_OAUTH_REDIRECT_URI.value() });
    }
    catch (_) {
        console.warn("Canonical sync succeeded; Google Calendar batch could not start");
    }
    return { success: true };
});
//# sourceMappingURL=index.js.map