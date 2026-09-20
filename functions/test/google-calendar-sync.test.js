const assert = require("node:assert/strict");
const test = require("node:test");
const crypto = require("node:crypto");
const {encryptRefreshToken} = require("../lib/googleCalendar/connectionService");
const {googleEventId, googleEventFor, reconcileEvents} = require("../lib/googleCalendar/reconciliation");
const {GoogleCalendarSyncService, CredentialError, syncUsersBounded} = require("../lib/googleCalendar/syncService");
const {classifyCalendarLookupFailure, MANAGED_EVENT_LIST_PARAMS} = require("../lib/functions/googleCalendarConnection");

const game = (overrides = {}) => ({id: "game/1", kickoffUtc: new Date("2026-09-20T10:00:00Z"),
  homeTeamName: "Arsenal", awayTeamName: "Chelsea", competitionCompact: "PL", status: "scheduled", venue: "Emirates", ...overrides});

class Events {
  constructor(items = []) { this.items = new Map(items.map(x => [x.id, x])); this.calls = []; }
  async listManaged() { return [...this.items.values()]; }
  async insert(_, event) { this.calls.push(["insert", event.id]); this.items.set(event.id, event); }
  async update(_, id, event) { this.calls.push(["update", id]); this.items.set(id, event); }
  async remove(_, id) { this.calls.push(["delete", id]); this.items.delete(id); }
}

test("event identity is deterministic, distinct, and Google-compatible", () => {
  assert.equal(googleEventId("one"), googleEventId("one"));
  assert.notEqual(googleEventId("one"), googleEventId("two"));
  assert.match(googleEventId("one"), /^[a-v0-9]{5,1024}$/);
});

test("Google presentation shares scheduled, result, zero, venue and status semantics", () => {
  assert.equal(googleEventFor(game()).summary, "[PL] Arsenal vs Chelsea");
  assert.equal(googleEventFor(game()).location, "Emirates");
  assert.equal(googleEventFor(game({status: "finished", homeScore: 2, awayScore: 1})).summary, "[PL] Arsenal 2-1 Chelsea");
  assert.equal(googleEventFor(game({status: "finished", homeScore: 0, awayScore: 0})).summary, "[PL] Arsenal 0-0 Chelsea");
  assert.equal(googleEventFor(game({status: "postponed"})).status, "tentative");
  assert.equal(googleEventFor(game({status: "cancelled"})).status, "confirmed");
  assert.equal(googleEventFor(game({status: "cancelled"})).summary, "[CANCELLED] [PL] Arsenal vs Chelsea");
  assert.equal(new Date(googleEventFor(game()).end.dateTime) - new Date(googleEventFor(game()).start.dateTime), 7200000);
});

test("cancelled canonical games stay visible, idempotent, and can return to scheduled", async () => {
  const events = new Events();
  const cancelled = game({status: "cancelled"});
  assert.equal((await reconcileEvents(events, "cal", [cancelled])).created, 1);
  const stored = events.items.get(googleEventId(cancelled.id));
  assert.equal(stored.status, "confirmed");
  assert.match(stored.summary, /^\[CANCELLED\]/);
  assert.equal(MANAGED_EVENT_LIST_PARAMS.showDeleted, false);
  events.calls.length = 0;
  assert.deepEqual(await reconcileEvents(events, "cal", [cancelled]),
    {created: 0, updated: 0, deleted: 0, unchanged: 1});
  assert.deepEqual(events.calls, []);
  assert.equal((await reconcileEvents(events, "cal", [game()])).updated, 1);
  assert.equal(events.items.get(googleEventId(cancelled.id)).summary, "[PL] Arsenal vs Chelsea");
  assert.equal((await reconcileEvents(events, "cal", [])).deleted, 1);
});

test("calendar lookup classifies quota/rate limits as retryable and only 404/410 as missing", () => {
  for (const reason of ["userRateLimitExceeded", "rateLimitExceeded", "quotaExceeded"]) {
    const failure = classifyCalendarLookupFailure(403, reason);
    assert.equal(failure.kind, "retryable");
    assert.notEqual(failure.code, "credential-rejected");
  }
  assert.deepEqual(classifyCalendarLookupFailure(429), {kind: "retryable", code: "rate-limited"});
  assert.equal(classifyCalendarLookupFailure(403, "unknown").kind, "retryable");
  assert.equal(classifyCalendarLookupFailure(404).kind, "missing");
  assert.equal(classifyCalendarLookupFailure(410).kind, "missing");
});

