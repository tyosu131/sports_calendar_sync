'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const { Timestamp } = require('firebase-admin/firestore');
const { displayTeamName } = require('../lib/domain/teamDisplayNamePolicy');
const { asNormalizedGame } = require('../lib/functions/getCalendar');
const { buildCalendar } = require('../lib/calendar/icsBuilder');

test('Japanese competitions use confirmed master localization without identity inference', () => {
  assert.equal(displayTeamName('football_j1', {
    japanese: 'Kashima Antlers', english: 'Kashima Antlers', provider: 'Kashima Antlers',
  }), '鹿島アントラーズ');
});

test('European competitions use English names', () => {
  assert.equal(displayTeamName('football_premier', {
    japanese: 'アーセナル', english: 'Arsenal', provider: 'Arsenal',
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
  assert.match(ics, /SUMMARY:川崎フロンターレ vs 鹿島アントラーズ/);
  assert.match(ics, /SUMMARY:Brighton & Hove Albion vs Arsenal/);
  assert.equal(domestic.awayTeamId, undefined);
  assert.match(ics, /UID:j1-game@sports-calendar-sync/);
});
