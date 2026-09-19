import { V1_GOAL_MEMBERSHIPS as M } from "../../config/v1GoalMemberships";
import { GoalMembershipBinding } from "./syncOrchestrator";

/** Human-approved V1 GOAL bindings. Excluded/deferred competitions are intentionally absent. */
export const V1_GOAL_MEMBERSHIP_BINDINGS: readonly GoalMembershipBinding[] = Object.freeze([
  {
    goalLeagueId: "cmr77dx7h00rvrx060kholaxg", goalLeagueYear: "2026/2027", leagueId: "j1",
    membership: M.j1,
  },
  {
    goalLeagueId: "cmr77dx7h00rurx06t3bbwaxc", goalLeagueYear: "2026/2027", leagueId: "j_league_cup",
    membership: M.jLeagueCup,
  },
  {
    goalLeagueId: "cmr77dx7h00rtrx065nbappc9", goalLeagueYear: "2026", leagueId: "emperor_cup",
    membership: M.emperorCup,
  },
  {
    goalLeagueId: "cmr77dvkr005nrx06lp7rvp49", goalLeagueYear: "2026/2027", leagueId: "premier_league",
    membership: M.premier,
  },
  {
    goalLeagueId: "cmr77dw3900f5rx06j05wgzv4", goalLeagueYear: "2026/2027", leagueId: "champions_league",
    membership: M.championsLeague,
  },
  {
    goalLeagueId: "cmr77dvkr005krx069ypbvs0i", goalLeagueYear: "2026/2027", leagueId: "league_cup",
    membership: M.leagueCup,
  },
]);

/** Deliberately not active until a current-season fixture establishes the season discriminator. */
export const PENDING_GOAL_COMPETITION_EVIDENCE = Object.freeze({
  arsenalFaCupGoalLeagueId: "cmr77dvkr005jrx06moiox5oh",
});
