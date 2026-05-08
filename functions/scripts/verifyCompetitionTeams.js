/**
 * verifyCompetitionTeams.js
 *
 * Generic team master verification script for a competition.
 *
 * Dry-run mode validates only in-memory data shape and generated
 * searchKeywords. It does not initialize Firebase Admin SDK.
 *
 * Usage:
 *   node functions/scripts/verifyCompetitionTeams.js football_j1 --dry-run
 *   node functions/scripts/verifyCompetitionTeams.js football_j1
 */

'use strict';

const { generateSearchKeywords } = require('./searchKeywords');
const { getCompetitionTeamData, listCompetitionKeys } = require('./data/competitionRegistry');

const MAX_UNICODE_SUFFIX = '\uDBFF\uDFFF';

function parseArgs(argv) {
  const competitionKey = argv.find((arg) => !arg.startsWith('--'));
  return {
    competitionKey,
    dryRun: argv.includes('--dry-run'),
  };
}

function usage() {
  return `Usage: node functions/scripts/verifyCompetitionTeams.js <competitionKey> [--dry-run]\nAvailable competitionKeys: ${listCompetitionKeys().join(', ')}`;
}

function check(label, actual, expected) {
  const pass = actual === expected;
  const status = pass ? 'PASS' : 'FAIL';
  console.log(`  [${status}] ${label}: ${JSON.stringify(actual)} (expected: ${JSON.stringify(expected)})`);
  return pass;
}

function checkExists(label, exists) {
  const status = exists ? 'PASS' : 'FAIL';
  console.log(`  [${status}] ${label}: document ${exists ? 'exists' : 'MISSING'}`);
  return exists;
}

function checkArrayIncludesAll(label, actual, expected) {
  const missing = expected.filter((value) => !Array.isArray(actual) || !actual.includes(value));
  const pass = missing.length === 0;
  const status = pass ? 'PASS' : 'FAIL';
  console.log(`  [${status}] ${label}: ${pass ? 'all expected values found' : `missing ${JSON.stringify(missing)}`}`);
  return pass;
}

function checkQueryContainsAll(label, docs, expectedIds) {
  const actualIds = docs.map((doc) => doc.id);
  const missing = expectedIds.filter((id) => !actualIds.includes(id));
  const pass = missing.length === 0;
  const status = pass ? 'PASS' : 'FAIL';
  console.log(`  [${status}] ${label}: ${pass ? 'all expected docs found' : `missing ${JSON.stringify(missing)} (got ${JSON.stringify(actualIds)})`}`);
  return pass;
}

function validateTeam(team) {
  const requiredFields = [
    'id',
    'nameJa',
    'nameEn',
    'aliases',
    'externalTeamId',
    'logoUrl',
    'source',
  ];

  for (const field of requiredFields) {
    if (team[field] === undefined || team[field] === null || team[field] === '') {
      throw new Error(`Missing required field "${field}" for team: ${team.id || '(unknown)'}`);
    }
  }

  if (!Array.isArray(team.aliases)) {
    throw new Error(`aliases must be an array for team: ${team.id}`);
  }

  if (typeof team.externalTeamId !== 'number') {
    throw new Error(`externalTeamId must be a number for team: ${team.id}`);
  }

  if (team.status !== 'confirmed') {
    throw new Error(`teams must contain confirmed teams only. Move unconfirmed team "${team.id}" to teamsTodo.`);
  }
}

function validateTeamsArray(teams) {
  for (const team of teams) {
    validateTeam(team);
  }
}

function expectedKeywords(team) {
  return generateSearchKeywords({
    nameJa: team.nameJa,
    nameEn: team.nameEn,
    aliases: team.aliases,
  });
}

function representativeKeyword(team) {
  const keywords = expectedKeywords(team);
  if (keywords.includes(team.nameJa)) {
    return team.nameJa;
  }
  if (keywords.length === 0) {
    throw new Error(`searchKeywords would be empty for team: ${team.id}`);
  }
  return keywords[keywords.length - 1];
}

function verifyInMemory({ competitionKey, teams, teamsTodo }) {
  console.log(`[verify:teams] competitionKey: ${competitionKey}`);
  console.log('[verify:teams] dryRun: true');
  console.log(`[verify:teams] confirmed teams: ${teams.length}`);
  console.log(`[verify:teams] teamsTodo ignored: ${teamsTodo.length}`);

  for (const team of teams) {
    validateTeam(team);
    const keywords = expectedKeywords(team);
    if (keywords.length === 0) {
      throw new Error(`searchKeywords would be empty for team: ${team.id}`);
    }
    console.log(`  [PASS] ${team.id}: shape valid, generated searchKeywords=${keywords.length}`);
  }

  console.log('✅ In-memory team master checks PASSED.');
  return true;
}

