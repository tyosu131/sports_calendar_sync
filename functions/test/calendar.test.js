const test = require("node:test");
const assert = require("node:assert/strict");
const { buildCalendar, calendarEventUid } = require("../lib/calendar/icsBuilder");

const game = (changes = {}) => ({
  id: "game-1", kickoffUtc: new Date("2026-09-20T10:00:00Z"),
  homeTeamName: "Home", awayTeamName: "Away", status: "scheduled", ...changes,
});

test("one game produces one event without an invented end", () => {
  const result = buildCalendar([game()]);
  assert.equal((result.match(/BEGIN:VEVENT/g) || []).length, 1);
  assert.match(result, /DTSTART:20260920T100000Z/);
  assert.doesNotMatch(result, /DTEND/);
});

test("identity is stable while changed kickoff changes DTSTART", () => {
  const first = buildCalendar([game()]);
  const changed = buildCalendar([game({ kickoffUtc: new Date("2026-09-21T12:30:00Z") })]);
  assert.equal(calendarEventUid("game-1"), "game-1@sports-calendar-sync");
  assert.match(first, /UID:game-1@sports-calendar-sync/);
  assert.match(changed, /UID:game-1@sports-calendar-sync/);
  assert.notEqual(first.match(/DTSTART:.+/)[0], changed.match(/DTSTART:.+/)[0]);
});

test("finished score changes summary without changing stable UID", () => {
  const first = buildCalendar([game({ status: "finished", homeScore: 2, awayScore: 1 })]);
  const changed = buildCalendar([game({ status: "finished", homeScore: 3, awayScore: 1 })]);
  assert.match(first, /SUMMARY:Home 2-1 Away/);
  assert.match(changed, /SUMMARY:Home 3-1 Away/);
  assert.equal(first.match(/UID:.+/)[0], changed.match(/UID:.+/)[0]);
});

test("finished 0-0 is preserved and unavailable score retains versus summary", () => {
  assert.match(buildCalendar([game({ status: "finished", homeScore: 0, awayScore: 0 })]), /SUMMARY:Home 0-0 Away/);
  assert.match(buildCalendar([game({ status: "finished" })]), /SUMMARY:Home vs Away/);
});

test("the personalized calendar shape preserves venue in the shared ICS event", () => {
  const result = buildCalendar([game({ venue: "National Stadium" })]);
  assert.match(result, /LOCATION:National Stadium/);
});

test("duplicate game IDs produce one event", () => {
  assert.equal((buildCalendar([game(), game()]).match(/BEGIN:VEVENT/g) || []).length, 1);
});

test("cancelled and postponed use interoperable statuses", () => {
  assert.match(buildCalendar([game({ status: "cancelled" })]), /STATUS:CANCELLED/);
  assert.match(buildCalendar([game({ status: "postponed" })]), /STATUS:TENTATIVE/);
});

test("optional fields may be absent and text is escaped", () => {
  const result = buildCalendar([game({
    homeTeamName: "A, B; C\\D\nE", venue: null, broadcastPlatforms: undefined,
  })]);
  assert.match(result, /SUMMARY:A\\, B\\; C\\\\D\\nE vs Away/);
  assert.doesNotMatch(result, /LOCATION|DESCRIPTION/);
  assert.match(result, /END:VCALENDAR\r\n$/);
});

test("ordering is deterministic by game identity", () => {
  const a = game({ id: "a" });
  const b = game({ id: "b", kickoffUtc: new Date("2025-01-01T00:00:00Z") });
  assert.equal(buildCalendar([b, a]), buildCalendar([a, b]));
  assert.ok(buildCalendar([b, a]).indexOf("UID:a@") < buildCalendar([b, a]).indexOf("UID:b@"));
});

test("unknown status is rejected rather than treated as scheduled", () => {
  assert.throws(() => buildCalendar([game({ status: "mystery" })]), /Unknown game status/);
});
