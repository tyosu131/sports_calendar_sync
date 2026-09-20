const test = require("node:test");
const assert = require("node:assert/strict");
const { Timestamp } = require("firebase-admin/firestore");
const {
  CalendarFeedNotFoundError,
  CalendarTeamNotFollowedError,
  buildPersonalizedCalendar,
} = require("../lib/calendar/personalizedCalendar");
const {
  CALENDAR_LOOKBACK_DAYS,
  asNormalizedGame,
  calendarWindowStart,
  serveCalendar,
} = require("../lib/functions/getCalendar");

function game(id, homeTeamId, awayTeamId) {
  return {
    id,
    kickoffUtc: new Date("2026-10-01T10:00:00Z"),
    homeTeamId,
    awayTeamId,
    homeTeamName: homeTeamId ?? "Unmapped Home",
    awayTeamName: awayTeamId ?? "Unmapped Away",
    status: "scheduled",
  };
}

function repository(changes = {}) {
  return {
    findFeed: async () => ({ ownerUid: "user-1", active: true }),
    findUser: async () => ({ followedTeamIds: ["team-a", "team-b", "team-a"] }),
    findCalendarGamesForTeams: async () => [
      game("included-home", "team-a", "other"),
      game("included-away", "other", "team-b"),
      game("not-a-member", "other", "another"),
    ],
    ...changes,
  };
}

test("token resolves owner and canonical follows before fixtures are loaded", async () => {
  const calls = [];
  const source = repository({
    findFeed: async (token) => { calls.push(["feed", token]); return { ownerUid: "user-1", active: true }; },
    findUser: async (uid) => { calls.push(["user", uid]); return { followedTeamIds: ["team-a", "team-a"] }; },
    findCalendarGamesForTeams: async (ids) => { calls.push(["games", [...ids]]); return [game("one", "team-a", "other")]; },
  });

  const calendar = await buildPersonalizedCalendar(source, "secret");
  assert.deepEqual(calls, [["feed", "secret"], ["user", "user-1"], ["games", ["team-a"]]]);
  assert.match(calendar, /UID:one@sports-calendar-sync/);
});

test("membership filtering excludes games unrelated to followed teams", async () => {
  const calendar = await buildPersonalizedCalendar(repository(), "secret");
  assert.match(calendar, /UID:included-home@/);
  assert.match(calendar, /UID:included-away@/);
  assert.doesNotMatch(calendar, /not-a-member/);
});

test("personalized filtering includes either mapped side and fails closed otherwise", async () => {
  const calendar = await buildPersonalizedCalendar(repository({
    findUser: async () => ({ followedTeamIds: ["arsenal"] }),
    findCalendarGamesForTeams: async () => [
      game("arsenal-home", "arsenal", undefined),
      game("arsenal-away", undefined, "arsenal"),
      game("neither-mapped", undefined, undefined),
      game("mapped-not-followed", "brighton", undefined),
    ],
  }), "secret");
  assert.match(calendar, /UID:arsenal-home@/);
  assert.match(calendar, /UID:arsenal-away@/);
  assert.doesNotMatch(calendar, /neither-mapped/);
  assert.doesNotMatch(calendar, /mapped-not-followed/);
});

test("Firestore normalization accepts one canonical side and rejects invalid identity", () => {
  const base = {
    startTimeUTC: Timestamp.fromDate(new Date("2026-10-01T10:00:00Z")),
    homeTeamNameJa: "Opponent FC",
    awayTeamNameJa: "アーセナル",
    status: "scheduled",
  };
  const awayMapped = asNormalizedGame("away-mapped", { ...base, awayTeamId: "arsenal" });
  assert.equal(awayMapped.homeTeamId, undefined);
  assert.equal(awayMapped.awayTeamId, "arsenal");
  assert.equal(awayMapped.awayTeamName, "Arsenal");
  const homeMapped = asNormalizedGame("home-mapped", {
    ...base, homeTeamId: "arsenal", homeTeamNameJa: "アーセナル", awayTeamNameJa: "Opponent FC",
  });
  assert.equal(homeMapped.homeTeamId, "arsenal");
  assert.equal(homeMapped.homeTeamName, "Arsenal");
  assert.equal(homeMapped.awayTeamId, undefined);
  assert.throws(() => asNormalizedGame("neither", base), /invalid team identity/);
  assert.throws(() => asNormalizedGame("empty", { ...base, awayTeamId: " " }), /invalid team identity/);
  assert.throws(() => asNormalizedGame("wrong-type", { ...base, homeTeamId: 7 }), /invalid team identity/);
});

