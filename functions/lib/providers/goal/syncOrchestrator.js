"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.orchestrateGoalTeamFixtures = orchestrateGoalTeamFixtures;
const goalFootballAdapter_1 = require("../../adapters/goalFootballAdapter");
const competitionSeasonMembership_1 = require("../../domain/competitionSeasonMembership");
const teamIdentity_1 = require("./teamIdentity");
/** Fetches and normalizes one supported team's fixtures without persistence. */
async function orchestrateGoalTeamFixtures(source, internalTeamId, bindings, names) {
    const providerTeamId = (0, teamIdentity_1.goalTeamIdForInternalTeam)(internalTeamId);
    if (!providerTeamId)
        return { games: [], skipped: [] };
    const fixtures = await source.fixtures(providerTeamId);
    const result = { games: [], skipped: [] };
    for (const fixture of fixtures) {
        const binding = bindings.find((item) => item.goalLeagueId === fixture.league.id);
        if (!binding) {
            result.skipped.push({ fixtureId: fixture.id, reason: "unknown_competition" });
            continue;
        }
        const homeTeamId = (0, teamIdentity_1.internalTeamIdForGoalTeam)(fixture.homeTeam.id);
        const awayTeamId = (0, teamIdentity_1.internalTeamIdForGoalTeam)(fixture.awayTeam.id);
        if (!homeTeamId || !awayTeamId) {
            result.skipped.push({ fixtureId: fixture.id, reason: "unknown_team" });
            continue;
        }
        const membership = binding.membership;
        const members = (0, competitionSeasonMembership_1.teamIdsForMembership)(membership);
        if (membership.status === "review" || !membership.seedable ||
            !members.includes(homeTeamId) || !members.includes(awayTeamId)) {
            result.skipped.push({ fixtureId: fixture.id, reason: "unapproved_membership" });
            continue;
        }
        try {
            result.games.push((0, goalFootballAdapter_1.adaptGoalFixtureToGameDoc)(fixture, {
                competitionKey: membership.competitionKey,
                competitionSeasonKey: membership.competitionSeasonKey,
                leagueId: binding.leagueId,
                homeTeamId,
                awayTeamId,
                homeTeamNameJa: names.nameJa(homeTeamId),
                awayTeamNameJa: names.nameJa(awayTeamId),
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