import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sports_calendar_sync/data/providers/game_providers.dart';
import 'package:sports_calendar_sync/domain/models/game.dart';
import 'package:sports_calendar_sync/domain/models/team.dart';
import 'package:sports_calendar_sync/domain/policies/japanese_club_display_evidence.dart';
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

  test('confirmed English and exact Japanese J1 names resolve master logos', () {
    final resolver = J1PresentationLogoResolver(const [
      Team(
        id: 'kashima-master',
        nameEn: 'Kashima Antlers',
        nameJa: '鹿島アントラーズ',
        leagueId: 'j1',
        logoUrl: 'https://team/kashima.png',
      ),
    ]);

    expect(
      resolver.resolve(
        competitionKey: 'football_j1',
        names: const ['Kashima Antlers'],
      ),
      'https://team/kashima.png',
    );
    expect(
      resolver.resolve(
        competitionKey: 'football_j1',
        names: const ['鹿島アントラーズ'],
      ),
      'https://team/kashima.png',
    );
  });

  test('unknown, partial, non-J1, conflicting, and missing logos resolve null', () {
    final resolver = J1PresentationLogoResolver(const [
      Team(
        id: 'kashima',
        nameEn: 'Kashima Antlers',
        nameJa: '鹿島アントラーズ',
        leagueId: 'j1',
        logoUrl: 'https://team/kashima.png',
      ),
      Team(
        id: 'urawa',
        nameEn: 'Urawa Reds',
        nameJa: '浦和レッズ',
        leagueId: 'j1',
      ),
    ]);

    expect(resolver.resolve(competitionKey: 'football_j1', names: const ['Unknown']), isNull);
    expect(resolver.resolve(competitionKey: 'football_j1', names: const ['Kashima Ant']), isNull);
    expect(resolver.resolve(competitionKey: 'football_j2', names: const ['Kashima Antlers']), isNull);
    expect(
      resolver.resolve(
        competitionKey: 'football_j1',
        names: const ['Kashima Antlers', 'Urawa Reds'],
      ),
      isNull,
    );
    expect(resolver.resolve(competitionKey: 'football_j1', names: const ['Urawa Reds']), isNull);
  });

  test('ambiguous evidence and non-unique Japanese master names resolve null', () {
    expect(
      uniqueConfirmedJapaneseClubName(
        'Collision',
        evidence: const {
          'collision': {'鹿島アントラーズ', '浦和レッズ'},
        },
      ),
      isNull,
    );
    final resolver = J1PresentationLogoResolver(const [
      Team(id: 'one', nameEn: 'Kashima', nameJa: '鹿島アントラーズ', leagueId: 'j1', logoUrl: 'one'),
      Team(id: 'two', nameEn: 'Kashima', nameJa: '鹿島アントラーズ', leagueId: 'j1', logoUrl: 'two'),
    ]);
    expect(resolver.resolve(competitionKey: 'football_j1', names: const ['Kashima Antlers']), isNull);
  });

  test('home enrichment batches canonical IDs and fetches J1 master once', () async {
    var canonicalReads = 0;
    var j1Reads = 0;
    final games = [
      _game(
        id: 'one',
        competitionKey: 'football_j1',
        homeTeamId: 'kawasaki_frontale',
        awayTeamId: null,
        awayNameJa: 'Kashima Antlers',
        awayProviderName: 'Kashima Antlers',
        homeSourceTeamId: 'goal-kawasaki',
        awaySourceTeamId: 'goal-kashima',
      ),
      _game(
        id: 'two',
        competitionKey: 'football_j1',
        homeTeamId: 'kawasaki_frontale',
        awayTeamId: null,
        awayNameJa: 'Unknown FC',
      ),
    ];
    final beforeIds = games
        .map((game) => [game.homeTeamId, game.awayTeamId, game.homeSourceTeamId, game.awaySourceTeamId])
        .toList();

    final result = await fetchHomeGameLogoFallbacks(games, (ids) async {
      canonicalReads++;
      expect(ids.toSet(), {'kawasaki_frontale'});
      return const [
        Team(id: 'kawasaki_frontale', nameEn: 'Kawasaki', nameJa: '川崎フロンターレ', leagueId: 'j1', logoUrl: 'https://team/kawasaki.png'),
      ];
    }, () async {
      j1Reads++;
      return const [
        Team(id: 'kashima', nameEn: 'Kashima', nameJa: '鹿島アントラーズ', leagueId: 'j1', logoUrl: 'https://team/kashima.png'),
      ];
    });

    expect(canonicalReads, 1);
    expect(j1Reads, 1);
    expect(result['one']?.home, 'https://team/kawasaki.png');
    expect(result['one']?.away, 'https://team/kashima.png');
    expect(result['two']?.away, isNull);
    expect(
      games.map((game) => [game.homeTeamId, game.awayTeamId, game.homeSourceTeamId, game.awaySourceTeamId]).toList(),
      beforeIds,
    );
  });

  test('fully resolved game logos avoid the J1 master read', () async {
    var j1Reads = 0;
    final result = await fetchHomeGameLogoFallbacks(
      [
        _game(
          id: 'resolved',
          competitionKey: 'football_j1',
          homeTeamId: null,
          awayTeamId: null,
          homeLogoUrl: 'https://game/home.png',
          awayLogoUrl: 'https://game/away.png',
        ),
      ],
      (_) async => const [],
      () async { j1Reads++; return const []; },
    );
    expect(j1Reads, 0);
    expect(result['resolved'], isNotNull);
  });

  test('logo lookup failure preserves loaded games with null fallback', () async {
    final result = await fetchHomeGameLogoFallbacks(
      [_game(id: 'game', competitionKey: 'football_j1', homeTeamId: null, awayTeamId: null)],
      (_) async => throw StateError('canonical unavailable'),
      () async => throw StateError('master unavailable'),
    );
    expect(result['game']?.home, isNull);
    expect(result['game']?.away, isNull);
  });
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
