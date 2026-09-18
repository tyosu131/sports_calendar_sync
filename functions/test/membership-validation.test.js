'use strict';

const assert = require('node:assert/strict');
const { test } = require('node:test');
const { spawnSync } = require('node:child_process');
const path = require('node:path');
const {
  membershipsForTeam,
} = require('../lib/domain/competitionSeasonMembership');
const {
  verifyCompetitionSeasonMemberships,
} = require('../scripts/verifyCompetitionSeasonMemberships');

function membership(competitionSeasonKey, competitionKey, memberTeamIds) {
  return {
    competitionSeasonKey,
    competitionKey,
    seasonYear: 2026,
    displayNameJa: competitionSeasonKey,
    membershipType: 'cup',
    memberTeamIds,
    source: 'synthetic test fixture',
    status: 'review',
    seedable: false,
  };
}

test('one stable team may belong to multiple competition seasons', () => {
  const seasons = [
    membership('premier_league_2026', 'football_premier_league', ['arsenal']),
    membership('fa_cup_2026', 'football_fa_cup', ['arsenal']),
    membership('league_cup_2026', 'football_league_cup', ['arsenal']),
    membership('ucl_2026', 'football_ucl', ['arsenal']),
  ];

  const result = verifyCompetitionSeasonMemberships({}, {
    seasons,
    confirmedTeamIds: new Set(['arsenal']),
    knownCompetitionKeys: new Set(seasons.map((item) => item.competitionKey)),
  });

  assert.deepEqual(result.failures, []);
  assert.deepEqual(
    membershipsForTeam('arsenal', seasons).map((item) => item.competitionSeasonKey),
    seasons.map((item) => item.competitionSeasonKey),
  );
  assert.deepEqual(membershipsForTeam('unknown', seasons), []);
  assert.deepEqual(membershipsForTeam('', seasons), []);
});

test('duplicate team in one ungrouped membership is rejected', () => {
  const result = verifyCompetitionSeasonMemberships({}, {
    seasons: [membership('premier_2026', 'football_j1', ['arsenal', 'arsenal'])],
    confirmedTeamIds: new Set(['arsenal']),
  });
  assert.ok(result.failures.some((failure) =>
    failure.reason.includes('teamId must not be duplicated')));
});

test('invalid confirmed team reference is rejected for ungrouped membership', () => {
  const season = membership('premier_2026', 'football_j1', ['missing_team']);
  season.teamIdStatuses = { missing_team: 'confirmed_team_master' };
  const result = verifyCompetitionSeasonMemberships({}, {
    seasons: [season],
    confirmedTeamIds: new Set(['arsenal']),
  });
  assert.ok(result.failures.some((failure) =>
    failure.reason.includes('confirmed_team_master teamId must exist')));
});

test('duplicate competition season key is rejected', () => {
  const seasons = [
    membership('premier_2026', 'football_j1', ['arsenal']),
    membership('premier_2026', 'football_j2', ['arsenal']),
  ];
  const result = verifyCompetitionSeasonMemberships({}, {
    seasons,
    confirmedTeamIds: new Set(['arsenal']),
  });
  assert.ok(result.failures.some((failure) =>
    failure.reason.includes('competitionSeasonKey must be unique')));
});

test('malformed shape and unknown competition are rejected', () => {
  const malformed = membership('unknown_2026', 'unknown_competition', ['arsenal']);
  malformed.groups = [];
  const result = verifyCompetitionSeasonMemberships({}, {
    seasons: [malformed],
    confirmedTeamIds: new Set(['arsenal']),
  });
  assert.ok(result.failures.some((failure) =>
    failure.reason.includes('known competition')));
  assert.ok(result.failures.some((failure) =>
    failure.reason.includes('either groups or memberTeamIds')));
});

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
      const { verifyCompetitionSeasonMemberships } = require('./scripts/verifyCompetitionSeasonMemberships');
      const result = verifyCompetitionSeasonMemberships({}, { seasons });
      if (result.failures.length) {
        console.error(result.failures.map((failure) => failure.reason).join('\\n'));
        process.exit(1);
      }
    `], { cwd: path.join(__dirname, '..'), encoding: 'utf8' });
    assert.ifError(result.error);
    assert.equal(result.status, 1, result.stdout + result.stderr);
    assert.ok(result.stderr.includes(expected), result.stderr);
  });
}
