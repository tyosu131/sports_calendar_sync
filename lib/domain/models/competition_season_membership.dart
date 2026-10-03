/// Season-scoped competition membership. Canonical team participation lives
/// here, not on [Team.competitionKey].
class CompetitionSeasonMembership {
  const CompetitionSeasonMembership({
    required this.competitionSeasonKey,
    required this.competitionKey,
    required this.seasonYear,
    required this.displayNameJa,
    required this.membershipType,
    required this.status,
    required this.seedable,
    this.memberTeamIds,
    this.groups,
  });

  final String competitionSeasonKey;
  final String competitionKey;
  final int seasonYear;
  final String displayNameJa;
  final String membershipType;
  final String status;
  final bool seedable;
  final List<String>? memberTeamIds;
  final List<CompetitionSeasonMembershipGroup>? groups;
}

class CompetitionSeasonMembershipGroup {
  const CompetitionSeasonMembershipGroup({
    required this.groupKey,
    required this.displayNameJa,
    required this.teamIds,
  });

  final String groupKey;
  final String displayNameJa;
  final List<String> teamIds;
}
