/**
 * j1Teams.js
 *
 * Master data for J1 team seed scripts.
 *
 * This file is data-only: it must not initialize Firebase Admin SDK, read
 * serviceAccountKey.json, or write to Firestore. Seed / verify scripts should
 * import this module and decide whether to write or validate.
 *
 * Policy:
 *   - UI display may say "Jリーグ", but the internal competitionKey remains
 *     "football_j1".
 *   - leagues/j1_league remains the J1 League entity.
 *   - J2 / J3 should be added later as separate competitions:
 *     "football_j2" / "football_j3".
 *   - Do not guess API-SPORTS team IDs or logo URLs. Add teams only after the
 *     data has been confirmed from an authoritative source or user-provided
 *     master list.
 */

'use strict';

const J1_COMPETITION_KEY = 'football_j1';
const J1_LEAGUE_ID = 'j1_league';
const J1_COUNTRY = 'Japan';
const J1_DATA_SOURCE_KEY = 'apisports_football';
const J1_SPORT_TYPE = 'football';

/**
 * Confirmed J1 teams.
 *
 * Required fields for each team:
 *   - id: Firestore document ID in /teams/{id}
 *   - nameJa / nameEn: display and search names
 *   - aliases: extra Japanese / English names for searchKeywords generation
 *   - externalTeamId: API-SPORTS team ID
 *   - logoUrl: API-SPORTS logo URL or another confirmed logo URL
 *
 * Firestore compatibility fields such as competitionKey, sportKey, sportType,
 * leagueId, country, dataSourceKey, and rapidApiId should be derived by seed
 * scripts from the constants above.
 */
const j1Teams = [
  {
    id: 'kashima_antlers',
    nameJa: '鹿島アントラーズ',
    nameEn: 'Kashima',
    aliases: ['鹿島', 'アントラーズ', 'Kashima Antlers', 'Antlers'],
    externalTeamId: 290,
    logoUrl: 'https://media.api-sports.io/football/teams/290.png',
    source: 'Existing seedJ1Minimum.js',
    status: 'confirmed',
  },
];

/**
 * Placeholder for teams whose names / API-SPORTS IDs / logo URLs still need
 * confirmation. Keep this list empty until confirmed data is supplied.
 */
const j1TeamsTodo = [];

module.exports = {
  J1_COMPETITION_KEY,
  J1_LEAGUE_ID,
  J1_COUNTRY,
  J1_DATA_SOURCE_KEY,
  J1_SPORT_TYPE,
  j1Teams,
  j1TeamsTodo,
};
