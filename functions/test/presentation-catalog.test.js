const test = require('node:test');
const assert = require('node:assert/strict');
const {check} = require('../scripts/generateTeamPresentation');
const {clubPresentation} = require('../lib/domain/clubPresentation');
const {displayTeamName} = require('../lib/domain/teamDisplayNamePolicy');
const entries = require('../lib/domain/teamPresentationCatalog.json');

test('Flutter and server presentation catalogs are generated from the same evidence', () => check());

test('presentation data never adds a canonical/provider identity or membership', () => {
  for (const entry of entries) {
    assert.deepEqual(Object.keys(entry).sort(), ['aliases', 'competitionKeys', 'logoUrl', 'nameEn', 'nameJa', 'scopedAliases', 'source']);
    assert.equal(new URL(entry.logoUrl).protocol, 'https:');
    assert.equal(clubPresentation([entry.nameEn], entry.competitionKeys[0]), entry);
  }
  const {internalTeamIdForGoalTeam} = require('../lib/providers/goal/teamIdentity');
  for (const team of require('../scripts/data/goalPresentationEvidence.json')) {
    assert.equal(internalTeamIdForGoalTeam(team.id), undefined);
  }
});

test('calendar names share Japanese domestic / English international presentation', () => {
  for (const key of ['football_j1', 'football_j2', 'football_j3', 'football_j_league_cup', 'football_emperor_cup']) {
    assert.equal(displayTeamName(key, {provider: 'JEF United'}), 'ジェフユナイテッド千葉');
  }
  for (const key of ['football_premier', 'football_champions_league', 'football_league_cup']) {
    assert.equal(displayTeamName(key, {provider: 'Arsenal FC'}), 'Arsenal');
    assert.equal(displayTeamName(key, {provider: 'Bayern München'}), 'Bayern Munich');
    assert.equal(displayTeamName(key, {provider: 'Slavia Praha'}), 'Slavia Prague');
  }
});

test('ambiguous, partial and unconfirmed names stay unresolved', () => {
  for (const name of ['United', 'Fulh', 'Tokyo', 'Tochigi', 'Sabah', 'Unknown FC']) {
    assert.equal(clubPresentation([name]), undefined);
  }
  assert.equal(clubPresentation(['Fulham', 'Arsenal']), undefined);
});

test('the three authorized GOAL details are presentation evidence with bounded competition context', () => {
  assert.ok(clubPresentation(['FC Tokyo'], 'football_champions_league').logoUrl);
  assert.equal(clubPresentation(['ＦＣ東京'], 'football_j1').nameJa, 'FC東京');
  assert.ok(clubPresentation(['Tochigi SC'], 'football_champions_league').logoUrl);
  assert.equal(displayTeamName('football_j1', {provider: 'Tokyo'}), 'FC東京');
  assert.equal(displayTeamName('football_emperor_cup', {provider: 'Tochigi'}), '栃木ＳＣ');
  assert.ok(clubPresentation(['Sabah'], 'football_champions_league').logoUrl);
  for (const name of ['Tokyo', 'Tochigi', 'Sabah']) {
    assert.equal(clubPresentation([name], 'football_malaysia'), undefined);
  }
  const evidence = require('../scripts/data/goalPresentationEvidence.json');
  assert.deepEqual(evidence.map(row => row.name), ['Tokyo', 'Tochigi', 'Sabah']);
  assert.equal(evidence.find(row => row.name === 'Sabah').country, 'Azerbaijan');
});

test('stored Game normalization feeds identical names to ICS and Google without changing identity', () => {
  const {Timestamp} = require('firebase-admin/firestore');
  const {asNormalizedGame} = require('../lib/functions/getCalendar');
  const {buildCalendar} = require('../lib/calendar/icsBuilder');
  const {googleEventFor, googleEventId} = require('../lib/googleCalendar/reconciliation');
  const game = asNormalizedGame('stable-game', {
    competitionKey: 'football_j1', leagueId: 'j1', status: 'scheduled',
    startTimeUTC: Timestamp.fromDate(new Date('2026-09-21T09:00:00Z')),
    homeTeamId: 'kawasaki_frontale', homeTeamNameJa: 'Kawasaki Frontale',
    awayTeamNameJa: 'JEF United', awayTeamProviderName: 'JEF United',
  });
  assert.equal(game.awayTeamId, undefined);
  const title = '[J1] 川崎フロンターレ vs ジェフユナイテッド千葉';
  assert.equal(googleEventFor(game).summary, title);
  assert.ok(buildCalendar([game]).replace(/\r\n /g, '').includes('SUMMARY:' + title));
  assert.equal(googleEventFor(game).id, googleEventId('stable-game'));
});
