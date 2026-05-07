import { Timestamp } from "firebase-admin/firestore";

// ── Sport types ───────────────────────────────────────────────────────────────

/**
 * @deprecated Legacy sport category string.  Kept for backward compatibility
 * with existing Firestore documents that store `sportType`.
 * New code should use CompetitionKey instead.
 */
export type SportType =
  | "football"
  | "baseball"
  | "basketball"
  | "americanFootball"
  | "rugby"
  | "hockey";

/**
 * Identifies a specific competition (league / tournament) in SportsRegistry.
 * Format: "{sportCategory}_{abbreviation}"
 * Examples: "football_j1", "football_premier", "baseball_npb", "basketball_nba"
 *
 * Stored in Firestore as `competitionKey` (new documents) and `sportKey`
 * (legacy alias, kept for backward compatibility).
 */
export type CompetitionKey = string;

// ── Firestore document shapes ─────────────────────────────────────────────────

export interface LeagueDoc {
  nameEn: string;
  nameJa: string;
  /** New field — matches CompetitionKey in SportsRegistry. */
  competitionKey?: CompetitionKey;
  /** @deprecated Legacy alias for competitionKey. */
  sportKey?: CompetitionKey;
  /** @deprecated Legacy sport category. */
  sportType?: SportType;
  country: string;
  logoUrl?: string;
  externalLeagueId?: number;
  /** @deprecated Use externalLeagueId. */
  rapidApiId?: number;
}

export interface TeamDoc {
  nameEn: string;
  nameJa: string;
  leagueId: string;
  /** New field — matches CompetitionKey in SportsRegistry. */
  competitionKey?: CompetitionKey;
  /** @deprecated Legacy alias for competitionKey. */
  sportKey?: CompetitionKey;
  /** @deprecated Legacy sport category. */
  sportType?: SportType;
  logoUrl?: string;
  country?: string;
  externalTeamId?: number;
  /** @deprecated Use externalTeamId. */
  rapidApiId?: number;
}

export interface BroadcastInfo {
  platform: string;
  url?: string;
  note?: string;
}

export type GameStatus =
  | "scheduled"
  | "live"
  | "finished"
  | "postponed"
  | "cancelled";

export interface GameDoc {
  /** Competition key matching CompetitionKey in SportsRegistry. */
  competitionKey?: CompetitionKey;
  /** @deprecated Legacy alias for competitionKey. */
  sportKey?: CompetitionKey;
  leagueId: string;
  homeTeamId: string;
  homeTeamNameJa: string;
  /** English team name — used as translation fallback. */
  homeTeamNameEn?: string;
  /** Team logo URL. */
  homeTeamLogoUrl?: string;
  awayTeamId: string;
  awayTeamNameJa: string;
  awayTeamNameEn?: string;
  awayTeamLogoUrl?: string;
  /** UTC Firestore Timestamp — used for calendar sync. */
  startTimeUTC: Timestamp;
  /** JST display string, e.g. "2025-07-15 19:00". */
  startTimeJST: string;
  /** Venue timezone, e.g. "Asia/Tokyo". */
  timezone: string;
  status: GameStatus;
  venue?: string;
  homeScore?: number;
  awayScore?: number;
  broadcastPlatforms: BroadcastInfo[];
  /** External API fixture ID (API-SPORTS or other source). */
  externalFixtureId?: number;
  /** @deprecated Use externalFixtureId. */
  rapidApiFixtureId?: number;
}

export interface UserDoc {
  email: string;
  displayName?: string;
  photoUrl?: string;
  /** Competition keys the user has opted into. */
  selectedCompetitions?: CompetitionKey[];
  /** Map from competitionKey to list of followed team IDs. */
  favoriteTeamIdsByCompetition?: Record<CompetitionKey, string[]>;
  /**
   * @deprecated Use favoriteTeamIdsByCompetition.
   * Kept for backward compatibility with older user profiles.
   */
  followedTeamIds?: string[];
  preferredLanguage: "ja" | "en";
  createdAt?: Timestamp;
}

// ── Translation map ───────────────────────────────────────────────────────────

/** Stored in /translationMaps/{sportType} */
export interface TranslationMapDoc {
  /** key: English name from API, value: Japanese name */
  teams: Record<string, string>;
  leagues: Record<string, string>;
}

// ── API-SPORTS response shapes (minimal — extend as needed) ───────────────────

export interface RapidApiFootballFixture {
  fixture: {
    id: number;
    date: string; // ISO 8601 UTC
    timezone: string;
    status: { short: string };
    venue?: { name: string };
  };
  league: {
    id: number;
    name: string;
  };
  teams: {
    home: { id: number; name: string; logo: string };
    away: { id: number; name: string; logo: string };
  };
  goals: {
    home: number | null;
    away: number | null;
  };
}

export interface RapidApiBaseballGame {
  id: number;
  date: string; // ISO 8601 UTC
  time: string;
  timezone: string;
  status: { short: string };
  league: { id: number; name: string };
  teams: {
    home: { id: number; name: string; logo: string };
    away: { id: number; name: string; logo: string };
  };
  scores: {
    home: { total: number | null };
    away: { total: number | null };
  };
}
