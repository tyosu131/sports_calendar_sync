const test = require("node:test");
const assert = require("node:assert/strict");
const {
  CalendarFeedNotFoundError,
  CalendarTeamNotFollowedError,
  buildPersonalizedCalendar,
} = require("../lib/calendar/personalizedCalendar");
const { serveCalendar } = require("../lib/functions/getCalendar");

function game(id, homeTeamId, awayTeamId) {
  return {
    id,
    kickoffUtc: new Date("2026-10-01T10:00:00Z"),
    homeTeamId,
    awayTeamId,
    homeTeamName: homeTeamId,
    awayTeamName: awayTeamId,
    status: "scheduled",
  };
}

function repository(changes = {}) {
  return {
    findFeed: async () => ({ ownerUid: "user-1", active: true }),
    findUser: async () => ({ followedTeamIds: ["team-a", "team-b", "team-a"] }),
    findUpcomingGamesForTeams: async () => [
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
    findUpcomingGamesForTeams: async (ids) => { calls.push(["games", [...ids]]); return [game("one", "team-a", "other")]; },
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
    findUpcomingGamesForTeams: async () => { queried = true; return []; },
  }), "secret");
  assert.equal(queried, false);
  assert.doesNotMatch(calendar, /BEGIN:VEVENT/);
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
