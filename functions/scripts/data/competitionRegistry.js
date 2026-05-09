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
const {
  J2_COMPETITION_KEY,
  J2_LEAGUE_ID,
  J2_COUNTRY,
  J2_DATA_SOURCE_KEY,
  J2_SPORT_TYPE,
  j2Teams,
  j2TeamsTodo,
} = require('./j2Teams');
const {
  J3_COMPETITION_KEY,
  J3_LEAGUE_ID,
  J3_COUNTRY,
  J3_DATA_SOURCE_KEY,
  J3_SPORT_TYPE,
  j3Teams,
  j3TeamsTodo,
} = require('./j3Teams');

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
  [J2_COMPETITION_KEY]: {
    competition: {
      competitionKey: J2_COMPETITION_KEY,
      leagueId: J2_LEAGUE_ID,
      displayNameJa: 'J2リーグ',
      displayNameEn: 'J2 League',
      sportCategory: 'football',
      sportType: J2_SPORT_TYPE,
      country: J2_COUNTRY,
      dataSourceKey: J2_DATA_SOURCE_KEY,
    },
    teams: j2Teams,
    teamsTodo: j2TeamsTodo,
  },
  [J3_COMPETITION_KEY]: {
    competition: {
      competitionKey: J3_COMPETITION_KEY,
      leagueId: J3_LEAGUE_ID,
      displayNameJa: 'J3リーグ',
      displayNameEn: 'J3 League',
      sportCategory: 'football',
      sportType: J3_SPORT_TYPE,
      country: J3_COUNTRY,
      dataSourceKey: J3_DATA_SOURCE_KEY,
    },
    teams: j3Teams,
    teamsTodo: j3TeamsTodo,
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
