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

const FOOTBALL_J2_J3_2026_HYAKUNEN_TEAM_ID_STATUSES = {
  vegalta_sendai: 'confirmed_team_master',
  shonan_bellmare: 'confirmed_team_master',
  blaublitz_akita: 'confirmed_team_master',
  sc_sagamihara: 'candidate_not_confirmed',
  yokohama_fc: 'confirmed_team_master',
  montedio_yamagata: 'confirmed_team_master',
  thespa_gunma: 'candidate_not_confirmed',
  tochigi_city: 'confirmed_team_master',
  tochigi_sc: 'confirmed_team_master',
  vanraure_hachinohe: 'confirmed_team_master',
  ventforet_kofu: 'confirmed_team_master',
  iwaki_fc: 'candidate_not_confirmed',
  rb_omiya_ardija: 'candidate_not_confirmed',
  hokkaido_consadole_sapporo: 'candidate_not_confirmed',
  fujieda_myfc: 'confirmed_team_master',
  fc_gifu: 'confirmed_team_master',
  matsumoto_yamaga: 'confirmed_team_master',
  jubilo_iwata: 'confirmed_team_master',
  fukushima_united: 'confirmed_team_master',
  ac_nagano_parceiro: 'candidate_not_confirmed',
  kataller_toyama: 'confirmed_team_master',
  tokushima_vortis: 'confirmed_team_master',
  albirex_niigata: 'confirmed_team_master',
  kochi_united: 'confirmed_team_master',
  ehime_fc: 'confirmed_team_master',
  zweigen_kanazawa: 'candidate_not_confirmed',
  fc_osaka: 'candidate_not_confirmed',
  fc_imabari: 'candidate_not_confirmed',
  nara_club: 'confirmed_team_master',
  kamatamare_sanuki: 'candidate_not_confirmed',
  tegevajaro_miyazaki: 'candidate_not_confirmed',
  sagan_tosu: 'candidate_not_confirmed',
  kagoshima_united: 'candidate_not_confirmed',
  renofa_yamaguchi: 'candidate_not_confirmed',
  roasso_kumamoto: 'candidate_not_confirmed',
  oita_trinita: 'candidate_not_confirmed',
  gainare_tottori: 'candidate_not_confirmed',
  giravanz_kitakyushu: 'candidate_not_confirmed',
  reilac_shiga: 'blocked_continuity',
  fc_ryukyu: 'candidate_not_confirmed',
};

const competitionSeasonMemberships = [
  {
    competitionSeasonKey: 'football_j2_j3_2026_hyakunen',
    seasonYear: 2026,
    competitionKey: 'football_j2_j3_special',
    displayNameJa: '明治安田Ｊ２・Ｊ３百年構想リーグ',
    membershipType: 'special_tournament',
    source: {
      official: [
        'https://www.jleague.jp/special/2026specialseason/j2-j3/',
        'https://www.jleague.jp/standings/j2j3/',
      ],
      reviewDocument: 'docs/current-j2-j3-season-membership-review.md',
    },
    groups: [
      {
        groupKey: 'east_a',
        displayNameJa: 'EAST-A',
        teamIds: [
          'vegalta_sendai',
          'shonan_bellmare',
          'blaublitz_akita',
          'sc_sagamihara',
          'yokohama_fc',
          'montedio_yamagata',
          'thespa_gunma',
          'tochigi_city',
          'tochigi_sc',
          'vanraure_hachinohe',
        ],
      },
      {
        groupKey: 'east_b',
        displayNameJa: 'EAST-B',
        teamIds: [
          'ventforet_kofu',
          'iwaki_fc',
          'rb_omiya_ardija',
          'hokkaido_consadole_sapporo',
          'fujieda_myfc',
          'fc_gifu',
          'matsumoto_yamaga',
          'jubilo_iwata',
          'fukushima_united',
          'ac_nagano_parceiro',
        ],
      },
      {
        groupKey: 'west_a',
        displayNameJa: 'WEST-A',
        teamIds: [
          'kataller_toyama',
          'tokushima_vortis',
          'albirex_niigata',
          'kochi_united',
          'ehime_fc',
          'zweigen_kanazawa',
          'fc_osaka',
          'fc_imabari',
          'nara_club',
          'kamatamare_sanuki',
        ],
      },
      {
        groupKey: 'west_b',
        displayNameJa: 'WEST-B',
        teamIds: [
          'tegevajaro_miyazaki',
          'sagan_tosu',
          'kagoshima_united',
          'renofa_yamaguchi',
          'roasso_kumamoto',
          'oita_trinita',
          'gainare_tottori',
          'giravanz_kitakyushu',
          'reilac_shiga',
          'fc_ryukyu',
        ],
      },
    ],
    teamIdStatuses: FOOTBALL_J2_J3_2026_HYAKUNEN_TEAM_ID_STATUSES,
    status: 'review',
    seedable: false,
  },
];

function listCompetitionSeasonMembershipKeys() {
  return [
    ...competitionSeasonMemberships,
    ...jLeagueMembershipScaffolds,
  ].map((membership) => membership.competitionSeasonKey);
}

module.exports = {
  competitionSeasonMemberships,
  jLeagueMembershipScaffolds,
  listCompetitionSeasonMembershipKeys,
};
