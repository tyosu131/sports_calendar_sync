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

export interface GoalFixturesPage {
  fixtures: GoalFixture[];
  pagination: { total: number; limit: number; offset: number; hasMore: boolean };
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
    return this.fixturesAll(teamId);
  }

  async fixturesPage(teamId: string, options: { limit: number; offset: number }): Promise<GoalFixturesPage> {
    const query = `limit=${encodeURIComponent(options.limit)}&offset=${encodeURIComponent(options.offset)}`;
    const body = await this.request(`/teams/${encodeURIComponent(teamId)}/fixtures?${query}`);
    const pagination = (body as { pagination?: unknown }).pagination;
    if (!isPagination(pagination)) {
      throw new GoalApiError("invalid_response", "GOAL fixtures response did not contain valid pagination");
    }
    return { fixtures: this.parseFixtures(body), pagination };
  }

  async fixturesAll(teamId: string, limit = 100, maxPages = 100): Promise<GoalFixture[]> {
    const byId = new Map<string, GoalFixture>();
    let offset = 0;
    for (let page = 0; page < maxPages; page += 1) {
      const result = await this.fixturesPage(teamId, { limit, offset });
      for (const fixture of result.fixtures) byId.set(fixture.id, fixture);
      if (!result.pagination.hasMore) return [...byId.values()];
      const nextOffset = result.pagination.offset + result.pagination.limit;
      if (result.pagination.limit <= 0 || nextOffset <= offset) {
        throw new GoalApiError("invalid_response", "GOAL fixtures pagination made no progress");
      }
      offset = nextOffset;
    }
    throw new GoalApiError("invalid_response", "GOAL fixtures pagination exceeded maximum pages");
  }

  upcoming(teamId: string): Promise<GoalFixture[]> {
    return this.fetch(`/teams/${encodeURIComponent(teamId)}/upcoming`);
  }

  private async fetch(path: string): Promise<GoalFixture[]> {
    return this.parseFixtures(await this.request(path));
  }

  private parseFixtures(body: unknown): GoalFixture[] {
    const envelope = body as { success?: unknown; data?: unknown };
    if (envelope.success !== true || !Array.isArray(envelope.data)) {
      throw new GoalApiError("invalid_response", "GOAL response did not contain valid fixtures");
    }
    const fixtures = envelope.data.map(normalizeGoalFixture);
    if (!fixtures.every((fixture): fixture is GoalFixture => fixture !== undefined)) {
      throw new GoalApiError("invalid_response", "GOAL response did not contain valid fixtures");
    }
    return fixtures;
  }

  private async request(path: string): Promise<unknown> {
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

type RawGoalFixture = Omit<GoalFixture, "homeScore" | "awayScore"> & {
  homeTeamScore?: unknown;
  awayTeamScore?: unknown;
  homeTeamFtScore?: unknown;
  awayTeamFtScore?: unknown;
};

function normalizeGoalFixture(value: unknown): GoalFixture | undefined {
  if (!value || typeof value !== "object") return undefined;
  const fixture = value as Partial<RawGoalFixture>;
  const team = (value: unknown): value is { id: string; name: string } =>
    !!value && typeof value === "object" &&
    typeof (value as { id?: unknown }).id === "string" &&
    typeof (value as { name?: unknown }).name === "string";
  const validFixture = typeof fixture.id === "string" && typeof fixture.kickoffUtc === "string" &&
    typeof fixture.matchStatus === "string" && team(fixture.league) &&
    typeof fixture.leagueYear === "string" &&
    team(fixture.homeTeam) && team(fixture.awayTeam) &&
    (fixture.venue === undefined || fixture.venue === null || typeof fixture.venue === "string") &&
    (fixture.matchStadium === undefined || fixture.matchStadium === null || typeof fixture.matchStadium === "string");
  if (!validFixture) return undefined;

  const scores = normalizeScorePair(fixture.homeTeamScore, fixture.awayTeamScore);
  if (scores === undefined) return undefined;
  const {
    homeTeamScore: _homeTeamScore,
    awayTeamScore: _awayTeamScore,
    homeTeamFtScore: _homeTeamFtScore,
    awayTeamFtScore: _awayTeamFtScore,
    ...canonical
  } = fixture;
  return { ...canonical, ...scores } as GoalFixture;
}

function normalizeScorePair(home: unknown, away: unknown): Pick<GoalFixture, "homeScore" | "awayScore"> | undefined {
  if (home === undefined && away === undefined) return {};
  if (home === null && away === null) return { homeScore: null, awayScore: null };
  if (typeof home !== "string" || typeof away !== "string" ||
      !/^\d+$/.test(home) || !/^\d+$/.test(away)) return undefined;
  const homeScore = Number(home);
  const awayScore = Number(away);
  if (!Number.isSafeInteger(homeScore) || !Number.isSafeInteger(awayScore)) return undefined;
  return { homeScore, awayScore };
}

function isPagination(value: unknown): value is GoalFixturesPage["pagination"] {
  if (!value || typeof value !== "object") return false;
  const page = value as Partial<GoalFixturesPage["pagination"]>;
  return Number.isInteger(page.total) && Number.isInteger(page.limit) &&
    Number.isInteger(page.offset) && typeof page.hasMore === "boolean";
}
