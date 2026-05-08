/**
 * fetchJ1TeamsFromApiSports.js
 *
 * Local inspection script for API-FOOTBALL J1 team candidates.
 *
 * This script only prints candidates to stdout. It does not write files,
 * initialize Firebase Admin SDK, read serviceAccountKey.json, or write to
 * Firestore.
 *
 * Usage:
 *   API_SPORTS_KEY=... J1_SEASON=2026 node functions/scripts/fetchJ1TeamsFromApiSports.js
 *   API_SPORTS_KEY=... J1_SEASON=2026 node functions/scripts/fetchJ1TeamsFromApiSports.js --json
 */

'use strict';

const axios = require('axios');

const API_HOST = 'v3.football.api-sports.io';
const API_BASE_URL = `https://${API_HOST}`;
const J1_LEAGUE_API_ID = 98;

function parseArgs(argv) {
  return {
    json: argv.includes('--json'),
  };
}

function currentSeason() {
  return new Date().getFullYear();
}

function parseSeason(value) {
  const raw = value || String(currentSeason());
  const season = Number(raw);
  if (!Number.isInteger(season) || season < 1900 || season > 3000) {
    throw new Error(`Invalid J1_SEASON: ${JSON.stringify(raw)}`);
  }
  return season;
}

function candidateIdFromName(name) {
  return name
    .normalize('NFKD')
    .replace(/[\u0300-\u036f]/g, '')
    .toLowerCase()
    .replace(/&/g, ' and ')
    .replace(/[^a-z0-9]+/g, '_')
    .replace(/^_+|_+$/g, '')
    .replace(/_+/g, '_');
}

function normalizeTeam(item) {
  const team = item.team || {};
  const rawName = team.name;
  return {
    id: candidateIdFromName(rawName || `team_${team.id}`),
    nameEn: rawName,
    externalTeamId: team.id,
    logoUrl: team.logo,
    country: item.team?.country || item.venue?.country || null,
    rawTeamName: rawName,
  };
}

async function fetchJ1Teams({ apiKey, season }) {
  const response = await axios.get(`${API_BASE_URL}/teams`, {
    timeout: 15000,
    headers: {
      'x-apisports-key': apiKey,
    },
    params: {
      league: J1_LEAGUE_API_ID,
      season,
    },
  });

  const items = response.data?.response;
  if (!Array.isArray(items)) {
    throw new Error('Unexpected API response: response is not an array');
  }

  return items.map(normalizeTeam);
}

function printText({ season, candidates }) {
  console.log(`API-FOOTBALL J1 team candidates`);
  console.log(`Endpoint: GET ${API_BASE_URL}/teams`);
  console.log(`Params: league=${J1_LEAGUE_API_ID}, season=${season}`);
  console.log(`Count: ${candidates.length}`);
  console.log('');

  for (const candidate of candidates) {
    console.log(`- ${candidate.id}`);
    console.log(`  nameEn: ${candidate.nameEn}`);
    console.log(`  externalTeamId: ${candidate.externalTeamId}`);
    console.log(`  logoUrl: ${candidate.logoUrl}`);
    console.log(`  country: ${candidate.country}`);
    console.log(`  rawTeamName: ${candidate.rawTeamName}`);
  }
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  const apiKey = process.env.API_SPORTS_KEY;

  if (!apiKey) {
    console.error('Missing API_SPORTS_KEY. Usage: API_SPORTS_KEY=... J1_SEASON=2026 node functions/scripts/fetchJ1TeamsFromApiSports.js');
    process.exit(1);
  }

  try {
    const season = parseSeason(process.env.J1_SEASON);
    const candidates = await fetchJ1Teams({ apiKey, season });

    if (args.json) {
      console.log(JSON.stringify({
        endpoint: `${API_BASE_URL}/teams`,
        params: {
          league: J1_LEAGUE_API_ID,
          season,
        },
        candidates,
      }, null, 2));
    } else {
      printText({ season, candidates });
    }
  } catch (err) {
    console.error('[fetch:j1:teams] Error:', err.message || err);
    process.exit(1);
  }
}

main();
