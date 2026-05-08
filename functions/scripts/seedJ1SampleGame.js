/**
 * seedJ1SampleGame.js
 *
 * Seeds minimal J1 sample game documents into Firestore for E2E UI
 * verification. Dry-run mode prints planned writes without initializing
 * Firebase Admin SDK or writing Firestore.
 *
 * Usage:
 *   node functions/scripts/seedJ1SampleGame.js --dry-run
 *   node functions/scripts/seedJ1SampleGame.js
 */

'use strict';

const { j1Teams } = require('./data/j1Teams');

const J1_LEAGUE_ID = 'j1_league';
const J1_COMPETITION_KEY = 'football_j1';
const TIMEZONE = 'Asia/Tokyo';

const sampleGameDefinitions = [
  {
    id: 'kashima_sample_001',
    homeTeamId: 'kashima_antlers',
    awayTeamId: 'urawa_reds',
    venue: 'Kashima Soccer Stadium',
    externalFixtureId: 999999001,
    daysFromNow: 7,
  },
  {
    id: 'j1_sample_osaka_derby_001',
    homeTeamId: 'gamba_osaka',
    awayTeamId: 'cerezo_osaka',
    venue: 'Panasonic Stadium Suita',
    externalFixtureId: 999999002,
    daysFromNow: 8,
  },
  {
    id: 'j1_sample_yokohama_tokyo_001',
    homeTeamId: 'yokohama_f_marinos',
    awayTeamId: 'tokyo_verdy',
    venue: 'Nissan Stadium',
    externalFixtureId: 999999003,
    daysFromNow: 9,
  },
  {
    id: 'j1_sample_fukuoka_hiroshima_001',
    homeTeamId: 'avispa_fukuoka',
    awayTeamId: 'sanfrecce_hiroshima',
    venue: 'Best Denki Stadium',
    externalFixtureId: 999999004,
    daysFromNow: 10,
  },
];

function parseArgs(argv) {
  return {
    dryRun: argv.includes('--dry-run'),
  };
}

function teamById(teamId) {
  const team = j1Teams.find((candidate) => candidate.id === teamId);
  if (!team) {
    throw new Error(`Unknown J1 team id in sample game definition: ${teamId}`);
  }
  return team;
}

/**
 * Compute startTimeUTC and startTimeJST for today + daysFromNow at 19:00 JST.
 *
 * JST = UTC+9, so 19:00 JST = 10:00 UTC.
 */
function computeGameTime(daysFromNow) {
  const now = new Date();
  const target = new Date(Date.UTC(
    now.getUTCFullYear(),
    now.getUTCMonth(),
    now.getUTCDate() + daysFromNow,
    10,
    0,
    0,
    0,
  ));

  const jstDate = new Date(target.getTime() + 9 * 60 * 60 * 1000);
  const yyyy = jstDate.getUTCFullYear();
  const MM = String(jstDate.getUTCMonth() + 1).padStart(2, '0');
  const dd = String(jstDate.getUTCDate()).padStart(2, '0');
  const HH = String(jstDate.getUTCHours()).padStart(2, '0');
  const mm = String(jstDate.getUTCMinutes()).padStart(2, '0');

  return {
    startTimeUTC: target,
    startTimeJST: `${yyyy}-${MM}-${dd} ${HH}:${mm}`,
  };
}

function buildSampleGameDocs({ timestampFromDate } = {}) {
  return sampleGameDefinitions.map((definition) => {
    const home = teamById(definition.homeTeamId);
    const away = teamById(definition.awayTeamId);
    const { startTimeUTC, startTimeJST } = computeGameTime(definition.daysFromNow);

    return {
      id: definition.id,
      path: `games/${definition.id}`,
      data: {
        leagueId: J1_LEAGUE_ID,
        competitionKey: J1_COMPETITION_KEY,
        sportKey: J1_COMPETITION_KEY,
        homeTeamId: home.id,
        homeTeamNameJa: home.nameJa,
        homeTeamNameEn: home.nameEn,
        homeTeamLogoUrl: home.logoUrl,
        awayTeamId: away.id,
        awayTeamNameJa: away.nameJa,
        awayTeamNameEn: away.nameEn,
        awayTeamLogoUrl: away.logoUrl,
        startTimeUTC: timestampFromDate
          ? timestampFromDate(startTimeUTC)
          : startTimeUTC.toISOString(),
        startTimeJST,
        timezone: TIMEZONE,
        status: 'scheduled',
        venue: definition.venue,
        homeScore: null,
        awayScore: null,
        broadcastPlatforms: [],
        externalFixtureId: definition.externalFixtureId,
        rapidApiFixtureId: definition.externalFixtureId,
      },
    };
  });
}

function printPlannedWrites(docs) {
  console.log(`[seed:j1:sample-games] planned games: ${docs.length}`);
  for (const doc of docs) {
    console.log(JSON.stringify(doc, null, 2));
  }
}

async function seed({ dryRun }) {
  if (dryRun) {
    const docs = buildSampleGameDocs();
    console.log('[seed:j1:sample-games] dryRun: true');
    console.log('[seed:j1:sample-games] Firestore will not be written.');
    printPlannedWrites(docs);
    return true;
  }

  const admin = require('firebase-admin');
  const serviceAccount = require('../serviceAccountKey.json');

  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });

  try {
    const db = admin.firestore();
    const docs = buildSampleGameDocs({
      timestampFromDate: (date) => admin.firestore.Timestamp.fromDate(date),
    });
    console.log('[seed:j1:sample-games] dryRun: false');
    printPlannedWrites(docs);
    for (const doc of docs) {
      await db.collection('games').doc(doc.id).set(doc.data);
      console.log(`[seed:j1:sample-games] ${doc.path} written`);
    }
    return true;
  } finally {
    await admin.app().delete();
  }
}

async function main() {
  let exitCode = 0;
  try {
    const ok = await seed(parseArgs(process.argv.slice(2)));
    exitCode = ok ? 0 : 1;
  } catch (err) {
    console.error('[seed:j1:sample-games] Error:', err);
    exitCode = 1;
  }
  process.exit(exitCode);
}

if (require.main === module) {
  main();
}

module.exports = {
  buildSampleGameDocs,
  sampleGameDefinitions,
};
