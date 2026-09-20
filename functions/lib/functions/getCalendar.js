"use strict";
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
exports.getCalendar = exports.FirestorePersonalizedCalendarRepository = exports.CALENDAR_LOOKBACK_DAYS = void 0;
exports.calendarWindowStart = calendarWindowStart;
exports.asNormalizedGame = asNormalizedGame;
exports.serveCalendar = serveCalendar;
const functions = __importStar(require("firebase-functions/v1"));
const firestore_1 = require("firebase-admin/firestore");
const personalizedCalendar_1 = require("../calendar/personalizedCalendar");
const teamDisplayNamePolicy_1 = require("../domain/teamDisplayNamePolicy");
const competitionDisplayPolicy_1 = require("../domain/competitionDisplayPolicy");
const VALID_STATUSES = new Set([
    "scheduled", "live", "finished", "postponed", "cancelled",
]);
exports.CALENDAR_LOOKBACK_DAYS = 30;
/** Deterministic lower bound used by calendar retrieval queries. */
function calendarWindowStart(now) {
    return new Date(now.getTime() - exports.CALENDAR_LOOKBACK_DAYS * 24 * 60 * 60 * 1000);
}
/** Validates a Firestore Game document at the Calendar domain boundary. */
function asNormalizedGame(id, data) {
    const kickoff = data.startTimeUTC;
    if (!(kickoff instanceof firestore_1.Timestamp))
        throw new Error(`Game ${id} has invalid startTimeUTC`);
    const hasHomeTeamId = Object.prototype.hasOwnProperty.call(data, "homeTeamId");
    const hasAwayTeamId = Object.prototype.hasOwnProperty.call(data, "awayTeamId");
    const validOptionalTeamId = (present, value) => !present || (typeof value === "string" && value.trim().length > 0);
    if (!validOptionalTeamId(hasHomeTeamId, data.homeTeamId) ||
        !validOptionalTeamId(hasAwayTeamId, data.awayTeamId) ||
        (!hasHomeTeamId && !hasAwayTeamId)) {
        throw new Error(`Game ${id} has invalid team identity`);
    }
    if (typeof data.homeTeamNameJa !== "string" || typeof data.awayTeamNameJa !== "string") {
        throw new Error(`Game ${id} has invalid team names`);
    }
    if (!VALID_STATUSES.has(data.status))
        throw new Error(`Game ${id} has invalid status`);
    const competitionKey = data.competitionKey ?? data.sportKey;
    const competitionCompact = (0, competitionDisplayPolicy_1.compactCompetitionDisplayName)(competitionKey);
    const hasHomeScore = Object.prototype.hasOwnProperty.call(data, "homeScore");
    const hasAwayScore = Object.prototype.hasOwnProperty.call(data, "awayScore");
    const validScore = (value) => typeof value === "number" && Number.isInteger(value) && value >= 0;
    if (hasHomeScore !== hasAwayScore ||
        (hasHomeScore && (!validScore(data.homeScore) || !validScore(data.awayScore)))) {
        throw new Error(`Game ${id} has invalid scores`);
    }
    return {
        id,
        kickoffUtc: kickoff.toDate(),
        ...(hasHomeTeamId ? { homeTeamId: data.homeTeamId } : {}),
        ...(hasAwayTeamId ? { awayTeamId: data.awayTeamId } : {}),
        homeTeamName: (0, teamDisplayNamePolicy_1.displayTeamName)(competitionKey, {
            japanese: data.homeTeamNameJa,
            english: data.homeTeamNameEn,
            provider: data.homeTeamProviderName,
        }, undefined, hasHomeTeamId ? data.homeTeamId : undefined),
        awayTeamName: (0, teamDisplayNamePolicy_1.displayTeamName)(competitionKey, {
            japanese: data.awayTeamNameJa,
            english: data.awayTeamNameEn,
            provider: data.awayTeamProviderName,
        }, undefined, hasAwayTeamId ? data.awayTeamId : undefined),
        ...(competitionCompact ? { competitionCompact } : {}),
        status: data.status,
        ...(hasHomeScore ? { homeScore: data.homeScore, awayScore: data.awayScore } : {}),
        venue: typeof data.venue === "string" ? data.venue : undefined,
        broadcastPlatforms: Array.isArray(data.broadcastPlatforms) ?
            data.broadcastPlatforms.filter((item) => typeof item === "object" && item !== null && typeof item.platform === "string") : [],
    };
}
class FirestorePersonalizedCalendarRepository {
    constructor(db, now = () => new Date()) {
        this.db = db;
        this.now = now;
    }
    async findFeed(token) {
        const snapshot = await this.db.collection("calendarFeeds").doc(token).get();
        if (!snapshot.exists)
            return undefined;
        const ownerUid = snapshot.get("ownerUid");
        if (typeof ownerUid !== "string")
            return undefined;
        return { ownerUid, active: snapshot.get("active") === true };
    }
    async findUser(uid) {
        const snapshot = await this.db.collection("users").doc(uid).get();
        if (!snapshot.exists)
            return undefined;
        const followed = snapshot.get("followedTeamIds");
        return { followedTeamIds: Array.isArray(followed) ? followed.filter((id) => typeof id === "string") : [] };
    }
    async findCalendarGamesForTeams(teamIds) {
        const games = new Map();
        const windowStart = calendarWindowStart(this.now());
        // Firestore `in` accepts at most 30 comparison values. Smaller chunks also
        // keep each home/away query and its response predictably bounded.
        for (let offset = 0; offset < teamIds.length; offset += 10) {
            const chunk = teamIds.slice(offset, offset + 10);
            const query = (field) => this.db.collection("games")
                .where(field, "in", chunk)
                .where("startTimeUTC", ">=", windowStart)
                .orderBy("startTimeUTC")
                .limit(100)
                .get();
            const [home, away] = await Promise.all([query("homeTeamId"), query("awayTeamId")]);
            for (const snapshot of [home, away]) {
                snapshot.forEach((doc) => games.set(doc.id, asNormalizedGame(doc.id, doc.data())));
            }
        }
        return [...games.values()];
    }
}
exports.FirestorePersonalizedCalendarRepository = FirestorePersonalizedCalendarRepository;
async function serveCalendar(req, res, repository) {
    const token = typeof req.query.token === "string" ? req.query.token.trim() : "";
    const teamId = typeof req.query.teamId === "string" ? req.query.teamId.trim() : undefined;
    if (!token) {
        res.status(400).send("Missing required query parameter: token");
        return;
    }
    if (!/^[A-Za-z0-9_-]{43}$/.test(token)) {
        res.status(404).send("Calendar feed not found");
        return;
    }
    try {
        const calendar = await (0, personalizedCalendar_1.buildPersonalizedCalendar)(repository, token, teamId || undefined);
        res.setHeader("Content-Type", "text/calendar; charset=utf-8");
        res.setHeader("Content-Disposition", 'inline; filename="sports_calendar.ics"');
        res.setHeader("Cache-Control", "private, no-store");
        res.send(calendar);
    }
    catch (error) {
        if (error instanceof personalizedCalendar_1.CalendarFeedNotFoundError) {
            res.status(404).send("Calendar feed not found");
        }
        else if (error instanceof personalizedCalendar_1.CalendarUserNotFoundError) {
            res.status(404).send("Calendar owner not found");
        }
        else if (error instanceof personalizedCalendar_1.CalendarTeamNotFollowedError) {
            res.status(403).send("Team is not followed by calendar owner");
        }
        else {
            console.error("Unable to build calendar feed", error);
            res.status(500).send("Unable to build calendar feed");
        }
    }
}
exports.getCalendar = functions.region("asia-northeast1").https.onRequest((req, res) => serveCalendar(req, res, new FirestorePersonalizedCalendarRepository((0, firestore_1.getFirestore)())));
//# sourceMappingURL=getCalendar.js.map