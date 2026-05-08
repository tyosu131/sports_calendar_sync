/**
 * competitionSeasons.js
 *
 * Local competition season / tournament profile data for seed and verify
 * scripts. This module is data-only: it must not initialize Firebase Admin SDK,
 * read serviceAccountKey.json, call external APIs, or write to Firestore.
 */

'use strict';

const CURRENT_J1_COMPETITION_SEASON_KEY = 'football_j1_2026_hyakunen';

const competitionSeasonProfiles = [
  {
    competitionKey: 'football_j1',
    competitionSeasonKey: CURRENT_J1_COMPETITION_SEASON_KEY,
    displayNameJa: '明治安田Ｊ１百年構想リーグ',
    displayNameEn: 'MEIJI YASUDA J1 100 YEAR VISION LEAGUE',
    externalLeagueId: 98,
    apiSeason: 2026,
    apiAccessibleOnCurrentPlan: false,
    startDate: '2026-02-06',
    endDate: '2026-06-07',
    status: 'active',
  },
];

function listCompetitionSeasonKeys() {
  return competitionSeasonProfiles.map((profile) => profile.competitionSeasonKey);
}

function getCompetitionSeasonProfile(competitionSeasonKey) {
  const profile = competitionSeasonProfiles.find(
    (candidate) => candidate.competitionSeasonKey === competitionSeasonKey,
  );
  if (!profile) {
    throw new Error(
      `Unknown competitionSeasonKey: ${competitionSeasonKey}. Available: ${listCompetitionSeasonKeys().join(', ')}`,
    );
  }
  return profile;
}

module.exports = {
  CURRENT_J1_COMPETITION_SEASON_KEY,
  competitionSeasonProfiles,
  getCompetitionSeasonProfile,
  listCompetitionSeasonKeys,
};
