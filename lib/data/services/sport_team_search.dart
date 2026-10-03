import '../../domain/models/team.dart';
import '../../domain/policies/home_sport_navigation.dart';
import '../repositories/team_repository.dart';

/// Search sport-home listing. Temporary compatibility path: each enabled
/// [SportsRegistry] competition for [tab] is queried separately. Results are
/// merged by team id so a club that appears in more than one competition of
/// the same sport is shown once. This does not use canonical season
/// membership.
Future<List<Team>> searchTeamsForSportTab({
  required TeamRepository repository,
  required HomeSportTab tab,
  required String query,
}) async {
  final competitions = competitionsForHomeSportTab(tab);
  if (competitions.isEmpty) return const [];

  final batches = await Future.wait([
    for (final competition in competitions)
      repository.searchTeams(query, competitionKey: competition.competitionKey),
  ]);

  final merged = <String, Team>{};
  for (final batch in batches) {
    for (final team in batch) {
      merged.putIfAbsent(team.id, () => team);
    }
  }

  final teams = merged.values.toList()
    ..sort((a, b) {
      final byName = a.nameJa.compareTo(b.nameJa);
      if (byName != 0) return byName;
      return a.id.compareTo(b.id);
    });
  return teams;
}
