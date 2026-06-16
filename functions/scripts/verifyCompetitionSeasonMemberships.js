/**
 * verifyCompetitionSeasonMemberships.js
 *
 * Read-only local validation for competition season membership data.
 *
 * Usage:
 *   node functions/scripts/verifyCompetitionSeasonMemberships.js [--dry-run] [--season <competitionSeasonKey>]
 */

'use strict';

const {
  competitionSeasonMemberships,
} = require('./data/competitionSeasonMemberships');
const { j1Teams } = require('./data/j1Teams');
const { j2Teams } = require('./data/j2Teams');
const { j3Teams } = require('./data/j3Teams');

const REQUIRED_SEASON_FIELDS = [
  'competitionSeasonKey',
  'seasonYear',
  'competitionKey',
  'displayNameJa',
  'membershipType',
  'source',
  'status',
  'seedable',
];

const ALLOWED_MEMBERSHIP_TYPES = new Set([
  'league',
  'special_tournament',
  'cup',
  'playoff',
]);

const ALLOWED_STATUSES = new Set([
  'review',
  'approved',
  'seedable',
  'seeded',
]);

const ALLOWED_TEAM_ID_STATUSES = new Set([
  'confirmed_team_master',
  'candidate_not_confirmed',
  'blocked_continuity',
  'missing_team_master',
]);

const BLOCKING_TEAM_ID_STATUSES = new Set([
  'candidate_not_confirmed',
  'blocked_continuity',
  'missing_team_master',
]);

const SPECIAL_2026_COMPETITION_SEASON_KEY =
  'football_j2_j3_2026_hyakunen';

const SPECIAL_2026_GROUP_KEYS = new Set([
  'east_a',
  'east_b',
  'west_a',
  'west_b',
]);

function parseArgs(argv) {
  const args = {
    dryRun: true,
    seasonKey: null,
  };

  for (let index = 0; index < argv.length; index += 1) {
    const arg = argv[index];

    if (arg === '--dry-run') {
      args.dryRun = true;
      continue;
    }

    if (arg === '--season') {
      const seasonKey = argv[index + 1];
      if (!seasonKey || seasonKey.startsWith('--')) {
        throw new Error('--season requires a competitionSeasonKey value.');
      }
      args.seasonKey = seasonKey;
      index += 1;
      continue;
    }

    throw new Error(`Unknown argument: ${arg}`);
  }

  return args;
}

function isNonEmptyString(value) {
  return typeof value === 'string' && value.trim().length > 0;
}

function addFailure(failures, reason, context = {}) {
  failures.push({
    reason,
    competitionSeasonKey: context.competitionSeasonKey || null,
    groupKey: context.groupKey || null,
    teamId: context.teamId || null,
  });
}

function formatFailure(failure) {
  const context = [];

  if (failure.competitionSeasonKey) {
    context.push(`competitionSeasonKey=${failure.competitionSeasonKey}`);
  }
  if (failure.groupKey) {
    context.push(`groupKey=${failure.groupKey}`);
  }
  if (failure.teamId) {
    context.push(`teamId=${failure.teamId}`);
  }

  return context.length > 0
    ? `${failure.reason} (${context.join(', ')})`
    : failure.reason;
}

function collectConfirmedTeamIds(teamModules) {
  const confirmedTeamIds = new Set();

  for (const teams of teamModules) {
    if (!Array.isArray(teams)) {
      continue;
    }

    for (const team of teams) {
      if (
        team &&
        team.status === 'confirmed' &&
        isNonEmptyString(team.id)
      ) {
        confirmedTeamIds.add(team.id);
      }
    }
  }

  return confirmedTeamIds;
}

function validateModuleShape(failures) {
  if (typeof competitionSeasonMemberships === 'undefined') {
    addFailure(
      failures,
      'competitionSeasonMemberships export is missing.'
    );
    return [];
  }

  if (!Array.isArray(competitionSeasonMemberships)) {
    addFailure(
      failures,
      'competitionSeasonMemberships export must be an array.'
    );
    return [];
  }

  return competitionSeasonMemberships;
}

