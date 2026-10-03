import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/sport.dart';
import '../../domain/models/team.dart';
import '../../domain/policies/home_sport_navigation.dart';
import '../services/sport_team_search.dart';
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

/// Teams for one SportsRegistry competition key.
///
/// Prefer readable competition-season membership when present. Otherwise fall
/// back to legacy team-master `competitionKey` queries (documented temporary).
final teamsByCompetitionProvider = FutureProvider.autoDispose
    .family<List<Team>, String>((ref, competitionKey) async {
      final listing = await ref
          .watch(competitionTeamListingServiceProvider)
          .listTeams(competitionKey);
      return listing.teams;
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

/// Active sport tab on team search. null = フォロー中 (cross-sport).
final teamSearchActiveSportTabIdProvider = StateProvider.autoDispose<String?>(
  (ref) => null,
);

/// Search results scoped to the current query and active sport tab.
///
/// Sport-home discovery queries each enabled registry competition for that
/// sport, then merges by team id. That is a temporary compatibility path, not
/// canonical season membership. Do not call `searchTeams` with a null
/// competition key here: the unscoped path is capped at the default page size
/// across every sport.
final teamSearchResultsProvider = FutureProvider.autoDispose<List<Team>>((
  ref,
) async {
  final query = ref.watch(teamSearchQueryProvider);
  final activeSportTabId = ref.watch(teamSearchActiveSportTabIdProvider);
  final repository = ref.watch(teamRepositoryProvider);

  if (activeSportTabId == null) {
    final teamIds = ref.watch(followedTeamIdsProvider);
    final teams = await repository.fetchTeamsByIds(teamIds);
    final normalizedQuery = _normalizeSearchText(query);
    if (normalizedQuery.isEmpty) return teams;
    return teams
        .where((team) => _teamSearchText(team).contains(normalizedQuery))
        .toList();
  }

  final sportTab = followDiscoverySportTabs().firstWhere(
    (tab) => tab.id == activeSportTabId,
    orElse: () => throw StateError('Unknown sport tab: $activeSportTabId'),
  );
  return searchTeamsForSportTab(
    repository: repository,
    tab: sportTab,
    query: query,
  );
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
