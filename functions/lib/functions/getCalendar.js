"use strict";
/**
 * getCalendar.ts
 *
 * HTTP Cloud Function (v1 API) that generates a dynamic .ics (iCalendar) file
 * for a user's followed teams.
 *
 * URL: https://asia-northeast1-sports-calendar-sync-a4564.cloudfunctions.net/getCalendar
 * Query params:
 *   - uid: Firebase user ID (required)
 *   - teamId: (optional) restrict to a single team
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
exports.getCalendar = void 0;
const functions = __importStar(require("firebase-functions/v1"));
const firestore_1 = require("firebase-admin/firestore");
const ical_generator_1 = __importStar(require("ical-generator"));
const luxon_1 = require("luxon");
exports.getCalendar = functions
    .region("asia-northeast1")
    .https.onRequest(async (req, res) => {
    const uid = req.query.uid;
    const teamId = req.query.teamId;
    if (!uid) {
        res.status(400).send("Missing required query parameter: uid");
        return;
    }
    const db = (0, firestore_1.getFirestore)();
    // 1. Load user profile to get followed team IDs
    const userDoc = await db.collection("users").doc(uid).get();
    if (!userDoc.exists) {
        res.status(404).send("User not found");
        return;
    }
    const userData = userDoc.data();
    const followedTeamIds = userData.followedTeamIds ?? [];
    const favoriteTeamIds = userData.favoriteTeamIdsByCompetition ?
        Object.values(userData.favoriteTeamIdsByCompetition).flat() :
        [];
    let teamIds = Array.from(new Set(followedTeamIds.length > 0 ? followedTeamIds : favoriteTeamIds));
    // If a specific teamId is requested, filter to just that team
    if (teamId) {
        if (!teamIds.includes(teamId)) {
            res.status(403).send("Team not in user's followed list");
            return;
        }
        teamIds = [teamId];
    }
    if (teamIds.length === 0) {
        const cal = (0, ical_generator_1.default)({ name: "スポーツカレンダー" });
        res.setHeader("Content-Type", "text/calendar; charset=utf-8");
        res.setHeader("Content-Disposition", 'attachment; filename="sports_calendar.ics"');
        res.send(cal.toString());
        return;
    }
    // 2. Fetch upcoming games for all followed teams
    const now = new Date();
    const gamesMap = new Map();
    const chunkSize = 10;
    for (let i = 0; i < teamIds.length; i += chunkSize) {
        const chunk = teamIds.slice(i, i + chunkSize);
        const [homeSnap, awaySnap] = await Promise.all([
            db
                .collection("games")
                .where("homeTeamId", "in", chunk)
                .where("startTimeUTC", ">=", now)
                .orderBy("startTimeUTC")
                .limit(100)
                .get(),
            db
                .collection("games")
                .where("awayTeamId", "in", chunk)
                .where("startTimeUTC", ">=", now)
                .orderBy("startTimeUTC")
                .limit(100)
                .get(),
        ]);
        homeSnap.forEach((doc) => gamesMap.set(doc.id, doc.data()));
        awaySnap.forEach((doc) => gamesMap.set(doc.id, doc.data()));
    }
    // 3. Build iCalendar
    const cal = (0, ical_generator_1.default)({
        name: "スポーツカレンダー",
        description: "フォロー中チームの試合日程",
        method: ical_generator_1.ICalCalendarMethod.PUBLISH,
        prodId: {
            company: "sports-calendar-sync",
            product: "sports-calendar-sync",
            language: "JA",
        },
    });
    for (const [gameId, game] of gamesMap) {
        const startUtc = game.startTimeUTC.toDate();
        const endUtc = new Date(startUtc.getTime() + 2 * 60 * 60 * 1000);
        const broadcastLines = game.broadcastPlatforms.length > 0
            ? `\n📺 視聴: ${game.broadcastPlatforms.map((b) => b.platform).join(" / ")}`
            : "";
        const jstString = luxon_1.DateTime.fromJSDate(startUtc, { zone: "utc" })
            .setZone("Asia/Tokyo")
            .toFormat("M月d日 HH:mm");
        cal.createEvent({
            id: gameId,
            summary: `${game.homeTeamNameJa} vs ${game.awayTeamNameJa}`,
            description: `${jstString} (JST)${broadcastLines}`,
            location: game.venue,
            start: startUtc,
            end: endUtc,
            timezone: "UTC",
        });
    }
    // 4. Return .ics response
    res.setHeader("Content-Type", "text/calendar; charset=utf-8");
    res.setHeader("Content-Disposition", 'attachment; filename="sports_calendar.ics"');
    res.setHeader("Cache-Control", "public, max-age=3600");
    res.send(cal.toString());
});
//# sourceMappingURL=getCalendar.js.map