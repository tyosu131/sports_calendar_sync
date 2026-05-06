/**
 * getCalendar.ts
 *
 * HTTP Cloud Function (v1 API) that generates a dynamic .ics (iCalendar) file
 * for a user's followed teams.
 *
 * URL: https://asia-northeast1-sports-calendar-sync-a4564.cloudfunctions.net/getCalendar
 * Query params:
 *   - uid: Firebase user ID (required)
 *   - teamId: (optional) restrict to a single team
 */

import * as functions from "firebase-functions/v1";
import { Request, Response } from "firebase-functions/v1";
import { getFirestore } from "firebase-admin/firestore";
import ical, { ICalCalendarMethod } from "ical-generator";
import { DateTime } from "luxon";
import { GameDoc, UserDoc } from "../types";

export const getCalendar = functions
  .region("asia-northeast1")
  .https.onRequest(async (req: Request, res: Response) => {
    const uid = req.query.uid as string | undefined;
    const teamId = req.query.teamId as string | undefined;

    if (!uid) {
      res.status(400).send("Missing required query parameter: uid");
      return;
    }

    const db = getFirestore();

    // 1. Load user profile to get followed team IDs
    const userDoc = await db.collection("users").doc(uid).get();
    if (!userDoc.exists) {
      res.status(404).send("User not found");
      return;
    }

    const userData = userDoc.data() as UserDoc;
    let teamIds: string[] = userData.followedTeamIds ?? [];

    // If a specific teamId is requested, filter to just that team
    if (teamId) {
      if (!teamIds.includes(teamId)) {
        res.status(403).send("Team not in user's followed list");
        return;
      }
      teamIds = [teamId];
    }

    if (teamIds.length === 0) {
      const cal = ical({ name: "スポーツカレンダー" });
      res.setHeader("Content-Type", "text/calendar; charset=utf-8");
      res.setHeader(
        "Content-Disposition",
        'attachment; filename="sports_calendar.ics"'
      );
      res.send(cal.toString());
      return;
    }

    // 2. Fetch upcoming games for all followed teams
    const now = new Date();
    const gamesMap = new Map<string, GameDoc>();

    const chunkSize = 10;
    for (let i = 0; i < teamIds.length; i += chunkSize) {
      const chunk = teamIds.slice(i, i + chunkSize);

      const [homeSnap, awaySnap] = await Promise.all([
        db
          .collection("games")
          .where("homeTeamId", "in", chunk)
          .where("startTimeUTC", ">=", now)
          .orderBy("startTimeUTC")
          .limit(100)
          .get(),
        db
          .collection("games")
          .where("awayTeamId", "in", chunk)
          .where("startTimeUTC", ">=", now)
          .orderBy("startTimeUTC")
          .limit(100)
          .get(),
      ]);

      homeSnap.forEach((doc) => gamesMap.set(doc.id, doc.data() as GameDoc));
      awaySnap.forEach((doc) => gamesMap.set(doc.id, doc.data() as GameDoc));
    }

    // 3. Build iCalendar
    const cal = ical({
      name: "スポーツカレンダー",
      description: "フォロー中チームの試合日程",
      method: ICalCalendarMethod.PUBLISH,
      prodId: {
        company: "sports-calendar-sync",
        product: "sports-calendar-sync",
        language: "JA",
      },
    });

    for (const [gameId, game] of gamesMap) {
      const startUtc = game.startTimeUTC.toDate();
      const endUtc = new Date(startUtc.getTime() + 2 * 60 * 60 * 1000);

      const broadcastLines =
        game.broadcastPlatforms.length > 0
          ? `\n📺 視聴: ${game.broadcastPlatforms.map((b) => b.platform).join(" / ")}`
          : "";

      const jstString = DateTime.fromJSDate(startUtc, { zone: "utc" })
        .setZone("Asia/Tokyo")
        .toFormat("M月d日 HH:mm");

      cal.createEvent({
        id: gameId,
        summary: `${game.homeTeamNameJa} vs ${game.awayTeamNameJa}`,
        description: `${jstString} (JST)${broadcastLines}`,
        location: game.venue,
        start: startUtc,
        end: endUtc,
        timezone: "UTC",
      });
    }

    // 4. Return .ics response
    res.setHeader("Content-Type", "text/calendar; charset=utf-8");
    res.setHeader(
      "Content-Disposition",
      'attachment; filename="sports_calendar.ics"'
    );
    res.setHeader("Cache-Control", "public, max-age=3600");
    res.send(cal.toString());
  });
