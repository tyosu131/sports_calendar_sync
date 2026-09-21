import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/game.dart';
import '../../domain/models/team.dart';
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

/// Home games plus a bounded canonical Team-logo lookup shared by every card.
final homeUpcomingGamesProvider = FutureProvider<HomeUpcomingGames>((ref) async {
  final games = await ref.watch(upcomingGamesForFollowedTeamsProvider.future);
  final logoUrls = await fetchCanonicalTeamLogoUrls(
    games,
    ref.watch(teamRepositoryProvider).fetchTeamsByIds,
  );
  return HomeUpcomingGames(games: games, canonicalLogoUrls: logoUrls);
});

class HomeUpcomingGames {
  const HomeUpcomingGames({
    required this.games,
    required this.canonicalLogoUrls,
  });

  final List<Game> games;
  final Map<String, String> canonicalLogoUrls;
}

/// Resolves all distinct canonical identities in one repository call. A game
/// without a canonical ID is deliberately ignored rather than name-matched.
Future<Map<String, String>> fetchCanonicalTeamLogoUrls(
  List<Game> games,
  Future<List<Team>> Function(List<String>) fetchTeamsByIds,
) async {
  final ids = <String>{};
  for (final game in games) {
    final homeTeamId = game.homeTeamId;
    final awayTeamId = game.awayTeamId;
    if (homeTeamId != null) ids.add(homeTeamId);
    if (awayTeamId != null) ids.add(awayTeamId);
  }
  if (ids.isEmpty) return const {};

  final teams = await fetchTeamsByIds(ids.toList(growable: false));
  final logoUrls = <String, String>{};
  for (final team in teams) {
    final logoUrl = team.logoUrl;
    if (logoUrl != null && logoUrl.isNotEmpty) logoUrls[team.id] = logoUrl;
  }
  return logoUrls;
}

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
