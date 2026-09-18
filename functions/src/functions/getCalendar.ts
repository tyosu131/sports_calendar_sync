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

const VALID_STATUSES = new Set<GameStatus>([
  "scheduled", "live", "finished", "postponed", "cancelled",
]);

function asNormalizedGame(id: string, data: DocumentData): NormalizedGame {
  const kickoff = data.startTimeUTC;
  if (!(kickoff instanceof Timestamp)) throw new Error(`Game ${id} has invalid startTimeUTC`);
  if (typeof data.homeTeamId !== "string" || typeof data.awayTeamId !== "string") {
    throw new Error(`Game ${id} has invalid team identity`);
  }
  if (typeof data.homeTeamNameJa !== "string" || typeof data.awayTeamNameJa !== "string") {
    throw new Error(`Game ${id} has invalid team names`);
  }
  if (!VALID_STATUSES.has(data.status)) throw new Error(`Game ${id} has invalid status`);

  return {
    id,
    kickoffUtc: kickoff.toDate(),
    homeTeamId: data.homeTeamId,
    awayTeamId: data.awayTeamId,
    homeTeamName: data.homeTeamNameJa,
    awayTeamName: data.awayTeamNameJa,
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

  async findUpcomingGamesForTeams(teamIds: readonly string[]): Promise<readonly NormalizedGame[]> {
    const games = new Map<string, NormalizedGame>();
    // Firestore `in` accepts at most 30 comparison values. Smaller chunks also
    // keep each home/away query and its response predictably bounded.
    for (let offset = 0; offset < teamIds.length; offset += 10) {
      const chunk = teamIds.slice(offset, offset + 10);
      const query = (field: "homeTeamId" | "awayTeamId") => this.db.collection("games")
        .where(field, "in", chunk)
        .where("startTimeUTC", ">=", this.now())
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
