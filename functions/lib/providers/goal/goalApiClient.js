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
        return this.fetch(`/teams/${encodeURIComponent(teamId)}/fixtures`);
    }
    upcoming(teamId) {
        return this.fetch(`/teams/${encodeURIComponent(teamId)}/upcoming`);
    }
    async fetch(path) {
        try {
            const response = await this.http.get(`${BASE_URL}${path}`, {
                headers: { Authorization: `Bearer ${this.apiKey}` },
                timeout: this.timeoutMs,
            });
            const body = response.data;
            if (!body || !Array.isArray(body.fixtures) || !body.fixtures.every(isGoalFixture)) {
                throw new GoalApiError("invalid_response", "GOAL response did not contain valid fixtures");
            }
            return body.fixtures;
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
        team(fixture.homeTeam) && team(fixture.awayTeam) &&
        (fixture.venue === null || typeof fixture.venue === "string");
}
//# sourceMappingURL=goalApiClient.js.map