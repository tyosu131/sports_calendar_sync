"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.TsdbSkip = exports.TSDB_PROVIDER = void 0;
exports.tsdbTeamId = tsdbTeamId;
exports.tsdbLeagueFollowId = tsdbLeagueFollowId;
exports.tsdbGameId = tsdbGameId;
exports.tsdbUtc = tsdbUtc;
exports.tsdbVenueOffsetMinutes = tsdbVenueOffsetMinutes;
exports.tsdbStatus = tsdbStatus;
exports.adaptTsdbEventToGameDoc = adaptTsdbEventToGameDoc;
exports.tsdbTeamDoc = tsdbTeamDoc;
exports.englishSearchKeywords = englishSearchKeywords;
const firestore_1 = require("firebase-admin/firestore");
const timezone_1 = require("../utils/timezone");
exports.TSDB_PROVIDER = "thesportsdb";
class TsdbSkip extends Error {
    constructor(reason, detail) {
        super(detail);
        this.reason = reason;
        this.name = "TsdbSkip";
    }
}
exports.TsdbSkip = TsdbSkip;
/** Canonical team id for a provider team id. Stable across seasons. */
function tsdbTeamId(providerTeamId) {
    return `tsdb_team_${providerTeamId}`;
}
/** The single follow item for an `event` competition (e.g. all UFC events). */
function tsdbLeagueFollowId(providerLeagueId) {
    return `tsdb_league_${providerLeagueId}`;
}
function tsdbGameId(idEvent) {
    return `tsdb_${idEvent}`;
}
/** Provider "2026-01-24T22:00:00" (UTC, no suffix) to a Date. Anything else is rejected. */
function tsdbUtc(timestamp) {
    if (!timestamp || !/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}$/.test(timestamp))
        return undefined;
    const date = new Date(`${timestamp}Z`);
    return Number.isNaN(date.getTime()) ? undefined : date;
}
/**
 * Venue offset from the UTC instant and the venue wall clock (`strTimeLocal`).
 * The provider's local date is not trusted (it can be a day off), so the
 * offset is the clock difference folded into -11h..+14h. ±12h is ambiguous
 * and returns undefined, as does a non-quarter-hour result.
 */
function tsdbVenueOffsetMinutes(utc, timeLocal) {
    const match = /^(\d{2}):(\d{2})(?::\d{2})?$/.exec(timeLocal ?? "");
    if (!match)
        return undefined;
    const local = Number(match[1]) * 60 + Number(match[2]);
    const utcMinutes = utc.getUTCHours() * 60 + utc.getUTCMinutes();
    let diff = local - utcMinutes;
    while (diff <= -12 * 60)
        diff += 24 * 60;
    while (diff > 14 * 60)
        diff -= 24 * 60;
    if (Math.abs(diff) === 12 * 60 || diff % 15 !== 0)
        return undefined;
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
function tsdbStatus(event, kind, utc, now) {
    const code = (event.strStatus ?? "").trim().toUpperCase();
    if ((event.strPostponed ?? "").trim().toLowerCase() === "yes" || code === "PST" || code === "POSTPONED")
        return "postponed";
    if (code === "CANC" || code === "CANCELLED" || code === "CANCELED" || code === "ABD")
        return "cancelled";
    if (kind === "event")
        return utc.getTime() > now.getTime() ? "scheduled" : "finished";
    if (code === "" || code === "NS")
        return "scheduled";
    if (code === "FT" || code === "AOT" || code === "AET")
        return "finished";
    return undefined;
}
function nonEmpty(value) {
    return typeof value === "string" && value.trim().length > 0 ? value.trim() : undefined;
}
function score(value) {
    if (value === null || !/^\d+$/.test(value))
        return undefined;
    const parsed = Number(value);
    return Number.isSafeInteger(parsed) ? parsed : undefined;
}
/** TheSportsDB event to canonical GameDoc. Throws [TsdbSkip] for events that must not be written. */
function adaptTsdbEventToGameDoc(event, competition, season, now) {
    const utc = tsdbUtc(event.strTimestamp);
    if (!utc)
        throw new TsdbSkip("invalid_time", `Event ${event.idEvent} has no valid UTC timestamp`);
    const status = tsdbStatus(event, competition.kind, utc, now);
    if (!status)
        throw new TsdbSkip("unsupported_status", `Event ${event.idEvent} status ${event.strStatus}`);
    const venue = nonEmpty(event.strVenue);
    const offset = tsdbVenueOffsetMinutes(utc, event.strTimeLocal);
    const common = {
        competitionKey: competition.competitionKey,
        competitionSeasonKey: `${competition.competitionKey}_${season}`,
        sportKey: competition.competitionKey,
        leagueId: competition.appLeagueId,
        startTimeUTC: firestore_1.Timestamp.fromDate(utc),
        startTimeJST: (0, timezone_1.toJstStorageString)(utc.toISOString()),
        timezone: "UTC",
        status,
        ...(venue ? { venue } : {}),
        ...(offset !== undefined ? { venueUtcOffsetMinutes: offset } : {}),
        broadcastPlatforms: [],
        sourceProvider: exports.TSDB_PROVIDER,
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
function tsdbTeamDoc(name, sourceTeamId, competition) {
    return {
        nameEn: name,
        nameJa: name,
        leagueId: competition.appLeagueId,
        competitionKey: competition.competitionKey,
        sportKey: competition.competitionKey,
        searchKeywords: englishSearchKeywords(name),
        sourceProvider: exports.TSDB_PROVIDER,
        sourceTeamId,
    };
}
/** Same rule as scripts/searchKeywords.js for an English name: phrase and per-word prefixes, lowercase. */
function englishSearchKeywords(name) {
    const set = new Set();
    const add = (value) => {
        for (let i = 1; i <= value.length; i += 1)
            set.add(value.slice(0, i));
    };
    const lower = name.trim().toLowerCase();
    if (!lower)
        return [];
    add(lower);
    for (const token of lower.split(/\s+/))
        if (token)
            add(token);
    set.delete("");
    return [...set];
}
//# sourceMappingURL=theSportsDbAdapter.js.map