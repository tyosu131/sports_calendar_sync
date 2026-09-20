import { GameStatus } from "../types";

export interface CalendarGame {
  id: string;
  kickoffUtc: Date;
  homeTeamName: string;
  awayTeamName: string;
  competitionCompact?: string;
  status: GameStatus;
  homeScore?: number;
  awayScore?: number;
  venue?: string | null;
  broadcastPlatforms?: Array<{ platform: string }> | null;
}

const CRLF = "\r\n";

function text(value: string): string {
  return value
    .replace(/\\/g, "\\\\")
    .replace(/\r\n|\r|\n/g, "\\n")
    .replace(/,/g, "\\,")
    .replace(/;/g, "\\;");
}

function utc(date: Date): string {
  if (Number.isNaN(date.getTime())) throw new Error("Invalid kickoffUtc");
  return date.toISOString().replace(/[-:]/g, "").replace(/\.\d{3}Z$/, "Z");
}

/** Builds a stable UID from domain identity only, never from mutable game data. */
export function calendarEventUid(gameId: string): string {
  if (!gameId) throw new Error("Game id is required");
  return `${gameId}@sports-calendar-sync`;
}

/** Pure, provider-independent and byte-for-byte deterministic iCalendar output. */
export function buildCalendar(games: readonly CalendarGame[]): string {
  const unique = new Map<string, CalendarGame>();
  for (const game of games) {
    if (!unique.has(game.id)) unique.set(game.id, game);
  }

  const events = [...unique.values()].sort((a, b) => a.id.localeCompare(b.id));
  const lines = [
    "BEGIN:VCALENDAR",
    "VERSION:2.0",
    "PRODID:-//sports-calendar-sync//Calendar V1//EN",
    "CALSCALE:GREGORIAN",
    "METHOD:PUBLISH",
    "X-WR-CALNAME:Sports Calendar",
  ];

  for (const game of events) {
    const allowed: readonly GameStatus[] = [
      "scheduled", "live", "finished", "postponed", "cancelled",
    ];
    if (!allowed.includes(game.status)) throw new Error(`Unknown game status: ${game.status}`);
    lines.push("BEGIN:VEVENT");
    lines.push(`UID:${text(calendarEventUid(game.id))}`);
    // DTSTAMP is required by RFC 5545. A constant value avoids introducing a
    // clock dependency; freshness is represented by each game's DTSTART.
    lines.push("DTSTAMP:19700101T000000Z");
    lines.push(`DTSTART:${utc(game.kickoffUtc)}`);
    const competition = game.competitionCompact ? `[${game.competitionCompact}] ` : "";
    const hasResult = game.status === "finished" &&
      Number.isInteger(game.homeScore) && Number.isInteger(game.awayScore) &&
      game.homeScore! >= 0 && game.awayScore! >= 0;
    const matchup = hasResult
      ? `${game.homeTeamName} ${game.homeScore}-${game.awayScore} ${game.awayTeamName}`
      : `${game.homeTeamName} vs ${game.awayTeamName}`;
    lines.push(`SUMMARY:${text(`${competition}${matchup}`)}`);
    if (game.venue) lines.push(`LOCATION:${text(game.venue)}`);
    const platforms = game.broadcastPlatforms?.map((item) => item.platform).filter(Boolean);
    if (platforms?.length) lines.push(`DESCRIPTION:${text(`Viewing: ${platforms.join(" / ")}`)}`);
    if (game.status === "cancelled") lines.push("STATUS:CANCELLED");
    // RFC 5545 has no POSTPONED status. TENTATIVE preserves the UID while
    // communicating that the published kickoff is not confirmed.
    if (game.status === "postponed") lines.push("STATUS:TENTATIVE");
    lines.push("END:VEVENT");
  }
  lines.push("END:VCALENDAR", "");
  return lines.join(CRLF);
}
