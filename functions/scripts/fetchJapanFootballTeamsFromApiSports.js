/**
 * fetchJapanFootballTeamsFromApiSports.js
 *
 * Local read-only inspection script for API-FOOTBALL Japan league / team
 * candidates.
 *
 * This script only prints candidates to stdout. It does not write files,
 * initialize Firebase Admin SDK, read serviceAccountKey.json, or write to
 * Firestore.
 *
 * Usage:
 *   API_SPORTS_KEY=... node functions/scripts/fetchJapanFootballTeamsFromApiSports.js --leagues --season 2024
 *   API_SPORTS_KEY=... node functions/scripts/fetchJapanFootballTeamsFromApiSports.js --league 99 --season 2024
 *   API_SPORTS_KEY=... node functions/scripts/fetchJapanFootballTeamsFromApiSports.js --search "Vegalta"
 *   API_SPORTS_KEY=... node functions/scripts/fetchJapanFootballTeamsFromApiSports.js --search "Vegalta" --json
 */

'use strict';

const axios = require('axios');

const API_HOST = 'v3.football.api-sports.io';
const API_BASE_URL = `https://${API_HOST}`;
const DEFAULT_COUNTRY = 'Japan';

function parseArgs(argv) {
  const options = {
    leagues: false,
    league: null,
    season: null,
    search: null,
    json: false,
  };

  for (let index = 0; index < argv.length; index += 1) {
    const arg = argv[index];

    if (arg === '--leagues') {
      options.leagues = true;
      continue;
    }

    if (arg === '--json') {
      options.json = true;
      continue;
    }

    if (arg === '--league') {
      options.league = parseRequiredNumber(argv, index, '--league');
      index += 1;
      continue;
    }

    if (arg === '--season') {
      options.season = parseRequiredNumber(argv, index, '--season');
      index += 1;
      continue;
    }

    if (arg === '--search') {
      options.search = parseRequiredString(argv, index, '--search');
      index += 1;
      continue;
    }

    throw new Error(`Unknown argument: ${arg}`);
  }

  return options;
}

function parseRequiredNumber(argv, index, name) {
  const raw = argv[index + 1];
  if (!raw || raw.startsWith('--')) {
    throw new Error(`Missing value for ${name}`);
  }

  const value = Number(raw);
  if (!Number.isInteger(value)) {
    throw new Error(`Invalid ${name}: ${JSON.stringify(raw)}`);
  }
  return value;
}

function parseRequiredString(argv, index, name) {
  const value = argv[index + 1];
  if (!value || value.startsWith('--')) {
    throw new Error(`Missing value for ${name}`);
  }
  return value;
}

