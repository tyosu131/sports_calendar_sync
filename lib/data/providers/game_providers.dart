import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/game.dart';
import '../../domain/models/team.dart';
import '../../domain/policies/team_presentation_policy.dart';
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

/// Home games plus bounded canonical and presentation-only logo enrichment.
final homeUpcomingGamesProvider = FutureProvider<HomeUpcomingGames>((
  ref,
) async {
  final games = await ref.watch(upcomingGamesForFollowedTeamsProvider.future);
  final resolver = await ref.watch(gamePresentationProvider(games).future);
  return HomeUpcomingGames(games: games, presentation: resolver);
});

/// Shared by Home, Schedule and Team detail. Each master is fetched once per
/// provider lifetime, independent of the number of games/cards/screens.
final presentationMasterProvider = FutureProvider.family<List<Team>, String>((
  ref,
  key,
) async {
  try {
    return await ref
        .watch(teamRepositoryProvider)
        .fetchTeams(competitionKey: key);
  } catch (_) {
    return const []; // Optional metadata must not suppress the schedule.
  }
});

final gamePresentationProvider =
    FutureProvider.family<TeamPresentationLogoResolver, List<Game>>((
      ref,
      games,
    ) async {
      final keys = <String>{};
      for (final game in games) {
        if (const {
          'football_j1',
          'football_j_league_cup',
          'football_emperor_cup',
        }.contains(game.competitionKey)) {
          keys.addAll(['football_j1', 'football_j2', 'football_j3']);
        } else if (const {
          'football_premier',
          'football_champions_league',
          'football_league_cup',
        }.contains(game.competitionKey)) {
          keys.add('football_premier');
        }
      }
      final masterFutures = [
        for (final key in keys)
          ref.watch(presentationMasterProvider(key).future),
      ];
      final ids = {
        for (final game in games) ...[game.homeTeamId, game.awayTeamId],
      }.whereType<String>().toList();
      List<Team> canonical = const [];
      if (ids.isNotEmpty) {
        try {
          canonical = await ref
              .watch(teamRepositoryProvider)
              .fetchTeamsByIds(ids);
        } catch (_) {
          /* Keep the games and use reviewed static presentation data. */
        }
      }
      final masters = await Future.wait(masterFutures);
      return TeamPresentationLogoResolver([
        ...{
          for (final team in [
            ...masters.expand((value) => value),
            ...canonical,
          ])
            team.id: team,
        }.values,
      ]);
    });

class HomeUpcomingGames {
  const HomeUpcomingGames({required this.games, required this.presentation});

  final List<Game> games;
  final TeamPresentationLogoResolver presentation;
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
