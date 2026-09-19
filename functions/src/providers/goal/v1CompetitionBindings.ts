import { CompetitionSeasonMembership } from "../../domain/competitionSeasonMembership";
import { GoalMembershipBinding } from "./syncOrchestrator";

function approvedMembership(
  competitionKey: string,
  competitionSeasonKey: string,
  displayNameJa: string,
  teamId: string
): CompetitionSeasonMembership {
  return {
    competitionKey,
    competitionSeasonKey,
    seasonYear: 2026,
    displayNameJa,
    membershipType: "league",
    memberTeamIds: [teamId],
    status: "approved",
    seedable: true,
  };
}

/** Human-approved V1 GOAL bindings. Excluded/deferred competitions are intentionally absent. */
export const V1_GOAL_MEMBERSHIP_BINDINGS: readonly GoalMembershipBinding[] = Object.freeze([
  {
    goalLeagueId: "cmr77dx7h00rvrx060kholaxg", goalLeagueYear: "2026/2027", leagueId: "j1",
    membership: approvedMembership("football_j1", "football_j1_2026_2027", "J1 League", "kawasaki_frontale"),
  },
  {
    goalLeagueId: "cmr77dx7h00rurx06t3bbwaxc", goalLeagueYear: "2026/2027", leagueId: "j_league_cup",
    membership: approvedMembership("football_j_league_cup", "football_j_league_cup_2026_2027", "Jリーグカップ", "kawasaki_frontale"),
  },
  {
    goalLeagueId: "cmr77dx7h00rtrx065nbappc9", goalLeagueYear: "2026", leagueId: "emperor_cup",
    membership: approvedMembership("football_emperor_cup", "football_emperor_cup_2026", "天皇杯", "kawasaki_frontale"),
  },
  {
    goalLeagueId: "cmr77dvkr005nrx06lp7rvp49", goalLeagueYear: "2026/2027", leagueId: "premier_league",
    membership: approvedMembership("football_premier", "football_premier_2026_2027", "プレミアリーグ", "arsenal"),
  },
  {
    goalLeagueId: "cmr77dw3900f5rx06j05wgzv4", goalLeagueYear: "2026/2027", leagueId: "champions_league",
    membership: approvedMembership("football_champions_league", "football_champions_league_2026_2027", "UEFAチャンピオンズリーグ", "arsenal"),
  },
  {
    goalLeagueId: "cmr77dvkr005krx069ypbvs0i", goalLeagueYear: "2026/2027", leagueId: "league_cup",
    membership: approvedMembership("football_league_cup", "football_league_cup_2026_2027", "リーグカップ", "arsenal"),
  },
]);

/** Deliberately not active until a current-season fixture establishes the season discriminator. */
export const PENDING_GOAL_COMPETITION_EVIDENCE = Object.freeze({
  arsenalFaCupGoalLeagueId: "cmr77dvkr005jrx06moiox5oh",
});
