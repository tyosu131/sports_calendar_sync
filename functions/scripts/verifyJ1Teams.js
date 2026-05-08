/**
 * verifyJ1Teams.js
 *
 * Verifies confirmed J1 team master data from scripts/data/j1Teams.js against
 * Firestore. This script does not write to Firestore.
 *
 * Usage:
 *   cd /Users/User/sportsCalender/sports_calendar_sync/sports_calendar_sync
 *   node functions/scripts/verifyJ1Teams.js
 */

'use strict';

const admin = require('firebase-admin');
const serviceAccount = require('../serviceAccountKey.json');
const { generateSearchKeywords } = require('./searchKeywords');
const {
  J1_COMPETITION_KEY,
  J1_LEAGUE_ID,
  J1_COUNTRY,
  J1_DATA_SOURCE_KEY,
  J1_SPORT_TYPE,
  j1Teams,
} = require('./data/j1Teams');

const MAX_UNICODE_SUFFIX = '\uDBFF\uDFFF';

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

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

async function verifyDocumentFields() {
  let allPassed = true;

  console.log('\n=== Section 1: Team document checks ===');

  for (const team of j1Teams) {
    console.log(`\nVerifying teams/${team.id} ...`);
    const doc = await db.collection('teams').doc(team.id).get();
    allPassed = checkExists(`teams/${team.id} exists`, doc.exists) && allPassed;
    if (!doc.exists) continue;

    const data = doc.data();
    allPassed = check('nameJa', data.nameJa, team.nameJa) && allPassed;
    allPassed = check('nameEn', data.nameEn, team.nameEn) && allPassed;
    allPassed = check('leagueId', data.leagueId, J1_LEAGUE_ID) && allPassed;
    allPassed = check('country', data.country, J1_COUNTRY) && allPassed;
    allPassed = check('competitionKey', data.competitionKey, J1_COMPETITION_KEY) && allPassed;
    allPassed = check('sportKey (legacy)', data.sportKey, J1_COMPETITION_KEY) && allPassed;
    allPassed = check('sportType (legacy)', data.sportType, J1_SPORT_TYPE) && allPassed;
    allPassed = check('dataSourceKey', data.dataSourceKey, J1_DATA_SOURCE_KEY) && allPassed;
    allPassed = check('externalTeamId', data.externalTeamId, team.externalTeamId) && allPassed;
    allPassed = check('rapidApiId (legacy)', data.rapidApiId, team.externalTeamId) && allPassed;
    allPassed = check('logoUrl', data.logoUrl, team.logoUrl) && allPassed;
    allPassed = checkArrayIncludesAll('searchKeywords', data.searchKeywords, expectedKeywords(team)) && allPassed;
  }

  return allPassed;
}

async function verifyQueries() {
  let allPassed = true;
  const expectedIds = j1Teams.map((team) => team.id);

  console.log('\n=== Section 2: Query checks ===');

  console.log('\nQuery: teams where leagueId == "j1_league" orderBy nameJa ...');
  try {
    const snap = await db.collection('teams')
      .where('leagueId', '==', J1_LEAGUE_ID)
      .orderBy('nameJa')
      .get();
    allPassed = checkQueryContainsAll('teams by leagueId orderBy nameJa', snap.docs, expectedIds) && allPassed;
  } catch (e) {
    console.log(`  [FAIL] Query error: ${e.message}`);
    allPassed = false;
  }

  console.log('\nQuery: teams where competitionKey == "football_j1" ...');
  try {
    const snap = await db.collection('teams')
      .where('competitionKey', '==', J1_COMPETITION_KEY)
      .get();
    allPassed = checkQueryContainsAll('teams by competitionKey', snap.docs, expectedIds) && allPassed;
  } catch (e) {
    console.log(`  [FAIL] Query error: ${e.message}`);
    allPassed = false;
  }

  console.log('\nQuery: teams where sportKey == "football_j1" ...');
  try {
    const snap = await db.collection('teams')
      .where('sportKey', '==', J1_COMPETITION_KEY)
      .get();
    allPassed = checkQueryContainsAll('teams by sportKey', snap.docs, expectedIds) && allPassed;
  } catch (e) {
    console.log(`  [FAIL] Query error: ${e.message}`);
    allPassed = false;
  }

  for (const team of j1Teams) {
    const namePrefix = team.nameJa.slice(0, Math.min(2, team.nameJa.length));
    const keyword = representativeKeyword(team);

    console.log(`\nQuery: teams nameJa prefix "${namePrefix}" + competitionKey ...`);
    try {
      const snap = await db.collection('teams')
        .where('nameJa', '>=', namePrefix)
        .where('nameJa', '<', `${namePrefix}${MAX_UNICODE_SUFFIX}`)
        .where('competitionKey', '==', J1_COMPETITION_KEY)
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
        .where('competitionKey', '==', J1_COMPETITION_KEY)
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

async function verify() {
  console.log(`[verify:j1:teams] Confirmed teams to verify: ${j1Teams.length}`);
  const fieldsPassed = await verifyDocumentFields();
  const queriesPassed = await verifyQueries();
  const allPassed = fieldsPassed && queriesPassed;

  console.log('\n' + (allPassed ? '✅ All J1 team checks PASSED.' : '❌ One or more J1 team checks FAILED.'));
  return allPassed;
}

async function main() {
  let exitCode = 0;

  try {
    const allPassed = await verify();
    exitCode = allPassed ? 0 : 1;
  } catch (err) {
    console.error('[verify:j1:teams] Error:', err);
    exitCode = 1;
  } finally {
    await admin.app().delete();
  }

  process.exit(exitCode);
}

main();
