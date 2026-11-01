"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.TSDB_COLOR_LOOKUPS_PER_RUN = exports.TSDB_WRITE_CHUNK_SIZE = exports.TSDB_RUN_BUDGET_MS = exports.UFC_CARDS_PER_RUN = exports.UFC_MAX_ROUND = exports.NFL_WEEKS_AFTER = exports.NFL_WEEKS_BEFORE = exports.NFL_REGULAR_SEASON_ROUNDS = exports.TSDB_COMPETITIONS = void 0;
exports.nflSeason = nflSeason;
exports.ufcSeasons = ufcSeasons;
exports.nflRoundsToRead = nflRoundsToRead;
exports.upcomingEventRounds = upcomingEventRounds;
exports.syncTheSportsDb = syncTheSportsDb;
const admin = __importStar(require("firebase-admin"));
const client_1 = require("../providers/thesportsdb/client");
const theSportsDbAdapter_1 = require("../adapters/theSportsDbAdapter");
/** Leagues read from TheSportsDB. Adding a league is a config change, not a roster. */
exports.TSDB_COMPETITIONS = Object.freeze([
    {
        competitionKey: "americanfootball_nfl", providerLeagueId: "4391", appLeagueId: "nfl", kind: "teams",
    },
    {
        competitionKey: "mma_ufc", providerLeagueId: "4443", appLeagueId: "ufc", kind: "event",
        followName: "UFC", eventNamePrefix: "UFC",
    },
]);
/** NFL regular season weeks. Pre-season (round 500) is skipped; the post-season round number is not known yet. */
exports.NFL_REGULAR_SEASON_ROUNDS = 18;
/** Weeks read before and after the current one. The free key allows only about a dozen calls per burst. */
exports.NFL_WEEKS_BEFORE = 1;
exports.NFL_WEEKS_AFTER = 3;
/** Upper bound when probing UFC card numbers (about 60 cards a year). */
exports.UFC_MAX_ROUND = 128;
/** Upcoming cards read per run. */
exports.UFC_CARDS_PER_RUN = 8;
/** Cards that started within this window are still refreshed. */
const UFC_LOOKBACK_MS = 7 * 24 * 60 * 60 * 1000;
const WEEK_MS = 7 * 24 * 60 * 60 * 1000;
/** The scheduled function times out at 540 s; stop waiting well before that. */
exports.TSDB_RUN_BUDGET_MS = 480000;
exports.TSDB_WRITE_CHUNK_SIZE = 400;
/** Team color lookups per run. Each is one more provider call, so colors fill in over several runs. */
exports.TSDB_COLOR_LOOKUPS_PER_RUN = 8;
/** NFL seasons are named by the year they start; January–February belong to the previous year. */
function nflSeason(now) {
    const year = now.getUTCFullYear();
    return String(now.getUTCMonth() < 2 ? year - 1 : year);
}
/** UFC seasons are calendar years. December also reads next year's cards. */
function ufcSeasons(now) {
    const year = now.getUTCFullYear();
    return now.getUTCMonth() === 11 ? [String(year), String(year + 1)] : [String(year)];
}
/**
 * Weeks to read now. Week 1 starts on [weekOneStart]; later weeks follow every
 * 7 days. Before the season, the first weeks are read.
 */
function nflRoundsToRead(weekOneStart, now) {
    const current = Math.min(exports.NFL_REGULAR_SEASON_ROUNDS, Math.max(1, Math.floor((now.getTime() - weekOneStart.getTime()) / WEEK_MS) + 1));
    const first = Math.max(1, current - exports.NFL_WEEKS_BEFORE);
    const last = Math.min(exports.NFL_REGULAR_SEASON_ROUNDS, current + exports.NFL_WEEKS_AFTER);
    const rounds = [];
    for (let round = first; round <= last; round += 1)
        rounds.push(round);
    return rounds;
}
function firestorePersistence(db) {
    return {
        gameRef: (id) => db.collection("games").doc(id),
        teamRef: (id) => db.collection("teams").doc(id),
        newBatch: () => db.batch(),
        teamsWithoutColor: async (teamIds) => {
            const snapshots = await Promise.all(teamIds.map((id) => db.collection("teams").doc(id).get()));
            return snapshots.filter((snapshot) => !snapshot.get("presentationColor")).map((snapshot) => snapshot.id);
        },
    };
}
/**
 * UFC card numbers run in date order within a season. A binary search finds the
 * first card not older than [from] (an empty number counts as "not older"),
 * then up to [limit] cards are read forward until an empty number.
 * About 7 + [limit] requests instead of one per card.
 */
