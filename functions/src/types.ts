import { Timestamp } from "firebase-admin/firestore";

// ── Sport types ───────────────────────────────────────────────────────────────

export type SportType =
  | "football"
  | "baseball"
  | "basketball"
  | "americanFootball"
  | "rugby";

// ── Firestore document shapes ─────────────────────────────────────────────────

export interface LeagueDoc {
  nameEn: string;
  nameJa: string;
  sportType: SportType;
  country: string;
  logoUrl?: string;
  rapidApiId?: number;
}

export interface TeamDoc {
  nameEn: string;
  nameJa: string;
  leagueId: string;
  sportType: SportType;
  logoUrl?: string;
  country?: string;
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
  leagueId: string;
  homeTeamId: string;
  homeTeamNameJa: string;
  awayTeamId: string;
  awayTeamNameJa: string;
  /** UTC Firestore Timestamp — used for calendar sync */
  startTimeUTC: Timestamp;
  /** JST display string e.g. "2025-07-15 19:00" */
  startTimeJST: string;
  /** Venue timezone e.g. "America/New_York" */
  timezone: string;
  status: GameStatus;
  venue?: string;
  homeScore?: number;
  awayScore?: number;
  broadcastPlatforms: BroadcastInfo[];
  rapidApiFixtureId?: number;
}

export interface UserDoc {
  email: string;
  displayName?: string;
  photoUrl?: string;
  followedTeamIds: string[];
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

// ── RapidAPI response shapes (minimal — extend as needed) ─────────────────────

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
