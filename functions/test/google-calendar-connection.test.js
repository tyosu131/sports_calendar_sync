const assert = require("node:assert/strict");
const test = require("node:test");
const crypto = require("node:crypto");
const {
  GoogleCalendarConnectionService,
  CalendarConnectionError,
  encryptRefreshToken,
  decryptRefreshToken,
  parseOAuthCallbackQuery,
} = require("../lib/googleCalendar/connectionService");
const {createGoogleCalendarHandlers, callbackHtml, handleGoogleCalendarCallback} = require("../lib/functions/googleCalendarConnection");

class Store {
  constructor() { this.states = new Map(); this.connections = new Map(); this.credentials = new Map(); this.consumed = 0; this.savedConnections = 0; this.savedCredentials = 0; }
  async createState(hash, uid, expiresAt) { this.states.set(hash, {uid, expiresAt}); }
  async consumeState(hash, now) {
    this.consumed++;
    const state = this.states.get(hash);
    this.states.delete(hash);
    return state && state.expiresAt > now ? state.uid : undefined;
  }
  async getConnection(uid) { return this.connections.get(uid); }
  async saveConnection(uid, value) { this.savedConnections++; this.connections.set(uid, value); }
  async saveCredential(uid, value) { this.savedCredentials++; this.credentials.set(uid, value); }
  async deleteCredential(uid) { this.credentials.delete(uid); }
}

class Google {
  constructor() { this.created = 0; this.exchanged = 0; this.accessible = true; this.result = {refreshToken: "secret-token", scopes: ["scope"]}; }
  async exchangeCode() { this.exchanged++; if (this.failure) throw new Error(); return this.result; }
  async isCalendarAccessible() {
    if (this.accessFailure) throw new Error("provider unavailable");
    return this.accessible;
  }
  async createCalendar() { this.created++; return "calendar-id"; }
}

const key = crypto.randomBytes(32).toString("base64");
const config = {clientId: "client", redirectUri: "https://example.test/callback", encryptionKey: key};
const make = (store = new Store(), google = new Google(), now = () => new Date("2026-01-01"), random) =>
  ({store, google, service: new GoogleCalendarConnectionService(store, google, config, now, random)});

test("all Google Calendar callables require Firebase authentication", async () => {
  const handlers = createGoogleCalendarHandlers({
    clientId: "unused", clientSecret: "unused", redirectUri: "https://example.test", encryptionKey: key,
  });
  for (const handler of [handlers.begin, handlers.status, handlers.disconnect, handlers.sync]) {
    await assert.rejects(() => handler({}, {}), error => error.code === "unauthenticated");
  }
});

test("AES-GCM credential round trip rejects malformed records", () => {
  const encrypted = encryptRefreshToken("refresh-secret", key);
  assert.equal(decryptRefreshToken(encrypted, key), "refresh-secret");
  assert.throws(() => decryptRefreshToken({...encrypted, authTag: "bad"}, key),
    error => error.code === "invalid-encrypted-credential");
});

test("callback HTML has explicit semantic outcomes and safe app actions", () => {
  const success = callbackHtml("success");
  assert.match(success, /sportscalendar:\/\/google-calendar\/oauth-complete/);
  assert.match(success, /Sports Calendarに戻る/);
  assert.match(success, /<script>/);
  const cancelled = callbackHtml("cancelled");
  assert.match(cancelled, /連携をキャンセルしました/);
  assert.doesNotMatch(cancelled, /連携が完了しました|連携を完了できませんでした|もう一度お試しください/);
  assert.match(cancelled, /Sports Calendarに戻る/);
  assert.match(cancelled, /<script>/);
  const failure = callbackHtml("failure");
  assert.match(failure, /もう一度お試しください/);
  assert.doesNotMatch(failure, /連携が完了しました/);
  assert.doesNotMatch(failure, /<script>/);
});

async function stateFrom(service) {
  const url = new URL(await service.begin("uid-1"));
  assert.equal(url.searchParams.get("scope"), "https://www.googleapis.com/auth/calendar.app.created");
  return url.searchParams.get("state");
}

test("state is random, opaque, and bound to its uid", async () => {
  const {store, service} = make();
  const first = await stateFrom(service);
  const second = await stateFrom(service);
  assert.notEqual(first, second);
  assert.equal([...store.states.values()][0].uid, "uid-1");
  assert.equal([...store.states.keys()].some(key => key === first), false);
});

