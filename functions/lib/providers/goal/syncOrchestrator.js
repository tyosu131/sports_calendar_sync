"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.orchestrateGoalTeamFixtures = orchestrateGoalTeamFixtures;
const goalFootballAdapter_1 = require("../../adapters/goalFootballAdapter");
const competitionSeasonMembership_1 = require("../../domain/competitionSeasonMembership");
const teamIdentity_1 = require("./teamIdentity");
/** Fetches and normalizes one supported team's fixtures without persistence. */
async function orchestrateGoalTeamFixtures(source, internalTeamId, bindings, names, now = () => new Date()) {
    const providerTeamId = (0, teamIdentity_1.goalTeamIdForInternalTeam)(internalTeamId);
    if (!providerTeamId)
        return { games: [], skipped: [] };
    const fixtures = await source.fixtures(providerTeamId);
    const result = { games: [], skipped: [] };
    for (const fixture of fixtures) {
        if (fixture.homeTeam.id !== providerTeamId && fixture.awayTeam.id !== providerTeamId) {
            result.skipped.push({ fixtureId: fixture.id, reason: "unknown_team" });
            continue;
        }
        const binding = bindings.find((item) => item.goalLeagueId === fixture.league.id &&
            item.goalLeagueYear === fixture.leagueYear);
        if (!binding) {
            result.skipped.push({ fixtureId: fixture.id, reason: "unknown_competition" });
            continue;
        }
        const homeTeamId = (0, teamIdentity_1.internalTeamIdForGoalTeam)(fixture.homeTeam.id);
        const awayTeamId = (0, teamIdentity_1.internalTeamIdForGoalTeam)(fixture.awayTeam.id);
        const membership = binding.membership;
        const members = (0, competitionSeasonMembership_1.teamIdsForMembership)(membership);
        if (membership.status === "review" || !membership.seedable ||
            !members.includes(internalTeamId)) {
            result.skipped.push({ fixtureId: fixture.id, reason: "unapproved_membership" });
            continue;
        }
        const kickoff = new Date(fixture.kickoffUtc);
        if (fixture.matchStatus !== "SCHEDULED" && Number.isFinite(kickoff.getTime()) &&
            kickoff.getTime() > now().getTime() + 5 * 60 * 1000) {
            result.skipped.push({ fixtureId: fixture.id, reason: "provider_data_anomaly" });
            continue;
        }
        try {
            result.games.push((0, goalFootballAdapter_1.adaptGoalFixtureToGameDoc)(fixture, {
                competitionKey: membership.competitionKey,
                competitionSeasonKey: membership.competitionSeasonKey,
                leagueId: binding.leagueId,
                homeTeamId,
                awayTeamId,
                homeTeamNameJa: homeTeamId ? names.nameJa(homeTeamId) : fixture.homeTeam.name,
                awayTeamNameJa: awayTeamId ? names.nameJa(awayTeamId) : fixture.awayTeam.name,
            }));
        }
        catch (error) {
            if (error instanceof goalFootballAdapter_1.UnsupportedGoalStatusError) {
                result.skipped.push({ fixtureId: fixture.id, reason: "unsupported_status" });
                continue;
            }
            throw error;
        }
    }
    return result;
}
//# sourceMappingURL=syncOrchestrator.js.map