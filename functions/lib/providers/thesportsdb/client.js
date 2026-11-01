"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.TheSportsDbClient = exports.TsdbApiError = void 0;
exports.parseEvents = parseEvents;
const axios_1 = __importDefault(require("axios"));
class TsdbApiError extends Error {
    constructor(kind, message, status, 
    /** Seconds the provider asked us to wait (Retry-After), when given. */
    retryAfterSeconds) {
        super(message);
        this.kind = kind;
        this.status = status;
        this.retryAfterSeconds = retryAfterSeconds;
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
 * Requests are spaced by [minIntervalMs]. A rate limit (429) or a non-JSON
 * body (seen when calls come too fast) is retried up to [maxRetries] times,
 * waiting the provider's Retry-After when given, otherwise a growing delay
 * starting at [retryDelayMs].
 */
class TheSportsDbClient {
    /** A retry wait that would pass this epoch-ms deadline is not taken; the error is thrown instead. */
    setDeadline(epochMs) {
        this.deadlineMs = epochMs;
    }
    constructor(apiKey, http = axios_1.default, minIntervalMs = 5000, retryDelayMs = 30000, sleep = (ms) => new Promise((r) => setTimeout(r, ms)), timeoutMs = 10000, maxRetries = 3, log = (message, detail) => console.warn(message, detail)) {
        this.apiKey = apiKey;
        this.http = http;
        this.minIntervalMs = minIntervalMs;
        this.retryDelayMs = retryDelayMs;
        this.sleep = sleep;
        this.timeoutMs = timeoutMs;
        this.maxRetries = maxRetries;
        this.log = log;
        this.lastRequestAt = 0;
        this.deadlineMs = Number.POSITIVE_INFINITY;
        if (!apiKey)
            throw new Error("TheSportsDB API key is required");
    }
    async eventsRound(leagueId, round, season) {
        const query = `id=${encodeURIComponent(leagueId)}&r=${encodeURIComponent(round)}&s=${encodeURIComponent(season)}`;
        const path = `/eventsround.php?${query}`;
        for (let attempt = 0;; attempt += 1) {
            try {
                return parseEvents(await this.request(path));
            }
            catch (error) {
                if (!(error instanceof TsdbApiError) ||
                    (error.kind !== "invalid_response" && error.kind !== "rate_limited") ||
                    attempt >= this.maxRetries)
                    throw error;
                const delay = Math.max((error.retryAfterSeconds ?? 0) * 1000, this.retryDelayMs * (attempt + 1));
                if (Date.now() + delay > this.deadlineMs)
                    throw error;
                this.log("TheSportsDB throttled; waiting before retry", {
                    kind: error.kind, status: error.status, attempt: attempt + 1, waitMs: delay,
                    retryAfterSeconds: error.retryAfterSeconds,
                });
                await this.sleep(delay);
            }
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
            if (status === 429) {
                const header = candidate.response?.headers?.["retry-after"];
                const seconds = Number(Array.isArray(header) ? header[0] : header);
                throw new TsdbApiError("rate_limited", "TheSportsDB rate limit exceeded", 429, Number.isFinite(seconds) && seconds > 0 && seconds <= 300 ? seconds : undefined);
            }
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