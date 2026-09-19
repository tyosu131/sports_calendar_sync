import { adaptGoalFixtureToGameDoc, UnsupportedGoalStatusError } from "../../adapters/goalFootballAdapter";
import { CompetitionSeasonMembership, teamIdsForMembership } from "../../domain/competitionSeasonMembership";
import { GameDoc, GoalFixture } from "../../types";
import { goalTeamIdForInternalTeam, internalTeamIdForGoalTeam } from "./teamIdentity";
import { isGoalTemporalAnomaly } from "./statusPolicy";

export interface GoalFixtureSource {
  fixtures(teamId: string): Promise<GoalFixture[]>;
}

/** Provider binding attached to an existing product membership decision. */
export interface GoalMembershipBinding {
  membership: CompetitionSeasonMembership;
  goalLeagueId: string;
  goalLeagueYear: string;
  leagueId: string;
}

export type GoalSkipReason =
  | "unknown_competition"
  | "unknown_team"
  | "unapproved_membership"
  | "unsupported_status"
  | "provider_data_anomaly";

export interface GoalSyncResult {
  games: GameDoc[];
  skipped: { fixtureId: string; reason: GoalSkipReason }[];
}

export interface TeamNames {
  nameJa(teamId: string): string;
}

/** Fetches and normalizes one supported team's fixtures without persistence. */
export async function orchestrateGoalTeamFixtures(
  source: GoalFixtureSource,
  internalTeamId: string,
  bindings: readonly GoalMembershipBinding[],
  names: TeamNames,
  now: () => Date = () => new Date()
): Promise<GoalSyncResult> {
  const providerTeamId = goalTeamIdForInternalTeam(internalTeamId);
  if (!providerTeamId) return { games: [], skipped: [] };

  const fixtures = await source.fixtures(providerTeamId);
  const result: GoalSyncResult = { games: [], skipped: [] };
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
    const homeTeamId = internalTeamIdForGoalTeam(fixture.homeTeam.id);
    const awayTeamId = internalTeamIdForGoalTeam(fixture.awayTeam.id);
    const membership = binding.membership;
    const members = teamIdsForMembership(membership);
    if (membership.status === "review" || !membership.seedable ||
        !members.includes(internalTeamId)) {
      result.skipped.push({ fixtureId: fixture.id, reason: "unapproved_membership" });
      continue;
    }
    if (isGoalTemporalAnomaly(fixture.matchStatus, fixture.kickoffUtc, now())) {
      result.skipped.push({ fixtureId: fixture.id, reason: "provider_data_anomaly" });
      continue;
    }
    try {
      result.games.push(adaptGoalFixtureToGameDoc(fixture, {
        competitionKey: membership.competitionKey,
        competitionSeasonKey: membership.competitionSeasonKey,
        leagueId: binding.leagueId,
        homeTeamId,
        awayTeamId,
        homeTeamNameJa: homeTeamId ? names.nameJa(homeTeamId) : fixture.homeTeam.name,
        awayTeamNameJa: awayTeamId ? names.nameJa(awayTeamId) : fixture.awayTeam.name,
      }));
    } catch (error: unknown) {
      if (error instanceof UnsupportedGoalStatusError) {
        result.skipped.push({ fixtureId: fixture.id, reason: "unsupported_status" });
        continue;
      }
      throw error;
    }
  }
  return result;
}
