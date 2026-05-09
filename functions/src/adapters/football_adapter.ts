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
 * syncFootball.ts delegates fixture conversion here so the sync pipeline and
 * app model stay aligned.
 */

import { Timestamp } from "firebase-admin/firestore";
import { RapidApiFootballFixture, GameDoc, CompetitionKey } from "../types";
import {
  toJstStorageString,
  toUtcDate,
  mapFootballStatus,
} from "../utils/timezone";

/**
 * Converts a single API-SPORTS football fixture to a Firestore GameDoc.
 *
 * @param fixture       - One element from the API-SPORTS /fixtures response.
 * @param competitionKey - SportsRegistry competition key, e.g. "football_j1".
 * @param competitionSeasonKey - Concrete competition season / tournament key.
 * @param leagueDocId   - Firestore /leagues/{id} document ID.
 * @param homeTeamDocId - Firestore /teams/{id} document ID for the home team.
 * @param awayTeamDocId - Firestore /teams/{id} document ID for the away team.
 * @param homeTeamNameJa - Japanese team name (from translation map or Firestore).
 * @param awayTeamNameJa - Japanese team name.
 */
export function adaptFootballFixtureToGameDoc(
  fixture: RapidApiFootballFixture,
  competitionKey: CompetitionKey,
  competitionSeasonKey: string,
  leagueDocId: string,
  homeTeamDocId: string,
  awayTeamDocId: string,
  homeTeamNameJa: string,
  awayTeamNameJa: string
): GameDoc {
  const utcDate = toUtcDate(fixture.fixture.date);

  return {
    competitionKey,
    competitionSeasonKey,
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
    startTimeUTC: Timestamp.fromDate(utcDate),
    startTimeJST: toJstStorageString(fixture.fixture.date),
    timezone: fixture.fixture.timezone ?? "UTC",
    status: mapFootballStatus(fixture.fixture.status.short),
    venue: fixture.fixture.venue?.name,
    homeScore: fixture.goals.home ?? undefined,
    awayScore: fixture.goals.away ?? undefined,
    broadcastPlatforms: [],
    externalFixtureId: fixture.fixture.id,
    // Legacy alias.
    rapidApiFixtureId: fixture.fixture.id,
  };
}
