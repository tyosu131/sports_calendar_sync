/**
 * verifyCompetitionSeasonMembershipFirestore.js
 *
 * Read-only Firestore verification for one competition season membership
 * document. This script reads exactly one Firestore document and compares it
 * with the local competitionSeasonMemberships.js profile.
 *
 * Usage:
 *   node functions/scripts/verifyCompetitionSeasonMembershipFirestore.js --season <competitionSeasonKey>
 */

'use strict';

const {
  competitionSeasonMemberships,
} = require('./data/competitionSeasonMemberships');

const REQUIRED_FIELDS = [
  'competitionSeasonKey',
  'seasonYear',
  'competitionKey',
  'displayNameJa',
  'membershipType',
  'status',
  'seedable',
  'source',
  'groups',
  'teamIdStatuses',
];

const SPECIAL_2026_COMPETITION_SEASON_KEY =
  'football_j2_j3_2026_hyakunen';

const BLOCKING_TEAM_ID_STATUSES = new Set([
  'candidate_not_confirmed',
  'blocked_continuity',
  'missing_team_master',
]);

function parseArgs(argv) {
  const args = {
    seasonKey: null,
  };

  for (let index = 0; index < argv.length; index += 1) {
    const arg = argv[index];

    if (arg === '--season') {
      const seasonKey = argv[index + 1];
      if (!seasonKey || seasonKey.startsWith('--')) {
        throw new Error('--season requires a competitionSeasonKey value.');
      }
      args.seasonKey = seasonKey;
      index += 1;
      continue;
    }

    if (arg === '--write') {
      throw new Error('--write is not supported by this read-only verifier.');
    }

    throw new Error(`Unknown argument: ${arg}`);
  }

  if (!args.seasonKey) {
    throw new Error('--season <competitionSeasonKey> is required.');
  }

  return args;
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

function stableStringify(value) {
  if (Array.isArray(value)) {
    return `[${value.map(stableStringify).join(',')}]`;
  }

  if (value && typeof value === 'object') {
    const keys = Object.keys(value).sort();
    return `{${keys
      .map((key) => `${JSON.stringify(key)}:${stableStringify(value[key])}`)
      .join(',')}}`;
  }

  return JSON.stringify(value);
}

function valuesMatch(left, right) {
  return stableStringify(left) === stableStringify(right);
}

function findLocalProfile(competitionSeasonKey) {
  if (!Array.isArray(competitionSeasonMemberships)) {
    return null;
  }

  return competitionSeasonMemberships.find(
    (profile) => profile.competitionSeasonKey === competitionSeasonKey
  ) || null;
}

function collectGroupTeamIds(groups) {
  const teamIds = [];

  if (!Array.isArray(groups)) {
    return teamIds;
  }

  for (const group of groups) {
    if (!Array.isArray(group && group.teamIds)) {
      continue;
    }

    for (const teamId of group.teamIds) {
      teamIds.push(teamId);
    }
  }

  return teamIds;
}

function countBlockingRows(teamIdStatuses) {
  if (
    !teamIdStatuses ||
    typeof teamIdStatuses !== 'object' ||
    Array.isArray(teamIdStatuses)
  ) {
    return 0;
  }

  return Object.values(teamIdStatuses).filter((status) =>
    BLOCKING_TEAM_ID_STATUSES.has(status)
  ).length;
}

function countConfirmedReferences(teamIdStatuses) {
  if (
    !teamIdStatuses ||
    typeof teamIdStatuses !== 'object' ||
    Array.isArray(teamIdStatuses)
  ) {
    return 0;
  }

  return Object.values(teamIdStatuses).filter(
    (status) => status === 'confirmed_team_master'
  ).length;
}

function validateRequiredFields(data, failures, competitionSeasonKey) {
  for (const field of REQUIRED_FIELDS) {
    if (!Object.prototype.hasOwnProperty.call(data, field)) {
      addFailure(
        failures,
        `Firestore document is missing required field: ${field}.`,
        { competitionSeasonKey }
      );
    }
  }
}

function validateScalarFields(data, localProfile, failures) {
  const competitionSeasonKey = localProfile.competitionSeasonKey;
  const scalarFields = [
    'competitionSeasonKey',
    'seasonYear',
    'competitionKey',
    'displayNameJa',
    'membershipType',
    'status',
    'seedable',
  ];

  for (const field of scalarFields) {
    if (data[field] !== localProfile[field]) {
      addFailure(
        failures,
        `Firestore field does not match local profile: ${field}.`,
        { competitionSeasonKey }
      );
    }
  }

  if (!valuesMatch(data.source, localProfile.source)) {
    addFailure(
      failures,
      'Firestore source does not match local profile.',
      { competitionSeasonKey }
    );
  }
}

function validateGroups(data, localProfile, failures) {
  const competitionSeasonKey = localProfile.competitionSeasonKey;

  if (!Array.isArray(data.groups)) {
    addFailure(
      failures,
      'Firestore groups must be an array.',
      { competitionSeasonKey }
    );
    return;
  }

  if (data.groups.length !== localProfile.groups.length) {
    addFailure(
      failures,
      'Firestore group count does not match local profile.',
      { competitionSeasonKey }
    );
  }

  const groupCount = Math.max(data.groups.length, localProfile.groups.length);

  for (let index = 0; index < groupCount; index += 1) {
    const firestoreGroup = data.groups[index];
    const localGroup = localProfile.groups[index];
    const groupKey =
      (localGroup && localGroup.groupKey) ||
      (firestoreGroup && firestoreGroup.groupKey) ||
      null;

    if (!firestoreGroup || !localGroup) {
      addFailure(
        failures,
        'Firestore group position does not match local profile.',
        { competitionSeasonKey, groupKey }
      );
      continue;
    }

    if (firestoreGroup.groupKey !== localGroup.groupKey) {
      addFailure(
        failures,
        'Firestore groupKey does not match local profile at the same position.',
        { competitionSeasonKey, groupKey }
      );
    }

    if (firestoreGroup.displayNameJa !== localGroup.displayNameJa) {
      addFailure(
        failures,
        'Firestore group displayNameJa does not match local profile.',
        { competitionSeasonKey, groupKey }
      );
    }

    if (!Array.isArray(firestoreGroup.teamIds)) {
      addFailure(
        failures,
        'Firestore group teamIds must be an array.',
        { competitionSeasonKey, groupKey }
      );
      continue;
    }

    if (firestoreGroup.teamIds.length !== localGroup.teamIds.length) {
      addFailure(
        failures,
        'Firestore group teamIds length does not match local profile.',
        { competitionSeasonKey, groupKey }
      );
    }

    const teamIdCount = Math.max(
      firestoreGroup.teamIds.length,
      localGroup.teamIds.length
    );

    for (let teamIndex = 0; teamIndex < teamIdCount; teamIndex += 1) {
      const firestoreTeamId = firestoreGroup.teamIds[teamIndex];
      const localTeamId = localGroup.teamIds[teamIndex];

      if (firestoreTeamId !== localTeamId) {
        addFailure(
          failures,
          'Firestore group teamIds order does not match local profile.',
          {
            competitionSeasonKey,
            groupKey,
            teamId: localTeamId || firestoreTeamId || null,
          }
        );
      }
    }
  }
}

function validateTeamIdStatuses(data, localProfile, failures) {
  const competitionSeasonKey = localProfile.competitionSeasonKey;
  const firestoreStatuses = data.teamIdStatuses;
  const localStatuses = localProfile.teamIdStatuses;

  if (
    !firestoreStatuses ||
    typeof firestoreStatuses !== 'object' ||
    Array.isArray(firestoreStatuses)
  ) {
    addFailure(
      failures,
      'Firestore teamIdStatuses must be an object.',
      { competitionSeasonKey }
    );
    return;
  }

  for (const [teamId, localStatus] of Object.entries(localStatuses)) {
    if (!Object.prototype.hasOwnProperty.call(firestoreStatuses, teamId)) {
      addFailure(
        failures,
        'Local teamId is missing from Firestore teamIdStatuses.',
        { competitionSeasonKey, teamId }
      );
      continue;
    }

    if (firestoreStatuses[teamId] !== localStatus) {
      addFailure(
        failures,
        'Firestore teamIdStatus does not match local profile.',
        { competitionSeasonKey, teamId }
      );
    }
  }

  for (const teamId of Object.keys(firestoreStatuses)) {
    if (!Object.prototype.hasOwnProperty.call(localStatuses, teamId)) {
      addFailure(
        failures,
        'Firestore teamIdStatuses contains extra teamId.',
        { competitionSeasonKey, teamId }
      );
    }
  }
}

function validateMembershipTeamIds(data, localProfile, failures) {
  const competitionSeasonKey = localProfile.competitionSeasonKey;
  const firestoreTeamIds = new Set(collectGroupTeamIds(data.groups));
  const localTeamIds = new Set(collectGroupTeamIds(localProfile.groups));

  for (const teamId of localTeamIds) {
    if (!firestoreTeamIds.has(teamId)) {
      addFailure(
        failures,
        'Local group teamId is missing from Firestore groups.',
        { competitionSeasonKey, teamId }
      );
    }
  }

  for (const teamId of firestoreTeamIds) {
    if (!localTeamIds.has(teamId)) {
      addFailure(
        failures,
        'Firestore groups contain extra teamId.',
        { competitionSeasonKey, teamId }
      );
    }
  }
}

function validateTimestamps(data, failures, competitionSeasonKey) {
  if (typeof data.createdAt === 'undefined' || data.createdAt === null) {
    addFailure(
      failures,
      'Firestore createdAt must exist.',
      { competitionSeasonKey }
    );
  }

  if (typeof data.updatedAt === 'undefined' || data.updatedAt === null) {
    addFailure(
      failures,
      'Firestore updatedAt must exist.',
      { competitionSeasonKey }
    );
  }
}

function validateSpecial2026ExpectedValues(data, failures, stats) {
  if (data.competitionSeasonKey !== SPECIAL_2026_COMPETITION_SEASON_KEY) {
    return;
  }

  const competitionSeasonKey = data.competitionSeasonKey;

  if (data.status !== 'seedable') {
    addFailure(
      failures,
      'football_j2_j3_2026_hyakunen status must be seedable.',
      { competitionSeasonKey }
    );
  }

  if (data.seedable !== true) {
    addFailure(
      failures,
      'football_j2_j3_2026_hyakunen seedable must be true.',
      { competitionSeasonKey }
    );
  }

  if (stats.groups !== 4) {
    addFailure(
      failures,
      'football_j2_j3_2026_hyakunen must have 4 groups.',
      { competitionSeasonKey }
    );
  }

  if (stats.membershipTeamIds !== 40) {
    addFailure(
      failures,
      'football_j2_j3_2026_hyakunen must have 40 membership teamIds.',
      { competitionSeasonKey }
    );
  }

  if (stats.confirmedTeamReferences !== 40) {
    addFailure(
      failures,
      'football_j2_j3_2026_hyakunen must have 40 confirmed team references.',
      { competitionSeasonKey }
    );
  }

  if (stats.blockedUnconfirmedRows !== 0) {
    addFailure(
      failures,
      'football_j2_j3_2026_hyakunen must have 0 blocked/unconfirmed rows.',
      { competitionSeasonKey }
    );
  }
}

function printFailures(failures) {
  console.error(
    '❌ Competition season membership Firestore verification FAILED.'
  );
  console.error(`failures: ${failures.length}`);
  for (const failure of failures) {
    console.error(`- ${formatFailure(failure)}`);
  }
}

async function readFirestoreDocument(competitionSeasonKey) {
  const admin = require('firebase-admin');
  const serviceAccount = require('../serviceAccountKey.json');

  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });

  const db = admin.firestore();
  const snapshot = await db
    .collection('competitionSeasonMemberships')
    .doc(competitionSeasonKey)
    .get();

  return {
    exists: snapshot.exists,
    data: snapshot.exists ? snapshot.data() : null,
  };
}

