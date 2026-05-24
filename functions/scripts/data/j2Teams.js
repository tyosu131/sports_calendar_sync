/**
 * j2Teams.js
 *
 * Stable team identity scaffold for future J2 seed scripts.
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

const J2_COMPETITION_KEY = 'football_j2';
const J2_LEAGUE_ID = 'j2_league';
const J2_COUNTRY = 'Japan';
const J2_DATA_SOURCE_KEY = 'apisports_football';
const J2_SPORT_TYPE = 'football';

/**
 * Confirmed stable team identities for J2.
 *
 * Add teams only after club identity, API-SPORTS team ID, and logo URL are
 * confirmed. Do not add season membership-only candidates here.
 */
const j2Teams = [
  {
    id: 'vegalta_sendai',
    nameJa: 'ベガルタ仙台',
    nameEn: 'Vegalta Sendai',
    aliases: ['仙台', 'ベガルタ', 'Vegalta Sendai'],
    externalTeamId: 286,
    logoUrl: 'https://media.api-sports.io/football/teams/286.png',
    source: 'API-SPORTS teams?league=99&season=2024 + Batch 1 j2Teams.js Exact Diff Plan',
    status: 'confirmed',
  },
  {
    id: 'shonan_bellmare',
    nameJa: '湘南ベルマーレ',
    nameEn: 'Shonan Bellmare',
    aliases: ['湘南', 'ベルマーレ', 'Shonan Bellmare'],
    externalTeamId: 284,
    logoUrl: 'https://media.api-sports.io/football/teams/284.png',
    source: 'API-SPORTS teams?league=98&season=2024 stable identity evidence + Batch 1 j2Teams.js Exact Diff Plan',
    status: 'confirmed',
  },
  {
    id: 'blaublitz_akita',
    nameJa: 'ブラウブリッツ秋田',
    nameEn: 'Blaublitz Akita',
    aliases: ['秋田', 'ブラウブリッツ', 'Blaublitz Akita'],
    externalTeamId: 4315,
    logoUrl: 'https://media.api-sports.io/football/teams/4315.png',
    source: 'API-SPORTS teams?league=99&season=2024 + Batch 1 j2Teams.js Exact Diff Plan',
    status: 'confirmed',
  },
  {
    id: 'yokohama_fc',
    nameJa: '横浜ＦＣ',
    nameEn: 'Yokohama FC',
    aliases: ['横浜FC', '横浜', 'Yokohama FC'],
    externalTeamId: 307,
    logoUrl: 'https://media.api-sports.io/football/teams/307.png',
    source: 'API-SPORTS teams?league=99&season=2024 + Batch 1 j2Teams.js Exact Diff Plan',
    status: 'confirmed',
  },
  {
    id: 'montedio_yamagata',
    nameJa: 'モンテディオ山形',
    nameEn: 'Montedio Yamagata',
    aliases: ['山形', 'モンテディオ', 'Montedio Yamagata'],
    externalTeamId: 312,
    logoUrl: 'https://media.api-sports.io/football/teams/312.png',
    source: 'API-SPORTS teams?league=99&season=2024 + Batch 1 j2Teams.js Exact Diff Plan',
    status: 'confirmed',
  },
  {
    id: 'tochigi_city',
    nameJa: '栃木シティ',
    nameEn: 'Tochigi City',
    aliases: ['栃木シティ', '栃木C', 'Tochigi City'],
    externalTeamId: 7145,
    logoUrl: 'https://media.api-sports.io/football/teams/7145.png',
    source: 'API-SPORTS teams?league=497&season=2024 + Batch 2 j2Teams.js / j3Teams.js Exact Diff Plan',
    status: 'confirmed',
  },
  {
    id: 'tochigi_sc',
    nameJa: '栃木ＳＣ',
    nameEn: 'Tochigi SC',
    aliases: ['栃木SC', '栃木ＳＣ', 'Tochigi SC'],
    externalTeamId: 315,
    logoUrl: 'https://media.api-sports.io/football/teams/315.png',
    source: 'API-SPORTS teams?league=99&season=2024 + Batch 2 j2Teams.js / j3Teams.js Exact Diff Plan',
    status: 'confirmed',
  },
  {
    id: 'ventforet_kofu',
    nameJa: 'ヴァンフォーレ甲府',
    nameEn: 'Ventforet Kofu',
    aliases: ['甲府', 'ヴァンフォーレ', 'Ventforet Kofu'],
    externalTeamId: 308,
    logoUrl: 'https://media.api-sports.io/football/teams/308.png',
    source: 'API-SPORTS teams?league=99&season=2024 + Batch 2 j2Teams.js / j3Teams.js Exact Diff Plan',
    status: 'confirmed',
  },
  {
    id: 'fujieda_myfc',
    nameJa: '藤枝ＭＹＦＣ',
    nameEn: 'Fujieda MYFC',
    aliases: ['藤枝', '藤枝MYFC', 'Fujieda MYFC'],
    externalTeamId: 4317,
    logoUrl: 'https://media.api-sports.io/football/teams/4317.png',
    source: 'API-SPORTS teams?league=99&season=2024 + Batch 2 j2Teams.js / j3Teams.js Exact Diff Plan',
    status: 'confirmed',
  },
  {
    id: 'jubilo_iwata',
    nameJa: 'ジュビロ磐田',
    nameEn: 'Jubilo Iwata',
    aliases: ['磐田', 'ジュビロ', 'Jubilo Iwata'],
    externalTeamId: 280,
    logoUrl: 'https://media.api-sports.io/football/teams/280.png',
    source: 'API-SPORTS teams?league=98&season=2024 + Batch 3 j2Teams.js / j3Teams.js Exact Diff Plan',
    status: 'confirmed',
  },
];

/**
 * Review-only placeholder. These entries are intentionally ignored by generic
 * seed / verify scripts.
 */
const j2TeamsTodo = [];

module.exports = {
  J2_COMPETITION_KEY,
  J2_LEAGUE_ID,
  J2_COUNTRY,
  J2_DATA_SOURCE_KEY,
  J2_SPORT_TYPE,
  j2Teams,
  j2TeamsTodo,
};
