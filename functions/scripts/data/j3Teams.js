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
  {
    id: 'fc_gifu',
    nameJa: 'ＦＣ岐阜',
    nameEn: 'FC Gifu',
    aliases: ['岐阜', 'FC岐阜', 'ＦＣ岐阜', 'FC Gifu'],
    externalTeamId: 297,
    logoUrl: 'https://media.api-sports.io/football/teams/297.png',
    source: 'API-SPORTS teams?league=100&season=2024 + Batch 3 j2Teams.js / j3Teams.js Exact Diff Plan',
    status: 'confirmed',
  },
  {
    id: 'matsumoto_yamaga',
    nameJa: '松本山雅ＦＣ',
    nameEn: 'Matsumoto Yamaga',
    aliases: ['松本', '山雅', '松本山雅', 'Matsumoto Yamaga'],
    externalTeamId: 304,
    logoUrl: 'https://media.api-sports.io/football/teams/304.png',
    source: 'API-SPORTS teams?league=100&season=2024 + Batch 3 j2Teams.js / j3Teams.js Exact Diff Plan',
    status: 'confirmed',
  },
  {
    id: 'fukushima_united',
    nameJa: '福島ユナイテッドＦＣ',
    nameEn: 'Fukushima United',
    aliases: ['福島', '福島ユナイテッド', 'Fukushima United'],
    externalTeamId: 4318,
    logoUrl: 'https://media.api-sports.io/football/teams/4318.png',
    source: 'API-SPORTS teams?league=100&season=2024 + Batch 3 j2Teams.js / j3Teams.js Exact Diff Plan',
    status: 'confirmed',
  },
  {
    id: 'kataller_toyama',
    nameJa: 'カターレ富山',
    nameEn: 'Kataller Toyama',
    aliases: ['富山', 'カターレ', 'Kataller Toyama'],
    externalTeamId: 4322,
    logoUrl: 'https://media.api-sports.io/football/teams/4322.png',
    source: 'API-SPORTS teams?league=100&season=2024 + Batch 3 j2Teams.js / j3Teams.js Exact Diff Plan',
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
