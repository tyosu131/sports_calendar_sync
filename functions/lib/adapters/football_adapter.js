"use strict";
/**
 * football_adapter.ts
 *
 * Adapter layer: API-SPORTS football API response → Firestore GameDoc.
 *
 * ## Responsibility
 * This file is the single conversion point between the external API shape
 * (RapidApiFootballFixture) and the domain model (GameDoc).  Changes to the
 * API response format should be handled here only.
 *
 * ## Phase 0 status
 * The function is defined here as a placeholder.  syncFootball.ts still
 * performs its own inline conversion.  Phase 1 will move that logic here.
 *
 * TODO (Phase 1): migrate fixtureToGameDoc from syncFootball.ts to this file.
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.adaptFootballFixtureToGameDoc = adaptFootballFixtureToGameDoc;
const firestore_1 = require("firebase-admin/firestore");
const timezone_1 = require("../utils/timezone");
/**
 * Converts a single API-SPORTS football fixture to a Firestore GameDoc.
 *
 * @param fixture       - One element from the API-SPORTS /fixtures response.
 * @param competitionKey - SportsRegistry competition key, e.g. "football_j1".
 * @param leagueDocId   - Firestore /leagues/{id} document ID.
 * @param homeTeamDocId - Firestore /teams/{id} document ID for the home team.
 * @param awayTeamDocId - Firestore /teams/{id} document ID for the away team.
 * @param homeTeamNameJa - Japanese team name (from translation map or Firestore).
 * @param awayTeamNameJa - Japanese team name.
 */
function adaptFootballFixtureToGameDoc(fixture, competitionKey, leagueDocId, homeTeamDocId, awayTeamDocId, homeTeamNameJa, awayTeamNameJa) {
    const utcDate = (0, timezone_1.toUtcDate)(fixture.fixture.date);
    return {
        competitionKey,
        // Legacy alias — written so existing queries on `sportKey` still work.
        sportKey: competitionKey,
        leagueId: leagueDocId,
        homeTeamId: homeTeamDocId,
        homeTeamNameJa,
        homeTeamNameEn: fixture.teams.home.name,
        homeTeamLogoUrl: fixture.teams.home.logo || undefined,
        awayTeamId: awayTeamDocId,
        awayTeamNameJa,
        awayTeamNameEn: fixture.teams.away.name,
        awayTeamLogoUrl: fixture.teams.away.logo || undefined,
        startTimeUTC: firestore_1.Timestamp.fromDate(utcDate),
        startTimeJST: (0, timezone_1.toJstStorageString)(fixture.fixture.date),
        timezone: fixture.fixture.timezone ?? "UTC",
        status: (0, timezone_1.mapFootballStatus)(fixture.fixture.status.short),
        venue: fixture.fixture.venue?.name,
        homeScore: fixture.goals.home ?? undefined,
        awayScore: fixture.goals.away ?? undefined,
        broadcastPlatforms: [],
        externalFixtureId: fixture.fixture.id,
        // Legacy alias.
        rapidApiFixtureId: fixture.fixture.id,
    };
}
//# sourceMappingURL=football_adapter.js.map