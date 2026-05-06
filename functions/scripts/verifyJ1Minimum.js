/**
 * verifyJ1Minimum.js
 *
 * Verifies that the J1 League minimum seed data exists in Firestore with the
 * correct field values required by Phase 1, and that the Firestore queries
 * used by the Flutter app return the expected documents.
 *
 * Checks:
 *   Section 1 — Document existence + field values
 *     leagues/j1_league        — existence + competitionKey + sportKey (legacy)
 *     teams/kashima_antlers    — existence + competitionKey + externalTeamId + rapidApiId + sportKey
 *                                + searchKeywords (array, spot-checks)
 *     translationMaps/football — existence
 *
 *   Section 2 — Query-level checks (mirrors Flutter TeamRepository queries)
 *     leagues where competitionKey == "football_j1"
 *     leagues where sportKey == "football_j1" (legacy fallback)
 *     teams where leagueId == "j1_league" orderBy nameJa  ← fetchTeamsByLeague()
 *     teams where competitionKey == "football_j1"
 *     teams where nameJa >= "鹿島" AND nameJa < "鹿島\uf8ff" AND competitionKey == "football_j1"  ← searchTeams() prefix
 *     teams where nameJa >= "鹿島" AND nameJa < "鹿島\uf8ff" AND sportKey == "football_j1"        ← searchTeams() legacy prefix
 *     teams where searchKeywords array-contains "鹿"                                              ← searchTeams() keyword
 *     teams where searchKeywords array-contains "アント"                                          ← searchTeams() keyword mid-string
 *     teams where searchKeywords array-contains "kashima" AND competitionKey == "football_j1"     ← searchTeams() keyword + filter
 *     teams where searchKeywords array-contains "antlers" AND sportKey == "football_j1"           ← searchTeams() keyword + legacy
 *
 * Exit codes:
 *   0 — all checks passed
 *   1 — one or more checks failed (or an error occurred)
 *
 * Usage:
 *   cd /Users/User/sportsCalender/sports_calendar_sync/functions
 *   node scripts/verifyJ1Minimum.js
 */

'use strict';

const admin = require('firebase-admin');
const serviceAccount = require('../serviceAccountKey.json');

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

function checkArrayContains(label, arr, value) {
  const pass = Array.isArray(arr) && arr.includes(value);
  const status = pass ? 'PASS' : 'FAIL';
  console.log(`  [${status}] ${label}: ${pass ? `"${value}" found in array` : `"${value}" NOT found (array: ${JSON.stringify(arr ? arr.slice(0, 5) : null)}...)`}`);
  return pass;
}

function checkQuery(label, docs, expectedDocId) {
  const found = docs.some((d) => d.id === expectedDocId);
  const status = found ? 'PASS' : 'FAIL';
  console.log(`  [${status}] ${label}: ${found ? `"${expectedDocId}" found` : `"${expectedDocId}" NOT found (got ${docs.map((d) => d.id).join(', ') || 'empty'})`}`);
  return found;
}

