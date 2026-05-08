/**
 * seedJ1Teams.js
 *
 * Seeds confirmed J1 team master data from scripts/data/j1Teams.js.
 *
 * This script writes only confirmed teams in `j1Teams`. It intentionally does
 * not write `j1TeamsTodo`.
 *
 * Usage:
 *   cd /Users/User/sportsCalender/sports_calendar_sync/sports_calendar_sync
 *   node functions/scripts/seedJ1Teams.js
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

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

function assertConfirmedTeam(team) {
  const requiredFields = [
    'id',
    'nameJa',
    'nameEn',
    'aliases',
    'externalTeamId',
    'logoUrl',
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
}

function toTeamDoc(team) {
  const searchKeywords = generateSearchKeywords({
    nameJa: team.nameJa,
    nameEn: team.nameEn,
    aliases: team.aliases,
  });

  return {
    nameJa: team.nameJa,
    nameEn: team.nameEn,
    searchKeywords,
    leagueId: J1_LEAGUE_ID,
    country: J1_COUNTRY,
    competitionKey: J1_COMPETITION_KEY,
    sportKey: J1_COMPETITION_KEY,
    sportType: J1_SPORT_TYPE,
    dataSourceKey: J1_DATA_SOURCE_KEY,
    externalTeamId: team.externalTeamId,
    rapidApiId: team.externalTeamId,
    logoUrl: team.logoUrl,
  };
}

async function seed() {
  console.log(`[seed:j1:teams] Confirmed teams to write: ${j1Teams.length}`);

  for (const team of j1Teams) {
    assertConfirmedTeam(team);
    const teamDoc = toTeamDoc(team);
    await db.collection('teams').doc(team.id).set(teamDoc, { merge: true });
    console.log(`[seed:j1:teams] teams/${team.id} upserted`);
  }

  console.log('[seed:j1:teams] Done.');
}

async function main() {
  let exitCode = 0;

  try {
    await seed();
  } catch (err) {
    console.error('[seed:j1:teams] Error:', err);
    exitCode = 1;
  } finally {
    await admin.app().delete();
  }

  process.exit(exitCode);
}

main();
