"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.TheSportsDbClient = exports.TsdbApiError = void 0;
exports.parseEvents = parseEvents;
const axios_1 = __importDefault(require("axios"));
class TsdbApiError extends Error {
    constructor(kind, message, status) {
        super(message);
        this.kind = kind;
        this.status = status;
        this.name = "TsdbApiError";
    }
}
exports.TsdbApiError = TsdbApiError;
const BASE_URL = "https://www.thesportsdb.com/api/v1/json";
/**
 * TheSportsDB v1 boundary. Only `eventsround` is used: on the free key the
 * season list stops at 15 events and the day list at 3, while one NFL week
 * (16 games) or one UFC card comes back whole from `eventsround`.
 *
 * Requests are spaced by [minIntervalMs]. A non-JSON body (seen when calls
 * come too fast) is retried once after [retryDelayMs].
 */
class TheSportsDbClient {
    constructor(apiKey, http = axios_1.default, minIntervalMs = 3000, retryDelayMs = 20000, sleep = (ms) => new Promise((r) => setTimeout(r, ms)), timeoutMs = 10000) {
        this.apiKey = apiKey;
        this.http = http;
        this.minIntervalMs = minIntervalMs;
        this.retryDelayMs = retryDelayMs;
        this.sleep = sleep;
        this.timeoutMs = timeoutMs;
        this.lastRequestAt = 0;
        if (!apiKey)
            throw new Error("TheSportsDB API key is required");
    }
    async eventsRound(leagueId, round, season) {
        const query = `id=${encodeURIComponent(leagueId)}&r=${encodeURIComponent(round)}&s=${encodeURIComponent(season)}`;
        const path = `/eventsround.php?${query}`;
        try {
            return parseEvents(await this.request(path));
        }
        catch (error) {
            if (!(error instanceof TsdbApiError) ||
                (error.kind !== "invalid_response" && error.kind !== "rate_limited"))
                throw error;
            await this.sleep(this.retryDelayMs);
            return parseEvents(await this.request(path));
        }
    }
    async request(path) {
        const wait = this.lastRequestAt + this.minIntervalMs - Date.now();
        if (this.lastRequestAt > 0 && wait > 0)
            await this.sleep(wait);
        this.lastRequestAt = Date.now();
        let text;
        try {
            const response = await this.http.get(`${BASE_URL}/${encodeURIComponent(this.apiKey)}${path}`, {
                timeout: this.timeoutMs,
                responseType: "text",
            });
            text = response.data;
        }
        catch (error) {
            const candidate = error;
            const status = candidate.response?.status;
            if (status === 429)
                throw new TsdbApiError("rate_limited", "TheSportsDB rate limit exceeded", 429);
            if (candidate.code === "ECONNABORTED" || candidate.code === "ETIMEDOUT") {
                throw new TsdbApiError("timeout", "TheSportsDB request timed out");
            }
            throw new TsdbApiError("http", `TheSportsDB request failed${status ? ` (${status})` : ""}`, status);
        }
        if (typeof text === "object" && text !== null)
            return text;
        if (typeof text !== "string")
            throw new TsdbApiError("invalid_response", "TheSportsDB returned no body");
        try {
            return JSON.parse(text);
        }
        catch {
            throw new TsdbApiError("invalid_response", "TheSportsDB returned a non-JSON body");
        }
    }
}
exports.TheSportsDbClient = TheSportsDbClient;
const STRING_OR_NULL_FIELDS = [
    "strSeason", "intRound", "strHomeTeam", "strAwayTeam", "idHomeTeam", "idAwayTeam",
    "intHomeScore", "intAwayScore", "strTimestamp", "strTimeLocal", "strVenue", "strCountry",
    "strStatus", "strPostponed",
];
/** `{"events": null}` is an empty round. Anything malformed rejects the response. */
function parseEvents(body) {
    if (!body || typeof body !== "object" || !("events" in body)) {
        throw new TsdbApiError("invalid_response", "TheSportsDB response has no events field");
    }
    const events = body.events;
    if (events === null)
        return [];
    if (!Array.isArray(events))
        throw new TsdbApiError("invalid_response", "TheSportsDB events is not a list");
    return events.map((value) => {
        if (!value || typeof value !== "object") {
            throw new TsdbApiError("invalid_response", "TheSportsDB event is not an object");
        }
        const raw = value;
        if (typeof raw.idEvent !== "string" || typeof raw.strEvent !== "string" || typeof raw.idLeague !== "string") {
            throw new TsdbApiError("invalid_response", "TheSportsDB event is missing its id, name or league");
        }
        const event = { idEvent: raw.idEvent, strEvent: raw.strEvent, idLeague: raw.idLeague };
        for (const field of STRING_OR_NULL_FIELDS) {
            const fieldValue = raw[field];
            if (fieldValue === undefined || fieldValue === null)
                event[field] = null;
            else if (typeof fieldValue === "string")
                event[field] = fieldValue;
            else
                throw new TsdbApiError("invalid_response", `TheSportsDB event field ${field} has an unexpected type`);
        }
        return event;
    });
}
//# sourceMappingURL=client.js.map