import * as functions from "firebase-functions/v1";
import { Request, Response } from "firebase-functions/v1";
import { DocumentData, Firestore, Timestamp, getFirestore } from "firebase-admin/firestore";
import {
  CalendarFeedNotFoundError,
  CalendarTeamNotFollowedError,
  CalendarUserNotFoundError,
  NormalizedGame,
  PersonalizedCalendarRepository,
  buildPersonalizedCalendar,
} from "../calendar/personalizedCalendar";
import { GameStatus } from "../types";
import { displayTeamName } from "../domain/teamDisplayNamePolicy";
import { compactCompetitionDisplayName } from "../domain/competitionDisplayPolicy";

const VALID_STATUSES = new Set<GameStatus>([
  "scheduled", "live", "finished", "postponed", "cancelled",
]);

export const CALENDAR_LOOKBACK_DAYS = 30;

/** Deterministic lower bound used by calendar retrieval queries. */
export function calendarWindowStart(now: Date): Date {
  return new Date(now.getTime() - CALENDAR_LOOKBACK_DAYS * 24 * 60 * 60 * 1000);
}

/** Validates a Firestore Game document at the Calendar domain boundary. */
export function asNormalizedGame(id: string, data: DocumentData): NormalizedGame {
  const kickoff = data.startTimeUTC;
  if (!(kickoff instanceof Timestamp)) throw new Error(`Game ${id} has invalid startTimeUTC`);
  const hasHomeTeamId = Object.prototype.hasOwnProperty.call(data, "homeTeamId");
  const hasAwayTeamId = Object.prototype.hasOwnProperty.call(data, "awayTeamId");
  const validOptionalTeamId = (present: boolean, value: unknown) =>
    !present || (typeof value === "string" && value.trim().length > 0);
  if (!validOptionalTeamId(hasHomeTeamId, data.homeTeamId) ||
      !validOptionalTeamId(hasAwayTeamId, data.awayTeamId) ||
      (!hasHomeTeamId && !hasAwayTeamId)) {
    throw new Error(`Game ${id} has invalid team identity`);
  }
  if (typeof data.homeTeamNameJa !== "string" || typeof data.awayTeamNameJa !== "string") {
    throw new Error(`Game ${id} has invalid team names`);
  }
  if (!VALID_STATUSES.has(data.status)) throw new Error(`Game ${id} has invalid status`);
  const competitionKey = data.competitionKey ?? data.sportKey;
  const competitionCompact = compactCompetitionDisplayName(competitionKey);

  return {
    id,
    kickoffUtc: kickoff.toDate(),
    ...(hasHomeTeamId ? { homeTeamId: data.homeTeamId as string } : {}),
    ...(hasAwayTeamId ? { awayTeamId: data.awayTeamId as string } : {}),
    homeTeamName: displayTeamName(competitionKey, {
      japanese: data.homeTeamNameJa,
      english: data.homeTeamNameEn,
      provider: data.homeTeamProviderName,
    }, undefined, hasHomeTeamId ? data.homeTeamId as string : undefined),
    awayTeamName: displayTeamName(competitionKey, {
      japanese: data.awayTeamNameJa,
      english: data.awayTeamNameEn,
      provider: data.awayTeamProviderName,
    }, undefined, hasAwayTeamId ? data.awayTeamId as string : undefined),
    ...(competitionCompact ? { competitionCompact } : {}),
    status: data.status,
    venue: typeof data.venue === "string" ? data.venue : undefined,
    broadcastPlatforms: Array.isArray(data.broadcastPlatforms) ?
      data.broadcastPlatforms.filter((item: unknown) =>
        typeof item === "object" && item !== null && typeof (item as { platform?: unknown }).platform === "string"
      ) : [],
  };
}

export class FirestorePersonalizedCalendarRepository implements PersonalizedCalendarRepository {
  constructor(private readonly db: Firestore, private readonly now: () => Date = () => new Date()) {}

  async findFeed(token: string) {
    const snapshot = await this.db.collection("calendarFeeds").doc(token).get();
    if (!snapshot.exists) return undefined;
    const ownerUid = snapshot.get("ownerUid");
    if (typeof ownerUid !== "string") return undefined;
    return { ownerUid, active: snapshot.get("active") === true };
  }

  async findUser(uid: string) {
    const snapshot = await this.db.collection("users").doc(uid).get();
    if (!snapshot.exists) return undefined;
    const followed = snapshot.get("followedTeamIds");
    return { followedTeamIds: Array.isArray(followed) ? followed.filter((id): id is string => typeof id === "string") : [] };
  }

  async findCalendarGamesForTeams(teamIds: readonly string[]): Promise<readonly NormalizedGame[]> {
    const games = new Map<string, NormalizedGame>();
    const windowStart = calendarWindowStart(this.now());
    // Firestore `in` accepts at most 30 comparison values. Smaller chunks also
    // keep each home/away query and its response predictably bounded.
    for (let offset = 0; offset < teamIds.length; offset += 10) {
      const chunk = teamIds.slice(offset, offset + 10);
      const query = (field: "homeTeamId" | "awayTeamId") => this.db.collection("games")
        .where(field, "in", chunk)
        .where("startTimeUTC", ">=", windowStart)
        .orderBy("startTimeUTC")
        .limit(100)
        .get();
      const [home, away] = await Promise.all([query("homeTeamId"), query("awayTeamId")]);
      for (const snapshot of [home, away]) {
        snapshot.forEach((doc) => games.set(doc.id, asNormalizedGame(doc.id, doc.data())));
      }
    }
    return [...games.values()];
  }
}

export async function serveCalendar(
  req: Pick<Request, "query">,
  res: Pick<Response, "status" | "setHeader" | "send">,
  repository: PersonalizedCalendarRepository
): Promise<void> {
  const token = typeof req.query.token === "string" ? req.query.token.trim() : "";
  const teamId = typeof req.query.teamId === "string" ? req.query.teamId.trim() : undefined;
  if (!token) {
    res.status(400).send("Missing required query parameter: token");
    return;
  }
  if (!/^[A-Za-z0-9_-]{43}$/.test(token)) {
    res.status(404).send("Calendar feed not found");
    return;
  }

  try {
    const calendar = await buildPersonalizedCalendar(repository, token, teamId || undefined);
    res.setHeader("Content-Type", "text/calendar; charset=utf-8");
    res.setHeader("Content-Disposition", 'inline; filename="sports_calendar.ics"');
    res.setHeader("Cache-Control", "private, no-store");
    res.send(calendar);
  } catch (error) {
    if (error instanceof CalendarFeedNotFoundError) {
      res.status(404).send("Calendar feed not found");
    } else if (error instanceof CalendarUserNotFoundError) {
      res.status(404).send("Calendar owner not found");
    } else if (error instanceof CalendarTeamNotFollowedError) {
      res.status(403).send("Team is not followed by calendar owner");
    } else {
      console.error("Unable to build calendar feed", error);
      res.status(500).send("Unable to build calendar feed");
    }
  }
}

export const getCalendar = functions.region("asia-northeast1").https.onRequest(
  (req, res) => serveCalendar(req, res, new FirestorePersonalizedCalendarRepository(getFirestore()))
);
