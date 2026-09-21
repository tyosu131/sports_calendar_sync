import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sports_calendar_sync/domain/models/game.dart';
import 'package:sports_calendar_sync/domain/models/team.dart';
import 'package:sports_calendar_sync/domain/policies/team_presentation_policy.dart';
import 'package:sports_calendar_sync/presentation/widgets/game_card.dart';
import 'package:sports_calendar_sync/presentation/widgets/game_presentation_scope.dart';
import 'package:sports_calendar_sync/presentation/widgets/team_list_tile.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ja');
  });

  test(
    'unverified game-level and canonical assets cannot bypass public rights',
    () {
      expect(
        resolveGameTeamLogoUrl(
          'https://game/logo.png',
          'https://team/logo.png',
        ),
        isNull,
      );
    },
  );

  test('unverified canonical assets also use neutral fallback', () {
    expect(resolveGameTeamLogoUrl(null, 'https://team/logo.png'), isNull);
  });

  testWidgets(
    'GameCard blocks unverified canonical logo before creating any Image',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GameCard(
              game: _game(homeTeamId: 'known', awayTeamId: null),
              homeTeamLogoUrlFallback: 'https://team/known.png',
            ),
          ),
        ),
      );

      expect(find.byType(Image), findsNothing);
      expect(find.text('ホ'), findsOneWidget);
    },
  );

  testWidgets('GameCard keeps fallback UI for an opponent without identity', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GameCard(game: _game(homeTeamId: null, awayTeamId: null)),
        ),
      ),
    );

    expect(find.byType(Image), findsNothing);
    expect(find.text('ホ'), findsOneWidget);
    expect(find.text('ア'), findsOneWidget);
  });

  testWidgets(
    'Home and Search agree on JEF name and neutral fallback without logo rights',
    (tester) async {
      const team = Team(
        id: 'jef_united_chiba',
        nameEn: 'JEF United Chiba',
        nameJa: 'ジェフユナイテッド千葉',
        leagueId: 'j1_league',
        competitionKey: 'football_j1',
        logoUrl: 'https://master/jef.png',
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GamePresentationScope(
              resolver: TeamPresentationLogoResolver([team]),
              child: Column(
                children: [
                  TeamListTile(
                    team: team,
                    isFollowing: false,
                    onFollowToggle: () {},
                  ),
                  GameCard(
                    game: _game(
                      homeTeamId: null,
                      awayTeamId: null,
                      competitionKey: 'football_j1',
                      homeNameJa: 'JEF United',
                      homeProviderName: 'JEF United',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      expect(find.text('ジェフユナイテッド千葉'), findsNWidgets(2));
      expect(find.text('JEF United'), findsNothing);
      expect(find.byType(Image), findsNothing);
      expect(find.text('ジ'), findsNWidgets(2));
    },
  );

  testWidgets(
    'screen-level ambiguity does not get bypassed by catalog fallback',
    (tester) async {
      const team = Team(
        id: 'one',
        nameEn: 'Fulham',
        nameJa: 'フラム',
        leagueId: 'premier',
        competitionKey: 'football_premier',
        logoUrl: 'https://master/one.png',
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GamePresentationScope(
              resolver: TeamPresentationLogoResolver([
                team,
                team.copyWith(id: 'two'),
              ]),
              child: GameCard(
                game: _game(
                  homeTeamId: null,
                  awayTeamId: null,
                  competitionKey: 'football_premier',
                  homeNameJa: 'Fulham',
                ),
              ),
            ),
          ),
        ),
      );
      expect(find.byType(Image), findsNothing);
    },
  );
}

Game _game({
  String id = 'game',
  required String? homeTeamId,
  required String? awayTeamId,
  String? competitionKey,
  String homeNameJa = 'ホーム',
  String awayNameJa = 'アウェー',
  String? homeProviderName,
  String? awayProviderName,
  String? homeSourceTeamId,
  String? awaySourceTeamId,
  String? homeLogoUrl,
  String? awayLogoUrl,
}) => Game(
  id: id,
  leagueId: 'league',
  competitionKey: competitionKey,
  homeTeamId: homeTeamId,
  homeSourceTeamId: homeSourceTeamId,
  homeTeamNameJa: homeNameJa,
  homeTeamProviderName: homeProviderName,
  homeTeamLogoUrl: homeLogoUrl,
  awayTeamId: awayTeamId,
  awaySourceTeamId: awaySourceTeamId,
  awayTeamNameJa: awayNameJa,
  awayTeamProviderName: awayProviderName,
  awayTeamLogoUrl: awayLogoUrl,
  startTimeUtc: Timestamp.fromMillisecondsSinceEpoch(0),
  startTimeJst: '1970-01-01 09:00',
  timezone: 'UTC',
  status: GameStatus.scheduled,
);