function validateOptions(options) {
  const modes = [
    options.leagues,
    typeof options.league === 'number',
    typeof options.search === 'string',
  ].filter(Boolean);

  if (modes.length !== 1) {
    throw new Error('Choose exactly one lookup mode: --leagues, --league <id>, or --search <name>');
  }

  if (options.leagues && typeof options.season !== 'number') {
    throw new Error('--leagues requires --season <year>');
  }

  if (typeof options.league === 'number' && typeof options.season !== 'number') {
    throw new Error('--league <id> requires --season <year>');
  }

  if (typeof options.season === 'number' && (options.season < 1900 || options.season > 3000)) {
    throw new Error(`Invalid --season: ${options.season}`);
  }
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

function normalizeLeague(item) {
  const league = item.league || {};
  const country = item.country || {};
  const seasons = Array.isArray(item.seasons) ? item.seasons : [];

  return {
    id: league.id,
    name: league.name,
    type: league.type,
    logoUrl: league.logo,
    country: country.name,
    countryCode: country.code,
    seasons: seasons.map((season) => ({
      year: season.year,
      start: season.start,
      end: season.end,
      current: season.current,
    })),
    raw: {
      league: {
        id: league.id,
        name: league.name,
        type: league.type,
        logo: league.logo,
      },
      country: {
        name: country.name,
        code: country.code,
      },
    },
  };
}

function normalizeTeam(item) {
  const team = item.team || {};
  const venue = item.venue || {};
  const rawName = team.name;

  return {
    apiNameSlug: candidateIdFromName(rawName || `team_${team.id}`),
    nameEn: rawName,
    externalTeamId: team.id,
    logoUrl: team.logo,
    country: team.country || venue.country || null,
    rawTeamName: rawName,
    raw: {
      team: {
        id: team.id,
        name: team.name,
        country: team.country,
        logo: team.logo,
      },
      venue: {
        id: venue.id,
        name: venue.name,
        city: venue.city,
        country: venue.country,
      },
    },
  };
}

async function fetchApi({ apiKey, endpointPath, params }) {
  const response = await axios.get(`${API_BASE_URL}${endpointPath}`, {
    timeout: 15000,
    headers: {
      'x-apisports-key': apiKey,
    },
    params,
  });

  const items = response.data?.response;
  if (!Array.isArray(items)) {
    throw new Error('Unexpected API response: response is not an array');
  }

  return items;
}

function buildRequest(options) {
  if (options.leagues) {
    return {
      endpointPath: '/leagues',
      params: {
        country: DEFAULT_COUNTRY,
        season: options.season,
      },
      normalize: normalizeLeague,
      title: 'API-FOOTBALL Japan league candidates',
    };
  }

  if (typeof options.league === 'number') {
    return {
      endpointPath: '/teams',
      params: {
        league: options.league,
        season: options.season,
      },
      normalize: normalizeTeam,
      title: 'API-FOOTBALL Japan league team candidates',
    };
  }

  return {
    endpointPath: '/teams',
    params: {
      search: options.search,
    },
    normalize: normalizeTeam,
    title: 'API-FOOTBALL team search candidates',
  };
}

function printText({ title, endpoint, params, candidates }) {
  console.log(title);
  console.log(`Endpoint: GET ${endpoint}`);
  console.log(`Params: ${JSON.stringify(params)}`);
  console.log(`Count: ${candidates.length}`);
  console.log('');

  for (const candidate of candidates) {
    if (typeof candidate.externalTeamId === 'number') {
      console.log(`- ${candidate.apiNameSlug}`);
      console.log(`  nameEn: ${candidate.nameEn}`);
      console.log(`  externalTeamId: ${candidate.externalTeamId}`);
      console.log(`  logoUrl: ${candidate.logoUrl}`);
      console.log(`  country: ${candidate.country}`);
      console.log(`  rawTeamName: ${candidate.rawTeamName}`);
    } else {
      console.log(`- ${candidate.name}`);
      console.log(`  externalLeagueId: ${candidate.id}`);
      console.log(`  type: ${candidate.type}`);
      console.log(`  logoUrl: ${candidate.logoUrl}`);
      console.log(`  country: ${candidate.country}`);
      console.log(`  seasons: ${candidate.seasons.map((season) => season.year).join(', ')}`);
    }
  }
}

async function main() {
  const apiKey = process.env.API_SPORTS_KEY;
  if (!apiKey) {
    console.error('Missing API_SPORTS_KEY. Usage: API_SPORTS_KEY=... node functions/scripts/fetchJapanFootballTeamsFromApiSports.js --search "Vegalta"');
    process.exit(1);
  }

  try {
    const options = parseArgs(process.argv.slice(2));
    validateOptions(options);

    const request = buildRequest(options);
    const items = await fetchApi({
      apiKey,
      endpointPath: request.endpointPath,
      params: request.params,
    });
    const candidates = items.map(request.normalize);
    const endpoint = `${API_BASE_URL}${request.endpointPath}`;

    if (options.json) {
      console.log(JSON.stringify({
        endpoint,
        params: request.params,
        count: candidates.length,
        candidates,
      }, null, 2));
      return;
    }

    printText({
      title: request.title,
      endpoint,
      params: request.params,
      candidates,
    });
  } catch (err) {
    console.error('[fetch:japan-football] Error:', err.message || err);
    process.exit(1);
  }
}

main();
