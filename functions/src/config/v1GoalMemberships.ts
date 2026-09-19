import { CompetitionSeasonMembership } from "../domain/competitionSeasonMembership";

/** Canonical V1 product membership decisions. Provider bindings reference these objects. */
export const V1_GOAL_MEMBERSHIPS: Readonly<Record<string, CompetitionSeasonMembership>> = Object.freeze({
  j1: membership("football_j1", "football_j1_2026_2027", "J1 League", "league", "kawasaki_frontale"),
  jLeagueCup: membership("football_j_league_cup", "football_j_league_cup_2026_2027", "Jリーグカップ", "cup", "kawasaki_frontale"),
  emperorCup: membership("football_emperor_cup", "football_emperor_cup_2026", "天皇杯", "cup", "kawasaki_frontale"),
  premier: membership("football_premier", "football_premier_2026_2027", "プレミアリーグ", "league", "arsenal"),
  championsLeague: membership("football_champions_league", "football_champions_league_2026_2027", "UEFAチャンピオンズリーグ", "league", "arsenal"),
  leagueCup: membership("football_league_cup", "football_league_cup_2026_2027", "リーグカップ", "cup", "arsenal"),
});

function membership(competitionKey: string, competitionSeasonKey: string, displayNameJa: string,
  membershipType: CompetitionSeasonMembership["membershipType"], teamId: string): CompetitionSeasonMembership {
  return Object.freeze({ competitionKey, competitionSeasonKey, seasonYear: 2026, displayNameJa,
    membershipType, memberTeamIds: Object.freeze([teamId]), status: "approved", seedable: true });
}
