"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.PENDING_GOAL_COMPETITION_EVIDENCE = exports.V1_GOAL_MEMBERSHIP_BINDINGS = void 0;
const v1GoalMemberships_1 = require("../../config/v1GoalMemberships");
/** Human-approved V1 GOAL bindings. Excluded/deferred competitions are intentionally absent. */
exports.V1_GOAL_MEMBERSHIP_BINDINGS = Object.freeze([
    {
        goalLeagueId: "cmr77dx7h00rvrx060kholaxg", goalLeagueYear: "2026/2027", leagueId: "j1",
        membership: v1GoalMemberships_1.V1_GOAL_MEMBERSHIPS.j1,
    },
    {
        goalLeagueId: "cmr77dx7h00rurx06t3bbwaxc", goalLeagueYear: "2026/2027", leagueId: "j_league_cup",
        membership: v1GoalMemberships_1.V1_GOAL_MEMBERSHIPS.jLeagueCup,
    },
    {
        goalLeagueId: "cmr77dx7h00rtrx065nbappc9", goalLeagueYear: "2026", leagueId: "emperor_cup",
        membership: v1GoalMemberships_1.V1_GOAL_MEMBERSHIPS.emperorCup,
    },
    {
        goalLeagueId: "cmr77dvkr005nrx06lp7rvp49", goalLeagueYear: "2026/2027", leagueId: "premier_league",
        membership: v1GoalMemberships_1.V1_GOAL_MEMBERSHIPS.premier,
    },
    {
        goalLeagueId: "cmr77dw3900f5rx06j05wgzv4", goalLeagueYear: "2026/2027", leagueId: "champions_league",
        membership: v1GoalMemberships_1.V1_GOAL_MEMBERSHIPS.championsLeague,
    },
    {
        goalLeagueId: "cmr77dvkr005krx069ypbvs0i", goalLeagueYear: "2026/2027", leagueId: "league_cup",
        membership: v1GoalMemberships_1.V1_GOAL_MEMBERSHIPS.leagueCup,
    },
]);
/** Deliberately not active until a current-season fixture establishes the season discriminator. */
exports.PENDING_GOAL_COMPETITION_EVIDENCE = Object.freeze({
    arsenalFaCupGoalLeagueId: "cmr77dvkr005jrx06moiox5oh",
});
//# sourceMappingURL=v1CompetitionBindings.js.map