function validateUniqueSeasonKeys(seasons, failures) {
  const seenSeasonKeys = new Set();

  for (const season of seasons) {
    const competitionSeasonKey = season && season.competitionSeasonKey;

    if (!isNonEmptyString(competitionSeasonKey)) {
      continue;
    }

    if (seenSeasonKeys.has(competitionSeasonKey)) {
      addFailure(
        failures,
        'competitionSeasonKey must be unique across all profiles.',
        { competitionSeasonKey }
      );
    }

    seenSeasonKeys.add(competitionSeasonKey);
  }
}

function validateRequiredSeasonFields(season, failures) {
  const competitionSeasonKey = season && season.competitionSeasonKey;

  for (const field of REQUIRED_SEASON_FIELDS) {
    if (!Object.prototype.hasOwnProperty.call(season, field)) {
      addFailure(
        failures,
        `Required field is missing: ${field}.`,
        { competitionSeasonKey }
      );
    }
  }

  if (!isNonEmptyString(season.competitionSeasonKey)) {
    addFailure(
      failures,
      'competitionSeasonKey must be a non-empty string.',
      { competitionSeasonKey }
    );
  }

  if (typeof season.seasonYear !== 'number') {
    addFailure(
      failures,
      'seasonYear must be a number.',
      { competitionSeasonKey }
    );
  }

  if (!isNonEmptyString(season.competitionKey)) {
    addFailure(
      failures,
      'competitionKey must be a non-empty string.',
      { competitionSeasonKey }
    );
  }

  if (!isNonEmptyString(season.displayNameJa)) {
    addFailure(
      failures,
      'displayNameJa must be a non-empty string.',
      { competitionSeasonKey }
    );
  }

  if (typeof season.source === 'undefined' || season.source === null) {
    addFailure(
      failures,
      'source must be present.',
      { competitionSeasonKey }
    );
  }

  if (!ALLOWED_MEMBERSHIP_TYPES.has(season.membershipType)) {
    addFailure(
      failures,
      `membershipType must be one of: ${Array.from(
        ALLOWED_MEMBERSHIP_TYPES
      ).join(', ')}.`,
      { competitionSeasonKey }
    );
  }

  if (!ALLOWED_STATUSES.has(season.status)) {
    addFailure(
      failures,
      `status must be one of: ${Array.from(ALLOWED_STATUSES).join(', ')}.`,
      { competitionSeasonKey }
    );
  }

  if (typeof season.seedable !== 'boolean') {
    addFailure(
      failures,
      'seedable must be a boolean.',
      { competitionSeasonKey }
    );
  }
}

function validateGroups(season, failures) {
  const competitionSeasonKey = season.competitionSeasonKey;
  const result = {
    groupCount: 0,
    teamIds: [],
  };

  if (typeof season.groups === 'undefined') {
    return result;
  }

  if (!Array.isArray(season.groups)) {
    addFailure(
      failures,
      'groups must be an array when present.',
      { competitionSeasonKey }
    );
    return result;
  }

  result.groupCount = season.groups.length;
  const seenGroupKeys = new Set();
  const seenTeamIds = new Set();

  for (const group of season.groups) {
    const groupKey = group && group.groupKey;

    if (!isNonEmptyString(groupKey)) {
      addFailure(
        failures,
        'groupKey must be a non-empty string.',
        { competitionSeasonKey }
      );
    } else if (seenGroupKeys.has(groupKey)) {
      addFailure(
        failures,
        'groupKey must be unique within a season.',
        { competitionSeasonKey, groupKey }
      );
    } else {
      seenGroupKeys.add(groupKey);
    }

    if (!isNonEmptyString(group && group.displayNameJa)) {
      addFailure(
        failures,
        'group displayNameJa must be a non-empty string.',
        { competitionSeasonKey, groupKey }
      );
    }

    if (!Array.isArray(group && group.teamIds)) {
      addFailure(
        failures,
        'group teamIds must be an array.',
        { competitionSeasonKey, groupKey }
      );
      continue;
    }

    for (const teamId of group.teamIds) {
      result.teamIds.push(teamId);

      if (!isNonEmptyString(teamId)) {
        addFailure(
          failures,
          'teamId must be a non-empty string.',
          { competitionSeasonKey, groupKey }
        );
        continue;
      }

      if (seenTeamIds.has(teamId)) {
        addFailure(
          failures,
          'teamId must not be duplicated within the same competitionSeasonKey.',
          { competitionSeasonKey, groupKey, teamId }
        );
      } else {
        seenTeamIds.add(teamId);
      }
    }
  }

  return result;
}

