import axios, { AxiosInstance } from "axios";

/** Fields this app reads from a TheSportsDB v1 event. Everything else is ignored. */
export interface TsdbEvent {
  idEvent: string;
  strEvent: string;
  strSeason: string | null;
  idLeague: string;
  intRound: string | null;
  strHomeTeam: string | null;
  strAwayTeam: string | null;
  idHomeTeam: string | null;
  idAwayTeam: string | null;
  intHomeScore: string | null;
  intAwayScore: string | null;
  /** UTC instant without a zone suffix, e.g. "2026-01-24T22:00:00". */
  strTimestamp: string | null;
  /** Venue wall clock "HH:mm:ss". The local date field is unreliable and not read. */
  strTimeLocal: string | null;
  strVenue: string | null;
  strCountry: string | null;
  strStatus: string | null;
  strPostponed: string | null;
}

export type TsdbErrorKind = "rate_limited" | "timeout" | "http" | "invalid_response";

export class TsdbApiError extends Error {
  constructor(
    public readonly kind: TsdbErrorKind,
    message: string,
    public readonly status?: number,
    /** Seconds the provider asked us to wait (Retry-After), when given. */
    public readonly retryAfterSeconds?: number
  ) {
    super(message);
    this.name = "TsdbApiError";
  }
}

export interface TsdbHttpClient {
  get(url: string, config: { timeout: number; responseType: "text" }): Promise<{ data: unknown }>;
}

export interface TsdbEventSource {
  eventsRound(leagueId: string, round: number, season: string): Promise<TsdbEvent[]>;
}

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
export class TheSportsDbClient implements TsdbEventSource {
  private lastRequestAt = 0;

  constructor(
    private readonly apiKey: string,
    private readonly http: TsdbHttpClient = axios as AxiosInstance,
    private readonly minIntervalMs = 5_000,
    private readonly retryDelayMs = 30_000,
    private readonly sleep: (ms: number) => Promise<void> = (ms) => new Promise((r) => setTimeout(r, ms)),
    private readonly timeoutMs = 10_000,
    private readonly maxRetries = 3,
    private readonly log: (message: string, detail: object) => void = (message, detail) => console.warn(message, detail)
  ) {
    if (!apiKey) throw new Error("TheSportsDB API key is required");
  }

  async eventsRound(leagueId: string, round: number, season: string): Promise<TsdbEvent[]> {
    const query = `id=${encodeURIComponent(leagueId)}&r=${encodeURIComponent(round)}&s=${encodeURIComponent(season)}`;
    const path = `/eventsround.php?${query}`;
    for (let attempt = 0; ; attempt += 1) {
      try {
        return parseEvents(await this.request(path));
      } catch (error) {
        if (!(error instanceof TsdbApiError) ||
            (error.kind !== "invalid_response" && error.kind !== "rate_limited") ||
            attempt >= this.maxRetries) throw error;
        const delay = Math.max((error.retryAfterSeconds ?? 0) * 1000, this.retryDelayMs * (attempt + 1));
        this.log("TheSportsDB throttled; waiting before retry", {
          kind: error.kind, status: error.status, attempt: attempt + 1, waitMs: delay,
          retryAfterSeconds: error.retryAfterSeconds,
        });
        await this.sleep(delay);
      }
    }
  }

  private async request(path: string): Promise<unknown> {
    const wait = this.lastRequestAt + this.minIntervalMs - Date.now();
    if (this.lastRequestAt > 0 && wait > 0) await this.sleep(wait);
    this.lastRequestAt = Date.now();
    let text: unknown;
    try {
      const response = await this.http.get(`${BASE_URL}/${encodeURIComponent(this.apiKey)}${path}`, {
        timeout: this.timeoutMs,
        responseType: "text",
      });
      text = response.data;
    } catch (error: unknown) {
      const candidate = error as {
        code?: string;
        response?: { status?: number; headers?: Record<string, unknown> };
      };
      const status = candidate.response?.status;
      if (status === 429) {
        const header = candidate.response?.headers?.["retry-after"];
        const seconds = Number(Array.isArray(header) ? header[0] : header);
        throw new TsdbApiError("rate_limited", "TheSportsDB rate limit exceeded", 429,
          Number.isFinite(seconds) && seconds > 0 && seconds <= 300 ? seconds : undefined);
      }
      if (candidate.code === "ECONNABORTED" || candidate.code === "ETIMEDOUT") {
        throw new TsdbApiError("timeout", "TheSportsDB request timed out");
      }
      throw new TsdbApiError("http", `TheSportsDB request failed${status ? ` (${status})` : ""}`, status);
    }
    if (typeof text === "object" && text !== null) return text;
    if (typeof text !== "string") throw new TsdbApiError("invalid_response", "TheSportsDB returned no body");
    try {
      return JSON.parse(text);
    } catch {
      throw new TsdbApiError("invalid_response", "TheSportsDB returned a non-JSON body");
    }
  }
}

const STRING_OR_NULL_FIELDS: readonly (keyof TsdbEvent)[] = [
  "strSeason", "intRound", "strHomeTeam", "strAwayTeam", "idHomeTeam", "idAwayTeam",
  "intHomeScore", "intAwayScore", "strTimestamp", "strTimeLocal", "strVenue", "strCountry",
  "strStatus", "strPostponed",
];

/** `{"events": null}` is an empty round. Anything malformed rejects the response. */
export function parseEvents(body: unknown): TsdbEvent[] {
  if (!body || typeof body !== "object" || !("events" in body)) {
    throw new TsdbApiError("invalid_response", "TheSportsDB response has no events field");
  }
  const events = (body as { events: unknown }).events;
  if (events === null) return [];
  if (!Array.isArray(events)) throw new TsdbApiError("invalid_response", "TheSportsDB events is not a list");
  return events.map((value) => {
    if (!value || typeof value !== "object") {
      throw new TsdbApiError("invalid_response", "TheSportsDB event is not an object");
    }
    const raw = value as Record<string, unknown>;
    if (typeof raw.idEvent !== "string" || typeof raw.strEvent !== "string" || typeof raw.idLeague !== "string") {
      throw new TsdbApiError("invalid_response", "TheSportsDB event is missing its id, name or league");
    }
    const event: Record<string, unknown> = { idEvent: raw.idEvent, strEvent: raw.strEvent, idLeague: raw.idLeague };
    for (const field of STRING_OR_NULL_FIELDS) {
      const fieldValue = raw[field];
      if (fieldValue === undefined || fieldValue === null) event[field] = null;
      else if (typeof fieldValue === "string") event[field] = fieldValue;
      else throw new TsdbApiError("invalid_response", `TheSportsDB event field ${field} has an unexpected type`);
    }
    return event as unknown as TsdbEvent;
  });
}
