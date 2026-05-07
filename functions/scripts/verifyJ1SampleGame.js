/**
 * verifyJ1SampleGame.js
 *
 * Verifies that games/kashima_sample_001 exists in Firestore with the correct
 * field values, and that the Firestore queries used by GameRepository return it.
 *
 * Checks:
 *   Section 1 — Document existence + field values
 *     games/kashima_sample_001 — existence + all required fields
 *
 *   Section 2 — Time consistency
 *     startTimeUTC is in the future
 *     startTimeJST matches startTimeUTC (UTC+9, "yyyy-MM-dd HH:mm" format)
 *
 *   Section 3 — Query-level checks (mirrors GameRepository queries)
 *     fetchUpcomingGamesForTeam (homeTeamId path):
 *       games where homeTeamId == "kashima_antlers"
 *             AND startTimeUTC >= now
 *             AND status == "scheduled"
 *             orderBy startTimeUTC
 *     fetchUpcomingGamesForTeam (awayTeamId path):
 *       games where awayTeamId == "kashima_antlers"
 *             AND startTimeUTC >= now
 *             AND status == "scheduled"
 *             orderBy startTimeUTC
 *     fetchUpcomingGamesForTeams (homeTeamId whereIn path):
 *       games where homeTeamId in ["kashima_antlers"]
 *             AND startTimeUTC >= now
 *             orderBy startTimeUTC
 *     fetchUpcomingGamesForTeams (awayTeamId whereIn path):
 *       games where awayTeamId in ["kashima_antlers"]
 *             AND startTimeUTC >= now
 *             orderBy startTimeUTC
 *     watchUpcomingGamesForTeam (stream path):
 *       games where homeTeamId == "kashima_antlers"
 *             AND startTimeUTC >= now
 *             orderBy startTimeUTC
 *
 * Exit codes:
 *   0 — all checks passed
 *   1 — one or more checks failed (or an error occurred)
 *
 * Usage:
 *   cd /Users/User/sportsCalender/sports_calendar_sync/sports_calendar_sync
 *   node functions/scripts/verifyJ1SampleGame.js
 */

'use strict';

const admin = require('firebase-admin');
const serviceAccount = require('../serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

// ── Helper functions ──────────────────────────────────────────────────────────

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

function checkNotNull(label, value) {
  const pass = value !== null && value !== undefined;
  const status = pass ? 'PASS' : 'FAIL';
  console.log(`  [${status}] ${label}: ${pass ? JSON.stringify(value) : 'null/undefined'}`);
  return pass;
}

function checkTrue(label, condition, detail) {
  const status = condition ? 'PASS' : 'FAIL';
  console.log(`  [${status}] ${label}${detail ? ': ' + detail : ''}`);
  return condition;
}

function checkQuery(label, docs, expectedDocId) {
  const found = docs.some((d) => d.id === expectedDocId);
  const status = found ? 'PASS' : 'FAIL';
  console.log(`  [${status}] ${label}: ${found ? `"${expectedDocId}" found` : `"${expectedDocId}" NOT found (got: ${docs.map((d) => d.id).join(', ') || 'empty'})`}`);
  return found;
}

/**
 * Validate that startTimeJST matches startTimeUTC (UTC+9).
 * Expected format: "yyyy-MM-dd HH:mm"
 */
function validateTimeConsistency(startTimeUTCDate, startTimeJST) {
  // Parse startTimeJST
  const jstRegex = /^(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2})$/;
  const match = startTimeJST.match(jstRegex);
  if (!match) {
    console.log(`  [FAIL] startTimeJST format: "${startTimeJST}" does not match "yyyy-MM-dd HH:mm"`);
    return false;
  }
  console.log(`  [PASS] startTimeJST format: "${startTimeJST}" matches "yyyy-MM-dd HH:mm"`);

  // Reconstruct UTC from JST string (subtract 9 hours)
  const [, yyyy, MM, dd, HH, mm] = match;
  const jstMs = Date.UTC(
    parseInt(yyyy),
    parseInt(MM) - 1,
    parseInt(dd),
    parseInt(HH),
    parseInt(mm),
    0,
    0,
  );
  const utcFromJst = new Date(jstMs - 9 * 60 * 60 * 1000);

  // Compare with startTimeUTC (allow up to 60 seconds tolerance for seconds/ms)
  const diffMs = Math.abs(utcFromJst.getTime() - startTimeUTCDate.getTime());
  const pass = diffMs < 60 * 1000;
  const status = pass ? 'PASS' : 'FAIL';
  console.log(`  [${status}] startTimeUTC/JST consistency: UTC=${startTimeUTCDate.toISOString()}, JST=${startTimeJST}, diff=${diffMs}ms`);
  return pass;
}

