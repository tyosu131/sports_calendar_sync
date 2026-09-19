"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.internalTeamIdForGoalTeam = internalTeamIdForGoalTeam;
exports.goalTeamIdForInternalTeam = goalTeamIdForInternalTeam;
const INTERNAL_TEAM_BY_GOAL_ID = Object.freeze({
    cmr7be2nq0qkwrx06zxbqr5ux: "kawasaki_frontale",
    cmr7foowe2kf3rx06u6eu3rhl: "arsenal",
});
function internalTeamIdForGoalTeam(goalTeamId) {
    return INTERNAL_TEAM_BY_GOAL_ID[goalTeamId];
}
function goalTeamIdForInternalTeam(teamId) {
    return Object.keys(INTERNAL_TEAM_BY_GOAL_ID).find((id) => INTERNAL_TEAM_BY_GOAL_ID[id] === teamId);
}
//# sourceMappingURL=teamIdentity.js.map