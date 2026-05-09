/**
 * competitionSeasonMemberships.js
 *
 * Data-only scaffold for season / tournament membership review.
 *
 * This intentionally does not write Firestore. It models membership separately
 * from stable team identity so promotion / relegation can move the same
 * internal team ID between J1 / J2 / J3 season memberships without duplicating
 * club documents.
 */

'use strict';

const jLeagueMembershipScaffolds = [
  {
    competitionSeasonKey: 'football_j2_membership_tbd',
    competitionKey: 'football_j2',
    season: 'TBD',
    memberTeamIds: [],
    status: 'scaffold',
    source: 'Membership source not verified yet.',
    notes:
      'Add only stable /teams/{id} values after official season membership review. Do not duplicate clubs already present in team master data.',
  },
  {
    competitionSeasonKey: 'football_j3_membership_tbd',
    competitionKey: 'football_j3',
    season: 'TBD',
    memberTeamIds: [],
    status: 'scaffold',
    source: 'Membership source not verified yet.',
    notes:
      'Add only stable /teams/{id} values after official season membership review. Do not duplicate clubs already present in team master data.',
  },
];

function listCompetitionSeasonMembershipKeys() {
  return jLeagueMembershipScaffolds.map(
    (membership) => membership.competitionSeasonKey,
  );
}

module.exports = {
  jLeagueMembershipScaffolds,
  listCompetitionSeasonMembershipKeys,
};