test("Firestore scores and venue flow through the same personalized ICS feed", async () => {
  const normalized = asNormalizedGame("result", {
    startTimeUTC: Timestamp.fromDate(new Date("2026-09-20T10:00:00Z")),
    competitionKey: "football_j1",
    homeTeamId: "kawasaki_frontale",
    awayTeamId: "nagoya_grampus",
    homeTeamNameJa: "川崎フロンターレ",
    awayTeamNameJa: "名古屋グランパス",
    status: "finished",
    homeScore: 3,
    awayScore: 0,
    venue: "等々力陸上競技場",
  });
  const calendar = await buildPersonalizedCalendar(repository({
    findUser: async () => ({ followedTeamIds: ["kawasaki_frontale"] }),
    findCalendarGamesForTeams: async () => [normalized],
  }), "secret");
  assert.match(calendar, /SUMMARY:\[J1\] 川崎フロンターレ 3-0 名古屋グランパス/);
  assert.match(calendar, /LOCATION:等々力陸上競技場/);
  assert.match(calendar, /UID:result@sports-calendar-sync/);
});

test("Firestore normalization preserves 0-0 and rejects malformed score pairs", () => {
  const base = {
    startTimeUTC: Timestamp.fromDate(new Date("2026-10-01T10:00:00Z")),
    homeTeamId: "home",
    awayTeamId: "away",
    homeTeamNameJa: "Home",
    awayTeamNameJa: "Away",
    status: "finished",
  };
  const nilNil = asNormalizedGame("nil-nil", { ...base, homeScore: 0, awayScore: 0 });
  assert.deepEqual([nilNil.homeScore, nilNil.awayScore], [0, 0]);
  assert.throws(() => asNormalizedGame("one-sided", { ...base, homeScore: 1 }), /invalid scores/);
  assert.throws(() => asNormalizedGame("decimal", { ...base, homeScore: 1.5, awayScore: 0 }), /invalid scores/);
});

test("team feed must be a member of the owner's canonical follows", async () => {
  await assert.rejects(
    buildPersonalizedCalendar(repository(), "secret", "other"),
    CalendarTeamNotFollowedError,
  );
  const calendar = await buildPersonalizedCalendar(repository(), "secret", "team-b");
  assert.doesNotMatch(calendar, /included-home/);
  assert.match(calendar, /included-away/);
});

test("inactive and unknown feed credentials fail closed", async () => {
  await assert.rejects(
    buildPersonalizedCalendar(repository({ findFeed: async () => ({ ownerUid: "user-1", active: false }) }), "revoked"),
    CalendarFeedNotFoundError,
  );
  await assert.rejects(
    buildPersonalizedCalendar(repository({ findFeed: async () => undefined }), "unknown"),
    CalendarFeedNotFoundError,
  );
});

test("a user with no follows receives an empty calendar without a games query", async () => {
  let queried = false;
  const calendar = await buildPersonalizedCalendar(repository({
    findUser: async () => ({ followedTeamIds: [] }),
    findCalendarGamesForTeams: async () => { queried = true; return []; },
  }), "secret");
  assert.equal(queried, false);
  assert.doesNotMatch(calendar, /BEGIN:VEVENT/);
});

test("calendar window begins exactly 30 days before the injected time", () => {
  const now = new Date("2026-09-18T12:34:56.789Z");
  assert.equal(CALENDAR_LOOKBACK_DAYS, 30);
  assert.equal(calendarWindowStart(now).toISOString(), "2026-08-19T12:34:56.789Z");
  assert.equal(now.toISOString(), "2026-09-18T12:34:56.789Z");
});

test("HTTP boundary requires token and publishes private deterministic ICS", async () => {
  const response = { statusCode: 200, headers: {}, body: undefined };
  const res = {
    status(code) { response.statusCode = code; return this; },
    setHeader(name, value) { response.headers[name] = value; },
    send(body) { response.body = body; return this; },
  };
  const token = "a".repeat(43);
  await serveCalendar({ query: { token } }, res, repository());
  assert.equal(response.statusCode, 200);
  assert.equal(response.headers["Content-Type"], "text/calendar; charset=utf-8");
  assert.equal(response.headers["Cache-Control"], "private, no-store");
  assert.match(response.body, /BEGIN:VCALENDAR/);

  await serveCalendar({ query: {} }, res, repository());
  assert.equal(response.statusCode, 400);
  assert.match(response.body, /token/);

  await serveCalendar({ query: { token: "not-a-feed-token" } }, res, repository());
  assert.equal(response.statusCode, 404);
});
