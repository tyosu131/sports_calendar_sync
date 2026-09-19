"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.UnsupportedGoalStatusError = void 0;
exports.adaptGoalFixtureToGameDoc = adaptGoalFixtureToGameDoc;
const firestore_1 = require("firebase-admin/firestore");
const timezone_1 = require("../utils/timezone");
class UnsupportedGoalStatusError extends Error {
    constructor(providerStatus) {
        super(`Unsupported GOAL match status: ${providerStatus}`);
        this.providerStatus = providerStatus;
        this.name = "UnsupportedGoalStatusError";
    }
}
exports.UnsupportedGoalStatusError = UnsupportedGoalStatusError;
/** GOAL fixture to canonical GameDoc. Only an evidenced status is accepted. */
function adaptGoalFixtureToGameDoc(fixture, context) {
    if (fixture.matchStatus !== "SCHEDULED")
        throw new UnsupportedGoalStatusError(fixture.matchStatus);
    const utc = (0, timezone_1.toUtcDate)(fixture.kickoffUtc);
    return {
        competitionKey: context.competitionKey,
        competitionSeasonKey: context.competitionSeasonKey,
        sportKey: context.competitionKey,
        leagueId: context.leagueId,
        homeTeamId: context.homeTeamId,
        homeTeamNameJa: context.homeTeamNameJa,
        homeTeamNameEn: fixture.homeTeam.name,
        awayTeamId: context.awayTeamId,
        awayTeamNameJa: context.awayTeamNameJa,
        awayTeamNameEn: fixture.awayTeam.name,
        startTimeUTC: firestore_1.Timestamp.fromDate(utc),
        startTimeJST: (0, timezone_1.toJstStorageString)(fixture.kickoffUtc),
        timezone: "UTC",
        status: "scheduled",
        venue: fixture.venue ?? undefined,
        broadcastPlatforms: [],
        sourceProvider: "goal",
        sourceFixtureId: fixture.id,
    };
}
//# sourceMappingURL=goalFootballAdapter.js.map