function validateSpecial2026Season(season, groupResult, failures) {
  if (season.competitionSeasonKey !== SPECIAL_2026_COMPETITION_SEASON_KEY) {
    return;
  }

  if (!Array.isArray(season.groups)) {
    return;
  }

  if (season.groups.length !== 4) {
    addFailure(
      failures,
      'football_j2_j3_2026_hyakunen must have exactly 4 groups.',
      { competitionSeasonKey: season.competitionSeasonKey }
    );
  }

  const groupKeys = new Set(season.groups.map((group) => group.groupKey));
  for (const requiredGroupKey of SPECIAL_2026_GROUP_KEYS) {
    if (!groupKeys.has(requiredGroupKey)) {
      addFailure(
        failures,
        'football_j2_j3_2026_hyakunen is missing a required group key.',
        {
          competitionSeasonKey: season.competitionSeasonKey,
          groupKey: requiredGroupKey,
        }
      );
    }
  }

  for (const group of season.groups) {
    if (Array.isArray(group.teamIds) && group.teamIds.length !== 10) {
      addFailure(
        failures,
        'Each 2026 special season group must have exactly 10 team IDs.',
        {
          competitionSeasonKey: season.competitionSeasonKey,
          groupKey: group.groupKey,
        }
      );
    }
  }

  if (groupResult.teamIds.length !== 40) {
    addFailure(
      failures,
      'football_j2_j3_2026_hyakunen must have exactly 40 team IDs.',
      { competitionSeasonKey: season.competitionSeasonKey }
    );
  }
}

function validateTeamIdStatuses(
  season,
  groupResult,
  confirmedTeamIds,
  failures
) {
  const competitionSeasonKey = season.competitionSeasonKey;
  const teamIdStatuses = season.teamIdStatuses;
  const teamIds = groupResult.teamIds.filter(isNonEmptyString);
  const teamIdSet = new Set(teamIds);
  const result = {
    confirmedTeamReferences: 0,
    blockedOrUnconfirmedRows: 0,
  };

  if (typeof teamIdStatuses === 'undefined') {
    return result;
  }

  if (
    !teamIdStatuses ||
    typeof teamIdStatuses !== 'object' ||
    Array.isArray(teamIdStatuses)
  ) {
    addFailure(
      failures,
      'teamIdStatuses must be an object when present.',
      { competitionSeasonKey }
    );
    return result;
  }

  for (const teamId of teamIdSet) {
    if (!Object.prototype.hasOwnProperty.call(teamIdStatuses, teamId)) {
      addFailure(
        failures,
        'Every group teamId must exist in teamIdStatuses.',
        { competitionSeasonKey, teamId }
      );
    }
  }

  for (const [teamId, teamIdStatus] of Object.entries(teamIdStatuses)) {
    if (!teamIdSet.has(teamId)) {
      addFailure(
        failures,
        'Every teamIdStatuses teamId must exist in a group.',
        { competitionSeasonKey, teamId }
      );
    }

    if (!ALLOWED_TEAM_ID_STATUSES.has(teamIdStatus)) {
      addFailure(
        failures,
        `teamIdStatus must be one of: ${Array.from(
          ALLOWED_TEAM_ID_STATUSES
        ).join(', ')}.`,
        { competitionSeasonKey, teamId }
      );
      continue;
    }

    if (teamIdStatus === 'confirmed_team_master') {
      if (confirmedTeamIds.has(teamId)) {
        result.confirmedTeamReferences += 1;
      } else {
        addFailure(
          failures,
          'confirmed_team_master teamId must exist in local confirmed team master data.',
          { competitionSeasonKey, teamId }
        );
      }
    }

    if (BLOCKING_TEAM_ID_STATUSES.has(teamIdStatus)) {
      result.blockedOrUnconfirmedRows += 1;

      if (season.seedable === true) {
        addFailure(
          failures,
          `${teamIdStatus} rows must not be seedable.`,
          { competitionSeasonKey, teamId }
        );
      }
    }
  }

  return result;
}

