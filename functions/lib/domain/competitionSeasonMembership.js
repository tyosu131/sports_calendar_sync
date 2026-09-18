"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.teamIdsForMembership = teamIdsForMembership;
exports.membershipsForTeam = membershipsForTeam;
function teamIdsForMembership(membership) {
    if (Array.isArray(membership.memberTeamIds)) {
        return membership.memberTeamIds;
    }
    return membership.groups?.flatMap((group) => group.teamIds) ?? [];
}
/**
 * Deterministically resolves a stable team ID without network or Firestore.
 * Invalid/unknown IDs safely produce an empty result. Validation is
 * responsible for rejecting duplicate team IDs inside one membership.
 */
function membershipsForTeam(teamId, memberships) {
    if (typeof teamId !== "string" || teamId.trim().length === 0)
        return [];
    return memberships.filter((membership) => teamIdsForMembership(membership).includes(teamId));
}
//# sourceMappingURL=competitionSeasonMembership.js.map