async function verifyDocumentFields({ db, competition, teams }) {
  let allPassed = true;

  console.log('\n=== Section 1: Team document checks ===');

  for (const team of teams) {
    console.log(`\nVerifying teams/${team.id} ...`);
    const doc = await db.collection('teams').doc(team.id).get();
    allPassed = checkExists(`teams/${team.id} exists`, doc.exists) && allPassed;
    if (!doc.exists) continue;

    const data = doc.data();
    allPassed = check('nameJa', data.nameJa, team.nameJa) && allPassed;
    allPassed = check('nameEn', data.nameEn, team.nameEn) && allPassed;
    allPassed = check('leagueId', data.leagueId, competition.leagueId) && allPassed;
    allPassed = check('country', data.country, competition.country) && allPassed;
    allPassed = check('competitionKey', data.competitionKey, competition.competitionKey) && allPassed;
    allPassed = check('sportKey (legacy)', data.sportKey, competition.competitionKey) && allPassed;
    allPassed = check('sportType (legacy)', data.sportType, competition.sportType) && allPassed;
    allPassed = check('dataSourceKey', data.dataSourceKey, competition.dataSourceKey) && allPassed;
    allPassed = check('externalTeamId', data.externalTeamId, team.externalTeamId) && allPassed;
    allPassed = check('rapidApiId (legacy)', data.rapidApiId, team.externalTeamId) && allPassed;
    allPassed = check('logoUrl', data.logoUrl, team.logoUrl) && allPassed;
    allPassed = checkArrayIncludesAll('searchKeywords', data.searchKeywords, expectedKeywords(team)) && allPassed;
  }

  return allPassed;
}

async function verifyQueries({ db, competition, teams }) {
  let allPassed = true;
  const expectedIds = teams.map((team) => team.id);

  console.log('\n=== Section 2: Query checks ===');

  console.log(`\nQuery: teams where leagueId == "${competition.leagueId}" orderBy nameJa ...`);
  try {
    const snap = await db.collection('teams')
      .where('leagueId', '==', competition.leagueId)
      .orderBy('nameJa')
      .get();
    allPassed = checkQueryContainsAll('teams by leagueId orderBy nameJa', snap.docs, expectedIds) && allPassed;
  } catch (e) {
    console.log(`  [FAIL] Query error: ${e.message}`);
    allPassed = false;
  }

  console.log(`\nQuery: teams where competitionKey == "${competition.competitionKey}" ...`);
  try {
    const snap = await db.collection('teams')
      .where('competitionKey', '==', competition.competitionKey)
      .get();
    allPassed = checkQueryContainsAll('teams by competitionKey', snap.docs, expectedIds) && allPassed;
  } catch (e) {
    console.log(`  [FAIL] Query error: ${e.message}`);
    allPassed = false;
  }

  console.log(`\nQuery: teams where sportKey == "${competition.competitionKey}" ...`);
  try {
    const snap = await db.collection('teams')
      .where('sportKey', '==', competition.competitionKey)
      .get();
    allPassed = checkQueryContainsAll('teams by sportKey', snap.docs, expectedIds) && allPassed;
  } catch (e) {
    console.log(`  [FAIL] Query error: ${e.message}`);
    allPassed = false;
  }

  for (const team of teams) {
    const namePrefix = team.nameJa.slice(0, Math.min(2, team.nameJa.length));
    const keyword = representativeKeyword(team);

    console.log(`\nQuery: teams nameJa prefix "${namePrefix}" + competitionKey ...`);
    try {
      const snap = await db.collection('teams')
        .where('nameJa', '>=', namePrefix)
        .where('nameJa', '<', `${namePrefix}${MAX_UNICODE_SUFFIX}`)
        .where('competitionKey', '==', competition.competitionKey)
        .limit(20)
        .get();
      allPassed = checkQueryContainsAll(`nameJa prefix query for ${team.id}`, snap.docs, [team.id]) && allPassed;
    } catch (e) {
      console.log(`  [FAIL] Query error: ${e.message}`);
      allPassed = false;
    }

    console.log(`\nQuery: teams searchKeywords array-contains generated keyword "${keyword}" + competitionKey ...`);
    try {
      const snap = await db.collection('teams')
        .where('competitionKey', '==', competition.competitionKey)
        .where('searchKeywords', 'array-contains', keyword)
        .limit(20)
        .get();
      allPassed = checkQueryContainsAll(`keyword query for ${team.id}`, snap.docs, [team.id]) && allPassed;
    } catch (e) {
      console.log(`  [FAIL] Query error: ${e.message}`);
      allPassed = false;
    }
  }

  return allPassed;
}

async function verify({ competitionKey, dryRun }) {
  if (!competitionKey) {
    throw new Error(usage());
  }

  const { competition, teams, teamsTodo } = getCompetitionTeamData(competitionKey);
  validateTeamsArray(teams);

  if (dryRun) {
    return verifyInMemory({ competitionKey, teams, teamsTodo });
  }

  const admin = require('firebase-admin');
  const serviceAccount = require('../serviceAccountKey.json');
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });

  try {
    const db = admin.firestore();
    console.log(`[verify:teams] competitionKey: ${competitionKey}`);
    console.log('[verify:teams] dryRun: false');
    console.log(`[verify:teams] confirmed teams: ${teams.length}`);
    console.log(`[verify:teams] teamsTodo ignored: ${teamsTodo.length}`);
    const fieldsPassed = await verifyDocumentFields({ db, competition, teams });
    const queriesPassed = await verifyQueries({ db, competition, teams });
    const allPassed = fieldsPassed && queriesPassed;
    console.log('\n' + (allPassed ? '✅ All competition team checks PASSED.' : '❌ One or more competition team checks FAILED.'));
    return allPassed;
  } finally {
    await admin.app().delete();
  }
}

async function main() {
  let exitCode = 0;

  try {
    const allPassed = await verify(parseArgs(process.argv.slice(2)));
    exitCode = allPassed ? 0 : 1;
  } catch (err) {
    console.error('[verify:teams] Error:', err.message || err);
    exitCode = 1;
  }

  process.exit(exitCode);
}

main();
