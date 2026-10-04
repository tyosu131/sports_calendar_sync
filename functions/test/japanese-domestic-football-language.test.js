'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const { Timestamp } = require('firebase-admin/firestore');
const oracle = require('../../test/fixtures/japanese_domestic_football_language.json');
const { isJapaneseDomesticFootballCompetition } = require('../lib/domain/japaneseDomesticFootball');
const { defaultDisplayLanguage, displayTeamName } = require('../lib/domain/teamDisplayNamePolicy');
const { clubPresentation } = require('../lib/domain/clubPresentation');
const { asNormalizedGame } = require('../lib/functions/getCalendar');
const { buildCalendar } = require('../lib/calendar/icsBuilder');
const { j1Teams } = require('../scripts/data/j1Teams');
const { j2Teams } = require('../scripts/data/j2Teams');
const { j3Teams } = require('../scripts/data/j3Teams');

const domesticKeys = [
  'football_j1',
  'football_j2',
  'football_j3',
  'football_j_league_cup',
  'football_emperor_cup',
  'football_j2_j3_special',
];

test('Japanese domestic football classification matches the shared oracle', () => {
  for (const key of oracle.japanese) {
    assert.equal(isJapaneseDomesticFootballCompetition(key), true, key);
    assert.equal(defaultDisplayLanguage(key), 'ja', key);
  }
  for (const key of oracle.english) {
    const value = key === '' ? undefined : key;
    assert.equal(isJapaneseDomesticFootballCompetition(value), false, key);
    assert.equal(defaultDisplayLanguage(value), 'en', key);
  }
});

test('shared name inputs choose the same canonical language', () => {
  for (const row of oracle.names) {
    assert.equal(displayTeamName(row.competition ?? undefined, {
      japanese: row.japanese,
      english: row.english,
      provider: row.provider,
    }, undefined, row.teamId), row.expected, row.id);
  }
});

test('confirmed J1 J2 and J3 clubs stay Japanese in every domestic context', () => {
  const clubs = [
    ...j1Teams.map(team => ({ ...team, division: 'football_j1' })),
    ...j2Teams.map(team => ({ ...team, division: 'football_j2' })),
    ...j3Teams.map(team => ({ ...team, division: 'football_j3' })),
  ];
  assert.ok(clubs.length > 0);
  for (const team of clubs) {
    assert.equal(team.status, 'confirmed', team.id);
    assert.ok(team.nameJa, team.id);
    assert.equal(displayTeamName(team.division, {
      japanese: team.nameJa,
      english: team.nameEn,
      provider: team.nameEn,
    }, undefined, team.id), team.nameJa, team.id);
    for (const competition of domesticKeys) {
      assert.equal(displayTeamName(competition, {
        japanese: team.nameJa,
        english: team.nameEn,
        provider: team.nameEn,
      }, undefined, team.id), team.nameJa, `${team.id} ${competition}`);
    }
  }
  assert.equal(displayTeamName('football_premier', {
    japanese: 'アーセナル', english: 'Arsenal', provider: 'Arsenal',
  }, undefined, 'arsenal'), 'Arsenal');
});

test('legacy sportKey and calendar summary use the domestic Japanese name', () => {
  const game = asNormalizedGame('legacy-special', {
    leagueId: 'j2_j3',
    sportKey: 'football_j2_j3_special',
    competitionSeasonKey: 'football_j2_j3_2026_hyakunen',
    status: 'scheduled',
    startTimeUTC: Timestamp.fromDate(new Date('2026-09-19T09:00:00Z')),
    homeTeamId: 'jubilo_iwata',
    homeTeamNameJa: 'ジュビロ磐田',
    homeTeamNameEn: 'Jubilo Iwata',
    homeTeamProviderName: 'Jubilo Iwata',
    awayTeamNameJa: 'ベガルタ仙台',
    awayTeamNameEn: 'Vegalta Sendai',
    awayTeamProviderName: 'Vegalta Sendai',
    broadcastPlatforms: [],
  });
  assert.equal(game.homeTeamName, 'ジュビロ磐田');
  assert.equal(game.awayTeamName, 'ベガルタ仙台');
  const ics = buildCalendar([game]).replace(/\r\n /g, '');
  assert.match(ics, /SUMMARY:ジュビロ磐田 vs ベガルタ仙台/);
  assert.doesNotMatch(ics, /磐田 vs 仙台/);
});

test('a season key alone does not create a domestic competition context', () => {
  assert.equal(displayTeamName(undefined, {
    japanese: 'ジュビロ磐田',
    english: 'Jubilo Iwata',
    provider: 'Jubilo Iwata',
  }, undefined, 'jubilo_iwata'), 'Jubilo Iwata');
});

test('short domestic aliases follow the same competition classification', () => {
  assert.equal(clubPresentation(['Tokyo'], 'football_j2_j3_special').nameJa, 'ＦＣ東京');
  assert.equal(clubPresentation(['Tochigi'], 'football_j_future_domestic').nameJa, '栃木ＳＣ');
  assert.equal(clubPresentation(['Tokyo'], 'football_premier'), undefined);
  assert.equal(clubPresentation(['Sabah'], 'football_j2_j3_special'), undefined);
});
