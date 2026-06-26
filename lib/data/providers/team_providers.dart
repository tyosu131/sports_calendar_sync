import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/sport.dart';
import '../../domain/models/team.dart';
import 'auth_providers.dart';
import 'repository_providers.dart';

// ── League providers ──────────────────────────────────────────────────────────

/// All leagues, optionally filtered by competitionKey.
/// null = no filter (all competitions).
final leaguesByCompetitionProvider =
    FutureProvider.family<List<League>, String?>((ref, competitionKey) async {
      return ref
          .watch(teamRepositoryProvider)
          .fetchLeagues(competitionKey: competitionKey);
    });

// ── Team providers ────────────────────────────────────────────────────────────

/// Teams for a specific league.
final teamsByLeagueProvider = FutureProvider.family<List<Team>, String>((
  ref,
  leagueId,
) async {
  return ref.watch(teamRepositoryProvider).fetchTeamsByLeague(leagueId);
});

/// A single team by ID.
final teamByIdProvider = FutureProvider.family<Team?, String>((
  ref,
  teamId,
) async {
  return ref.watch(teamRepositoryProvider).fetchTeam(teamId);
});

/// The current user's followed teams (full Team objects).
final followedTeamsProvider = FutureProvider<List<Team>>((ref) async {
  final teamIds = ref.watch(followedTeamIdsProvider);
  if (teamIds.isEmpty) return [];
  return ref.watch(teamRepositoryProvider).fetchTeamsByIds(teamIds);
});

// ── Search ────────────────────────────────────────────────────────────────────

/// Search query state
final teamSearchQueryProvider = StateProvider.autoDispose<String>((ref) => '');

/// Active competition filter for search.
/// null = no active competition tab (used by the "Followed" tab).
final teamSearchCompetitionKeyProvider = StateProvider.autoDispose<String?>(
  (ref) => null,
);

/// Whether the search screen is scoped to the current user's followed teams.
final teamSearchFollowedOnlyProvider = StateProvider.autoDispose<bool>(
  (ref) => true,
);

/// Search results scoped to the current query and active competition tab.
final teamSearchResultsProvider = FutureProvider.autoDispose<List<Team>>((
  ref,
) async {
  final query = ref.watch(teamSearchQueryProvider);
  final followedOnly = ref.watch(teamSearchFollowedOnlyProvider);
  final competitionKey = ref.watch(teamSearchCompetitionKeyProvider);
  final repository = ref.watch(teamRepositoryProvider);

  if (followedOnly) {
    final teamIds = ref.watch(followedTeamIdsProvider);
    final teams = await repository.fetchTeamsByIds(teamIds);
    final normalizedQuery = _normalizeSearchText(query);
    if (normalizedQuery.isEmpty) return teams;
    return teams
        .where((team) => _teamSearchText(team).contains(normalizedQuery))
        .toList();
  }

  return repository.searchTeams(query, competitionKey: competitionKey);
});

String _teamSearchText(Team team) {
  return [
    team.id,
    team.nameEn,
    team.nameJa,
  ].map(_normalizeSearchText).join(' ');
}

String _normalizeSearchText(String value) {
  return value.toLowerCase().trim();
}
