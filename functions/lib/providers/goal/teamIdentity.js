"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.internalTeamIdForGoalTeam = internalTeamIdForGoalTeam;
exports.goalTeamIdForInternalTeam = goalTeamIdForInternalTeam;
exports.v1TeamNameJa = v1TeamNameJa;
const INTERNAL_TEAM_BY_GOAL_ID = Object.freeze({
    cmr7be2nq0qkwrx06zxbqr5ux: "kawasaki_frontale",
    cmr7foowe2kf3rx06u6eu3rhl: "arsenal",
});
/** V1 product display names for the canonical teams this provider may map. */
const TEAM_NAME_JA_BY_INTERNAL_ID = Object.freeze({
    kawasaki_frontale: "川崎フロンターレ",
    arsenal: "アーセナル",
});
function internalTeamIdForGoalTeam(goalTeamId) {
    return INTERNAL_TEAM_BY_GOAL_ID[goalTeamId];
}
function goalTeamIdForInternalTeam(teamId) {
    return Object.keys(INTERNAL_TEAM_BY_GOAL_ID).find((id) => INTERNAL_TEAM_BY_GOAL_ID[id] === teamId);
}
/** Fails closed rather than exposing an internal identifier as a display name. */
function v1TeamNameJa(teamId) {
    const name = TEAM_NAME_JA_BY_INTERNAL_ID[teamId];
    if (!name)
        throw new Error(`Missing V1 Japanese display name for canonical team: ${teamId}`);
    return name;
}
//# sourceMappingURL=teamIdentity.js.map