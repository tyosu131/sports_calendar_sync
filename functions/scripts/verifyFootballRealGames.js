/**
 * verifyFootballRealGames.js
 *
 * Read-only verification for football GameDoc data after future API sync.
 * Dry-run mode validates script configuration and planned checks without
 * initializing Firebase Admin SDK. Non-dry mode reads Firestore only.
 *
 * Usage:
 *   node functions/scripts/verifyFootballRealGames.js --dry-run
 *   node functions/scripts/verifyFootballRealGames.js
 *   node functions/scripts/verifyFootballRealGames.js --require-games
 */

'use strict';

const { getCompetitionTeamData, listCompetitionKeys } = require('./data/competitionRegistry');
const {
  CURRENT_J1_COMPETITION_SEASON_KEY,
  getCompetitionSeasonProfile,
} = require('./data/competitionSeasons');

const DEFAULT_COMPETITION_KEY = 'football_j1';
const DEFAULT_COMPETITION_SEASON_KEY = CURRENT_J1_COMPETITION_SEASON_KEY;
const QUERY_LIMIT = 100;
const HOME_QUERY_LIMIT = 50;
const WHERE_IN_LIMIT = 10;

const VALID_STATUSES = [
  'scheduled',
  'live',
  'finished',
  'postponed',
  'cancelled',
];

const REQUIRED_GAME_FIELDS = [
  'competitionKey',
  'competitionSeasonKey',
  'sportKey',
  'leagueId',
  'homeTeamId',
  'awayTeamId',
  'homeTeamNameJa',
  'awayTeamNameJa',
  'homeTeamNameEn',
  'awayTeamNameEn',
  'homeTeamLogoUrl',
  'awayTeamLogoUrl',
  'startTimeUTC',
  'startTimeJST',
  'timezone',
  'status',
  'broadcastPlatforms',
  'externalFixtureId',
  'rapidApiFixtureId',
];

function isRealSyncGameDoc(doc) {
  return doc.id.startsWith('football_');
}

function parseArgs(argv) {
  const options = {
    competitionKey: DEFAULT_COMPETITION_KEY,
    competitionSeasonKey: DEFAULT_COMPETITION_SEASON_KEY,
    dryRun: argv.includes('--dry-run'),
    requireGames: argv.includes('--require-games'),
  };

  for (const arg of argv) {
    if (arg.startsWith('--competitionKey=')) {
      options.competitionKey = arg.slice('--competitionKey='.length);
    } else if (arg.startsWith('--competitionSeasonKey=')) {
      options.competitionSeasonKey = arg.slice('--competitionSeasonKey='.length);
    }
  }

  return options;
}

function check(label, condition, detail) {
  const status = condition ? 'PASS' : 'FAIL';
  console.log(`  [${status}] ${label}${detail ? ': ' + detail : ''}`);
  return condition;
}

function warn(label, detail) {
  console.log(`  [WARN] ${label}${detail ? ': ' + detail : ''}`);
}

function startTimeDate(value) {
  if (value instanceof Date) return value;
  if (typeof value === 'string') return new Date(value);
  if (value && typeof value.toDate === 'function') return value.toDate();
  return null;
}

function chunkArray(values, size) {
  const chunks = [];
  for (let i = 0; i < values.length; i += size) {
    chunks.push(values.slice(i, i + size));
  }
  return chunks;
}

