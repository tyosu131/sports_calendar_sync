"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.GoalApiClient = exports.GoalApiError = void 0;
const axios_1 = __importDefault(require("axios"));
class GoalApiError extends Error {
    constructor(kind, message, status) {
        super(message);
        this.kind = kind;
        this.status = status;
        this.name = "GoalApiError";
    }
}
exports.GoalApiError = GoalApiError;
const BASE_URL = "https://api.goal-api.com/v1";
/** Small, injectable boundary for the only two GOAL endpoints used by V1. */
class GoalApiClient {
    constructor(apiKey, http = axios_1.default, timeoutMs = 10000) {
        this.apiKey = apiKey;
        this.http = http;
        this.timeoutMs = timeoutMs;
        if (!apiKey)
            throw new Error("GOAL API key is required");
    }
    fixtures(teamId) {
        return this.fixturesAll(teamId);
    }
    async fixturesPage(teamId, options) {
        const query = `limit=${encodeURIComponent(options.limit)}&offset=${encodeURIComponent(options.offset)}`;
        const body = await this.request(`/teams/${encodeURIComponent(teamId)}/fixtures?${query}`);
        const pagination = body.pagination;
        if (!isPagination(pagination)) {
            throw new GoalApiError("invalid_response", "GOAL fixtures response did not contain valid pagination");
        }
        return { fixtures: this.parseFixtures(body), pagination };
    }
    async fixturesAll(teamId, limit = 100, maxPages = 100) {
        const byId = new Map();
        let offset = 0;
        for (let page = 0; page < maxPages; page += 1) {
            const result = await this.fixturesPage(teamId, { limit, offset });
            for (const fixture of result.fixtures)
                byId.set(fixture.id, fixture);
            if (!result.pagination.hasMore)
                return [...byId.values()];
            const nextOffset = result.pagination.offset + result.pagination.limit;
            if (result.pagination.limit <= 0 || nextOffset <= offset) {
                throw new GoalApiError("invalid_response", "GOAL fixtures pagination made no progress");
            }
            offset = nextOffset;
        }
        throw new GoalApiError("invalid_response", "GOAL fixtures pagination exceeded maximum pages");
    }
    upcoming(teamId) {
        return this.fetch(`/teams/${encodeURIComponent(teamId)}/upcoming`);
    }
    async fetch(path) {
        return this.parseFixtures(await this.request(path));
    }
    parseFixtures(body) {
        const envelope = body;
        if (envelope.success !== true || !Array.isArray(envelope.data) ||
            !envelope.data.every(isGoalFixture)) {
            throw new GoalApiError("invalid_response", "GOAL response did not contain valid fixtures");
        }
        return envelope.data;
    }
    async request(path) {
        try {
            const response = await this.http.get(`${BASE_URL}${path}`, {
                headers: { Authorization: `Bearer ${this.apiKey}` },
                timeout: this.timeoutMs,
            });
            const body = response.data;
            if (!body || typeof body !== "object") {
                throw new GoalApiError("invalid_response", "GOAL response did not contain valid fixtures");
            }
            return body;
        }
        catch (error) {
            if (error instanceof GoalApiError)
                throw error;
            const candidate = error;
            const status = candidate.response?.status;
            if (status === 429)
                throw new GoalApiError("rate_limited", "GOAL rate limit exceeded", 429);
            if (candidate.code === "ECONNABORTED" || candidate.code === "ETIMEDOUT") {
                throw new GoalApiError("timeout", "GOAL request timed out");
            }
            throw new GoalApiError("http", `GOAL request failed${status ? ` (${status})` : ""}`, status);
        }
    }
}
exports.GoalApiClient = GoalApiClient;
function isGoalFixture(value) {
    if (!value || typeof value !== "object")
        return false;
    const fixture = value;
    const team = (value) => !!value && typeof value === "object" &&
        typeof value.id === "string" &&
        typeof value.name === "string";
    return typeof fixture.id === "string" && typeof fixture.kickoffUtc === "string" &&
        typeof fixture.matchStatus === "string" && team(fixture.league) &&
        typeof fixture.leagueYear === "string" &&
        team(fixture.homeTeam) && team(fixture.awayTeam) &&
        (fixture.venue === undefined || fixture.venue === null || typeof fixture.venue === "string") &&
        (fixture.matchStadium === undefined || fixture.matchStadium === null || typeof fixture.matchStadium === "string");
}
function isPagination(value) {
    if (!value || typeof value !== "object")
        return false;
    const page = value;
    return Number.isInteger(page.total) && Number.isInteger(page.limit) &&
        Number.isInteger(page.offset) && typeof page.hasMore === "boolean";
}
//# sourceMappingURL=goalApiClient.js.map