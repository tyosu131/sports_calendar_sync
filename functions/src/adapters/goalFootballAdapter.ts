import { Timestamp } from "firebase-admin/firestore";
import { CompetitionKey, GameDoc, GoalFixture } from "../types";
import { toJstStorageString, toUtcDate } from "../utils/timezone";
import { goalGameStatus } from "../providers/goal/statusPolicy";

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
  homeTeamId?: string;
  awayTeamId?: string;
  homeTeamNameJa: string;
  awayTeamNameJa: string;
}

/** GOAL fixture to canonical GameDoc. Only an evidenced status is accepted. */
export function adaptGoalFixtureToGameDoc(fixture: GoalFixture, context: GoalAdapterContext): GameDoc {
  const status = goalGameStatus(fixture.matchStatus);
  if (!status) throw new UnsupportedGoalStatusError(fixture.matchStatus);
  const utc = toUtcDate(fixture.kickoffUtc);
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
    startTimeUTC: Timestamp.fromDate(utc),
    startTimeJST: toJstStorageString(fixture.kickoffUtc),
    timezone: "UTC",
    status,
    ...(venue ? { venue } : {}),
    broadcastPlatforms: [],
    sourceProvider: "goal",
    sourceFixtureId: fixture.id,
  };
}

function nonEmpty(value: string | null | undefined): string | undefined {
  return typeof value === "string" && value.trim().length > 0 ? value : undefined;
}
