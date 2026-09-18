'use strict';

const assert = require('node:assert/strict');
const { test } = require('node:test');
const { spawnSync } = require('node:child_process');
const path = require('node:path');

// Mutate only a child process's in-memory fixture; never edit checked-in config.
const invalidCases = [
  ['duplicate season keys', 'seasons.push(structuredClone(seasons[0]));', 'competitionSeasonKey must be unique'],
  ['duplicate group keys', 'seasons[0].groups[1].groupKey = seasons[0].groups[0].groupKey;', 'groupKey must be unique'],
  ['duplicate membership team IDs', 'seasons[0].groups[0].teamIds[1] = seasons[0].groups[0].teamIds[0];', 'teamId must not be duplicated'],
  ['invalid confirmed team reference', `
    const season = seasons[0];
    const oldId = season.groups[0].teamIds[0];
    season.groups[0].teamIds[0] = 'nonexistent_test_team';
    delete season.teamIdStatuses[oldId];
    season.teamIdStatuses.nonexistent_test_team = 'confirmed_team_master';
  `, 'confirmed_team_master teamId must exist'],
  ['malformed season profile', 'delete seasons[0].seasonYear;', 'Required field is missing: seasonYear'],
];

for (const [label, mutation, expected] of invalidCases) {
  test(`membership validator exits nonzero for ${label}`, () => {
    const result = spawnSync(process.execPath, ['-e', `
      const { competitionSeasonMemberships: seasons } = require('./scripts/data/competitionSeasonMemberships');
      ${mutation}
      require('./scripts/verifyCompetitionSeasonMemberships');
    `], { cwd: path.join(__dirname, '..'), encoding: 'utf8' });
    assert.ifError(result.error);
    assert.equal(result.status, 1, result.stdout + result.stderr);
    assert.ok(result.stderr.includes(expected), result.stderr);
  });
}
