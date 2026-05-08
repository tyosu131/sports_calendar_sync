/**
 * competitionRegistry.js
 *
 * Data-only registry for competition team master modules.
 *
 * This module must not initialize Firebase Admin SDK, read serviceAccountKey,
 * write files, or write Firestore.
 */

'use strict';

const {
  J1_COMPETITION_KEY,
  J1_LEAGUE_ID,
  J1_COUNTRY,
  J1_DATA_SOURCE_KEY,
  J1_SPORT_TYPE,
  j1Teams,
  j1TeamsTodo,
} = require('./j1Teams');

const competitionTeamDataByKey = {
  [J1_COMPETITION_KEY]: {
    competition: {
      competitionKey: J1_COMPETITION_KEY,
      leagueId: J1_LEAGUE_ID,
      displayNameJa: 'Jリーグ',
      displayNameEn: 'J.League',
      sportCategory: 'football',
      sportType: J1_SPORT_TYPE,
      country: J1_COUNTRY,
      dataSourceKey: J1_DATA_SOURCE_KEY,
      externalLeagueId: 98,
    },
    teams: j1Teams,
    teamsTodo: j1TeamsTodo,
  },
};

function getCompetitionTeamData(competitionKey) {
  const data = competitionTeamDataByKey[competitionKey];
  if (!data) {
    throw new Error(
      `Unknown competitionKey: ${competitionKey}. Available keys: ${listCompetitionKeys().join(', ')}`
    );
  }
  return data;
}

function listCompetitionKeys() {
  return Object.keys(competitionTeamDataByKey);
}

module.exports = {
  getCompetitionTeamData,
  listCompetitionKeys,
};
