/**
 * j3Teams.js
 *
 * Stable team identity scaffold for future J3 seed scripts.
 *
 * This file is data-only: it must not initialize Firebase Admin SDK, read
 * serviceAccountKey.json, call external APIs, or write Firestore.
 *
 * Promotion / relegation policy:
 *   - Do not duplicate clubs per division.
 *   - A club promoted or relegated between J1 / J2 / J3 must keep the same
 *     internal /teams/{id} document ID.
 *   - Division membership belongs in competition season membership data, not
 *     permanent team master data.
 */

'use strict';

const J3_COMPETITION_KEY = 'football_j3';
const J3_LEAGUE_ID = 'j3_league';
const J3_COUNTRY = 'Japan';
const J3_DATA_SOURCE_KEY = 'apisports_football';
const J3_SPORT_TYPE = 'football';

/**
 * Confirmed stable team identities for J3.
 *
 * Add teams only after club identity, API-SPORTS team ID, and logo URL are
 * confirmed. Do not add season membership-only candidates here.
 */
const j3Teams = [
  {
    id: 'vanraure_hachinohe',
    nameJa: 'ヴァンラーレ八戸',
    nameEn: 'Vanraure Hachinohe',
    aliases: ['八戸', 'ヴァンラーレ', 'Vanraure Hachinohe'],
    externalTeamId: 4326,
    logoUrl: 'https://media.api-sports.io/football/teams/4326.png',
    source: 'API-SPORTS teams?league=100&season=2024 + Batch 2 j2Teams.js / j3Teams.js Exact Diff Plan',
    status: 'confirmed',
  },
];

/**
 * Review-only placeholder. These entries are intentionally ignored by generic
 * seed / verify scripts.
 */
const j3TeamsTodo = [];

module.exports = {
  J3_COMPETITION_KEY,
  J3_LEAGUE_ID,
  J3_COUNTRY,
  J3_DATA_SOURCE_KEY,
  J3_SPORT_TYPE,
  j3Teams,
  j3TeamsTodo,
};
