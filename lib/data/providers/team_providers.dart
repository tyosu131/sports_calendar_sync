import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/sport.dart';
import '../../domain/models/team.dart';
import 'auth_providers.dart';
import 'repository_providers.dart';

// ── League providers ──────────────────────────────────────────────────────────

/// All leagues, optionally filtered by sport type.
final leaguesProvider =
    FutureProvider.family<List<League>, SportType?>((ref, sportType) async {
  return ref.watch(teamRepositoryProvider).fetchLeagues(sportType: sportType);
});

// ── Team providers ────────────────────────────────────────────────────────────

/// Teams for a specific league.
final teamsByLeagueProvider =
    FutureProvider.family<List<Team>, String>((ref, leagueId) async {
  return ref.watch(teamRepositoryProvider).fetchTeamsByLeague(leagueId);
});

/// A single team by ID.
final teamByIdProvider =
    FutureProvider.family<Team?, String>((ref, teamId) async {
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
final teamSearchQueryProvider = StateProvider<String>((ref) => '');

/// Search results based on current query
final teamSearchResultsProvider = FutureProvider<List<Team>>((ref) async {
  final query = ref.watch(teamSearchQueryProvider);
  if (query.isEmpty) return [];
  return ref.watch(teamRepositoryProvider).searchTeams(query);
});