async function upcomingEventRounds(source, leagueId, season, from, maxRound = exports.UFC_MAX_ROUND, limit = exports.UFC_CARDS_PER_RUN) {
    const cache = new Map();
    const read = async (round) => {
        if (!cache.has(round))
            cache.set(round, await source.eventsRound(leagueId, round, season));
        return cache.get(round);
    };
    const startsBefore = (events) => {
        const time = events.map((event) => (0, theSportsDbAdapter_1.tsdbUtc)(event.strTimestamp)?.getTime())
            .find((value) => value !== undefined);
        return time !== undefined && time < from.getTime();
    };
    let low = 0; // highest number known to be older than [from]
    let high = maxRound + 1; // lowest number known to be not older (or empty)
    while (high - low > 1) {
        const mid = Math.floor((low + high) / 2);
        const events = await read(mid);
        if (events.length > 0 && startsBefore(events))
            low = mid;
        else
            high = mid;
    }
    const result = [];
    for (let round = low + 1; round <= maxRound && round <= low + limit; round += 1) {
        const events = await read(round);
        if (events.length === 0)
            break;
        result.push(...events);
    }
    return result;
}
async function persist(persistence, writes) {
    const ordered = [...writes.values()].sort((a, b) => `${a.kind}:${a.id}`.localeCompare(`${b.kind}:${b.id}`));
    for (let offset = 0; offset < ordered.length; offset += exports.TSDB_WRITE_CHUNK_SIZE) {
        const batch = persistence.newBatch();
        for (const write of ordered.slice(offset, offset + exports.TSDB_WRITE_CHUNK_SIZE)) {
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
async function syncTheSportsDb(apiKey, options = {}) {
    let requests = 0;
    const startedAt = Date.now();
    const budgetMs = options.budgetMs ?? exports.TSDB_RUN_BUDGET_MS;
    let base = options.source;
    if (!base) {
        const client = new client_1.TheSportsDbClient(apiKey);
        client.setDeadline(startedAt + budgetMs);
        base = client;
    }
    const inner = base;
    const source = {
        eventsRound: async (league, round, season) => {
            requests += 1;
            return inner.eventsRound(league, round, season);
        },
    };
    const persistence = options.persistence ?? firestorePersistence(admin.firestore());
    const now = (options.now ?? (() => new Date()))();
    const failedRounds = [];
    const skipCounts = {};
    const skip = (reason) => { skipCounts[reason] = (skipCounts[reason] ?? 0) + 1; };
    let fetched = 0;
    let games = 0;
    let teams = 0;
    let colors = 0;
    const colorCandidates = [];
    for (const competition of options.competitions ?? exports.TSDB_COMPETITIONS) {
        const writes = new Map();
        const batches = [];
        const fail = (label, error) => {
            failedRounds.push(label);
            console.error("TheSportsDB read failed", { label, error: error instanceof Error ? error.message : String(error) });
        };
        if (competition.kind === "teams") {
            const season = nflSeason(now);
            try {
                const first = await source.eventsRound(competition.providerLeagueId, 1, season);
                batches.push({ season, events: first });
                const startTimes = first.map((event) => (0, theSportsDbAdapter_1.tsdbUtc)(event.strTimestamp)?.getTime())
                    .filter((value) => value !== undefined);
                if (startTimes.length > 0) {
                    const weekOne = new Date(Math.min(...startTimes));
                    for (const round of nflRoundsToRead(weekOne, now)) {
                        if (round === 1)
                            continue;
                        // A throttled week must not discard the weeks already read.
                        try {
                            batches.push({ season, events: await source.eventsRound(competition.providerLeagueId, round, season) });
                        }
                        catch (error) {
                            fail(`${competition.competitionKey}:${season}:${round}`, error);
                        }
                    }
                }
                else {
                    fail(`${competition.competitionKey}:${season}:no-week-one`, new Error("week 1 is empty"));
                }
            }
            catch (error) {
                fail(`${competition.competitionKey}:${season}:1`, error);
            }
        }
        else {
            for (const season of ufcSeasons(now)) {
                try {
                    batches.push({ season, events: await upcomingEventRounds(source, competition.providerLeagueId, season, new Date(now.getTime() - UFC_LOOKBACK_MS)) });
                }
                catch (error) {
                    fail(`${competition.competitionKey}:${season}`, error);
                }
            }
            const followId = (0, theSportsDbAdapter_1.tsdbLeagueFollowId)(competition.providerLeagueId);
            writes.set(`team:${followId}`, { kind: "team", id: followId,
                data: (0, theSportsDbAdapter_1.tsdbTeamDoc)(competition.followName ?? competition.competitionKey, competition.providerLeagueId, competition) });
        }
        for (const { season, events } of batches) {
            for (const event of events) {
                fetched += 1;
                if (event.idLeague !== competition.providerLeagueId) {
                    skip("filtered_event");
                    continue;
                }
                if (competition.eventNamePrefix && !event.strEvent.trim().startsWith(competition.eventNamePrefix)) {
                    skip("filtered_event");
                    continue;
                }
                let game;
                try {
                    game = (0, theSportsDbAdapter_1.adaptTsdbEventToGameDoc)(event, competition, season, now);
                }
                catch (error) {
                    if (error instanceof theSportsDbAdapter_1.TsdbSkip) {
                        skip(error.reason);
                        continue;
                    }
                    throw error;
                }
                writes.set(`game:${event.idEvent}`, { kind: "game", id: (0, theSportsDbAdapter_1.tsdbGameId)(event.idEvent), data: game });
                if (competition.kind === "teams") {
                    for (const [name, id] of [[event.strHomeTeam, event.idHomeTeam], [event.strAwayTeam, event.idAwayTeam]]) {
                        const teamId = (0, theSportsDbAdapter_1.tsdbTeamId)(id);
                        writes.set(`team:${teamId}`, { kind: "team", id: teamId, data: (0, theSportsDbAdapter_1.tsdbTeamDoc)(name.trim(), id, competition) });
                    }
                }
            }
        }
        await persist(persistence, writes);
        for (const write of writes.values()) {
            if (write.kind === "game")
                games += 1;
            else
                teams += 1;
            if (competition.kind === "teams" && write.kind === "team")
                colorCandidates.push(write.id);
        }
    }
    // Team colors come from the provider, a few per run, for teams that have none
    // yet. Last, so a short time budget costs colors before it costs games.
    if (colorCandidates.length > 0 && inner.lookupTeamColor) {
        try {
            const missing = (await persistence.teamsWithoutColor(colorCandidates)).slice(0, exports.TSDB_COLOR_LOOKUPS_PER_RUN);
            const colorWrites = new Map();
            for (const teamId of missing) {
                requests += 1;
                const found = await inner.lookupTeamColor(teamId.replace(/^tsdb_team_/, ""));
                if (found?.primaryColor) {
                    colorWrites.set(`team:${teamId}`, { kind: "team", id: teamId, data: { presentationColor: found.primaryColor } });
                    colors += 1;
                }
                // Keep what was read if a later lookup is throttled.
                await persist(persistence, colorWrites);
                colorWrites.clear();
            }
        }
        catch (error) {
            failedRounds.push("colors");
            console.error("TheSportsDB read failed", { label: "colors", error: error instanceof Error ? error.message : String(error) });
        }
    }
    const summary = {
        failedRounds,
        requests,
        eventsFetched: fetched,
        gamesUpserted: games,
        teamsUpserted: teams,
        colorsSaved: colors,
        skipCounts,
    };
    console.info("TheSportsDB sync complete", summary);
    return summary;
}
//# sourceMappingURL=syncTheSportsDb.js.map