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
 * Keep this empty until club identity, API-SPORTS team ID, and logo URL are
 * confirmed. Do not add season membership-only candidates here.
 */
const j2Teams = [];

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
