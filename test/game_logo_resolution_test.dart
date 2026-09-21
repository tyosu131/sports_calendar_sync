import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sports_calendar_sync/data/providers/game_providers.dart';
import 'package:sports_calendar_sync/domain/models/game.dart';
import 'package:sports_calendar_sync/domain/models/team.dart';
import 'package:sports_calendar_sync/presentation/widgets/game_card.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ja');
  });

  test('game-level logo wins over canonical Team fallback', () {
    expect(
      resolveGameTeamLogoUrl('https://game/logo.png', 'https://team/logo.png'),
      'https://game/logo.png',
    );
  });

  test('canonical Team logo fills an absent game-level logo', () {
    expect(
      resolveGameTeamLogoUrl(null, 'https://team/logo.png'),
      'https://team/logo.png',
    );
  });

  testWidgets('GameCard displays the canonical Team logo fallback', (
    tester,
  ) async {
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

    final image = tester.widget<Image>(find.byType(Image));
    expect((image.image as NetworkImage).url, 'https://team/known.png');
  });

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

  test('unknown identity remains without a guessed logo', () async {
    final calls = <List<String>>[];
    final logos = await fetchCanonicalTeamLogoUrls(
      [_game(homeTeamId: null, awayTeamId: null)],
      (ids) async {
        calls.add(ids);
        return const [];
      },
    );

    expect(logos, isEmpty);
    expect(calls, isEmpty);
    expect(resolveGameTeamLogoUrl(null, logos['provider-name']), isNull);
  });

  test('repeated IDs are resolved in one distinct batched fetch', () async {
    final calls = <List<String>>[];
    final games = [
      _game(homeTeamId: 'kawasaki_frontale', awayTeamId: null),
      _game(homeTeamId: 'kawasaki_frontale', awayTeamId: 'arsenal'),
    ];

    final logos = await fetchCanonicalTeamLogoUrls(games, (ids) async {
      calls.add(ids);
      return const [
        Team(
          id: 'kawasaki_frontale',
          nameEn: 'Kawasaki Frontale',
          nameJa: '川崎フロンターレ',
          leagueId: 'j1',
          logoUrl: 'https://team/kawasaki.png',
        ),
        Team(
          id: 'arsenal',
          nameEn: 'Arsenal',
          nameJa: 'アーセナル',
          leagueId: 'premier',
          logoUrl: 'https://team/arsenal.png',
        ),
      ];
    });

    expect(calls, hasLength(1));
    expect(calls.single.toSet(), {'kawasaki_frontale', 'arsenal'});
    expect(logos['kawasaki_frontale'], 'https://team/kawasaki.png');
    expect(logos['arsenal'], 'https://team/arsenal.png');
  });
}

Game _game({required String? homeTeamId, required String? awayTeamId}) => Game(
      id: 'game',
      leagueId: 'league',
      homeTeamId: homeTeamId,
      homeTeamNameJa: 'ホーム',
      awayTeamId: awayTeamId,
      awayTeamNameJa: 'アウェー',
      startTimeUtc: Timestamp.fromMillisecondsSinceEpoch(0),
      startTimeJst: '1970-01-01 09:00',
      timezone: 'UTC',
      status: GameStatus.scheduled,
    );
