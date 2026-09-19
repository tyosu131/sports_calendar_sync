import axios, { AxiosInstance } from "axios";
import { GoalFixture } from "../../types";

export type GoalApiErrorKind = "rate_limited" | "timeout" | "http" | "invalid_response";

export class GoalApiError extends Error {
  constructor(public readonly kind: GoalApiErrorKind, message: string, public readonly status?: number) {
    super(message);
    this.name = "GoalApiError";
  }
}

export interface GoalHttpClient {
  get(url: string, config: { headers: Record<string, string>; timeout: number }): Promise<{ data: unknown }>;
}

const BASE_URL = "https://api.goal-api.com/v1";

/** Small, injectable boundary for the only two GOAL endpoints used by V1. */
export class GoalApiClient {
  constructor(
    private readonly apiKey: string,
    private readonly http: GoalHttpClient = axios as AxiosInstance,
    private readonly timeoutMs = 10_000
  ) {
    if (!apiKey) throw new Error("GOAL API key is required");
  }

  fixtures(teamId: string): Promise<GoalFixture[]> {
    return this.fetch(`/teams/${encodeURIComponent(teamId)}/fixtures`);
  }

  upcoming(teamId: string): Promise<GoalFixture[]> {
    return this.fetch(`/teams/${encodeURIComponent(teamId)}/upcoming`);
  }

  private async fetch(path: string): Promise<GoalFixture[]> {
    try {
      const response = await this.http.get(`${BASE_URL}${path}`, {
        headers: { Authorization: `Bearer ${this.apiKey}` },
        timeout: this.timeoutMs,
      });
      const body = response.data;
      if (!body || typeof body !== "object") {
        throw new GoalApiError("invalid_response", "GOAL response did not contain valid fixtures");
      }
      const envelope = body as { success?: unknown; data?: unknown };
      if (envelope.success !== true || !Array.isArray(envelope.data) ||
          !envelope.data.every(isGoalFixture)) {
        throw new GoalApiError("invalid_response", "GOAL response did not contain valid fixtures");
      }
      return envelope.data;
    } catch (error: unknown) {
      if (error instanceof GoalApiError) throw error;
      const candidate = error as { code?: string; response?: { status?: number } };
      const status = candidate.response?.status;
      if (status === 429) throw new GoalApiError("rate_limited", "GOAL rate limit exceeded", 429);
      if (candidate.code === "ECONNABORTED" || candidate.code === "ETIMEDOUT") {
        throw new GoalApiError("timeout", "GOAL request timed out");
      }
      throw new GoalApiError("http", `GOAL request failed${status ? ` (${status})` : ""}`, status);
    }
  }
}

function isGoalFixture(value: unknown): value is GoalFixture {
  if (!value || typeof value !== "object") return false;
  const fixture = value as Partial<GoalFixture>;
  const team = (value: unknown): value is { id: string; name: string } =>
    !!value && typeof value === "object" &&
    typeof (value as { id?: unknown }).id === "string" &&
    typeof (value as { name?: unknown }).name === "string";
  return typeof fixture.id === "string" && typeof fixture.kickoffUtc === "string" &&
    typeof fixture.matchStatus === "string" && team(fixture.league) &&
    team(fixture.homeTeam) && team(fixture.awayTeam) &&
    (fixture.venue === null || typeof fixture.venue === "string");
}
