import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/game.dart';
import '../../domain/models/team.dart';
import '../../domain/policies/japanese_club_display_evidence.dart';
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
final homeUpcomingGamesProvider = FutureProvider<HomeUpcomingGames>((ref) async {
  final games = await ref.watch(upcomingGamesForFollowedTeamsProvider.future);
  final repository = ref.watch(teamRepositoryProvider);
  final logoFallbacks = await fetchHomeGameLogoFallbacks(
    games,
    repository.fetchTeamsByIds,
    () => repository.fetchTeams(competitionKey: 'football_j1'),
  );
  return HomeUpcomingGames(games: games, logoFallbacks: logoFallbacks);
});

class HomeUpcomingGames {
  const HomeUpcomingGames({
    required this.games,
    required this.logoFallbacks,
  });

  final List<Game> games;
  final Map<String, HomeGameLogoFallback> logoFallbacks;
}

class HomeGameLogoFallback {
  const HomeGameLogoFallback({this.home, this.away});

  final String? home;
  final String? away;
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

/// Enriches Home presentation without changing any Game identity fields.
/// Canonical IDs are fetched in one batch; the J1 master is fetched at most
/// once and only when a J1 side still lacks both game and canonical logos.
Future<Map<String, HomeGameLogoFallback>> fetchHomeGameLogoFallbacks(
  List<Game> games,
  Future<List<Team>> Function(List<String>) fetchTeamsByIds,
  Future<List<Team>> Function() fetchJ1Teams,
) async {
  Map<String, String> canonical = const {};
  try {
    canonical = await fetchCanonicalTeamLogoUrls(games, fetchTeamsByIds);
  } catch (_) {
    // Games are already loaded; optional logo metadata must not hide the feed.
  }

  bool needsJ1(Game game, bool home) {
    if (game.competitionKey != 'football_j1') return false;
    final gameLogo = home ? game.homeTeamLogoUrl : game.awayTeamLogoUrl;
    final id = home ? game.homeTeamId : game.awayTeamId;
    return !_hasLogo(gameLogo) && !_hasLogo(id == null ? null : canonical[id]);
  }

  final shouldFetchJ1 = games.any(
    (game) => needsJ1(game, true) || needsJ1(game, false),
  );
  List<Team> j1Teams = const [];
  if (shouldFetchJ1) {
    try {
      j1Teams = await fetchJ1Teams();
    } catch (_) {
      // Presentation-only enrichment degrades to the existing initials UI.
    }
  }
  final resolver = J1PresentationLogoResolver(j1Teams);

  return {
    for (final game in games)
      game.id: HomeGameLogoFallback(
        home: _sideFallback(game, true, canonical, resolver),
        away: _sideFallback(game, false, canonical, resolver),
      ),
  };
}

String? _sideFallback(
  Game game,
  bool home,
  Map<String, String> canonical,
  J1PresentationLogoResolver resolver,
) {
  final id = home ? game.homeTeamId : game.awayTeamId;
  final canonicalLogo = id == null ? null : canonical[id];
  if (_hasLogo(canonicalLogo)) return canonicalLogo;
  return resolver.resolve(
    competitionKey: game.competitionKey,
    names: home
        ? [game.homeTeamNameEn, game.homeTeamProviderName, game.homeTeamNameJa]
        : [game.awayTeamNameEn, game.awayTeamProviderName, game.awayTeamNameJa],
  );
}

bool _hasLogo(String? value) => value != null && value.isNotEmpty;

/// Pure presentation resolver: confirmed alias -> unique exact Japanese master
/// name -> one non-empty logo. It never returns or assigns a Team ID.
class J1PresentationLogoResolver {
  J1PresentationLogoResolver(List<Team> teams) {
    for (final team in teams) {
      final name = team.nameJa.trim();
      _teamsByJapaneseName.putIfAbsent(name, () => []).add(team);
    }
  }

  final Map<String, List<Team>> _teamsByJapaneseName = {};

  String? resolve({required String? competitionKey, required List<String?> names}) {
    if (competitionKey != 'football_j1') return null;
    final confirmedNames = <String>{};
    for (final value in names) {
      if (value == null) continue;
      final confirmed = uniqueConfirmedJapaneseClubName(value);
      if (confirmed != null) confirmedNames.add(confirmed);
    }
    if (confirmedNames.length != 1) return null;
    final teams = _teamsByJapaneseName[confirmedNames.single];
    if (teams == null || teams.length != 1) return null;
    final logo = teams.single.logoUrl;
    return _hasLogo(logo) ? logo : null;
  }
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
