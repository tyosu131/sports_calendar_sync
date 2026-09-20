'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const { Timestamp } = require('firebase-admin/firestore');
const { displayTeamName } = require('../lib/domain/teamDisplayNamePolicy');
const { asNormalizedGame } = require('../lib/functions/getCalendar');
const { buildCalendar } = require('../lib/calendar/icsBuilder');
const { competitionDisplayMetadata } = require('../lib/domain/competitionDisplayPolicy');

test('competition catalog carries Japanese English and compact V1 metadata', () => {
  const keys = [
    'football_j1', 'football_j_league_cup', 'football_emperor_cup',
    'football_premier', 'football_champions_league', 'football_league_cup',
  ];
  for (const key of keys) {
    const metadata = competitionDisplayMetadata(key);
    assert.ok(metadata?.nameJa);
    assert.ok(metadata?.nameEn);
    assert.ok(metadata?.compact);
  }
  assert.equal(competitionDisplayMetadata('unsupported'), undefined);
});

test('Japanese competitions use confirmed master localization without identity inference', () => {
  assert.equal(displayTeamName('football_j1', {
    japanese: 'Kashima Antlers', english: 'Kashima Antlers', provider: 'Kashima Antlers',
  }), '鹿島アントラーズ');
});

test('domestic cups localize J2 and J3 display evidence', () => {
  assert.equal(displayTeamName('football_emperor_cup', {
    japanese: 'Vegalta Sendai', provider: 'Vegalta Sendai',
  }), 'ベガルタ仙台');
  assert.equal(displayTeamName('football_emperor_cup', {
    japanese: 'FC Gifu', provider: 'FC Gifu',
  }), 'ＦＣ岐阜');
  const game = asNormalizedGame('domestic-cup-game', {
    competitionKey: 'football_emperor_cup', leagueId: 'emperor-cup',
    startTimeUTC: Timestamp.fromDate(new Date('2026-09-19T09:00:00Z')),
    status: 'scheduled', broadcastPlatforms: [], homeTeamId: 'followed',
    homeTeamNameJa: 'Vegalta Sendai', homeTeamNameEn: 'Vegalta Sendai',
    awayTeamNameJa: 'FC Gifu', awayTeamNameEn: 'FC Gifu',
  });
  assert.match(buildCalendar([game]), /SUMMARY:\[天皇杯\] ベガルタ仙台 vs ＦＣ岐阜/);
  assert.equal(game.awayTeamId, undefined);
});

test('safe normalization accepts width punctuation whitespace and case', () => {
  assert.equal(displayTeamName('football_j_league_cup', {
    japanese: 'provider', provider: '  kyoto sanga f．c． ',
  }), '京都サンガF.C.');
  assert.equal(displayTeamName('football_j_league_cup', {
    japanese: 'provider', provider: 'f c  gifu',
  }), 'ＦＣ岐阜');
});

test('European competitions use English names', () => {
  assert.equal(displayTeamName('football_premier', {
    japanese: 'アーセナル', english: 'Arsenal', provider: 'Arsenal',
  }), 'Arsenal');
});

test('canonical Team identity overrides a provider display variant', () => {
  assert.equal(displayTeamName('football_premier', {
    japanese: 'アーセナルFC', english: 'Arsenal FC', provider: 'Arsenal FC',
    canonicalTeamId: 'arsenal',
  }), 'Arsenal');
});

test('unknown domestic names fall back to provider text', () => {
  assert.equal(displayTeamName('football_j1', {
    japanese: 'Provider United', english: 'Provider United', provider: 'Provider United',
  }), 'Provider United');
});

test('normalized calendar and ICS SUMMARY share competition policy', () => {
  const base = {
    leagueId: 'league', startTimeUTC: Timestamp.fromDate(new Date('2026-09-19T09:00:00Z')),
    status: 'scheduled', broadcastPlatforms: [], homeTeamId: 'followed',
  };
  const domestic = asNormalizedGame('j1-game', {
    ...base, competitionKey: 'football_j1',
    homeTeamNameJa: 'Kawasaki Frontale', homeTeamNameEn: 'Kawasaki Frontale',
    awayTeamNameJa: 'Kashima Antlers', awayTeamNameEn: 'Kashima Antlers',
  });
  const european = asNormalizedGame('premier-game', {
    ...base, competitionKey: 'football_premier',
    homeTeamNameJa: 'ブライトン', homeTeamNameEn: 'Brighton & Hove Albion',
    awayTeamNameJa: 'アーセナル', awayTeamNameEn: 'Arsenal',
  });
  const ics = buildCalendar([domestic, european]);
  assert.match(ics, /SUMMARY:\[J1\] 川崎フロンターレ vs 鹿島アントラーズ/);
  assert.match(ics, /SUMMARY:\[PL\] Brighton & Hove Albion vs Arsenal/);
  assert.equal(domestic.awayTeamId, undefined);
  assert.match(ics, /UID:j1-game@sports-calendar-sync/);
});
