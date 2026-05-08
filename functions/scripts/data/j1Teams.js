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
    source: 'Existing seedJ1Minimum.js + J.LEAGUE official 2026 J1 list',
    status: 'confirmed',
  },
  {
    id: 'mito_hollyhock',
    nameJa: '水戸ホーリーホック',
    nameEn: 'Mito Hollyhock',
    aliases: ['水戸', 'ホーリーホック', 'Mito Hollyhock'],
    externalTeamId: 305,
    logoUrl: 'https://media.api-sports.io/football/teams/305.png',
    source: 'J.LEAGUE official 2026 J1 list + API-SPORTS /teams search lookup',
    status: 'confirmed',
  },
  {
    id: 'urawa_reds',
    nameJa: '浦和レッズ',
    nameEn: 'Urawa Reds',
    aliases: ['浦和', 'レッズ', 'Urawa Reds'],
    externalTeamId: 287,
    logoUrl: 'https://media.api-sports.io/football/teams/287.png',
    source: 'J.LEAGUE official 2026 J1 list + API-SPORTS 2024 J1 output reference',
    status: 'confirmed',
  },
  {
    id: 'jef_united_chiba',
    nameJa: 'ジェフユナイテッド千葉',
    nameEn: 'JEF United Chiba',
    aliases: ['千葉', 'ジェフ', 'ジェフ千葉', 'JEF United Chiba', 'JEF Chiba'],
    externalTeamId: 301,
    logoUrl: 'https://media.api-sports.io/football/teams/301.png',
    source: 'J.LEAGUE official 2026 J1 list + API-SPORTS /teams search lookup',
    status: 'confirmed',
  },
  {
    id: 'kashiwa_reysol',
    nameJa: '柏レイソル',
    nameEn: 'Kashiwa Reysol',
    aliases: ['柏', 'レイソル', 'Kashiwa Reysol'],
    externalTeamId: 281,
    logoUrl: 'https://media.api-sports.io/football/teams/281.png',
    source: 'J.LEAGUE official 2026 J1 list + API-SPORTS 2024 J1 output reference',
    status: 'confirmed',
  },
  {
    id: 'fc_tokyo',
    nameJa: 'ＦＣ東京',
    nameEn: 'FC Tokyo',
    aliases: ['FC東京', '東京', 'FC Tokyo'],
    externalTeamId: 292,
    logoUrl: 'https://media.api-sports.io/football/teams/292.png',
    source: 'J.LEAGUE official 2026 J1 list + API-SPORTS 2024 J1 output reference',
    status: 'confirmed',
  },
  {
    id: 'tokyo_verdy',
    nameJa: '東京ヴェルディ',
    nameEn: 'Tokyo Verdy',
    aliases: ['東京V', 'ヴェルディ', 'Tokyo Verdy'],
    externalTeamId: 306,
    logoUrl: 'https://media.api-sports.io/football/teams/306.png',
    source: 'J.LEAGUE official 2026 J1 list + API-SPORTS 2024 J1 output reference',
    status: 'confirmed',
  },
  {
    id: 'fc_machida_zelvia',
    nameJa: 'ＦＣ町田ゼルビア',
    nameEn: 'FC Machida Zelvia',
    aliases: ['町田', 'ゼルビア', 'FC Machida Zelvia', 'Machida Zelvia'],
    externalTeamId: 303,
    logoUrl: 'https://media.api-sports.io/football/teams/303.png',
    source: 'J.LEAGUE official 2026 J1 list + API-SPORTS 2024 J1 output reference',
    status: 'confirmed',
  },
  {
    id: 'kawasaki_frontale',
    nameJa: '川崎フロンターレ',
    nameEn: 'Kawasaki Frontale',
    aliases: ['川崎', 'フロンターレ', 'Kawasaki Frontale'],
    externalTeamId: 294,
    logoUrl: 'https://media.api-sports.io/football/teams/294.png',
    source: 'J.LEAGUE official 2026 J1 list + API-SPORTS 2024 J1 output reference',
    status: 'confirmed',
  },
  {
    id: 'yokohama_f_marinos',
    nameJa: '横浜Ｆ・マリノス',
    nameEn: 'Yokohama F･Marinos',
    aliases: ['横浜FM', 'マリノス', 'Yokohama F･Marinos', 'Yokohama F. Marinos', 'F. Marinos'],
    externalTeamId: 296,
    logoUrl: 'https://media.api-sports.io/football/teams/296.png',
    source: 'J.LEAGUE official 2026 J1 list + API-SPORTS 2024 J1 output reference',
    status: 'confirmed',
  },
  {
    id: 'shimizu_s_pulse',
    nameJa: '清水エスパルス',
    nameEn: 'Shimizu S-Pulse',
    aliases: ['清水', 'エスパルス', 'Shimizu S-Pulse'],
    externalTeamId: 283,
    logoUrl: 'https://media.api-sports.io/football/teams/283.png',
    source: 'J.LEAGUE official 2026 J1 list + API-SPORTS /teams search lookup',
    status: 'confirmed',
  },
  {
    id: 'nagoya_grampus',
    nameJa: '名古屋グランパス',
    nameEn: 'Nagoya Grampus',
    aliases: ['名古屋', 'グランパス', 'Nagoya Grampus'],
    externalTeamId: 288,
    logoUrl: 'https://media.api-sports.io/football/teams/288.png',
    source: 'J.LEAGUE official 2026 J1 list + API-SPORTS 2024 J1 output reference',
    status: 'confirmed',
  },
  {
    id: 'kyoto_sanga',
    nameJa: '京都サンガF.C.',
    nameEn: 'Kyoto Sanga F.C.',
    aliases: ['京都', 'サンガ', 'Kyoto Sanga F.C.', 'Kyoto Sanga'],
    externalTeamId: 302,
    logoUrl: 'https://media.api-sports.io/football/teams/302.png',
    source: 'J.LEAGUE official 2026 J1 list + API-SPORTS 2024 J1 output reference',
    status: 'confirmed',
  },
  {
    id: 'gamba_osaka',
    nameJa: 'ガンバ大阪',
    nameEn: 'Gamba Osaka',
    aliases: ['G大阪', 'ガンバ', 'Gamba Osaka'],
    externalTeamId: 293,
    logoUrl: 'https://media.api-sports.io/football/teams/293.png',
    source: 'J.LEAGUE official 2026 J1 list + API-SPORTS 2024 J1 output reference',
    status: 'confirmed',
  },
  {
    id: 'cerezo_osaka',
    nameJa: 'セレッソ大阪',
    nameEn: 'Cerezo Osaka',
    aliases: ['C大阪', 'セレッソ', 'Cerezo Osaka'],
    externalTeamId: 291,
    logoUrl: 'https://media.api-sports.io/football/teams/291.png',
    source: 'J.LEAGUE official 2026 J1 list + API-SPORTS 2024 J1 output reference',
    status: 'confirmed',
  },
  {
    id: 'vissel_kobe',
    nameJa: 'ヴィッセル神戸',
    nameEn: 'Vissel Kobe',
    aliases: ['神戸', 'ヴィッセル', 'Vissel Kobe'],
    externalTeamId: 289,
    logoUrl: 'https://media.api-sports.io/football/teams/289.png',
    source: 'J.LEAGUE official 2026 J1 list + API-SPORTS 2024 J1 output reference',
    status: 'confirmed',
  },
  {
    id: 'fagiano_okayama',
    nameJa: 'ファジアーノ岡山',
    nameEn: 'Fagiano Okayama',
    aliases: ['岡山', 'ファジアーノ', 'Fagiano Okayama'],
    externalTeamId: 310,
    logoUrl: 'https://media.api-sports.io/football/teams/310.png',
    source: 'J.LEAGUE official 2026 J1 list + API-SPORTS /teams search lookup',
    status: 'confirmed',
  },
  {
    id: 'sanfrecce_hiroshima',
    nameJa: 'サンフレッチェ広島',
    nameEn: 'Sanfrecce Hiroshima',
    aliases: ['広島', 'サンフレッチェ', 'Sanfrecce Hiroshima'],
    externalTeamId: 282,
    logoUrl: 'https://media.api-sports.io/football/teams/282.png',
    source: 'J.LEAGUE official 2026 J1 list + API-SPORTS 2024 J1 output reference',
    status: 'confirmed',
  },
  {
    id: 'avispa_fukuoka',
    nameJa: 'アビスパ福岡',
    nameEn: 'Avispa Fukuoka',
    aliases: ['福岡', 'アビスパ', 'Avispa Fukuoka'],
    externalTeamId: 316,
    logoUrl: 'https://media.api-sports.io/football/teams/316.png',
    source: 'J.LEAGUE official 2026 J1 list + API-SPORTS 2024 J1 output reference',
    status: 'confirmed',
  },
  {
    id: 'v_varen_nagasaki',
    nameJa: 'Ｖ・ファーレン長崎',
    nameEn: 'V-Varen Nagasaki',
    aliases: ['長崎', 'Ｖ・ファーレン', 'V-Varen Nagasaki', 'V. Varen Nagasaki'],
    externalTeamId: 285,
    logoUrl: 'https://media.api-sports.io/football/teams/285.png',
    source: 'J.LEAGUE official 2026 J1 list + API-SPORTS /teams search lookup',
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
