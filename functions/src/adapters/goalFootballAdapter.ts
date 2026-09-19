import { Timestamp } from "firebase-admin/firestore";
import { CompetitionKey, GameDoc, GoalFixture } from "../types";
import { toJstStorageString, toUtcDate } from "../utils/timezone";

export class UnsupportedGoalStatusError extends Error {
  constructor(public readonly providerStatus: string) {
    super(`Unsupported GOAL match status: ${providerStatus}`);
    this.name = "UnsupportedGoalStatusError";
  }
}

export interface GoalAdapterContext {
  competitionKey: CompetitionKey;
  competitionSeasonKey: string;
  leagueId: string;
  homeTeamId: string;
  awayTeamId: string;
  homeTeamNameJa: string;
  awayTeamNameJa: string;
}

/** GOAL fixture to canonical GameDoc. Only an evidenced status is accepted. */
export function adaptGoalFixtureToGameDoc(fixture: GoalFixture, context: GoalAdapterContext): GameDoc {
  if (fixture.matchStatus !== "SCHEDULED") throw new UnsupportedGoalStatusError(fixture.matchStatus);
  const utc = toUtcDate(fixture.kickoffUtc);
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
    startTimeUTC: Timestamp.fromDate(utc),
    startTimeJST: toJstStorageString(fixture.kickoffUtc),
    timezone: "UTC",
    status: "scheduled",
    venue: fixture.venue ?? undefined,
    broadcastPlatforms: [],
    sourceProvider: "goal",
    sourceFixtureId: fixture.id,
  };
}