async function verify() {
  let allPassed = true;

  // ── Section 1: Document existence + field values ───────────────────────────

  console.log('\n=== Section 1: Document field checks ===');

  console.log('\nVerifying leagues/j1_league ...');
  const leagueDoc = await db.collection('leagues').doc('j1_league').get();
  allPassed = checkExists('leagues/j1_league exists', leagueDoc.exists) && allPassed;

  if (leagueDoc.exists) {
    const d = leagueDoc.data();
    allPassed = check('league.competitionKey', d.competitionKey, 'football_j1') && allPassed;
    allPassed = check('league.sportKey (legacy)', d.sportKey, 'football_j1') && allPassed;
    allPassed = check('league.externalLeagueId', d.externalLeagueId, 98) && allPassed;
    allPassed = check('league.rapidApiId (legacy)', d.rapidApiId, 98) && allPassed;
  }

  console.log('\nVerifying teams/kashima_antlers ...');
  const teamDoc = await db.collection('teams').doc('kashima_antlers').get();
  allPassed = checkExists('teams/kashima_antlers exists', teamDoc.exists) && allPassed;

  if (teamDoc.exists) {
    const d = teamDoc.data();
    allPassed = check('team.competitionKey', d.competitionKey, 'football_j1') && allPassed;
    allPassed = check('team.sportKey (legacy)', d.sportKey, 'football_j1') && allPassed;
    allPassed = check('team.externalTeamId', d.externalTeamId, 290) && allPassed;
    allPassed = check('team.rapidApiId (legacy)', d.rapidApiId, 290) && allPassed;
    allPassed = check('team.leagueId', d.leagueId, 'j1_league') && allPassed;
    allPassed = check('team.nameJa', d.nameJa, '鹿島アントラーズ') && allPassed;

    // searchKeywords spot-checks
    console.log('\n  searchKeywords spot-checks:');
    allPassed = checkArrayContains('team.searchKeywords contains "鹿"', d.searchKeywords, '鹿') && allPassed;
    allPassed = checkArrayContains('team.searchKeywords contains "鹿島"', d.searchKeywords, '鹿島') && allPassed;
    allPassed = checkArrayContains('team.searchKeywords contains "鹿島アントラーズ"', d.searchKeywords, '鹿島アントラーズ') && allPassed;
    allPassed = checkArrayContains('team.searchKeywords contains "アント"', d.searchKeywords, 'アント') && allPassed;
    allPassed = checkArrayContains('team.searchKeywords contains "k"', d.searchKeywords, 'k') && allPassed;
    allPassed = checkArrayContains('team.searchKeywords contains "ka"', d.searchKeywords, 'ka') && allPassed;
    allPassed = checkArrayContains('team.searchKeywords contains "kashima"', d.searchKeywords, 'kashima') && allPassed;
    allPassed = checkArrayContains('team.searchKeywords contains "antlers"', d.searchKeywords, 'antlers') && allPassed;
  }

  console.log('\nVerifying translationMaps/football ...');
  const translationDoc = await db.collection('translationMaps').doc('football').get();
  allPassed = checkExists('translationMaps/football exists', translationDoc.exists) && allPassed;

  // ── Section 2: Query-level checks (mirrors Flutter TeamRepository) ─────────

  console.log('\n=== Section 2: Query-level checks ===');

  // fetchLeagues(competitionKey: "football_j1") — primary query
  console.log('\nQuery: leagues where competitionKey == "football_j1" ...');
  try {
    const q1 = await db.collection('leagues').where('competitionKey', '==', 'football_j1').get();
    allPassed = checkQuery('leagues by competitionKey → j1_league', q1.docs, 'j1_league') && allPassed;
  } catch (e) {
    console.log(`  [FAIL] Query error: ${e.message}`);
    allPassed = false;
  }

  // fetchLeagues(competitionKey: "football_j1") — legacy sportKey fallback
  console.log('\nQuery: leagues where sportKey == "football_j1" (legacy fallback) ...');
  try {
    const q2 = await db.collection('leagues').where('sportKey', '==', 'football_j1').get();
    allPassed = checkQuery('leagues by sportKey → j1_league', q2.docs, 'j1_league') && allPassed;
  } catch (e) {
    console.log(`  [FAIL] Query error: ${e.message}`);
    allPassed = false;
  }

  // fetchTeamsByLeague("j1_league") — mirrors TeamRepository.fetchTeamsByLeague()
  console.log('\nQuery: teams where leagueId == "j1_league" orderBy nameJa ...');
  try {
    const q3 = await db.collection('teams')
      .where('leagueId', '==', 'j1_league')
      .orderBy('nameJa')
      .get();
    allPassed = checkQuery('teams by leagueId orderBy nameJa → kashima_antlers', q3.docs, 'kashima_antlers') && allPassed;
  } catch (e) {
    console.log(`  [FAIL] Query error (possible missing composite index): ${e.message}`);
    allPassed = false;
  }

  // fetchLeagues / searchTeams — teams by competitionKey
  console.log('\nQuery: teams where competitionKey == "football_j1" ...');
  try {
    const q4 = await db.collection('teams').where('competitionKey', '==', 'football_j1').get();
    allPassed = checkQuery('teams by competitionKey → kashima_antlers', q4.docs, 'kashima_antlers') && allPassed;
  } catch (e) {
    console.log(`  [FAIL] Query error: ${e.message}`);
    allPassed = false;
  }

  // searchTeams("鹿島", competitionKey: "football_j1") — primary prefix query
  // Upper bound uses U+F8FF (same as TeamRepository.searchTeams() after fix).
  console.log('\nQuery: teams where nameJa >= "鹿島" AND nameJa < "鹿島\\uf8ff" AND competitionKey == "football_j1" ...');
  try {
    const q5 = await db.collection('teams')
      .where('nameJa', '>=', '鹿島')
      .where('nameJa', '<', '鹿島\uf8ff')
      .where('competitionKey', '==', 'football_j1')
      .limit(20)
      .get();
    allPassed = checkQuery('searchTeams by nameJa + competitionKey → kashima_antlers', q5.docs, 'kashima_antlers') && allPassed;
  } catch (e) {
    console.log(`  [FAIL] Query error (possible missing composite index): ${e.message}`);
    allPassed = false;
  }

  // searchTeams("鹿島", competitionKey: "football_j1") — legacy sportKey prefix fallback
  // Upper bound uses U+F8FF (same as TeamRepository.searchTeams() after fix).
  console.log('\nQuery: teams where nameJa >= "鹿島" AND nameJa < "鹿島\\uf8ff" AND sportKey == "football_j1" (legacy) ...');
  try {
    const q6 = await db.collection('teams')
      .where('nameJa', '>=', '鹿島')
      .where('nameJa', '<', '鹿島\uf8ff')
      .where('sportKey', '==', 'football_j1')
      .limit(20)
      .get();
    allPassed = checkQuery('searchTeams by nameJa + sportKey → kashima_antlers', q6.docs, 'kashima_antlers') && allPassed;
  } catch (e) {
    console.log(`  [FAIL] Query error (possible missing composite index): ${e.message}`);
    allPassed = false;
  }

  // searchTeams keyword: array-contains "鹿" (no competitionKey filter — "すべて" tab)
  console.log('\nQuery: teams where searchKeywords array-contains "鹿" ...');
  try {
    const q7 = await db.collection('teams')
      .where('searchKeywords', 'array-contains', '鹿')
      .limit(20)
      .get();
    allPassed = checkQuery('searchTeams by searchKeywords "鹿" → kashima_antlers', q7.docs, 'kashima_antlers') && allPassed;
  } catch (e) {
    console.log(`  [FAIL] Query error: ${e.message}`);
    allPassed = false;
  }

  // searchTeams keyword: array-contains "アント" (mid-string alias match)
  console.log('\nQuery: teams where searchKeywords array-contains "アント" ...');
  try {
    const q8 = await db.collection('teams')
      .where('searchKeywords', 'array-contains', 'アント')
      .limit(20)
      .get();
    allPassed = checkQuery('searchTeams by searchKeywords "アント" → kashima_antlers', q8.docs, 'kashima_antlers') && allPassed;
  } catch (e) {
    console.log(`  [FAIL] Query error: ${e.message}`);
    allPassed = false;
  }

  // searchTeams keyword: array-contains "kashima" + competitionKey filter
  console.log('\nQuery: teams where searchKeywords array-contains "kashima" AND competitionKey == "football_j1" ...');
  try {
    const q9 = await db.collection('teams')
      .where('competitionKey', '==', 'football_j1')
      .where('searchKeywords', 'array-contains', 'kashima')
      .limit(20)
      .get();
    allPassed = checkQuery('searchTeams by searchKeywords "kashima" + competitionKey → kashima_antlers', q9.docs, 'kashima_antlers') && allPassed;
  } catch (e) {
    console.log(`  [FAIL] Query error (possible missing composite index): ${e.message}`);
    allPassed = false;
  }

  // searchTeams keyword: array-contains "antlers" + sportKey legacy filter
  console.log('\nQuery: teams where searchKeywords array-contains "antlers" AND sportKey == "football_j1" ...');
  try {
    const q10 = await db.collection('teams')
      .where('sportKey', '==', 'football_j1')
      .where('searchKeywords', 'array-contains', 'antlers')
      .limit(20)
      .get();
    allPassed = checkQuery('searchTeams by searchKeywords "antlers" + sportKey → kashima_antlers', q10.docs, 'kashima_antlers') && allPassed;
  } catch (e) {
    console.log(`  [FAIL] Query error (possible missing composite index): ${e.message}`);
    allPassed = false;
  }

  // ── Summary ────────────────────────────────────────────────────────────────
  console.log('\n' + (allPassed ? '✅ All checks PASSED.' : '❌ One or more checks FAILED.'));
  process.exit(allPassed ? 0 : 1);
}

verify().catch((err) => {
  console.error('[verify] Error:', err);
  process.exit(1);
});
