import '../models/competition_season_membership.dart';

/// Status values that may be read for UI listing. Scaffolds are ignored.
const readableMembershipStatuses = {'approved', 'seedable', 'seeded'};

/// Stable team IDs for one membership document.
List<String> teamIdsForMembership(CompetitionSeasonMembership membership) {
  final flat = membership.memberTeamIds;
  if (flat != null && flat.isNotEmpty) {
    return List<String>.unmodifiable(flat);
  }
  final groups = membership.groups;
  if (groups == null || groups.isEmpty) return const [];
  return List<String>.unmodifiable([
    for (final group in groups) ...group.teamIds,
  ]);
}

bool membershipIsReadable(CompetitionSeasonMembership membership) {
  if (!readableMembershipStatuses.contains(membership.status)) return false;
  return teamIdsForMembership(membership).isNotEmpty;
}

/// Memberships that include [teamId], across competitions/seasons.
List<CompetitionSeasonMembership> membershipsForTeam(
  String teamId,
  Iterable<CompetitionSeasonMembership> memberships,
) {
  if (teamId.trim().isEmpty) return const [];
  return [
    for (final membership in memberships)
      if (teamIdsForMembership(membership).contains(teamId)) membership,
  ];
}