test("expired and reused states are rejected", async () => {
  let now = new Date("2026-01-01");
  const fixture = make(new Store(), new Google(), () => now);
  const expired = await stateFrom(fixture.service);
  now = new Date("2026-01-02");
  await assert.rejects(() => fixture.service.callback({state: expired, code: "x"}), error => error.code === "invalid-or-expired-state");
  now = new Date("2026-01-01");
  const used = await stateFrom(fixture.service);
  await fixture.service.callback({state: used, code: "x"});
  await assert.rejects(() => fixture.service.callback({state: used, code: "x"}), error => error.code === "invalid-or-expired-state");
});

test("callback query parser accepts scalar strings only", () => {
  assert.deepEqual(parseOAuthCallbackQuery({state: "state", error: "access_denied"}), {
    state: "state", code: undefined, error: "access_denied",
  });
  for (const query of [null, [], {state: ["state"]}, {state: {nested: true}}, {code: ["code"]}, {state: "state", extra: ["value"]}]) {
    assert.throws(() => parseOAuthCallbackQuery(query), error => error.code === "malformed-callback");
  }
});

test("malformed callback fails while explicit denial is cancellation", async () => {
  const {service} = make();
  await assert.rejects(() => service.callback({}), error => error.code === "malformed-callback");
  const state = await stateFrom(service);
  assert.equal(await service.callback({state, error: "access_denied"}), "cancelled");
});

test("cancellation consumes state once and performs no provider or persistence mutation", async () => {
  const fixture = make();
  const existing = {status: "active", calendarId: "existing-calendar"};
  fixture.store.connections.set("uid-1", existing);
  fixture.store.credentials.set("uid-1", {existing: true});
  const state = await stateFrom(fixture.service);

  assert.equal(await fixture.service.callback({state, error: "access_denied"}), "cancelled");
  assert.equal(fixture.store.consumed, 1);
  assert.equal(fixture.google.exchanged, 0);
  assert.equal(fixture.google.created, 0);
  assert.equal(fixture.store.savedCredentials, 0);
  assert.equal(fixture.store.savedConnections, 0);
  assert.equal(fixture.store.connections.get("uid-1"), existing);
  assert.deepEqual(fixture.store.credentials.get("uid-1"), {existing: true});
  await assert.rejects(
    () => fixture.service.callback({state, error: "access_denied"}),
    error => error.code === "invalid-or-expired-state"
  );
});

function responseRecorder() {
  return {
    statusCode: undefined, contentType: undefined, body: undefined,
    status(value) { this.statusCode = value; return this; },
    type(value) { this.contentType = value; return this; },
    send(value) { this.body = value; return this; },
  };
}

test("HTTP callback returns success and cancellation pages with automatic app return", async () => {
  for (const outcome of ["success", "cancelled"]) {
    const fixture = make();
    const state = await stateFrom(fixture.service);
    const response = responseRecorder();
    const query = outcome === "success" ? {state, code: "code"} : {state, error: "access_denied"};
    await handleGoogleCalendarCallback(query, response, fixture.service);
    assert.equal(response.statusCode, 200);
    assert.equal(response.contentType, "html");
    assert.match(response.body, /Sports Calendarに戻る/);
    assert.match(response.body, /<script>/);
    assert.match(response.body, outcome === "success" ? /連携が完了しました/ : /連携をキャンセルしました/);
  }
});

test("HTTP callback rejects invalid, reused, conflicting, unknown, and malformed inputs", async () => {
  const cases = [
    async fixture => ({state: "invalid", error: "access_denied"}),
    async fixture => ({state: await stateFrom(fixture.service), error: "server_error"}),
    async fixture => ({state: await stateFrom(fixture.service), code: "code", error: "access_denied"}),
    async fixture => ({state: [await stateFrom(fixture.service)], error: "access_denied"}),
    async fixture => ({state: await stateFrom(fixture.service), error: ""}),
  ];
  for (const makeQuery of cases) {
    const fixture = make();
    const response = responseRecorder();
    await handleGoogleCalendarCallback(await makeQuery(fixture), response, fixture.service);
    assert.equal(response.statusCode, 400);
    assert.doesNotMatch(response.body, /連携をキャンセルしました/);
    assert.doesNotMatch(response.body, /<script>/);
  }

  const reused = make();
  const state = await stateFrom(reused.service);
  await reused.service.callback({state, error: "access_denied"});
  const response = responseRecorder();
  await handleGoogleCalendarCallback({state, error: "access_denied"}, response, reused.service);
  assert.equal(response.statusCode, 400);
});

