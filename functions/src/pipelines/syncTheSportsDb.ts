import * as admin from "firebase-admin";
import { GameDoc } from "../types";
import { TheSportsDbClient, TsdbEvent, TsdbEventSource } from "../providers/thesportsdb/client";
import {
  adaptTsdbEventToGameDoc, TsdbCompetition, TsdbSkip, TsdbTeamDoc,
  tsdbGameId, tsdbLeagueFollowId, tsdbTeamDoc, tsdbTeamId, tsdbUtc,
} from "../adapters/theSportsDbAdapter";

/** Leagues read from TheSportsDB. Adding a league is a config change, not a roster. */
export const TSDB_COMPETITIONS: readonly TsdbCompetition[] = Object.freeze([
  {
    competitionKey: "americanfootball_nfl", providerLeagueId: "4391", appLeagueId: "nfl", kind: "teams",
  },
  {
    competitionKey: "mma_ufc", providerLeagueId: "4443", appLeagueId: "ufc", kind: "event",
    followName: "UFC", eventNamePrefix: "UFC",
  },
]);

/** NFL regular season weeks. Pre-season (round 500) is skipped; the post-season round number is not known yet. */
export const NFL_REGULAR_SEASON_ROUNDS = 18;
/** Weeks read before and after the current one. The free key allows only about a dozen calls per burst. */
export const NFL_WEEKS_BEFORE = 1;
export const NFL_WEEKS_AFTER = 3;
/** Upper bound when probing UFC card numbers (about 60 cards a year). */
export const UFC_MAX_ROUND = 128;
/** Upcoming cards read per run. */
export const UFC_CARDS_PER_RUN = 8;
/** Cards that started within this window are still refreshed. */
const UFC_LOOKBACK_MS = 7 * 24 * 60 * 60 * 1000;
const WEEK_MS = 7 * 24 * 60 * 60 * 1000;
/** The scheduled function times out at 540 s; stop waiting well before that. */
export const TSDB_RUN_BUDGET_MS = 480_000;
export const TSDB_WRITE_CHUNK_SIZE = 400;

/** NFL seasons are named by the year they start; January–February belong to the previous year. */
export function nflSeason(now: Date): string {
  const year = now.getUTCFullYear();
  return String(now.getUTCMonth() < 2 ? year - 1 : year);
}

/** UFC seasons are calendar years. December also reads next year's cards. */
export function ufcSeasons(now: Date): string[] {
  const year = now.getUTCFullYear();
  return now.getUTCMonth() === 11 ? [String(year), String(year + 1)] : [String(year)];
}

/**
 * Weeks to read now. Week 1 starts on [weekOneStart]; later weeks follow every
 * 7 days. Before the season, the first weeks are read.
 */
export function nflRoundsToRead(weekOneStart: Date, now: Date): number[] {
  const current = Math.min(NFL_REGULAR_SEASON_ROUNDS,
    Math.max(1, Math.floor((now.getTime() - weekOneStart.getTime()) / WEEK_MS) + 1));
  const first = Math.max(1, current - NFL_WEEKS_BEFORE);
  const last = Math.min(NFL_REGULAR_SEASON_ROUNDS, current + NFL_WEEKS_AFTER);
  const rounds: number[] = [];
  for (let round = first; round <= last; round += 1) rounds.push(round);
  return rounds;
}

export type TsdbSkipReason = TsdbSkip["reason"] | "filtered_event";

export interface TsdbSyncSummary {
  /** Rounds that could not be read after retries; their games keep the last stored state. */
  failedRounds: string[];
  requests: number;
  eventsFetched: number;
  gamesUpserted: number;
  teamsUpserted: number;
  skipCounts: Partial<Record<TsdbSkipReason, number>>;
}

interface WriteBatchLike {
  set(ref: admin.firestore.DocumentReference, data: object, options: { merge: true }): unknown;
  commit(): Promise<unknown>;
}

