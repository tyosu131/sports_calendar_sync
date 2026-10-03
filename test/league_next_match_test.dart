import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sports_calendar_sync/domain/models/game.dart';
import 'package:sports_calendar_sync/domain/models/team.dart';
import 'package:sports_calendar_sync/domain/policies/league_browse_presentation.dart';

Team _arsenal() {
  return const Team(
    id: 'arsenal',
    nameEn: 'Arsenal',
    nameJa: 'アーセナル',
    leagueId: 'premier',
    competitionKey: 'football_premier',
  );
}

Game _game({
  required String id,
  required String competitionKey,
  required DateTime start,
}) {
  return Game(
    id: id,
    leagueId: 'league',
    competitionKey: competitionKey,
    homeTeamId: 'arsenal',
    homeTeamNameJa: 'アーセナル',
    homeTeamNameEn: 'Arsenal',
    awayTeamId: 'opponent',
    awayTeamNameJa: '対戦相手',
    awayTeamNameEn: 'Opponent',
    startTimeUtc: Timestamp.fromDate(start),
    startTimeJst: '2026-10-01 19:00',
    timezone: 'Asia/Tokyo',
    status: GameStatus.scheduled,
  );
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ja');
  });

  test('next match respects league competition context', () {
    final team = _arsenal();
    final games = [
      _game(
        id: 'ucl',
        competitionKey: 'football_champions_league',
        start: DateTime.utc(2026, 10, 5, 19),
      ),
      _game(
        id: 'pl',
        competitionKey: 'football_premier',
        start: DateTime.utc(2026, 10, 12, 19),
      ),
    ];

    final premier = nextMatchForTeam(
      team,
      games,
      competitionContextKey: 'football_premier',
    );
    expect(premier, isNotNull);
    expect(premier!.opponent, contains('vs'));

    final ucl = nextMatchForTeam(
      team,
      games,
      competitionContextKey: 'football_champions_league',
    );
    expect(ucl, isNotNull);
    expect(ucl!.when, isNot(premier.when));
  });
}
