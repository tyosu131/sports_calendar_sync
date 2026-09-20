import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sports_calendar_sync/domain/models/game.dart';
import 'package:sports_calendar_sync/domain/policies/competition_display_policy.dart';
import 'package:sports_calendar_sync/presentation/screens/schedule_screen.dart';
import 'package:sports_calendar_sync/presentation/widgets/game_card.dart';

Game _emperorCupGame() => Game(
      id: 'competition-game',
      leagueId: 'emperor_cup',
      competitionKey: 'football_emperor_cup',
      competitionSeasonKey: 'football_emperor_cup_2026',
      homeTeamId: 'kawasaki_frontale',
      homeTeamNameJa: '川崎フロンターレ',
      homeTeamNameEn: 'Kawasaki Frontale',
      homeTeamProviderName: 'Kawasaki Frontale',
      awayTeamNameJa: '鹿島アントラーズ',
      awayTeamNameEn: 'Kashima Antlers',
      awayTeamProviderName: 'Kashima Antlers',
      startTimeUtc: Timestamp.fromDate(DateTime.utc(2026, 9, 19, 9)),
      startTimeJst: '2026-09-19 18:00',
      timezone: 'UTC',
      status: GameStatus.scheduled,
    );

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ja');
  });

  test('catalog covers every V1 competition with full and compact labels', () {
    const expected = {
      'football_j1': ('J1リーグ', 'J1 League', 'J1'),
      'football_j_league_cup': (
        'ルヴァンカップ',
        'J.League Cup',
        'ルヴァン',
      ),
      'football_emperor_cup': ('天皇杯', "Emperor's Cup", '天皇杯'),
      'football_premier': ('プレミアリーグ', 'Premier League', 'PL'),
      'football_champions_league': (
        'UEFAチャンピオンズリーグ',
        'Champions League',
        'UCL',
      ),
      'football_league_cup': ('リーグカップ', 'League Cup', 'EFL Cup'),
    };
    for (final entry in expected.entries) {
      final display = CompetitionDisplayPolicy.forKey(entry.key)!;
      expect((display.nameJa, display.nameEn, display.compact), entry.value);
    }
  });

  testWidgets('home GameCard shows competition identity', (tester) async {
    final value = _emperorCupGame();
    expect(value.competitionKey, 'football_emperor_cup');
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: GameCard(game: value))),
    );
    expect(find.text('天皇杯'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('selected-date ScheduleGameTile shows competition identity', (
    tester,
  ) async {
    final value = _emperorCupGame();
    expect(value.competitionKey, 'football_emperor_cup');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ScheduleGameTile(game: value)),
      ),
    );
    expect(find.text('天皇杯'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