export interface TsdbPersistence {
  gameRef(id: string): admin.firestore.DocumentReference;
  teamRef(id: string): admin.firestore.DocumentReference;
  newBatch(): WriteBatchLike;
}

function firestorePersistence(db: admin.firestore.Firestore): TsdbPersistence {
  return {
    gameRef: (id) => db.collection("games").doc(id),
    teamRef: (id) => db.collection("teams").doc(id),
    newBatch: () => db.batch(),
  };
}

type Write =
  | { kind: "game"; id: string; data: GameDoc }
  | { kind: "team"; id: string; data: TsdbTeamDoc };

/**
 * UFC card numbers run in date order within a season. A binary search finds the
 * first card not older than [from] (an empty number counts as "not older"),
 * then up to [limit] cards are read forward until an empty number.
 * About 7 + [limit] requests instead of one per card.
 */
export async function upcomingEventRounds(
  source: TsdbEventSource,
  leagueId: string,
  season: string,
  from: Date,
  maxRound = UFC_MAX_ROUND,
  limit = UFC_CARDS_PER_RUN
): Promise<TsdbEvent[]> {
  const cache = new Map<number, TsdbEvent[]>();
  const read = async (round: number) => {
    if (!cache.has(round)) cache.set(round, await source.eventsRound(leagueId, round, season));
    return cache.get(round)!;
  };
  const startsBefore = (events: TsdbEvent[]) => {
    const time = events.map((event) => tsdbUtc(event.strTimestamp)?.getTime())
      .find((value): value is number => value !== undefined);
    return time !== undefined && time < from.getTime();
  };

  let low = 0; // highest number known to be older than [from]
  let high = maxRound + 1; // lowest number known to be not older (or empty)
  while (high - low > 1) {
    const mid = Math.floor((low + high) / 2);
    const events = await read(mid);
    if (events.length > 0 && startsBefore(events)) low = mid;
    else high = mid;
  }
  const result: TsdbEvent[] = [];
  for (let round = low + 1; round <= maxRound && round <= low + limit; round += 1) {
    const events = await read(round);
    if (events.length === 0) break;
    result.push(...events);
  }
  return result;
}

export interface SyncTsdbOptions {
  source?: TsdbEventSource;
  persistence?: TsdbPersistence;
  now?: () => Date;
  competitions?: readonly TsdbCompetition[];
  /** Milliseconds this run may spend waiting on the provider. */
  budgetMs?: number;
}

async function persist(persistence: TsdbPersistence, writes: Map<string, Write>): Promise<void> {
  const ordered = [...writes.values()].sort((a, b) => `${a.kind}:${a.id}`.localeCompare(`${b.kind}:${b.id}`));
  for (let offset = 0; offset < ordered.length; offset += TSDB_WRITE_CHUNK_SIZE) {
    const batch = persistence.newBatch();
    for (const write of ordered.slice(offset, offset + TSDB_WRITE_CHUNK_SIZE)) {
      const ref = write.kind === "game" ? persistence.gameRef(write.id) : persistence.teamRef(write.id);
      batch.set(ref, write.data, { merge: true });
    }
    await batch.commit();
  }
}

/**
 * Fetches the current NFL weeks and upcoming UFC cards, then upserts games and
 * teams. Each competition is saved as soon as it is read, so a throttled or
 * timed-out later competition cannot discard it. Never deletes.
 */
