import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sports_calendar_sync/domain/models/game.dart';
import 'package:sports_calendar_sync/domain/models/team.dart';
import 'package:sports_calendar_sync/domain/policies/team_presentation_policy.dart';
import 'package:sports_calendar_sync/presentation/widgets/game_card.dart';
import 'package:sports_calendar_sync/presentation/widgets/game_presentation_scope.dart';

Team _team(String id, String name, {String? color}) => Team(
  id: id,
  nameEn: name,
  nameJa: name,
  leagueId: 'nfl',
  competitionKey: 'americanfootball_nfl',
  presentationColor: color,
);

Game _game() => Game(
  id: 'g',
  leagueId: 'nfl',
  competitionKey: 'americanfootball_nfl',
  homeTeamId: 'tsdb_team_1',
  homeTeamNameJa: 'Cincinnati Bengals',
  homeTeamNameEn: 'Cincinnati Bengals',
  awayTeamId: 'tsdb_team_2',
  awayTeamNameJa: 'Pittsburgh Steelers',
  awayTeamNameEn: 'Pittsburgh Steelers',
  startTimeUtc: Timestamp.fromDate(DateTime.utc(2026, 11, 16, 1, 20)),
  startTimeJst: '',
  timezone: 'UTC',
  status: GameStatus.scheduled,
);

void main() {
  setUpAll(() async => initializeDateFormatting('ja'));

  test('side color comes only from the canonical team', () {
    final resolver = TeamPresentationLogoResolver([
      _team('tsdb_team_1', 'Cincinnati Bengals', color: '#FB4F14'),
      _team('tsdb_team_2', 'Pittsburgh Steelers'),
    ]);
    expect(resolver.sideColor(_game(), true), const Color(0xFFFB4F14));
    expect(resolver.sideColor(_game(), false), isNull);
    expect(
      TeamPresentationLogoResolver(const []).sideColor(_game(), true),
      isNull,
    );
  });

  testWidgets('game card circle uses the team color; no chevron is drawn', (
    tester,
  ) async {
    final resolver = TeamPresentationLogoResolver([
      _team('tsdb_team_1', 'Cincinnati Bengals', color: '#FB4F14'),
      _team('tsdb_team_2', 'Pittsburgh Steelers'),
    ]);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: GamePresentationScope(
              resolver: resolver,
              child: GameCard(game: _game()),
            ),
          ),
        ),
      ),
    );
    final avatars = tester
        .widgetList<CircleAvatar>(find.byType(CircleAvatar))
        .map((avatar) => avatar.backgroundColor)
        .toList();
    expect(avatars.first, const Color(0xFFFB4F14));
    expect(avatars.last, isNot(const Color(0xFFFB4F14)));
    expect(tester.takeException(), isNull);
  });
}
