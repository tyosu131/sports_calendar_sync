import { CalendarGame, buildCalendar } from "./icsBuilder";

export interface CalendarFeed {
  ownerUid: string;
  active: boolean;
}

export interface CalendarUser {
  /** Canonical, competition-independent follow state. */
  followedTeamIds: readonly string[];
}

export interface NormalizedGame extends CalendarGame {
  homeTeamId: string;
  awayTeamId: string;
}

export interface PersonalizedCalendarRepository {
  findFeed(token: string): Promise<CalendarFeed | undefined>;
  findUser(uid: string): Promise<CalendarUser | undefined>;
  findUpcomingGamesForTeams(teamIds: readonly string[]): Promise<readonly NormalizedGame[]>;
}

export class CalendarFeedNotFoundError extends Error {}
export class CalendarUserNotFoundError extends Error {}
export class CalendarTeamNotFollowedError extends Error {}

function uniqueNonEmpty(values: readonly string[]): string[] {
  return [...new Set(values.filter((value) => typeof value === "string" && value.trim().length > 0))];
}

/**
 * Resolves the public feed credential to its owner, applies canonical team
 * membership, and renders only normalized games involving those teams.
 */
export async function buildPersonalizedCalendar(
  repository: PersonalizedCalendarRepository,
  token: string,
  requestedTeamId?: string
): Promise<string> {
  const feed = await repository.findFeed(token);
  if (!feed?.active) throw new CalendarFeedNotFoundError("Calendar feed not found");

  const user = await repository.findUser(feed.ownerUid);
  if (!user) throw new CalendarUserNotFoundError("Calendar owner not found");

  let teamIds = uniqueNonEmpty(user.followedTeamIds);
  if (requestedTeamId) {
    if (!teamIds.includes(requestedTeamId)) {
      throw new CalendarTeamNotFollowedError("Team is not followed by calendar owner");
    }
    teamIds = [requestedTeamId];
  }

  if (teamIds.length === 0) return buildCalendar([]);
  const allowed = new Set(teamIds);
  const games = await repository.findUpcomingGamesForTeams(teamIds);

  // Repository queries are an optimization, never an authorization boundary.
  // Reapply membership here so an over-broad adapter cannot leak fixtures.
  return buildCalendar(games.filter((game) =>
    allowed.has(game.homeTeamId) || allowed.has(game.awayTeamId)
  ));
}