test("quota and rate-limit lookup failures keep the connection active with sanitized codes", async () => {
  const key = crypto.randomBytes(32).toString("base64");
  const cases = [
    [403, "userRateLimitExceeded"],
    [403, "rateLimitExceeded"],
    [403, "quotaExceeded"],
    [429, undefined],
  ];
  for (const [status, reason] of cases) {
    let reauth = false; const records = [];
    const store = {getConnection: async () => ({status: "active", calendarId: "cal"}),
      getCredential: async () => encryptRefreshToken("refresh", key), getGames: async () => [],
      updateCalendar: async () => {}, record: async (_, value) => records.push(value),
      requireReauth: async () => { reauth = true; }};
    const failure = classifyCalendarLookupFailure(status, reason);
    const google = {refresh: async () => "access", calendarUsable: async () => {
      throw new CredentialError(false, failure.code);
    }};
    await assert.rejects(() => new GoogleCalendarSyncService(store, google, key).sync("uid"));
    assert.equal(reauth, false);
    assert.equal(records.at(-1).status, "error");
    assert.equal(records.at(-1).errorCode, failure.code);
  }
});

test("404 and 410 calendar lookups recreate the calendar and reconcile events", async () => {
  const key = crypto.randomBytes(32).toString("base64");
  for (const status of [404, 410]) {
    let recreated = 0; const events = new Events();
    const store = {getConnection: async () => ({status: "active", calendarId: "missing"}),
      getCredential: async () => encryptRefreshToken("refresh", key), getGames: async () => [game()],
      updateCalendar: async () => {}, record: async () => {}, requireReauth: async () => assert.fail()};
    const google = {refresh: async () => "access", calendarUsable: async () =>
      classifyCalendarLookupFailure(status).kind !== "missing",
    createCalendar: async () => { recreated++; return "replacement"; }, events: () => events};
    const result = await new GoogleCalendarSyncService(store, google, key).sync("uid");
    assert.equal(result.calendarRecreated, true);
    assert.equal(result.created, 1);
    assert.equal(recreated, 1);
  }
});

test("reconciliation creates, is idempotent, updates changes, recreates deletion and removes only managed stale events", async () => {
  const events = new Events();
  assert.deepEqual(await reconcileEvents(events, "cal", [game()]), {created: 1, updated: 0, deleted: 0, unchanged: 0});
  assert.deepEqual(await reconcileEvents(events, "cal", [game()]), {created: 0, updated: 0, deleted: 0, unchanged: 1});
  assert.equal((await reconcileEvents(events, "cal", [game({venue: "New", kickoffUtc: new Date("2026-09-20T11:00:00Z")})])).updated, 1);
  events.items.clear();
  assert.equal((await reconcileEvents(events, "cal", [game()])).created, 1);
  const unrelated = {...googleEventFor(game({id: "other"})), extendedProperties: {private: {sportsCalendarSync: "0", gameId: "other"}}};
  events.items.set(unrelated.id, unrelated);
  assert.equal((await reconcileEvents(events, "cal", [])).deleted, 1);
  assert.equal(events.items.has(unrelated.id), true);
});

test("sync recreates a deleted calendar and revoked credentials require reconnect without leaking tokens", async () => {
  const key = crypto.randomBytes(32).toString("base64");
  const records = []; let reauth = false; const events = new Events();
  const store = {getConnection: async () => ({status: "active", calendarId: "gone"}),
    getCredential: async () => encryptRefreshToken("top-secret", key), getGames: async () => [game()],
    updateCalendar: async (_, id) => records.push({calendarId: id}), record: async (_, value) => records.push(value),
    requireReauth: async () => { reauth = true; }};
  const google = {refresh: async token => { assert.equal(token, "top-secret"); return "access-secret"; },
    calendarUsable: async () => false, createCalendar: async () => "replacement", events: () => events};
  const result = await new GoogleCalendarSyncService(store, google, key).sync("uid");
  assert.equal(result.calendarRecreated, true); assert.equal(result.created, 1);
  assert.equal(JSON.stringify(result).includes("secret"), false);
  google.refresh = async () => { throw new CredentialError(true, "invalid-grant"); };
  assert.equal((await new GoogleCalendarSyncService(store, google, key).sync("uid")).status, "reauth_required");
  assert.equal(reauth, true);
});

test("transient failure remains retryable and batch isolates one user", async () => {
  const key = crypto.randomBytes(32).toString("base64"); let reauth = false; const records = [];
  const store = {getConnection: async () => ({status: "active", calendarId: "cal"}),
    getCredential: async () => encryptRefreshToken("refresh", key), getGames: async () => [], updateCalendar: async () => {},
    record: async (_, value) => records.push(value), requireReauth: async () => {reauth = true;}};
  const google = {refresh: async () => { throw new CredentialError(false, "token-refresh-failed"); }};
  await assert.rejects(() => new GoogleCalendarSyncService(store, google, key).sync("uid"));
  assert.equal(reauth, false); assert.equal(records.at(-1).status, "error");
  const batch = await syncUsersBounded(["ok", "bad", "ok2"], async uid => { if (uid === "bad") throw new Error(); }, 2);
  assert.deepEqual(batch, {considered: 3, synced: 2, failed: 1});
});

test("finished score and unfollow/no-follow state update or remove events", async () => {
  const events = new Events([googleEventFor(game())]);
  assert.equal((await reconcileEvents(events, "cal", [game({status: "finished", homeScore: 3, awayScore: 0})])).updated, 1);
  assert.equal((await reconcileEvents(events, "cal", [])).deleted, 1);
});