function validateConfiguration(options) {
  console.log('=== Section 1: Configuration ===');
  const competitionData = getCompetitionTeamData(options.competitionKey);
  const seasonProfile = getCompetitionSeasonProfile(options.competitionSeasonKey);

  let allPassed = true;
  allPassed = check(
    'competitionKey exists in competition registry',
    competitionData.competition.competitionKey === options.competitionKey,
    options.competitionKey,
  ) && allPassed;
  allPassed = check(
    'competitionSeasonKey exists in season profiles',
    seasonProfile.competitionSeasonKey === options.competitionSeasonKey,
    options.competitionSeasonKey,
  ) && allPassed;
  allPassed = check(
    'season profile competitionKey matches selected competitionKey',
    seasonProfile.competitionKey === options.competitionKey,
    `${seasonProfile.competitionKey} (expected: ${options.competitionKey})`,
  ) && allPassed;
  allPassed = check(
    'confirmed team candidates are available',
    competitionData.teams.length > 0,
    `${competitionData.teams.length} teams`,
  ) && allPassed;

  console.log(`  competitionKey: ${options.competitionKey}`);
  console.log(`  competitionSeasonKey: ${options.competitionSeasonKey}`);
  console.log(`  leagueId: ${competitionData.competition.leagueId}`);
  console.log(`  candidate followed teams: ${competitionData.teams.length}`);
  console.log(`  requireGames: ${options.requireGames}`);

  return {
    allPassed,
    competitionData,
    seasonProfile,
  };
}

function validateGameDoc(doc, data, { competitionKey, competitionSeasonKey, leagueId }) {
  let allPassed = true;

  console.log(`\nVerifying games/${doc.id} ...`);
  console.log('=== Section 2: Game document field checks ===');
  for (const field of REQUIRED_GAME_FIELDS) {
    allPassed = check(
      `${doc.id}.${field} present`,
      data[field] !== undefined && data[field] !== null,
    ) && allPassed;
  }

  allPassed = check(
    `${doc.id}.competitionKey matches selected competition`,
    data.competitionKey === competitionKey,
    `${JSON.stringify(data.competitionKey)} (expected: ${JSON.stringify(competitionKey)})`,
  ) && allPassed;
  allPassed = check(
    `${doc.id}.competitionSeasonKey matches selected profile`,
    data.competitionSeasonKey === competitionSeasonKey,
    `${JSON.stringify(data.competitionSeasonKey)} (expected: ${JSON.stringify(competitionSeasonKey)})`,
  ) && allPassed;
  allPassed = check(
    `${doc.id}.leagueId matches competition`,
    data.leagueId === leagueId,
    `${JSON.stringify(data.leagueId)} (expected: ${JSON.stringify(leagueId)})`,
  ) && allPassed;
  allPassed = check(
    `${doc.id}.status is supported`,
    VALID_STATUSES.includes(data.status),
    JSON.stringify(data.status),
  ) && allPassed;
  allPassed = check(
    `${doc.id}.broadcastPlatforms is array`,
    Array.isArray(data.broadcastPlatforms),
  ) && allPassed;

  const start = startTimeDate(data.startTimeUTC);
  allPassed = check(
    `${doc.id}.startTimeUTC parseable`,
    start instanceof Date && !Number.isNaN(start.getTime()),
  ) && allPassed;

  console.log('=== Section 4: Fixture ID compatibility checks ===');
  allPassed = check(
    `${doc.id}.competitionKey === sportKey`,
    data.competitionKey === data.sportKey,
    `${JSON.stringify(data.competitionKey)} / ${JSON.stringify(data.sportKey)}`,
  ) && allPassed;
  allPassed = check(
    `${doc.id}.externalFixtureId === rapidApiFixtureId`,
    data.externalFixtureId === data.rapidApiFixtureId,
    `${JSON.stringify(data.externalFixtureId)} / ${JSON.stringify(data.rapidApiFixtureId)}`,
  ) && allPassed;
  allPassed = check(
    `${doc.id}.externalFixtureId is number`,
    typeof data.externalFixtureId === 'number',
    JSON.stringify(data.externalFixtureId),
  ) && allPassed;

  return allPassed;
}