function validateSeedability(season, groupResult, confirmedTeamIds, failures) {
  const competitionSeasonKey = season.competitionSeasonKey;
  const teamIdStatuses = season.teamIdStatuses || {};
  const teamIds = groupResult.teamIds.filter(isNonEmptyString);

  if (season.seedable !== true) {
    return;
  }

  for (const teamId of teamIds) {
    if (teamIdStatuses[teamId] !== 'confirmed_team_master') {
      addFailure(
        failures,
        'Seedable season teamIds must all be confirmed_team_master.',
        { competitionSeasonKey, teamId }
      );
    }

    if (!confirmedTeamIds.has(teamId)) {
      addFailure(
        failures,
        'Seedable season teamIds must all exist in local confirmed team master data.',
        { competitionSeasonKey, teamId }
      );
    }
  }
}

function validateSpecial2026SeedabilityDeferred(season, failures) {
  if (season.competitionSeasonKey !== SPECIAL_2026_COMPETITION_SEASON_KEY) {
    return;
  }

  if (season.seedable !== false) {
    addFailure(
      failures,
      'football_j2_j3_2026_hyakunen must remain seedable false until separate seedability review.',
      { competitionSeasonKey: season.competitionSeasonKey }
    );
  }
}

function verifyCompetitionSeasonMemberships(args) {
  const failures = [];
  const seasons = validateModuleShape(failures);
  const confirmedTeamIds = collectConfirmedTeamIds([j1Teams, j2Teams, j3Teams]);
  const counts = {
    checkedSeasons: 0,
    checkedGroups: 0,
    checkedMembershipTeamIds: 0,
    confirmedTeamReferences: 0,
    blockedOrUnconfirmedRows: 0,
  };

  validateUniqueSeasonKeys(seasons, failures);

  const targetSeasons = args.seasonKey
    ? seasons.filter(
        (season) => season.competitionSeasonKey === args.seasonKey
      )
    : seasons;

  if (args.seasonKey && targetSeasons.length === 0) {
    addFailure(
      failures,
      'Requested competitionSeasonKey was not found.',
      { competitionSeasonKey: args.seasonKey }
    );
  }

  for (const season of targetSeasons) {
    counts.checkedSeasons += 1;

    validateRequiredSeasonFields(season, failures);
    const groupResult = validateGroups(season, failures);
    validateSpecial2026Season(season, groupResult, failures);

    const teamStatusCounts = validateTeamIdStatuses(
      season,
      groupResult,
      confirmedTeamIds,
      failures
    );

    validateSeedability(season, groupResult, confirmedTeamIds, failures);
    validateSpecial2026SeedabilityDeferred(season, failures);

    counts.checkedGroups += groupResult.groupCount;
    counts.checkedMembershipTeamIds += groupResult.teamIds.length;
    counts.confirmedTeamReferences +=
      teamStatusCounts.confirmedTeamReferences;
    counts.blockedOrUnconfirmedRows +=
      teamStatusCounts.blockedOrUnconfirmedRows;
  }

  return {
    counts,
    failures,
  };
}

function printResult(result) {
  const { counts, failures } = result;

  console.log(`checked seasons: ${counts.checkedSeasons}`);
  console.log(`checked groups: ${counts.checkedGroups}`);
  console.log(
    `checked membership teamIds: ${counts.checkedMembershipTeamIds}`
  );
  console.log(`confirmed team references: ${counts.confirmedTeamReferences}`);
  console.log(`blocked/unconfirmed rows: ${counts.blockedOrUnconfirmedRows}`);

  if (failures.length === 0) {
    console.log('✅ Competition season membership checks PASSED.');
    return;
  }

  console.error('❌ Competition season membership checks FAILED.');
  console.error(`failures: ${failures.length}`);
  for (const failure of failures) {
    console.error(`- ${formatFailure(failure)}`);
  }
}

function main() {
  try {
    const args = parseArgs(process.argv.slice(2));
    const result = verifyCompetitionSeasonMemberships(args);

    printResult(result);

    if (result.failures.length > 0) {
      process.exit(1);
    }
  } catch (error) {
    console.error('❌ Competition season membership checks FAILED.');
    console.error(`failures: 1`);
    console.error(`- ${error.message}`);
    process.exit(1);
  }
}

main();
