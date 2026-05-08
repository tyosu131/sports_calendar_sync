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

const { generateSearchKeywords } = require('./searchKeywords');
const { getCompetitionTeamData, listCompetitionKeys } = require('./data/competitionRegistry');

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

function toTeamDoc({ competition, team }) {
  const searchKeywords = generateSearchKeywords({
    nameJa: team.nameJa,
    nameEn: team.nameEn,
    aliases: team.aliases,
  });

  return {
    nameJa: team.nameJa,
    nameEn: team.nameEn,
    searchKeywords,
    leagueId: competition.leagueId,
    country: competition.country,
    competitionKey: competition.competitionKey,
    sportKey: competition.competitionKey,
    sportType: competition.sportType,
    dataSourceKey: competition.dataSourceKey,
    externalTeamId: team.externalTeamId,
    rapidApiId: team.externalTeamId,
    logoUrl: team.logoUrl,
  };
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