async function verifyCompetitionSeasonMembershipFirestore(args) {
  const failures = [];
  const localProfile = findLocalProfile(args.seasonKey);

  if (!localProfile) {
    addFailure(
      failures,
      'Requested competitionSeasonKey was not found in local profile data.',
      { competitionSeasonKey: args.seasonKey }
    );
    printFailures(failures);
    return 1;
  }

  const firestoreDocument = await readFirestoreDocument(args.seasonKey);

  if (!firestoreDocument.exists) {
    addFailure(
      failures,
      'Target Firestore document does not exist.',
      { competitionSeasonKey: args.seasonKey }
    );
    printFailures(failures);
    return 1;
  }

  const data = firestoreDocument.data;
  const stats = {
    groups: Array.isArray(data.groups) ? data.groups.length : 0,
    membershipTeamIds: collectGroupTeamIds(data.groups).length,
    confirmedTeamReferences: countConfirmedReferences(data.teamIdStatuses),
    blockedUnconfirmedRows: countBlockingRows(data.teamIdStatuses),
  };

  validateRequiredFields(data, failures, args.seasonKey);
  validateScalarFields(data, localProfile, failures);
  validateGroups(data, localProfile, failures);
  validateTeamIdStatuses(data, localProfile, failures);
  validateMembershipTeamIds(data, localProfile, failures);
  validateTimestamps(data, failures, args.seasonKey);
  validateSpecial2026ExpectedValues(data, failures, stats);

  if (failures.length > 0) {
    printFailures(failures);
    return 1;
  }

  console.log('mode: firestore-read');
  console.log('checked documents: 1');
  console.log('target document exists: yes');
  console.log(`groups: ${stats.groups}`);
  console.log(`membership teamIds: ${stats.membershipTeamIds}`);
  console.log(`confirmed team references: ${stats.confirmedTeamReferences}`);
  console.log(`blocked/unconfirmed rows: ${stats.blockedUnconfirmedRows}`);
  console.log('field checks: PASS');
  console.log('group checks: PASS');
  console.log('teamIdStatuses checks: PASS');
  console.log('result: PASS');
  console.log(
    '✅ Competition season membership Firestore verification PASSED.'
  );
  return 0;
}

async function main() {
  let exitCode = 0;

  try {
    const args = parseArgs(process.argv.slice(2));
    exitCode = await verifyCompetitionSeasonMembershipFirestore(args);
  } catch (error) {
    printFailures([
      {
        reason: error.message || String(error),
        competitionSeasonKey: null,
        groupKey: null,
        teamId: null,
      },
    ]);
    exitCode = 1;
  }

  process.exit(exitCode);
}

main();
