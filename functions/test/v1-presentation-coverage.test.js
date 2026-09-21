const test = require('node:test');
const assert = require('node:assert/strict');
const {Timestamp} = require('firebase-admin/firestore');
const snapshot = require('../../test/fixtures/v1_presentation_snapshot.json');
const {asNormalizedGame} = require('../lib/functions/getCalendar');
const {buildCalendar} = require('../lib/calendar/icsBuilder');
const {googleEventFor, googleEventId} = require('../lib/googleCalendar/reconciliation');

test('reviewable coverage matrix matches the actual server presentation output', () => {
  const {readFileSync} = require('node:fs');
  const {join} = require('node:path');
  const {coverageReport} = require('../scripts/auditV1Presentation');
  assert.equal(readFileSync(join(__dirname, '../../docs/v1-presentation-coverage.md'), 'utf8'), coverageReport());
});

test('all captured V1 sides use the shared Flutter/ICS/Google presentation oracle', () => {
  assert.equal(snapshot.games.length, 89);
  const families = new Set();
  const labels = new Set();
  for (const raw of snapshot.games) {
    families.add(raw.competitionKey);
    const before = JSON.stringify(raw);
    // Only presentation was captured. Use a deterministic valid kickoff/status
    // rather than representing synthetic test lifecycle fields as live evidence.
    const game = asNormalizedGame(raw.id, {...raw, status: 'scheduled',
      startTimeUTC: Timestamp.fromDate(new Date('2026-09-21T09:00:00Z'))});
    for (const side of ['home', 'away']) {
      labels.add(raw[side + 'TeamProviderName'] || raw[side + 'TeamNameEn'] || raw[side + 'TeamNameJa']);
      assert.equal(game[side + 'TeamName'], raw[side + 'ExpectedName'], raw.id + ':' + side);
      assert.equal(game[side + 'TeamId'], raw[side + 'TeamId']);
    }
    const event = googleEventFor(game);
    assert.ok(event.summary.endsWith(`${raw.homeExpectedName} vs ${raw.awayExpectedName}`));
    assert.ok(buildCalendar([game]).replace(/\r\n /g, '').includes('SUMMARY:' + event.summary));
    assert.equal(event.id, googleEventId(raw.id));
    assert.equal(JSON.stringify(raw), before);
  }
  assert.equal(labels.size, 52);
  assert.deepEqual([...families].sort(), ['football_champions_league', 'football_emperor_cup',
    'football_j1', 'football_j_league_cup', 'football_league_cup', 'football_premier']);
});
