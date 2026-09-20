import { createHash } from "crypto";
import { CalendarGame } from "../calendar/icsBuilder";
import { presentCalendarGame } from "../calendar/eventPresentation";

export const MANAGED_EVENT_MARKER = "1";
export const SYNTHETIC_EVENT_DURATION_MS = 2 * 60 * 60 * 1000;

export interface GoogleEvent {
  id: string;
  summary: string;
  location?: string;
  status: "confirmed" | "tentative" | "cancelled";
  start: {dateTime: string};
  end: {dateTime: string};
  extendedProperties: {private: {sportsCalendarSync: string; gameId: string}};
}

export interface ReconcileGateway {
  listManaged(calendarId: string): Promise<readonly GoogleEvent[]>;
  insert(calendarId: string, event: GoogleEvent): Promise<void>;
  update(calendarId: string, eventId: string, event: GoogleEvent): Promise<void>;
  remove(calendarId: string, eventId: string): Promise<void>;
}

export interface ReconcileSummary {created: number; updated: number; deleted: number; unchanged: number}

/** Google permits base32hex event IDs; a prefixed SHA-256 hex digest is stable and valid. */
export function googleEventId(gameId: string): string {
  if (!gameId) throw new Error("Game id is required");
  return `sc${createHash("sha256").update(gameId).digest("hex")}`;
}

export function googleEventFor(game: CalendarGame): GoogleEvent {
  const view = presentCalendarGame(game);
  return {
    id: googleEventId(game.id), summary: view.title,
    ...(view.venue ? {location: view.venue} : {}),
    status: view.status === "cancelled" ? "cancelled" : view.status === "postponed" ? "tentative" : "confirmed",
    start: {dateTime: game.kickoffUtc.toISOString()},
    // Google requires an end. It is adapter-only synthetic data, never canonical provider truth.
    end: {dateTime: new Date(game.kickoffUtc.getTime() + SYNTHETIC_EVENT_DURATION_MS).toISOString()},
    extendedProperties: {private: {sportsCalendarSync: MANAGED_EVENT_MARKER, gameId: game.id}},
  };
}

function signature(event: GoogleEvent): string {
  return JSON.stringify({summary: event.summary, location: event.location ?? null, status: event.status,
    start: event.start, end: event.end, extendedProperties: event.extendedProperties});
}

export async function reconcileEvents(gateway: ReconcileGateway, calendarId: string,
  games: readonly CalendarGame[]): Promise<ReconcileSummary> {
  const desired = new Map(games.map(game => { const event = googleEventFor(game); return [event.id, event]; }));
  const existing = new Map((await gateway.listManaged(calendarId))
    .filter(event => event.extendedProperties?.private?.sportsCalendarSync === MANAGED_EVENT_MARKER)
    .map(event => [event.id, event]));
  const result = {created: 0, updated: 0, deleted: 0, unchanged: 0};
  for (const [id, event] of desired) {
    const current = existing.get(id);
    if (!current) { await gateway.insert(calendarId, event); result.created++; }
    else if (signature(current) !== signature(event)) { await gateway.update(calendarId, id, event); result.updated++; }
    else result.unchanged++;
    existing.delete(id);
  }
  for (const id of existing.keys()) { await gateway.remove(calendarId, id); result.deleted++; }
  return result;
}
