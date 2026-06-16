/**
 * seedCompetitionSeasonMemberships.js
 *
 * Dry-run first seed preparation script for competition season memberships.
 *
 * Dry-run mode does not initialize Firebase Admin SDK, does not read
 * serviceAccountKey, and does not read or write Firestore.
 *
 * Usage:
 *   node functions/scripts/seedCompetitionSeasonMemberships.js [--dry-run] [--season <competitionSeasonKey>]
 *   node functions/scripts/seedCompetitionSeasonMemberships.js --write [--season <competitionSeasonKey>]
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

const SEED_ALLOWED_STATUSES = new Set([
  'approved',
  'seedable',
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

function parseArgs(argv) {
  const args = {
    dryRun: true,
    write: false,
    seasonKey: null,
  };

  for (let index = 0; index < argv.length; index += 1) {
    const arg = argv[index];

    if (arg === '--dry-run') {
      args.dryRun = true;
      continue;
    }

    if (arg === '--write') {
      args.write = true;
      args.dryRun = false;
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

function collectConfirmedTeamIds() {
  const confirmedTeamIds = new Set();

  for (const teams of [j1Teams, j2Teams, j3Teams]) {
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

  if (!Array.isArray(season.groups)) {
    addFailure(
      failures,
      'groups must be an array.',
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
    hasBlockingRows: false,
    allConfirmedTeamMaster: true,
  };

  if (
    !teamIdStatuses ||
    typeof teamIdStatuses !== 'object' ||
    Array.isArray(teamIdStatuses)
  ) {
    addFailure(
      failures,
      'teamIdStatuses must be an object.',
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
      result.allConfirmedTeamMaster = false;
      continue;
    }

    if (teamIdStatus !== 'confirmed_team_master') {
      result.allConfirmedTeamMaster = false;
    }

    if (teamIdStatus === 'confirmed_team_master') {
      if (!confirmedTeamIds.has(teamId)) {
        addFailure(
          failures,
          'confirmed_team_master teamId must exist in local confirmed team master data.',
          { competitionSeasonKey, teamId }
        );
        result.allConfirmedTeamMaster = false;
      }
    }

    if (BLOCKING_TEAM_ID_STATUSES.has(teamIdStatus)) {
      result.hasBlockingRows = true;

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

function validateSeasons({ seasonKey }) {
  const failures = [];
  const seasons = validateModuleShape(failures);
  const confirmedTeamIds = collectConfirmedTeamIds();

  validateUniqueSeasonKeys(seasons, failures);

  const targetSeasons = seasonKey
    ? seasons.filter((season) => season.competitionSeasonKey === seasonKey)
    : seasons;

  if (seasonKey && targetSeasons.length === 0) {
    addFailure(
      failures,
      'Requested competitionSeasonKey was not found.',
      { competitionSeasonKey: seasonKey }
    );
  }

  const profiles = targetSeasons.map((season) => {
    validateRequiredSeasonFields(season, failures);
    const groupResult = validateGroups(season, failures);
    const teamIdStatusResult = validateTeamIdStatuses(
      season,
      groupResult,
      confirmedTeamIds,
      failures
    );
    validateSpecial2026SeedabilityDeferred(season, failures);

    if (
      season.seedable === true &&
      !SEED_ALLOWED_STATUSES.has(season.status)
    ) {
      addFailure(
        failures,
        'Seedable season must have a seed-allowed status.',
        { competitionSeasonKey: season.competitionSeasonKey }
      );
    }

    return {
      season,
      groupResult,
      hasBlockingRows: teamIdStatusResult.hasBlockingRows,
      allConfirmedTeamMaster: teamIdStatusResult.allConfirmedTeamMaster,
    };
  });

  return {
    failures,
    profiles,
  };
}

function isWriteCandidate(profile) {
  return (
    profile.season.seedable === true &&
    SEED_ALLOWED_STATUSES.has(profile.season.status) &&
    profile.hasBlockingRows === false &&
    profile.allConfirmedTeamMaster === true
  );
}

function toFirestoreDoc(profile, admin) {
  const { season } = profile;
  const timestamp = admin.firestore.FieldValue.serverTimestamp();

  return {
    competitionSeasonKey: season.competitionSeasonKey,
    seasonYear: season.seasonYear,
    competitionKey: season.competitionKey,
    displayNameJa: season.displayNameJa,
    membershipType: season.membershipType,
    status: season.status,
    seedable: season.seedable,
    source: season.source,
    groups: season.groups,
    teamIdStatuses: season.teamIdStatuses,
    createdAt: timestamp,
    updatedAt: timestamp,
  };
}

async function writeSeasonMemberships(writeCandidates) {
  if (writeCandidates.length === 0) {
    return 0;
  }

  const admin = require('firebase-admin');
  const serviceAccount = require('../serviceAccountKey.json');
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });

  try {
    const db = admin.firestore();
    for (const profile of writeCandidates) {
      const doc = toFirestoreDoc(profile, admin);
      await db
        .collection('competitionSeasonMemberships')
        .doc(profile.season.competitionSeasonKey)
        .set(doc, { merge: true });
    }
  } finally {
    await admin.app().delete();
  }

  return writeCandidates.length;
}

function printFailures(failures) {
  console.error('❌ Competition season membership seed preparation FAILED.');
  console.error(`failures: ${failures.length}`);
  for (const failure of failures) {
    console.error(`- ${formatFailure(failure)}`);
  }
}

async function seedCompetitionSeasonMemberships(args) {
  const mode = args.write ? 'write' : 'dry-run';
  const validation = validateSeasons({ seasonKey: args.seasonKey });

  if (validation.failures.length > 0) {
    printFailures(validation.failures);
    return 1;
  }

  const checkedSeasons = validation.profiles.length;
  const seedableSeasons = validation.profiles.filter(
    (profile) => profile.season.seedable === true
  ).length;
  const writeCandidates = validation.profiles.filter(isWriteCandidate);
  const skippedNonSeedableSeasons = checkedSeasons - writeCandidates.length;
  const writtenSeasons = args.write
    ? await writeSeasonMemberships(writeCandidates)
    : 0;

  console.log(`mode: ${mode}`);
  console.log(`checked seasons: ${checkedSeasons}`);
  console.log(`seedable seasons: ${seedableSeasons}`);
  console.log(`skipped non-seedable seasons: ${skippedNonSeedableSeasons}`);
  console.log(`write candidates: ${writeCandidates.length}`);
  console.log(`written seasons: ${writtenSeasons}`);

  if (!args.write) {
    console.log('Dry-run only. Firestore will not be written.');
  } else if (writeCandidates.length === 0) {
    console.log('No write candidates. Firestore was not written.');
  }

  console.log('✅ Competition season membership seed preparation PASSED.');
  return 0;
}

async function main() {
  let exitCode = 0;

  try {
    const args = parseArgs(process.argv.slice(2));
    exitCode = await seedCompetitionSeasonMemberships(args);
  } catch (error) {
    console.error('❌ Competition season membership seed preparation FAILED.');
    console.error(`failures: 1`);
    console.error(`- ${error.message || error}`);
    exitCode = 1;
  }

  process.exit(exitCode);
}

main();
