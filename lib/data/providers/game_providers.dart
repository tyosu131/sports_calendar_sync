import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/game.dart';
import '../../domain/models/team.dart';
import '../../domain/policies/japanese_domestic_football.dart';
import '../../domain/policies/team_presentation_policy.dart';
import 'auth_providers.dart';
import 'repository_providers.dart';

// ── Game providers ────────────────────────────────────────────────────────────

/// Upcoming games for an explicit set of team ids.
///
/// [teamIdsKey] is a unit-separator-joined, sorted id list from
/// [leagueTeamIdsKey]. The league team cards use one read for the whole list.
final upcomingGamesForTeamIdsProvider = FutureProvider.autoDispose
    .family<List<Game>, String>((ref, teamIdsKey) async {
      final ids = teamIdsKey
          .split('\u001f')
          .where((id) => id.isNotEmpty)
          .toList();
      if (ids.isEmpty) return const [];
      return ref.watch(gameRepositoryProvider).fetchUpcomingGamesForTeams(ids);
    });

/// Stable provider key for [upcomingGamesForTeamIdsProvider].
String leagueTeamIdsKey(Iterable<String> teamIds) {
  final ids = teamIds.toList()..sort();
  return ids.join('\u001f');
}

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
  final teamIds = await ref.watch(followedTeamIdsProvider.future);
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
  } on Exception {
    // Optional logo metadata. Network and decode failures stay empty so the
    // match list remains. Programmer errors are not Exception and propagate.
    return const [];
  }
});

final gamePresentationProvider =
    FutureProvider.family<TeamPresentationLogoResolver, List<Game>>((
      ref,
      games,
    ) async {
      final keys = <String>{};
      for (final game in games) {
        // Domestic name policy and this master lookup are the same set:
        // J1/J2/J3, the special, both domestic cups, and a future football_j*
        // key. Overseas clubs that share the Premier League master are a
        // different lookup and stay listed below.
        if (isJapaneseDomesticFootballCompetition(game.competitionKey)) {
          keys.addAll(const ['football_j1', 'football_j2', 'football_j3']);
        } else if (_premierClubMasterCompetitions.contains(
          game.competitionKey,
        )) {
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
        } on Exception {
          // Same optional-metadata boundary as presentationMasterProvider.
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

/// Overseas club competitions whose presentation master is the Premier
/// League team list. Not Japanese domestic football, and not a navigation
/// category.
const _premierClubMasterCompetitions = {
  'football_premier',
  'football_champions_league',
  'football_league_cup',
};

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
  final teamIds = await ref.watch(followedTeamIdsProvider.future);
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
