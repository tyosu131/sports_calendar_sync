import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/game.dart';
import 'auth_providers.dart';
import 'repository_providers.dart';

// ── Game providers ────────────────────────────────────────────────────────────

/// Upcoming games for a specific team.
final upcomingGamesForTeamProvider = FutureProvider.family<List<Game>, String>((
  ref,
  teamId,
) async {
  return ref.watch(gameRepositoryProvider).fetchUpcomingGamesForTeam(teamId);
});

/// Stream of upcoming games for a team (real-time).
final gamesStreamForTeamProvider = StreamProvider.family<List<Game>, String>((
  ref,
  teamId,
) {
  return ref.watch(gameRepositoryProvider).watchUpcomingGamesForTeam(teamId);
});

/// Upcoming games for ALL of the user's followed teams (home screen feed).
final upcomingGamesForFollowedTeamsProvider = FutureProvider<List<Game>>((
  ref,
) async {
  final teamIds = ref.watch(followedTeamIdsProvider);
  if (teamIds.isEmpty) return [];
  return ref.watch(gameRepositoryProvider).fetchUpcomingGamesForTeams(teamIds);
});

/// Schedule games for ALL of the user's followed teams.
///
/// Unlike the home feed, this provider is intended for calendar/schedule UI and
/// may include past, live, finished, postponed, cancelled, and future games.
final scheduleGamesForFollowedTeamsProvider = FutureProvider<List<Game>>((
  ref,
) async {
  final teamIds = ref.watch(followedTeamIdsProvider);
  if (teamIds.isEmpty) return [];
  return ref.watch(gameRepositoryProvider).fetchScheduleGamesForTeams(teamIds);
});

/// A single game by ID.
final gameByIdProvider = FutureProvider.family<Game?, String>((
  ref,
  gameId,
) async {
  return ref.watch(gameRepositoryProvider).fetchGame(gameId);
});
