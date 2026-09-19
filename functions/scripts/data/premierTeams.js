/**
 * V1 Premier League team master data.
 *
 * Provider-specific team identity remains owned by
 * src/providers/goal/teamIdentity.ts. This file only describes the stable
 * /teams document used for discovery.
 */

'use strict';

const PREMIER_COMPETITION_KEY = 'football_premier';
const PREMIER_LEAGUE_ID = 'premier_league';
const PREMIER_COUNTRY = 'England';
const PREMIER_DATA_SOURCE_KEY = 'goal';
const PREMIER_SPORT_TYPE = 'football';

const premierTeams = [
  {
    id: 'arsenal',
    nameJa: 'アーセナル',
    nameEn: 'Arsenal',
    aliases: ['アーセナル', 'Arsenal'],
    source: 'GOAL-backed V1 team master',
    status: 'confirmed',
  },
];

const premierTeamsTodo = [];

module.exports = {
  PREMIER_COMPETITION_KEY,
  PREMIER_LEAGUE_ID,
  PREMIER_COUNTRY,
  PREMIER_DATA_SOURCE_KEY,
  PREMIER_SPORT_TYPE,
  premierTeams,
  premierTeamsTodo,
};
