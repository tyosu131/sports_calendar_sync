import '../../domain/models/team.dart';
import '../../domain/policies/competition_season_membership_policy.dart';
import '../repositories/competition_membership_repository.dart';
import '../repositories/team_repository.dart';

/// How league team lists were resolved.
enum CompetitionTeamListingSource {
  /// Team IDs came from a readable competition-season membership document.
  canonicalSeasonMembership,

  /// No readable membership exists; team master `competitionKey` / `sportKey`
  /// queries were used. Temporary until membership is seeded for that league.
  legacyTeamDocumentCompatibility,
}

class CompetitionTeamListingResult {
  const CompetitionTeamListingResult({
    required this.teams,
    required this.source,
  });

  final List<Team> teams;
  final CompetitionTeamListingSource source;
}

/// Resolves teams for one registry competition without treating legacy team
/// fields as canonical membership.
class CompetitionTeamListingService {
  CompetitionTeamListingService({
    required TeamRepository teamRepository,
    required CompetitionMembershipRepository membershipRepository,
  }) : _teams = teamRepository,
       _memberships = membershipRepository;

  final TeamRepository _teams;
  final CompetitionMembershipRepository _memberships;

  Future<CompetitionTeamListingResult> listTeams(String competitionKey) async {
    final key = competitionKey.trim();
    if (key.isEmpty) {
      return const CompetitionTeamListingResult(
        teams: [],
        source: CompetitionTeamListingSource.legacyTeamDocumentCompatibility,
      );
    }

    final membership = await _memberships.findReadableMembershipForCompetition(
      key,
    );
    if (membership != null) {
      final ids = teamIdsForMembership(membership);
      if (ids.isNotEmpty) {
        final loaded = await _teams.fetchTeamsByIds(ids);
        final byId = {for (final team in loaded) team.id: team};
        final ordered = [
          for (final id in ids)
            if (byId.containsKey(id)) byId[id]!,
        ]..sort((a, b) => a.nameJa.compareTo(b.nameJa));
        return CompetitionTeamListingResult(
          teams: ordered,
          source: CompetitionTeamListingSource.canonicalSeasonMembership,
        );
      }
    }

    final legacy = await _teams.fetchTeams(competitionKey: key);
    return CompetitionTeamListingResult(
      teams: legacy,
      source: CompetitionTeamListingSource.legacyTeamDocumentCompatibility,
    );
  }
}