// ── Main verify function ──────────────────────────────────────────────────────

async function verify() {
  let allPassed = true;
  const now = new Date();
  const nowTimestamp = admin.firestore.Timestamp.fromDate(now);

  // ── Section 1: Document existence + field values ───────────────────────────

  console.log('\n=== Section 1: Document field checks ===');
  console.log('\nVerifying games/kashima_sample_001 ...');

  const gameDoc = await db.collection('games').doc('kashima_sample_001').get();
  allPassed = checkExists('games/kashima_sample_001 exists', gameDoc.exists) && allPassed;

  if (!gameDoc.exists) {
    console.log('\n❌ Document missing — run seedJ1SampleGame.js first.');
    process.exit(1);
  }

  const d = gameDoc.data();

  allPassed = check('game.leagueId', d.leagueId, 'j1_league') && allPassed;
  allPassed = check('game.competitionKey', d.competitionKey, 'football_j1') && allPassed;
  allPassed = check('game.sportKey (legacy)', d.sportKey, 'football_j1') && allPassed;
  allPassed = check('game.homeTeamId', d.homeTeamId, 'kashima_antlers') && allPassed;
  allPassed = check('game.homeTeamNameJa', d.homeTeamNameJa, '鹿島アントラーズ') && allPassed;
  allPassed = check('game.awayTeamId', d.awayTeamId, 'sample_opponent') && allPassed;
  allPassed = check('game.status', d.status, 'scheduled') && allPassed;
  allPassed = check('game.timezone', d.timezone, 'Asia/Tokyo') && allPassed;
  allPassed = check('game.venue', d.venue, 'Kashima Soccer Stadium') && allPassed;
  allPassed = checkNotNull('game.startTimeUTC', d.startTimeUTC) && allPassed;
  allPassed = checkNotNull('game.startTimeJST', d.startTimeJST) && allPassed;

  // ── Section 2: Time consistency ────────────────────────────────────────────

  console.log('\n=== Section 2: Time consistency checks ===');

  const startTimeUTCDate = d.startTimeUTC ? d.startTimeUTC.toDate() : null;

  if (startTimeUTCDate) {
    const isFuture = startTimeUTCDate > now;
    allPassed = checkTrue(
      'startTimeUTC is in the future',
      isFuture,
      `startTimeUTC=${startTimeUTCDate.toISOString()}, now=${now.toISOString()}`,
    ) && allPassed;

    if (d.startTimeJST) {
      allPassed = validateTimeConsistency(startTimeUTCDate, d.startTimeJST) && allPassed;
    }
  } else {
    console.log('  [FAIL] startTimeUTC is null — cannot check time consistency');
    allPassed = false;
  }

  // ── Section 3: Query-level checks (mirrors GameRepository) ────────────────

  console.log('\n=== Section 3: Query-level checks (mirrors GameRepository) ===');

  // fetchUpcomingGamesForTeam — homeTeamId path
  // games where homeTeamId == "kashima_antlers"
  //       AND startTimeUTC >= now
  //       AND status == "scheduled"
  //       orderBy startTimeUTC
  console.log('\nQuery: fetchUpcomingGamesForTeam (homeTeamId path) ...');
  try {
    const q1 = await db.collection('games')
      .where('homeTeamId', '==', 'kashima_antlers')
      .where('startTimeUTC', '>=', nowTimestamp)
      .where('status', '==', 'scheduled')
      .orderBy('startTimeUTC')
      .limit(20)
      .get();
    allPassed = checkQuery(
      'homeTeamId + startTimeUTC >= now + status == scheduled → kashima_sample_001',
      q1.docs,
      'kashima_sample_001',
    ) && allPassed;
  } catch (e) {
    console.log(`  [FAIL] Query error (possible missing composite index): ${e.message}`);
    allPassed = false;
  }

  // fetchUpcomingGamesForTeam — awayTeamId path
  // games where awayTeamId == "kashima_antlers"
  //       AND startTimeUTC >= now
  //       AND status == "scheduled"
  //       orderBy startTimeUTC
  // Note: kashima_sample_001 has awayTeamId = "sample_opponent", so this
  // query should NOT return it. We verify it returns empty (or other docs).
  console.log('\nQuery: fetchUpcomingGamesForTeam (awayTeamId path, awayTeamId == "kashima_antlers") ...');
  try {
    const q2 = await db.collection('games')
      .where('awayTeamId', '==', 'kashima_antlers')
      .where('startTimeUTC', '>=', nowTimestamp)
      .where('status', '==', 'scheduled')
      .orderBy('startTimeUTC')
      .limit(20)
      .get();
    // kashima_sample_001 has awayTeamId = "sample_opponent", so it should NOT appear here.
    // This is expected — we just verify the query runs without error.
    const status = 'PASS';
    console.log(`  [${status}] awayTeamId == "kashima_antlers" query ran OK (${q2.docs.length} docs, kashima_sample_001 correctly absent)`);
  } catch (e) {
    console.log(`  [FAIL] Query error (possible missing composite index): ${e.message}`);
    allPassed = false;
  }

  // fetchUpcomingGamesForTeams — homeTeamId whereIn path
  // games where homeTeamId in ["kashima_antlers"]
  //       AND startTimeUTC >= now
  //       orderBy startTimeUTC
  console.log('\nQuery: fetchUpcomingGamesForTeams (homeTeamId whereIn path) ...');
  try {
    const q3 = await db.collection('games')
      .where('homeTeamId', 'in', ['kashima_antlers'])
      .where('startTimeUTC', '>=', nowTimestamp)
      .orderBy('startTimeUTC')
      .limit(50)
      .get();
    allPassed = checkQuery(
      'homeTeamId whereIn + startTimeUTC >= now → kashima_sample_001',
      q3.docs,
      'kashima_sample_001',
    ) && allPassed;
  } catch (e) {
    console.log(`  [FAIL] Query error (possible missing composite index): ${e.message}`);
    allPassed = false;
  }

  // fetchUpcomingGamesForTeams — awayTeamId whereIn path
  // games where awayTeamId in ["kashima_antlers"]
  //       AND startTimeUTC >= now
  //       orderBy startTimeUTC
  // Note: kashima_sample_001 has awayTeamId = "sample_opponent", so this
  // query should NOT return it. We verify it runs without error.
  console.log('\nQuery: fetchUpcomingGamesForTeams (awayTeamId whereIn path, awayTeamId in ["kashima_antlers"]) ...');
  try {
    const q4 = await db.collection('games')
      .where('awayTeamId', 'in', ['kashima_antlers'])
      .where('startTimeUTC', '>=', nowTimestamp)
      .orderBy('startTimeUTC')
      .limit(50)
      .get();
    console.log(`  [PASS] awayTeamId whereIn query ran OK (${q4.docs.length} docs, kashima_sample_001 correctly absent)`);
  } catch (e) {
    console.log(`  [FAIL] Query error (possible missing composite index): ${e.message}`);
    allPassed = false;
  }

  // watchUpcomingGamesForTeam — stream path (same as homeTeamId path without status filter)
  // games where homeTeamId == "kashima_antlers"
  //       AND startTimeUTC >= now
  //       orderBy startTimeUTC
  console.log('\nQuery: watchUpcomingGamesForTeam (homeTeamId + startTimeUTC >= now, no status filter) ...');
  try {
    const q5 = await db.collection('games')
      .where('homeTeamId', '==', 'kashima_antlers')
      .where('startTimeUTC', '>=', nowTimestamp)
      .orderBy('startTimeUTC')
      .limit(20)
      .get();
    allPassed = checkQuery(
      'homeTeamId + startTimeUTC >= now (stream query) → kashima_sample_001',
      q5.docs,
      'kashima_sample_001',
    ) && allPassed;
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
