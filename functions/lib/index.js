"use strict";
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
exports.triggerFootballSync = exports.scheduledSyncFootball = exports.getCalendar = void 0;
const admin = __importStar(require("firebase-admin"));
const functions = __importStar(require("firebase-functions/v1"));
// Initialize Firebase Admin SDK (singleton)
admin.initializeApp();
// ── HTTPS Functions ───────────────────────────────────────────────────────────
var getCalendar_1 = require("./functions/getCalendar");
Object.defineProperty(exports, "getCalendar", { enumerable: true, get: function () { return getCalendar_1.getCalendar; } });
// ── Scheduled Functions ───────────────────────────────────────────────────────
const syncFootball_1 = require("./pipelines/syncFootball");
/** Sync football fixtures every 6 hours. */
exports.scheduledSyncFootball = functions
    .region("asia-northeast1")
    .pubsub.schedule("every 6 hours")
    .timeZone("Asia/Tokyo")
    .onRun(async (_context) => {
    const apiSportsKey = functions.config().apisports?.key;
    if (!apiSportsKey) {
        console.error("API_SPORTS_KEY not configured. Run: firebase functions:config:set apisports.key=YOUR_KEY");
        return;
    }
    await (0, syncFootball_1.syncFootballFixtures)(apiSportsKey);
});
/** Manual trigger for football sync (HTTPS callable — for testing/admin use). */
exports.triggerFootballSync = functions
    .region("asia-northeast1")
    .https.onCall(async (_data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError("unauthenticated", "Authentication required");
    }
    const apiSportsKey = functions.config().apisports?.key;
    if (!apiSportsKey) {
        throw new functions.https.HttpsError("failed-precondition", "API-SPORTS key not configured");
    }
    await (0, syncFootball_1.syncFootballFixtures)(apiSportsKey);
    return { success: true };
});
//# sourceMappingURL=index.js.map