async function verifyTeamMapping({ db, gameDocs, competitionKey }) {
  let allPassed = true;
  const teamIds = new Set();

  console.log('\n=== Section 3: Team mapping checks ===');
  for (const doc of gameDocs) {
    const data = doc.data();
    teamIds.add(data.homeTeamId);
    teamIds.add(data.awayTeamId);
  }

  for (const teamId of teamIds) {
    allPassed = check(
      `${teamId} is not placeholder-like`,
      typeof teamId === 'string' && !teamId.startsWith('football_team_'),
    ) && allPassed;

    if (typeof teamId !== 'string') {
      allPassed = false;
      continue;
    }

    const teamDoc = await db.collection('teams').doc(teamId).get();
    allPassed = check(`${teamId} exists in /teams`, teamDoc.exists) && allPassed;
    if (!teamDoc.exists) continue;

    const teamData = teamDoc.data();
    const teamCompetitionKey = teamData.competitionKey ?? teamData.sportKey;
    const externalTeamId = teamData.externalTeamId ?? teamData.rapidApiId;
    allPassed = check(
      `${teamId}.competitionKey or sportKey matches`,
      teamCompetitionKey === competitionKey,
      `${JSON.stringify(teamCompetitionKey)} (expected: ${JSON.stringify(competitionKey)})`,
    ) && allPassed;
    allPassed = check(
      `${teamId}.externalTeamId or rapidApiId is number`,
      typeof externalTeamId === 'number',
      JSON.stringify(externalTeamId),
    ) && allPassed;
  }

  return allPassed;
}

async function fetchUpcomingGamesForFollowedTeams({ db, teamIds, nowTimestamp, limit = HOME_QUERY_LIMIT }) {
  const docsById = new Map();

  for (const chunk of chunkArray(teamIds, WHERE_IN_LIMIT)) {
    const homeSnap = await db.collection('games')
      .where('homeTeamId', 'in', chunk)
      .where('startTimeUTC', '>=', nowTimestamp)
      .orderBy('startTimeUTC')
      .limit(limit)
      .get();
    console.log(`  [INFO] homeTeamId in [${chunk.join(', ')}] returned ${homeSnap.docs.length} docs`);

    const awaySnap = await db.collection('games')
      .where('awayTeamId', 'in', chunk)
      .where('startTimeUTC', '>=', nowTimestamp)
      .orderBy('startTimeUTC')
      .limit(limit)
      .get();
    console.log(`  [INFO] awayTeamId in [${chunk.join(', ')}] returned ${awaySnap.docs.length} docs`);

    for (const doc of [...homeSnap.docs, ...awaySnap.docs]) {
      docsById.set(doc.id, doc);
    }
  }

  return Array.from(docsById.values())
    .sort((a, b) => startTimeDate(a.data().startTimeUTC) - startTimeDate(b.data().startTimeUTC))
    .slice(0, limit);
}

async function verifyHomeQuery({ db, teamIds, nowTimestamp }) {
  let allPassed = true;

  console.log('\n=== Section 5: Home query checks ===');
  console.log('Query shape mirrors GameRepository.fetchUpcomingGamesForTeams:');
  console.log('  homeTeamId in chunk OR awayTeamId in chunk, startTimeUTC >= now, orderBy startTimeUTC, limit 50');
  console.log('  status filter: none');

  const docs = await fetchUpcomingGamesForFollowedTeams({ db, teamIds, nowTimestamp });
  const realSyncDocs = docs.filter(isRealSyncGameDoc);
  console.log(`  [INFO] merged upcoming followed-team query returned ${docs.length} docs`);
  console.log(`  [INFO] real sync docs from home query: ${realSyncDocs.length}`);

  for (const doc of docs) {
    const data = doc.data();
    const start = startTimeDate(data.startTimeUTC);
    allPassed = check(
      `home query result ${doc.id}.startTimeUTC parseable`,
      start instanceof Date && !Number.isNaN(start.getTime()),
    ) && allPassed;
  }

  return allPassed;
}

