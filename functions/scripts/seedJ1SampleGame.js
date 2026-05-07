/**
 * seedJ1SampleGame.js
 *
 * Seeds a sample game document into Firestore for E2E UI verification.
 *
 * Document written:
 *   games/kashima_sample_001 — set() (full overwrite)
 *
 * Date policy:
 *   startTimeUTC / startTimeJST are computed dynamically at seed time.
 *   The game is always set to (today + 7 days) at 19:00 JST (10:00 UTC),
 *   so it is always in the future relative to GameRepository's
 *   `startTimeUTC >= now` filter.
 *
 * Usage:
 *   cd /Users/User/sportsCalender/sports_calendar_sync/sports_calendar_sync
 *   node functions/scripts/seedJ1SampleGame.js
 *
 * Prerequisites:
 *   - functions/serviceAccountKey.json must exist (never commit this file)
 *   - firebase-admin must be installed (npm install in functions/)
 */

'use strict';

const admin = require('firebase-admin');
const serviceAccount = require('../serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

/**
 * Compute startTimeUTC and startTimeJST for "today + 7 days at 19:00 JST".
 *
 * JST = UTC+9, so 19:00 JST = 10:00 UTC.
 */
function computeGameTime() {
  const now = new Date();

  // Build the target date: today + 7 days, at 10:00 UTC (= 19:00 JST)
  const target = new Date(Date.UTC(
    now.getUTCFullYear(),
    now.getUTCMonth(),
    now.getUTCDate() + 7,
    10, // 10:00 UTC = 19:00 JST
    0,
    0,
    0,
  ));

  // startTimeJST: "yyyy-MM-dd HH:mm" in JST
  const jstDate = new Date(target.getTime() + 9 * 60 * 60 * 1000); // shift to JST
  const yyyy = jstDate.getUTCFullYear();
  const MM = String(jstDate.getUTCMonth() + 1).padStart(2, '0');
  const dd = String(jstDate.getUTCDate()).padStart(2, '0');
  const HH = String(jstDate.getUTCHours()).padStart(2, '0');
  const mm = String(jstDate.getUTCMinutes()).padStart(2, '0');
  const startTimeJST = `${yyyy}-${MM}-${dd} ${HH}:${mm}`;

  return { startTimeUTC: target, startTimeJST };
}

async function seed() {
  const { startTimeUTC, startTimeJST } = computeGameTime();

  console.log(`[seed] Computed game time:`);
  console.log(`  startTimeUTC: ${startTimeUTC.toISOString()}`);
  console.log(`  startTimeJST: ${startTimeJST}`);

  await db.collection('games').doc('kashima_sample_001').set({
    // Competition / league
    leagueId: 'j1_league',
    competitionKey: 'football_j1',
    sportKey: 'football_j1', // legacy alias

    // Home team — Kashima Antlers
    homeTeamId: 'kashima_antlers',
    homeTeamNameJa: '鹿島アントラーズ',
    homeTeamNameEn: 'Kashima',
    homeTeamLogoUrl: 'https://media.api-sports.io/football/teams/290.png',

    // Away team — sample opponent (no real Firestore doc required)
    awayTeamId: 'sample_opponent',
    awayTeamNameJa: 'サンプル対戦相手',
    awayTeamNameEn: 'Sample Opponent',
    awayTeamLogoUrl: null,

    // Time — always future relative to now
    startTimeUTC: admin.firestore.Timestamp.fromDate(startTimeUTC),
    startTimeJST,
    timezone: 'Asia/Tokyo',

    // Status — must be "scheduled" for GameRepository filter
    status: 'scheduled',

    // Venue
    venue: 'Kashima Soccer Stadium',

    // Score — null for upcoming game
    homeScore: null,
    awayScore: null,

    // Broadcast — empty for sample
    broadcastPlatforms: [],

    // External IDs — fake values for sample
    externalFixtureId: 999999001,
    rapidApiFixtureId: 999999001, // legacy alias
  });

  console.log('[seed] games/kashima_sample_001 written');
  console.log('[seed] Done.');
  process.exit(0);
}

seed().catch((err) => {
  console.error('[seed] Error:', err);
  process.exit(1);
});
