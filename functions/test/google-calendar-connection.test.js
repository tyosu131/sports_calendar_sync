const assert = require("node:assert/strict");
const test = require("node:test");
const crypto = require("node:crypto");
const {
  GoogleCalendarConnectionService,
  CalendarConnectionError,
} = require("../lib/googleCalendar/connectionService");
const {createGoogleCalendarHandlers} = require("../lib/functions/googleCalendarConnection");

class Store {
  constructor() { this.states = new Map(); this.connections = new Map(); this.credentials = new Map(); }
  async createState(hash, uid, expiresAt) { this.states.set(hash, {uid, expiresAt}); }
  async consumeState(hash, now) {
    const state = this.states.get(hash);
    this.states.delete(hash);
    return state && state.expiresAt > now ? state.uid : undefined;
  }
  async getConnection(uid) { return this.connections.get(uid); }
  async saveConnection(uid, value) { this.connections.set(uid, value); }
  async saveCredential(uid, value) { this.credentials.set(uid, value); }
  async deleteCredential(uid) { this.credentials.delete(uid); }
}

class Google {
  constructor() { this.created = 0; this.existing = undefined; this.result = {refreshToken: "secret-token", scopes: ["scope"]}; }
  async exchangeCode() { if (this.failure) throw new Error(); return this.result; }
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
  for (const handler of [handlers.begin, handlers.status, handlers.disconnect]) {
    await assert.rejects(() => handler({}, {}), error => error.code === "unauthenticated");
  }
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

test("malformed callback and OAuth denial have stable errors", async () => {
  const {service} = make();
  await assert.rejects(() => service.callback({}), error => error.code === "malformed-callback");
  const state = await stateFrom(service);
  await assert.rejects(() => service.callback({state, error: "access_denied"}), error => error.code === "oauth-denied");
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

test("reconnect reuses the persisted calendar and disconnect disables use", async () => {
  const fixture = make();
  await fixture.service.callback({state: await stateFrom(fixture.service), code: "x"});
  await fixture.service.callback({state: await stateFrom(fixture.service), code: "x"});
  assert.equal(fixture.google.created, 1);
  await fixture.service.disconnect("uid-1");
  assert.deepEqual(await fixture.service.status("uid-1"), {connected: false});
  assert.equal(fixture.store.credentials.has("uid-1"), false);
  assert.equal(fixture.store.connections.get("uid-1").calendarId, "calendar-id");
});