test("HTTP token exchange failure is 5xx with manual return only", async () => {
  const fixture = make(); fixture.google.failure = true;
  const response = responseRecorder();
  await handleGoogleCalendarCallback(
    {state: await stateFrom(fixture.service), code: "code"}, response, fixture.service
  );
  assert.equal(response.statusCode, 502);
  assert.match(response.body, /Sports Calendarに戻る/);
  assert.doesNotMatch(response.body, /<script>/);
});

test("missing refresh token is rejected without persistence", async () => {
  const fixture = make(); fixture.google.result = {scopes: []};
  const state = await stateFrom(fixture.service);
  await assert.rejects(() => fixture.service.callback({state, code: "x"}), error => error.code === "missing-refresh-token");
  assert.equal(fixture.store.credentials.size, 0);
});

test("invalid encryption configuration fails before calendar creation", async () => {
  const store = new Store();
  const google = new Google();
  const service = new GoogleCalendarConnectionService(store, google, {
    ...config,
    encryptionKey: Buffer.from("too-short").toString("base64"),
  }, () => new Date("2026-01-01"));

  const state = await stateFrom(service);
  await assert.rejects(
    () => service.callback({state, code: "x"}),
    error => error.code === "invalid-encryption-key"
  );
  assert.equal(google.created, 0);
  assert.equal(store.credentials.size, 0);
  assert.equal(store.connections.size, 0);
});

test("token exchange and calendar creation failures are distinguished", async () => {
  const exchange = make(); exchange.google.failure = true;
  const exchangeState = await stateFrom(exchange.service);
  await assert.rejects(() => exchange.service.callback({state: exchangeState, code: "x"}), error => error.code === "token-exchange-failed");

  const calendar = make();
  calendar.google.createCalendar = async () => { throw new Error("provider unavailable"); };
  const calendarState = await stateFrom(calendar.service);
  await assert.rejects(() => calendar.service.callback({state: calendarState, code: "x"}), error => error.code === "calendar-creation-failed");
});

test("bootstrap encrypts credentials and status is sanitized", async () => {
  const fixture = make();
  await fixture.service.callback({state: await stateFrom(fixture.service), code: "x"});
  assert.equal(fixture.google.created, 1);
  const credential = fixture.store.credentials.get("uid-1");
  assert.equal(JSON.stringify(credential).includes("secret-token"), false);
  assert.deepEqual(await fixture.service.status("uid-1"), {connected: true, calendarName: "Sports Calendar"});
  assert.equal(JSON.stringify(await fixture.service.status("uid-1")).includes("token"), false);
});

test("accessible persisted calendar is reused without duplicate creation", async () => {
  const fixture = make();
  await fixture.service.callback({state: await stateFrom(fixture.service), code: "x"});
  await fixture.service.callback({state: await stateFrom(fixture.service), code: "x"});
  assert.equal(fixture.google.created, 1);
  assert.equal(fixture.store.connections.get("uid-1").calendarId, "calendar-id");
});

test("inaccessible or deleted persisted calendar is replaced and persisted", async () => {
  for (const condition of ["inaccessible", "deleted"]) {
    const fixture = make();
    fixture.store.connections.set("uid-1", {status: "disconnected", calendarId: `old-${condition}`});
    fixture.google.accessible = false;
    fixture.google.createCalendar = async () => {
      fixture.google.created++;
      return `new-${condition}`;
    };

    await fixture.service.callback({state: await stateFrom(fixture.service), code: "x"});
    assert.equal(fixture.google.created, 1);
    assert.equal(fixture.store.connections.get("uid-1").calendarId, `new-${condition}`);
  }
});

test("unexpected calendar verification failure does not create or activate", async () => {
  const fixture = make();
  fixture.store.connections.set("uid-1", {status: "disconnected", calendarId: "existing-id"});
  fixture.google.accessFailure = true;
  const state = await stateFrom(fixture.service);
  await assert.rejects(
    () => fixture.service.callback({state, code: "x"}),
    error => error.code === "calendar-verification-failed"
  );
  assert.equal(fixture.google.created, 0);
  assert.deepEqual(fixture.store.connections.get("uid-1"), {
    status: "disconnected", calendarId: "existing-id",
  });
  assert.equal(fixture.store.credentials.size, 0);
});

test("disconnect disables active use while preserving the usable calendar id", async () => {
  const fixture = make();
  await fixture.service.callback({state: await stateFrom(fixture.service), code: "x"});
  await fixture.service.disconnect("uid-1");
  assert.deepEqual(await fixture.service.status("uid-1"), {connected: false});
  assert.equal(fixture.store.credentials.has("uid-1"), false);
  assert.equal(fixture.store.connections.get("uid-1").calendarId, "calendar-id");
});
