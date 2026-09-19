/**
 * seedCompetitionTeams.js
 *
 * Generic team master seed script for a competition.
 *
 * Dry-run mode does not initialize Firebase Admin SDK and does not write
 * Firestore.
 *
 * Usage:
 *   node functions/scripts/seedCompetitionTeams.js football_j1 --dry-run
 *   node functions/scripts/seedCompetitionTeams.js football_j1
 */

'use strict';

const { getCompetitionTeamData, listCompetitionKeys } = require('./data/competitionRegistry');
const { toTeamDoc, validateTeamsArray } = require('./teamMasterContract');

function parseArgs(argv) {
  const competitionKey = argv.find((arg) => !arg.startsWith('--'));
  return {
    competitionKey,
    dryRun: argv.includes('--dry-run'),
  };
}

function usage() {
  return `Usage: node functions/scripts/seedCompetitionTeams.js <competitionKey> [--dry-run]\nAvailable competitionKeys: ${listCompetitionKeys().join(', ')}`;
}

async function seed({ competitionKey, dryRun }) {
  if (!competitionKey) {
    throw new Error(usage());
  }

  const { competition, teams, teamsTodo } = getCompetitionTeamData(competitionKey);
  validateTeamsArray(teams);

  console.log(`[seed:teams] competitionKey: ${competitionKey}`);
  console.log(`[seed:teams] dryRun: ${dryRun}`);
  console.log(`[seed:teams] confirmed teams: ${teams.length}`);
  console.log(`[seed:teams] teamsTodo ignored: ${teamsTodo.length}`);

  const docs = teams.map((team) => {
    return {
      id: team.id,
      path: `teams/${team.id}`,
      data: toTeamDoc({ competition, team }),
    };
  });

  if (dryRun) {
    console.log('[seed:teams] Dry-run only. Firestore will not be written.');
    for (const doc of docs) {
      console.log(JSON.stringify(doc, null, 2));
    }
    return;
  }

  const admin = require('firebase-admin');
  const serviceAccount = require('../serviceAccountKey.json');
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });

  try {
    const db = admin.firestore();
    for (const doc of docs) {
      await db.collection('teams').doc(doc.id).set(doc.data, { merge: true });
      console.log(`[seed:teams] ${doc.path} upserted`);
    }
  } finally {
    await admin.app().delete();
  }
}

async function main() {
  let exitCode = 0;

  try {
    await seed(parseArgs(process.argv.slice(2)));
  } catch (err) {
    console.error('[seed:teams] Error:', err.message || err);
    exitCode = 1;
  }

  process.exit(exitCode);
}

main();
