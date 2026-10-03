import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sports_calendar_sync/domain/models/game.dart';
import 'package:sports_calendar_sync/presentation/screens/schedule_screen.dart';

Game makeGame(
  String id,
  int hour, {
  GameStatus status = GameStatus.scheduled,
  int? homeScore,
  int? awayScore,
}) => Game(
  id: id,
  competitionKey: 'football_premier',
  leagueId: 'premier',
  homeTeamNameJa: 'アーセナル',
  homeTeamNameEn: 'Arsenal',
  awayTeamNameJa: 'ブライトン',
  awayTeamNameEn: 'Brighton & Hove Albion',
  startTimeUtc: Timestamp.fromDate(DateTime.utc(2026, 9, 19, hour)),
  startTimeJst: '2026-09-19',
  timezone: 'UTC',
  status: status,
  homeScore: homeScore,
  awayScore: awayScore,
);

Future<void> pumpCalendar(
  WidgetTester tester,
  Size size,
  List<Game> games,
) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final date = DateTime(2026, 9, 19);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ScheduleMonthCalendar(
          visibleMonth: DateTime(2026, 9),
          minMonth: DateTime(2026, 9),
          maxMonth: DateTime(2026, 9),
          selectedDate: null,
          gamesByDate: {date: games},
          onDateSelected: (_) {},
          onMonthChanged: (_) {},
        ),
      ),
    ),
  );
  expect(tester.takeException(), isNull);
}

void main() {
  testWidgets('iPhone portrait one-game date communicates matchup and time', (
    tester,
  ) async {
    await pumpCalendar(tester, const Size(390, 844), [makeGame('one', 9)]);
    expect(find.byKey(const ValueKey('compact-game-one')), findsOneWidget);
    expect(find.textContaining('18:00'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('iPhone portrait shows both same-day games without overflow', (
    tester,
  ) async {
    await pumpCalendar(tester, const Size(390, 844), [
      makeGame('one', 9),
      makeGame('two', 14),
    ]);
    expect(find.byKey(const ValueKey('compact-game-one')), findsOneWidget);
    expect(find.byKey(const ValueKey('compact-game-two')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('iPhone portrait bounds three games with a remainder', (
    tester,
  ) async {
    await pumpCalendar(tester, const Size(390, 844), [
      makeGame('one', 9),
      makeGame('two', 14),
      makeGame('three', 17),
    ]);
    expect(find.byKey(const ValueKey('compact-more-games')), findsOneWidget);
    expect(find.text('+1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('wide calendar keeps rich preview', (tester) async {
    await pumpCalendar(tester, const Size(1200, 900), [makeGame('wide', 9)]);
    expect(find.text('vs'), findsOneWidget);
    expect(find.byKey(const ValueKey('compact-game-wide')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('compact finished game shows its authoritative score', (
    tester,
  ) async {
    await pumpCalendar(tester, const Size(390, 844), [
      makeGame(
        'scored',
        9,
        status: GameStatus.finished,
        homeScore: 3,
        awayScore: 0,
      ),
    ]);
    expect(find.text('3-0'), findsOneWidget);
    expect(find.text('終了'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('compact finished game without score keeps finished label', (
    tester,
  ) async {
    await pumpCalendar(tester, const Size(390, 844), [
      makeGame('unscored', 9, status: GameStatus.finished),
    ]);
    expect(find.text('終了'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('compact labels use the full display name', (tester) async {
    await pumpCalendar(tester, const Size(390, 844), [
      Game(
        id: 'frontale',
        competitionKey: 'football_j1',
        leagueId: 'j1',
        homeTeamNameJa: '川崎フロンターレ',
        homeTeamNameEn: 'Kawasaki Frontale',
        awayTeamNameJa: '浦和レッズ',
        awayTeamNameEn: 'Urawa Reds',
        startTimeUtc: Timestamp.fromDate(DateTime.utc(2026, 9, 19, 10)),
        startTimeJst: '2026-09-19',
        timezone: 'UTC',
        status: GameStatus.scheduled,
      ),
    ]);
    final frontale = tester.widget<Text>(find.text('川崎フロンターレ/浦和レッズ'));
    expect(frontale.maxLines, 1);
    expect(frontale.overflow, TextOverflow.ellipsis);
    expect(find.text('川崎/浦和'), findsNothing);
    expect(find.text('川/浦'), findsNothing);
    expect(find.text('川崎F'), findsNothing);

    await pumpCalendar(tester, const Size(390, 844), [
      Game(
        id: 'giants',
        competitionKey: 'baseball_npb',
        leagueId: 'npb',
        homeTeamNameJa: '読売ジャイアンツ',
        homeTeamNameEn: 'Yomiuri Giants',
        awayTeamNameJa: '阪神タイガース',
        awayTeamNameEn: 'Hanshin Tigers',
        startTimeUtc: Timestamp.fromDate(DateTime.utc(2026, 9, 19, 10)),
        startTimeJst: '2026-09-19',
        timezone: 'UTC',
        status: GameStatus.scheduled,
      ),
    ]);
    final marker = tester.widget<Text>(
      find.text('Yomiuri Giants/Hanshin Tigers'),
    );
    expect(marker.maxLines, 1);
    expect(marker.overflow, TextOverflow.ellipsis);
    expect(find.text('Y/H'), findsNothing);
    expect(find.text('Giants/Tigers'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('compact finished game preserves a nil-nil score', (
    tester,
  ) async {
    await pumpCalendar(tester, const Size(390, 844), [
      makeGame(
        'draw',
        9,
        status: GameStatus.finished,
        homeScore: 0,
        awayScore: 0,
      ),
    ]);
    expect(find.text('0-0'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