export async function syncTheSportsDb(apiKey: string, options: SyncTsdbOptions = {}): Promise<TsdbSyncSummary> {
  let requests = 0;
  const startedAt = Date.now();
  const budgetMs = options.budgetMs ?? TSDB_RUN_BUDGET_MS;
  let base = options.source;
  if (!base) {
    const client = new TheSportsDbClient(apiKey);
    client.setDeadline(startedAt + budgetMs);
    base = client;
  }
  const inner = base;
  const source: TsdbEventSource = {
    eventsRound: async (league, round, season) => {
      requests += 1;
      return inner.eventsRound(league, round, season);
    },
  };
  const persistence = options.persistence ?? firestorePersistence(admin.firestore());
  const now = (options.now ?? (() => new Date()))();
  const failedRounds: string[] = [];
  const skipCounts: Partial<Record<TsdbSkipReason, number>> = {};
  const skip = (reason: TsdbSkipReason) => { skipCounts[reason] = (skipCounts[reason] ?? 0) + 1; };
  let fetched = 0;
  let games = 0;
  let teams = 0;

  for (const competition of options.competitions ?? TSDB_COMPETITIONS) {
    const writes = new Map<string, Write>();
    const batches: { season: string; events: TsdbEvent[] }[] = [];
    const fail = (label: string, error: unknown) => {
      failedRounds.push(label);
      console.error("TheSportsDB read failed", { label, error: error instanceof Error ? error.message : String(error) });
    };

    if (competition.kind === "teams") {
      const season = nflSeason(now);
      try {
        const first = await source.eventsRound(competition.providerLeagueId, 1, season);
        batches.push({ season, events: first });
        const startTimes = first.map((event) => tsdbUtc(event.strTimestamp)?.getTime())
          .filter((value): value is number => value !== undefined);
        if (startTimes.length > 0) {
          const weekOne = new Date(Math.min(...startTimes));
          for (const round of nflRoundsToRead(weekOne, now)) {
            if (round === 1) continue;
            // A throttled week must not discard the weeks already read.
            try {
              batches.push({ season, events: await source.eventsRound(competition.providerLeagueId, round, season) });
            } catch (error) {
              fail(`${competition.competitionKey}:${season}:${round}`, error);
            }
          }
        } else {
          fail(`${competition.competitionKey}:${season}:no-week-one`, new Error("week 1 is empty"));
        }
      } catch (error) {
        fail(`${competition.competitionKey}:${season}:1`, error);
      }
    } else {
      for (const season of ufcSeasons(now)) {
        try {
          batches.push({ season, events: await upcomingEventRounds(source, competition.providerLeagueId, season,
            new Date(now.getTime() - UFC_LOOKBACK_MS)) });
        } catch (error) {
          fail(`${competition.competitionKey}:${season}`, error);
        }
      }
      const followId = tsdbLeagueFollowId(competition.providerLeagueId);
      writes.set(`team:${followId}`, { kind: "team", id: followId,
        data: tsdbTeamDoc(competition.followName ?? competition.competitionKey, competition.providerLeagueId, competition) });
    }

    for (const { season, events } of batches) {
      for (const event of events) {
        fetched += 1;
        if (event.idLeague !== competition.providerLeagueId) { skip("filtered_event"); continue; }
        if (competition.eventNamePrefix && !event.strEvent.trim().startsWith(competition.eventNamePrefix)) {
          skip("filtered_event");
          continue;
        }
        let game: GameDoc;
        try {
          game = adaptTsdbEventToGameDoc(event, competition, season, now);
        } catch (error) {
          if (error instanceof TsdbSkip) { skip(error.reason); continue; }
          throw error;
        }
        writes.set(`game:${event.idEvent}`, { kind: "game", id: tsdbGameId(event.idEvent), data: game });
        if (competition.kind === "teams") {
          for (const [name, id] of [[event.strHomeTeam, event.idHomeTeam], [event.strAwayTeam, event.idAwayTeam]]) {
            const teamId = tsdbTeamId(id!);
            writes.set(`team:${teamId}`, { kind: "team", id: teamId, data: tsdbTeamDoc(name!.trim(), id!, competition) });
          }
        }
      }
    }
    await persist(persistence, writes);
    for (const write of writes.values()) {
      if (write.kind === "game") games += 1; else teams += 1;
    }

  }

  const summary: TsdbSyncSummary = {
    failedRounds,
    requests,
    eventsFetched: fetched,
    gamesUpserted: games,
    teamsUpserted: teams,
    skipCounts,
  };
  console.info("TheSportsDB sync complete", summary);
  return summary;
}
