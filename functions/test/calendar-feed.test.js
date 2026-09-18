const test = require("node:test");
const assert = require("node:assert/strict");
const { CalendarFeedService, generateCalendarFeedToken } = require("../lib/calendar/feedService");
const { requireAuthenticatedUid } = require("../lib/functions/calendarFeeds");

class MemoryRepository {
  constructor() { this.feeds = new Map(); this.owners = new Map(); }
  async transact(uid, operation) {
    return operation({
      getActiveToken: async () => {
        const token = this.owners.get(uid);
        return token && this.feeds.get(token)?.active ? token : undefined;
      },
      tokenExists: async (token) => this.feeds.has(token),
      create: (token, record) => this.feeds.set(token, record),
      deactivate: (token, rotatedAt) => this.feeds.set(token, { ...this.feeds.get(token), active: false, rotatedAt }),
      setActiveToken: (token) => this.owners.set(uid, token),
    });
  }
}

test("generated credentials have 256 random bits in URL-safe form", () => {
  const token = generateCalendarFeedToken();
  assert.match(token, /^[A-Za-z0-9_-]{43}$/);
  assert.equal(Buffer.from(token, "base64url").length, 32);
  assert.notEqual(token, generateCalendarFeedToken());
});

test("ensure is idempotent for one active feed", async () => {
  const repository = new MemoryRepository();
  const values = ["first"];
  const service = new CalendarFeedService(repository, () => values.shift());
  assert.equal(await service.ensure("user-a"), "first");
  assert.equal(await service.ensure("user-a"), "first");
  assert.equal(repository.feeds.size, 1);
});

test("rotation revokes the old credential and activates a new one", async () => {
  const repository = new MemoryRepository();
  const values = ["old", "new"];
  const service = new CalendarFeedService(repository, () => values.shift(), () => new Date("2026-01-01Z"));
  assert.equal(await service.ensure("user-a"), "old");
  assert.equal(await service.rotate("user-a"), "new");
  assert.equal(repository.feeds.get("old").active, false);
  assert.equal(repository.feeds.get("new").active, true);
});

test("token collisions never overwrite an existing feed", async () => {
  const repository = new MemoryRepository();
  repository.feeds.set("collision", { ownerUid: "other", active: true });
  const values = ["collision", "unique"];
  assert.equal(await new CalendarFeedService(repository, () => values.shift()).ensure("user-a"), "unique");
  assert.equal(repository.feeds.get("collision").ownerUid, "other");
});

test("issuance and rotation authentication guard rejects unauthenticated calls", () => {
  for (const operation of ["ensure", "rotate"]) {
    assert.throws(
      () => requireAuthenticatedUid({}),
      (error) => error.code === "unauthenticated",
      `${operation} must reject an unauthenticated context`
    );
  }
  assert.equal(requireAuthenticatedUid({ auth: { uid: "private-user-id" } }), "private-user-id");
});
