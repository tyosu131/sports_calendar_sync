"use strict";
/**
 * syncFootball.ts
 *
 * Pipeline: API-SPORTS (API-Football v3) → timezone normalization → translation → Firestore
 *
 * Triggered by: Cloud Scheduler (e.g. every 6 hours)
 * Entry point: exported `syncFootballFixtures` function
 *
 * Flow:
 *   1. Read all football leagues from Firestore (those with rapidApiId set)
 *   2. For each league, fetch fixtures from API-SPORTS for the next 30 days
 *   3. Normalize timezone: store UTC Timestamp + JST string
 *   4. Apply translation map: English team/league names → Japanese
 *   5. Upsert into /games/{fixtureId} in Firestore
 */
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.syncFootballFixtures = syncFootballFixtures;
const axios_1 = __importDefault(require("axios"));
const firestore_1 = require("firebase-admin/firestore");
const timezone_1 = require("../utils/timezone");
const translation_1 = require("../utils/translation");
const RAPID_API_HOST = "v3.football.api-sports.io";
const RAPID_API_BASE = `https://${RAPID_API_HOST}`;
/**
 * Fetch football fixtures for a league from API-SPORTS (direct contract).
 * Base URL: https://v3.football.api-sports.io/
 * Auth header: x-apisports-key
 */
async function fetchFixtures(leagueId, season, rapidApiKey) {
    const today = new Date().toISOString().split("T")[0];
    const future = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000)
        .toISOString()
        .split("T")[0];
    const response = await axios_1.default.get(`${RAPID_API_BASE}/fixtures`, {
        headers: {
            "x-apisports-key": rapidApiKey,
        },
        params: {
            league: leagueId,
            season,
            from: today,
            to: future,
            timezone: "UTC",
        },
    });
    return response.data.response;
}
/**
 * Convert an API-SPORTS fixture to a Firestore GameDoc.
 */
function fixtureToGameDoc(fixture, leagueDocId, homeTeamDocId, awayTeamDocId, homeTeamNameJa, awayTeamNameJa) {
    const utcDate = (0, timezone_1.toUtcDate)(fixture.fixture.date);
    return {
        leagueId: leagueDocId,
        homeTeamId: homeTeamDocId,
        homeTeamNameJa,
        awayTeamId: awayTeamDocId,
        awayTeamNameJa,
        startTimeUTC: firestore_1.Timestamp.fromDate(utcDate),
        startTimeJST: (0, timezone_1.toJstStorageString)(fixture.fixture.date),
        timezone: fixture.fixture.timezone ?? "UTC",
        status: (0, timezone_1.mapFootballStatus)(fixture.fixture.status.short),
        venue: fixture.fixture.venue?.name,
        homeScore: fixture.goals.home ?? undefined,
        awayScore: fixture.goals.away ?? undefined,
        broadcastPlatforms: [], // Populated separately via broadcast mapping
        rapidApiFixtureId: fixture.fixture.id,
    };
}
/**
 * Main sync pipeline for football.
 * Call this from a scheduled Cloud Function.
 */
async function syncFootballFixtures(rapidApiKey) {
    const db = (0, firestore_1.getFirestore)();
    const currentSeason = new Date().getFullYear();
    // 1. Load all football leagues with a rapidApiId
    const leaguesSnap = await db
        .collection("leagues")
        .where("sportType", "==", "football")
        .get();
    if (leaguesSnap.empty) {
        console.log("No football leagues found in Firestore.");
        return;
    }
    // 2. Load translation map for football
    const translationMap = await (0, translation_1.getTranslationMap)("football");
    // 3. Load all football teams (for ID mapping: rapidApiId → docId)
    const teamsSnap = await db
        .collection("teams")
        .where("sportType", "==", "football")
        .get();
    const teamByRapidId = new Map();
    teamsSnap.forEach((doc) => {
        const data = doc.data();
        if (data.rapidApiId) {
            teamByRapidId.set(data.rapidApiId, {
                docId: doc.id,
                nameJa: data.nameJa,
            });
        }
    });
    // 4. For each league, fetch and upsert fixtures
    const batch = db.batch();
    let batchCount = 0;
    const MAX_BATCH = 400; // Firestore batch limit is 500
    for (const leagueDoc of leaguesSnap.docs) {
        const leagueData = leagueDoc.data();
        if (!leagueData.rapidApiId)
            continue;
        console.log(`Fetching fixtures for league: ${leagueData.nameEn}`);
        let fixtures;
        try {
            fixtures = await fetchFixtures(leagueData.rapidApiId, currentSeason, rapidApiKey);
        }
        catch (err) {
            console.error(`Failed to fetch fixtures for ${leagueData.nameEn}:`, err);
            continue;
        }
        for (const fixture of fixtures) {
            const homeRapidId = fixture.teams.home.id;
            const awayRapidId = fixture.teams.away.id;
            // Resolve team doc IDs (fall back to creating a placeholder key)
            const homeTeam = teamByRapidId.get(homeRapidId);
            const awayTeam = teamByRapidId.get(awayRapidId);
            const homeTeamDocId = homeTeam?.docId ?? `football_team_${homeRapidId}`;
            const awayTeamDocId = awayTeam?.docId ?? `football_team_${awayRapidId}`;
            // Apply translation (fall back to English name)
            const homeTeamNameJa = homeTeam?.nameJa ??
                (0, translation_1.translateTeamName)(translationMap, fixture.teams.home.name);
            const awayTeamNameJa = awayTeam?.nameJa ??
                (0, translation_1.translateTeamName)(translationMap, fixture.teams.away.name);
            const gameDoc = fixtureToGameDoc(fixture, leagueDoc.id, homeTeamDocId, awayTeamDocId, homeTeamNameJa, awayTeamNameJa);
            const gameRef = db
                .collection("games")
                .doc(`football_${fixture.fixture.id}`);
            batch.set(gameRef, gameDoc, { merge: true });
            batchCount++;
            // Commit in chunks to avoid hitting the 500-write limit
            if (batchCount >= MAX_BATCH) {
                await batch.commit();
                batchCount = 0;
            }
        }
    }
    if (batchCount > 0) {
        await batch.commit();
    }
    console.log("Football sync complete.");
}
//# sourceMappingURL=syncFootball.js.map