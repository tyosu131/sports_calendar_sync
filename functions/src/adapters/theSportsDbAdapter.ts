import { Timestamp } from "firebase-admin/firestore";
import { CompetitionKey, GameDoc, GameStatus } from "../types";
import { toJstStorageString } from "../utils/timezone";
import { TsdbEvent } from "../providers/thesportsdb/client";

export const TSDB_PROVIDER = "thesportsdb";

/**
 * How one TheSportsDB league maps into the app.
 *
 * - `teams`: each event has two teams (NFL). Teams are created from provider
 *   ids, so no team list is maintained by hand.
 * - `event`: each event is a card with no participants (UFC). The whole
 *   league is one followable item and each event is one game.
 */
export interface TsdbCompetition {
  competitionKey: CompetitionKey;
  providerLeagueId: string;
  appLeagueId: string;
  kind: "teams" | "event";
  /** Display name of the single follow item for `event` competitions. */
  followName?: string;
  /** Event-name prefix kept for `event` competitions (drops side shows). */
  eventNamePrefix?: string;
}

export class TsdbSkip extends Error {
  constructor(public readonly reason: "unsupported_status" | "invalid_time" | "missing_team", detail: string) {
    super(detail);
    this.name = "TsdbSkip";
  }
}

/** Canonical team id for a provider team id. Stable across seasons. */
export function tsdbTeamId(providerTeamId: string): string {
  return `tsdb_team_${providerTeamId}`;
}

/** The single follow item for an `event` competition (e.g. all UFC events). */
export function tsdbLeagueFollowId(providerLeagueId: string): string {
  return `tsdb_league_${providerLeagueId}`;
}

export function tsdbGameId(idEvent: string): string {
  return `tsdb_${idEvent}`;
}

/** Provider "2026-01-24T22:00:00" (UTC, no suffix) to a Date. Anything else is rejected. */
export function tsdbUtc(timestamp: string | null): Date | undefined {
  if (!timestamp || !/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}$/.test(timestamp)) return undefined;
  const date = new Date(`${timestamp}Z`);
  return Number.isNaN(date.getTime()) ? undefined : date;
}

/**
 * Venue offset from the UTC instant and the venue wall clock (`strTimeLocal`).
 * The provider's local date is not trusted (it can be a day off), so the
 * offset is the clock difference folded into -11h..+14h. ±12h is ambiguous
 * and returns undefined, as does a non-quarter-hour result.
 */
export function tsdbVenueOffsetMinutes(utc: Date, timeLocal: string | null): number | undefined {
  const match = /^(\d{2}):(\d{2})(?::\d{2})?$/.exec(timeLocal ?? "");
  if (!match) return undefined;
  const local = Number(match[1]) * 60 + Number(match[2]);
  const utcMinutes = utc.getUTCHours() * 60 + utc.getUTCMinutes();
  let diff = local - utcMinutes;
  while (diff <= -12 * 60) diff += 24 * 60;
  while (diff > 14 * 60) diff -= 24 * 60;
  if (Math.abs(diff) === 12 * 60 || diff % 15 !== 0) return undefined;
  return diff;
}

/**
 * Status policy.
 * Teams: NS / "" → scheduled, FT / AOT / AET → finished. Live and unknown
 * codes are skipped (the stored game is kept) rather than guessed.
 * Event cards: the provider keeps past cards at NS, so a card is
 * scheduled before its start and finished after it.
 * Both: postponed / cancelled flags win.
 */
export function tsdbStatus(event: TsdbEvent, kind: TsdbCompetition["kind"], utc: Date, now: Date): GameStatus | undefined {
  const code = (event.strStatus ?? "").trim().toUpperCase();
  if ((event.strPostponed ?? "").trim().toLowerCase() === "yes" || code === "PST" || code === "POSTPONED") return "postponed";
  if (code === "CANC" || code === "CANCELLED" || code === "CANCELED" || code === "ABD") return "cancelled";
  if (kind === "event") return utc.getTime() > now.getTime() ? "scheduled" : "finished";
  if (code === "" || code === "NS") return "scheduled";
  if (code === "FT" || code === "AOT" || code === "AET") return "finished";
  return undefined;
}

function nonEmpty(value: string | null | undefined): string | undefined {
  return typeof value === "string" && value.trim().length > 0 ? value.trim() : undefined;
}

