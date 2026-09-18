'use strict';

const assert = require('node:assert/strict');
const { test } = require('node:test');
const { execFileSync } = require('node:child_process');
const path = require('node:path');
const { getCompetitionTeamData, listCompetitionKeys } = require('../../scripts/data/competitionRegistry');
const localSeasons = require('../../scripts/data/competitionSeasons');
const runtimeSeasons = require('../../lib/config/competitionSeasons');

function verify(script, args = []) {
  execFileSync(process.execPath, [path.join(__dirname, '../../scripts', script), ...args]);
}

for (const key of listCompetitionKeys()) {
  test(`${key}: existing team master validation in dry-run mode`, () => {
    verify('verifyCompetitionTeams.js', [key, '--dry-run']);
  });
}

test('team master IDs and provider IDs are unique across the current registry', () => {
  const ids = new Set();
  const externalIds = new Set();
  for (const key of listCompetitionKeys()) {
    const { competition, teams } = getCompetitionTeamData(key);
    assert.equal(competition.competitionKey, key);
    for (const team of teams) {
      assert.ok(!ids.has(team.id), `Duplicate team ID: ${team.id}`);
      assert.ok(!externalIds.has(team.externalTeamId), `Duplicate external team ID: ${team.externalTeamId}`);
      ids.add(team.id);
      externalIds.add(team.externalTeamId);
    }
  }
});

test('season profiles have valid keys, competition references, dates and fields', () => {
  const keys = new Set();
  for (const profile of localSeasons.competitionSeasonProfiles) {
    assert.ok(!keys.has(profile.competitionSeasonKey), `Duplicate season: ${profile.competitionSeasonKey}`);
    keys.add(profile.competitionSeasonKey);
    for (const field of ['competitionSeasonKey', 'displayNameJa', 'displayNameEn']) {
      assert.equal(typeof profile[field], 'string', field);
      assert.ok(profile[field].trim(), field);
    }
    const { competition } = getCompetitionTeamData(profile.competitionKey);
    assert.equal(profile.externalLeagueId, competition.externalLeagueId);
    assert.ok(Number.isInteger(profile.externalLeagueId) && profile.externalLeagueId > 0);
    assert.ok(Number.isInteger(profile.apiSeason) && profile.apiSeason > 0);
    assert.equal(typeof profile.apiAccessibleOnCurrentPlan, 'boolean');
    assert.ok(['active', 'upcoming', 'archived'].includes(profile.status));
    for (const field of ['startDate', 'endDate']) {
      assert.match(profile[field], /^\d{4}-\d{2}-\d{2}$/);
      assert.equal(new Date(profile[field]).toISOString().slice(0, 10), profile[field]);
    }
    assert.ok(profile.startDate <= profile.endDate, 'season dates must be ordered');
  }
  assert.ok(keys.has(localSeasons.CURRENT_J1_COMPETITION_SEASON_KEY));
  assert.equal(runtimeSeasons.CURRENT_J1_COMPETITION_SEASON_KEY, localSeasons.CURRENT_J1_COMPETITION_SEASON_KEY);
  assert.deepEqual(runtimeSeasons.competitionSeasonProfiles, localSeasons.competitionSeasonProfiles,
    'runtime and script profiles must agree');
});

test('existing membership validation checks keys, groups, references and seedability', () => {
  verify('verifyCompetitionSeasonMemberships.js', ['--dry-run']);
});
