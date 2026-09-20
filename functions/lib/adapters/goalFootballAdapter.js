"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.UnsupportedGoalStatusError = void 0;
exports.adaptGoalFixtureToGameDoc = adaptGoalFixtureToGameDoc;
const firestore_1 = require("firebase-admin/firestore");
const timezone_1 = require("../utils/timezone");
const statusPolicy_1 = require("../providers/goal/statusPolicy");
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
    const status = (0, statusPolicy_1.goalGameStatus)(fixture.matchStatus);
    if (!status)
        throw new UnsupportedGoalStatusError(fixture.matchStatus);
    const utc = (0, timezone_1.toUtcDate)(fixture.kickoffUtc);
    const venue = nonEmpty(fixture.venue) ?? nonEmpty(fixture.matchStadium);
    return {
        competitionKey: context.competitionKey,
        competitionSeasonKey: context.competitionSeasonKey,
        sportKey: context.competitionKey,
        leagueId: context.leagueId,
        ...(context.homeTeamId ? { homeTeamId: context.homeTeamId } : {}),
        homeSourceTeamId: fixture.homeTeam.id,
        homeTeamNameJa: context.homeTeamNameJa,
        homeTeamNameEn: fixture.homeTeam.name,
        homeTeamProviderName: fixture.homeTeam.name,
        ...(context.awayTeamId ? { awayTeamId: context.awayTeamId } : {}),
        awaySourceTeamId: fixture.awayTeam.id,
        awayTeamNameJa: context.awayTeamNameJa,
        awayTeamNameEn: fixture.awayTeam.name,
        awayTeamProviderName: fixture.awayTeam.name,
        startTimeUTC: firestore_1.Timestamp.fromDate(utc),
        startTimeJST: (0, timezone_1.toJstStorageString)(fixture.kickoffUtc),
        timezone: "UTC",
        status,
        ...(typeof fixture.homeScore === "number" && typeof fixture.awayScore === "number" ? {
            homeScore: fixture.homeScore,
            awayScore: fixture.awayScore,
        } : {}),
        ...(venue ? { venue } : {}),
        broadcastPlatforms: [],
        sourceProvider: "goal",
        sourceFixtureId: fixture.id,
    };
}
function nonEmpty(value) {
    return typeof value === "string" && value.trim().length > 0 ? value : undefined;
}
//# sourceMappingURL=goalFootballAdapter.js.map