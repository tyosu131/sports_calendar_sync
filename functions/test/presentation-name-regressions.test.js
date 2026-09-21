'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const { Timestamp } = require('firebase-admin/firestore');
const cases = require('../../test/fixtures/presentation_name_regressions.json');
const { displayTeamName } = require('../lib/domain/teamDisplayNamePolicy');
const { asNormalizedGame } = require('../lib/functions/getCalendar');
const { buildCalendar } = require('../lib/calendar/icsBuilder');
const { googleEventFor, googleEventId } = require('../lib/googleCalendar/reconciliation');

for (const row of cases) {
  test(`final name policy shared oracle: ${row.id}`, () => {
    assert.equal(displayTeamName(row.competition, row.names), row.expected);
  });
}

test('server ICS and Google preserve raw rejected names and identity', () => {
  for (const row of cases.filter(row => row.expected)) {
    const raw = {
      competitionKey: row.competition, leagueId: 'test', status: 'scheduled',
      startTimeUTC: Timestamp.fromDate(new Date('2026-09-21T09:00:00Z')),
      homeTeamId: 'kawasaki_frontale', homeTeamNameJa: '川崎フロンターレ',
      awayTeamNameJa: row.names.japanese ?? '',
      awayTeamNameEn: row.names.english,
      awayTeamProviderName: row.names.provider,
    };
    const before = JSON.stringify(raw);
    const game = asNormalizedGame(row.id, raw);
    assert.equal(game.awayTeamName, row.expected, row.id);
    assert.equal(game.awayTeamId, undefined);
    assert.equal(game.homeTeamId, 'kawasaki_frontale');
    const event = googleEventFor(game);
    assert.ok(event.summary.endsWith(` vs ${row.expected}`), row.id);
    assert.ok(buildCalendar([game]).replace(/\r\n /g, '').includes('SUMMARY:' + event.summary), row.id);
    assert.equal(event.id, googleEventId(row.id));
    assert.equal(JSON.stringify(raw), before);
  }
});
