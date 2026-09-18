'use strict';

const assert = require('node:assert/strict');
const { test } = require('node:test');
const { execFileSync } = require('node:child_process');
const path = require('node:path');
const { adaptFootballFixtureToGameDoc } = require('../lib/adapters/football_adapter');
const { toUtcDate, toJstStorageString, toICalDateString } = require('../lib/utils/timezone');

// Synthetic API-SPORTS-shaped input; no live response or credentials.
function fixture() {
  return {
    fixture: {
      id: 12345,
      date: '2026-07-01T19:30:45+09:00',
      timezone: 'Asia/Tokyo',
      status: { short: 'NS' },
      venue: { name: 'Test stadium' },
    },
    teams: {
      home: { id: 101, name: 'Home FC', logo: 'https://example.invalid/home.png' },
      away: { id: 202, name: 'Away FC', logo: 'https://example.invalid/away.png' },
    },
    goals: { home: 0, away: 2 },
  };
}

function adapt(input) {
  return adaptFootballFixtureToGameDoc(
    input, 'football_j1', 'football_j1_2026_hyakunen', 'j1_league',
    'home_club', 'away_club', 'ホーム', 'アウェイ'
  );
}

test('adapter maps fixture identity, canonical team IDs, names and scores', () => {
  const input = fixture();
  const before = structuredClone(input);
  const game = adapt(input);
  const { startTimeUTC, ...fields } = game;
  assert.equal(startTimeUTC.toDate().toISOString(), '2026-07-01T10:30:45.000Z');
  assert.deepEqual(fields, {
    competitionKey: 'football_j1', competitionSeasonKey: 'football_j1_2026_hyakunen',
    sportKey: 'football_j1', leagueId: 'j1_league',
    homeTeamId: 'home_club', homeTeamNameJa: 'ホーム', homeTeamNameEn: 'Home FC',
    homeTeamLogoUrl: 'https://example.invalid/home.png',
    awayTeamId: 'away_club', awayTeamNameJa: 'アウェイ', awayTeamNameEn: 'Away FC',
    awayTeamLogoUrl: 'https://example.invalid/away.png',
    startTimeJST: '2026-07-01 19:30', timezone: 'Asia/Tokyo', status: 'scheduled',
    venue: 'Test stadium', homeScore: 0, awayScore: 2, broadcastPlatforms: [],
    externalFixtureId: 12345, rapidApiFixtureId: 12345,
  });
  assert.deepEqual(input, before, 'conversion must not mutate provider input');
});

test('adapter accepts absent optional data and preserves null-score semantics', () => {
  const input = fixture();
  input.fixture.venue = null;
  delete input.fixture.timezone;
  input.teams.home.logo = '';
  input.teams.away.logo = null;
  input.goals = { home: null, away: null };
  const game = adapt(input);
  assert.equal(game.venue, undefined);
  assert.equal(game.timezone, 'UTC');
  assert.equal(game.homeTeamLogoUrl, undefined);
  assert.equal(game.awayTeamLogoUrl, undefined);
  assert.equal(game.homeScore, undefined);
  assert.equal(game.awayScore, undefined);
});

test('kickoff/status changes preserve external fixture identity', () => {
  const input = fixture();
  const before = adapt(input);
  input.fixture.date = '2026-07-03T12:00:00Z';
  input.fixture.status.short = 'PST';
  const after = adapt(input);
  assert.equal(after.externalFixtureId, before.externalFixtureId);
  assert.equal(after.rapidApiFixtureId, before.rapidApiFixtureId);
  assert.equal(after.startTimeUTC.toDate().toISOString(), '2026-07-03T12:00:00.000Z');
  assert.equal(after.startTimeJST, '2026-07-03 21:00');
  assert.equal(after.status, 'postponed');
  input.fixture.status.short = 'CANC';
  assert.equal(adapt(input).status, 'cancelled');
});

test('timezone conversion normalizes offsets and JST year rollover', () => {
  for (const iso of ['2026-12-31T18:30:45Z', '2027-01-01T03:30:45+09:00', '2026-12-31T13:30:45-05:00']) {
    assert.equal(toUtcDate(iso).toISOString(), '2026-12-31T18:30:45.000Z');
    assert.equal(toJstStorageString(iso), '2027-01-01 03:30');
    assert.equal(toICalDateString(toUtcDate(iso)), '20261231T183045Z');
  }
});

test('existing status verifier, including unknown -> scheduled characterization', () => {
  // This records current behavior, not an endorsement of the unknown fallback.
  execFileSync(process.execPath, [path.join(__dirname, '../scripts/verifyFootballStatusMapping.js')]);
});
