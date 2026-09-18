/** The two supported membership layouts. Grouping is only domain-significant
 * for tournaments which already expose groups; both layouts resolve to stable
 * team IDs in exactly the same way. */
export interface CompetitionSeasonMembership {
  competitionSeasonKey: string;
  competitionKey: string;
  seasonYear: number;
  displayNameJa: string;
  membershipType: "league" | "special_tournament" | "cup" | "playoff";
  memberTeamIds?: readonly string[];
  groups?: readonly {
    groupKey: string;
    displayNameJa: string;
    teamIds: readonly string[];
  }[];
  status: "review" | "approved" | "seedable" | "seeded";
  seedable: boolean;
}

export function teamIdsForMembership(
  membership: CompetitionSeasonMembership
): readonly string[] {
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
export function membershipsForTeam(
  teamId: string,
  memberships: readonly CompetitionSeasonMembership[]
): CompetitionSeasonMembership[] {
  if (typeof teamId !== "string" || teamId.trim().length === 0) return [];
  return memberships.filter((membership) =>
    teamIdsForMembership(membership).includes(teamId)
  );
}