async function verifyFirestore(options, competitionData) {
  const admin = require('firebase-admin');
  const serviceAccount = require('../serviceAccountKey.json');

  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });

  try {
    const db = admin.firestore();
    const nowTimestamp = admin.firestore.Timestamp.now();
    let allPassed = true;

    console.log('\n=== Section 2: Game document field checks ===');
    const gamesSnap = await db.collection('games')
      .where('competitionKey', '==', options.competitionKey)
      .where('competitionSeasonKey', '==', options.competitionSeasonKey)
      .limit(QUERY_LIMIT)
      .get();
    const realSyncDocs = gamesSnap.docs.filter(isRealSyncGameDoc);
    const nonRealDocs = gamesSnap.docs.filter((doc) => !isRealSyncGameDoc(doc));

    console.log(`  [INFO] matching season docs: ${gamesSnap.docs.length}`);
    console.log(`  [INFO] real sync docs (id starts with "football_"): ${realSyncDocs.length}`);
    console.log(`  [INFO] non-real/sample docs: ${nonRealDocs.length}`);
    if (nonRealDocs.length > 0) {
      console.log(`  [INFO] non-real/sample doc ids: ${nonRealDocs.map((doc) => doc.id).join(', ')}`);
    }

    if (realSyncDocs.length === 0) {
      const message = '0 real games found. Real sync has not populated matching games yet.';
      if (options.requireGames) {
        allPassed = check('real games exist when --require-games is set', false, message) && allPassed;
      } else {
        warn('real games not found', message);
      }
    }

    for (const doc of realSyncDocs) {
      allPassed = validateGameDoc(doc, doc.data(), {
        competitionKey: options.competitionKey,
        competitionSeasonKey: options.competitionSeasonKey,
        leagueId: competitionData.competition.leagueId,
      }) && allPassed;
    }

    if (realSyncDocs.length > 0) {
      allPassed = await verifyTeamMapping({
        db,
        gameDocs: realSyncDocs,
        competitionKey: options.competitionKey,
      }) && allPassed;
    } else {
      console.log('\n=== Section 3: Team mapping checks ===');
      warn('team mapping checks skipped', 'No real sync games found.');
      console.log('\n=== Section 4: Fixture ID compatibility checks ===');
      warn('fixture ID compatibility checks skipped', 'No real sync games found.');
    }

    const followedTeamIds = competitionData.teams.map((team) => team.id);
    allPassed = await verifyHomeQuery({
      db,
      teamIds: followedTeamIds,
      nowTimestamp,
    }) && allPassed;

    return allPassed;
  } finally {
    await admin.app().delete();
  }
}

async function verify(options) {
  const { allPassed, competitionData } = validateConfiguration(options);

  if (options.dryRun) {
    console.log('\n=== Section 2: Planned checks ===');
    console.log('  Firestore will not be initialized, read, or written.');
    console.log(`  Required GameDoc fields: ${REQUIRED_GAME_FIELDS.join(', ')}`);
    console.log(`  Valid statuses: ${VALID_STATUSES.join(', ')}`);
    console.log('  Non-dry mode will verify game fields, team mapping, fixture ID compatibility, and home query behavior.');
    console.log('\n=== Section 6: Summary ===');
    return allPassed;
  }

  const firestorePassed = await verifyFirestore(options, competitionData);
  console.log('\n=== Section 6: Summary ===');
  return allPassed && firestorePassed;
}

async function main() {
  let exitCode = 0;
  try {
    const options = parseArgs(process.argv.slice(2));
    console.log('[verify:football-real-games] readOnly: true');
    console.log(`[verify:football-real-games] dryRun: ${options.dryRun}`);
    console.log(`[verify:football-real-games] available competitionKeys: ${listCompetitionKeys().join(', ')}`);

    const allPassed = await verify(options);
    console.log('\n' + (allPassed ?
      '✅ Football real game checks PASSED.' :
      '❌ One or more football real game checks FAILED.'));
    exitCode = allPassed ? 0 : 1;
  } catch (err) {
    console.error('[verify:football-real-games] Error:', err);
    exitCode = 1;
  }

  process.exit(exitCode);
}

main();