function score(value: string | null): number | undefined {
  if (value === null || !/^\d+$/.test(value)) return undefined;
  const parsed = Number(value);
  return Number.isSafeInteger(parsed) ? parsed : undefined;
}

/** TheSportsDB event to canonical GameDoc. Throws [TsdbSkip] for events that must not be written. */
export function adaptTsdbEventToGameDoc(
  event: TsdbEvent,
  competition: TsdbCompetition,
  season: string,
  now: Date
): GameDoc {
  const utc = tsdbUtc(event.strTimestamp);
  if (!utc) throw new TsdbSkip("invalid_time", `Event ${event.idEvent} has no valid UTC timestamp`);
  const status = tsdbStatus(event, competition.kind, utc, now);
  if (!status) throw new TsdbSkip("unsupported_status", `Event ${event.idEvent} status ${event.strStatus}`);
  const venue = nonEmpty(event.strVenue);
  const offset = tsdbVenueOffsetMinutes(utc, event.strTimeLocal);
  const common = {
    competitionKey: competition.competitionKey,
    competitionSeasonKey: `${competition.competitionKey}_${season}`,
    sportKey: competition.competitionKey,
    leagueId: competition.appLeagueId,
    startTimeUTC: Timestamp.fromDate(utc),
    startTimeJST: toJstStorageString(utc.toISOString()),
    timezone: "UTC",
    status,
    ...(venue ? { venue } : {}),
    ...(offset !== undefined ? { venueUtcOffsetMinutes: offset } : {}),
    broadcastPlatforms: [],
    sourceProvider: TSDB_PROVIDER,
    sourceFixtureId: event.idEvent,
  };

  if (competition.kind === "event") {
    // One card, no participants: the follow item is the home side and the
    // card title is its name. The away side is intentionally empty.
    const title = event.strEvent.trim();
    return {
      ...common,
      homeTeamId: tsdbLeagueFollowId(competition.providerLeagueId),
      homeTeamNameJa: title,
      homeTeamNameEn: title,
      homeTeamProviderName: title,
      awayTeamNameJa: "",
    };
  }

  const home = nonEmpty(event.strHomeTeam);
  const away = nonEmpty(event.strAwayTeam);
  const homeId = nonEmpty(event.idHomeTeam);
  const awayId = nonEmpty(event.idAwayTeam);
  if (!home || !away || !homeId || !awayId) {
    throw new TsdbSkip("missing_team", `Event ${event.idEvent} lacks a team name or id`);
  }
  const homeScore = score(event.intHomeScore);
  const awayScore = score(event.intAwayScore);
  return {
    ...common,
    homeTeamId: tsdbTeamId(homeId),
    homeSourceTeamId: homeId,
    // Teams abroad use English names, so both fields carry the provider name.
    homeTeamNameJa: home,
    homeTeamNameEn: home,
    homeTeamProviderName: home,
    awayTeamId: tsdbTeamId(awayId),
    awaySourceTeamId: awayId,
    awayTeamNameJa: away,
    awayTeamNameEn: away,
    awayTeamProviderName: away,
    ...(status === "finished" && homeScore !== undefined && awayScore !== undefined
      ? { homeScore, awayScore } : {}),
  };
}

/** Team document fields derived from a provider event side. */
export interface TsdbTeamDoc {
  nameEn: string;
  nameJa: string;
  leagueId: string;
  competitionKey: CompetitionKey;
  sportKey: CompetitionKey;
  searchKeywords: string[];
  sourceProvider: string;
  sourceTeamId: string;
}

export function tsdbTeamDoc(name: string, sourceTeamId: string, competition: TsdbCompetition): TsdbTeamDoc {
  return {
    nameEn: name,
    nameJa: name,
    leagueId: competition.appLeagueId,
    competitionKey: competition.competitionKey,
    sportKey: competition.competitionKey,
    searchKeywords: englishSearchKeywords(name),
    sourceProvider: TSDB_PROVIDER,
    sourceTeamId,
  };
}

/** Same rule as scripts/searchKeywords.js for an English name: phrase and per-word prefixes, lowercase. */
export function englishSearchKeywords(name: string): string[] {
  const set = new Set<string>();
  const add = (value: string) => {
    for (let i = 1; i <= value.length; i += 1) set.add(value.slice(0, i));
  };
  const lower = name.trim().toLowerCase();
  if (!lower) return [];
  add(lower);
  for (const token of lower.split(/\s+/)) if (token) add(token);
  set.delete("");
  return [...set];
}
