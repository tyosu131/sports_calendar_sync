import 'dart:io';
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sports_calendar_sync/data/providers/auth_providers.dart';
import 'package:sports_calendar_sync/data/providers/game_providers.dart';
import 'package:sports_calendar_sync/data/providers/team_providers.dart';
import 'package:sports_calendar_sync/domain/models/game.dart';
import 'package:sports_calendar_sync/domain/models/team.dart';
import 'package:sports_calendar_sync/domain/models/user_profile.dart';
import 'package:sports_calendar_sync/domain/policies/followed_fixture_place.dart';
import 'package:sports_calendar_sync/domain/policies/team_presentation_policy.dart';
import 'package:sports_calendar_sync/presentation/screens/home_screen.dart';
import 'package:sports_calendar_sync/presentation/widgets/game_card.dart';

const _captureDir = String.fromEnvironment('CAPTURE_PLACE_CUE');

String? _fontFamily;

Future<void> _loadCjkFont() async {
  const path = '/usr/share/fonts/truetype/droid/DroidSansFallbackFull.ttf';
  if (!File(path).existsSync()) return;
  final bytes = await File(path).readAsBytes();
  await ui.loadFontFromList(bytes, fontFamily: 'DroidSansFallback');
  _fontFamily = 'DroidSansFallback';
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ja');
    await _loadCjkFont();
  });

  test('stadium when the only perspective id is the home side', () {
    expect(
      fixturePlaceForPerspective(
        homeTeamId: 'kashima_antlers',
        awayTeamId: 'urawa_reds',
        perspectiveTeamIds: const ['kashima_antlers'],
      ),
      FollowedFixturePlace.stadium,
    );
  });

  test('travel when the only perspective id is the away side', () {
    expect(
      fixturePlaceForPerspective(
        homeTeamId: 'urawa_reds',
        awayTeamId: 'kashima_antlers',
        perspectiveTeamIds: const ['kashima_antlers'],
      ),
      FollowedFixturePlace.travel,
    );
  });

  test('no cue when both sides are perspective teams', () {
    expect(
      fixturePlaceForPerspective(
        homeTeamId: 'kashima_antlers',
        awayTeamId: 'gamba_osaka',
        perspectiveTeamIds: const ['gamba_osaka', 'kashima_antlers'],
      ),
      isNull,
    );
  });

  test(
    'no cue when neither side matches, including source-id-only opponents',
    () {
      expect(
        fixturePlaceForPerspective(
          homeTeamId: 'arsenal',
          awayTeamId: null,
          perspectiveTeamIds: const ['goal-opponent'],
        ),
        isNull,
      );
      expect(
        fixturePlaceForPerspective(
          homeTeamId: null,
          awayTeamId: null,
          perspectiveTeamIds: const ['kashima_antlers'],
        ),
        isNull,
      );
    },
  );

  test('blank ids and a duplicated side do not invent a cue', () {
    expect(
      fixturePlaceForPerspective(
        homeTeamId: '  ',
        awayTeamId: 'kashima_antlers',
        perspectiveTeamIds: const ['', ' kashima_antlers '],
      ),
      FollowedFixturePlace.travel,
    );
    expect(
      fixturePlaceForPerspective(
        homeTeamId: 'kashima_antlers',
        awayTeamId: 'kashima_antlers',
        perspectiveTeamIds: const ['kashima_antlers'],
      ),
      isNull,
    );
    expect(
      fixturePlaceForPerspective(
        homeTeamId: 'Kashima',
        awayTeamId: 'urawa_reds',
        perspectiveTeamIds: const ['kashima'],
      ),
      isNull,
    );
  });

  test('labels stay short and do not call travel a flight', () {
    expect(followedFixturePlaceLabel(FollowedFixturePlace.stadium), 'スタジアム');
    expect(followedFixturePlaceLabel(FollowedFixturePlace.travel), '移動');
  });

  testWidgets('home card shows a stadium cue on the home side', (tester) async {
    await _pumpCard(
      tester,
      game: _game(homeTeamId: 'kashima_antlers', awayTeamId: 'urawa_reds'),
      perspectiveTeamIds: const ['kashima_antlers'],
    );

    expect(find.text('スタジアム'), findsOneWidget);
    expect(find.byIcon(Icons.stadium), findsOneWidget);
    expect(find.text('移動'), findsNothing);
    expect(find.byIcon(Icons.flight), findsNothing);
    expect(find.text('2026年10月17日(土)'), findsOneWidget);
    expect(find.text('19:00'), findsOneWidget);
    _expectCueOnHomeSide(tester);
    await _capture(tester, 'home-stadium-card');
  });

  testWidgets('away card shows a transit cue on the away side', (tester) async {
    await _pumpCard(
      tester,
      game: _game(
        homeTeamId: 'urawa_reds',
        awayTeamId: 'kashima_antlers',
        homeName: '浦和レッズ',
        awayName: '鹿島アントラーズ',
        venue: '埼玉スタジアム2002',
      ),
      perspectiveTeamIds: const ['kashima_antlers'],
    );

    expect(find.text('移動'), findsOneWidget);
    expect(find.byIcon(Icons.directions_transit), findsOneWidget);
    expect(find.text('スタジアム'), findsNothing);
    expect(find.byIcon(Icons.flight), findsNothing);
    expect(find.byIcon(Icons.airplanemode_active), findsNothing);
    _expectCueOnAwaySide(tester);
    await _capture(tester, 'away-travel-card');
  });

  testWidgets('ambiguous and unmatched fixtures hide the cue', (tester) async {
    await _pumpCard(
      tester,
      game: _game(homeTeamId: 'kashima_antlers', awayTeamId: 'gamba_osaka'),
      perspectiveTeamIds: const ['kashima_antlers', 'gamba_osaka'],
    );
    expect(find.byKey(const Key('followed-fixture-place')), findsNothing);

    await _pumpCard(
      tester,
      game: _game(homeTeamId: 'kashima_antlers', awayTeamId: null),
      perspectiveTeamIds: const ['goal-opponent'],
    );
    expect(find.text('スタジアム'), findsNothing);
    expect(find.text('移動'), findsNothing);
  });

  testWidgets('home and sport-home cards use followed team ids', (
    tester,
  ) async {
    final teams = [
      _team('kashima_antlers', '鹿島アントラーズ', 'football_j1'),
      _team('gamba_osaka', 'ガンバ大阪', 'football_j1'),
    ];
    final games = [
      _game(
        id: 'home-fixture',
        homeTeamId: 'kashima_antlers',
        awayTeamId: 'urawa_reds',
      ),
      _game(
        id: 'travel-fixture',
        homeTeamId: 'urawa_reds',
        awayTeamId: 'kashima_antlers',
        homeName: '浦和レッズ',
        awayName: '鹿島アントラーズ',
      ),
      _game(
        id: 'both-followed',
        homeTeamId: 'kashima_antlers',
        awayTeamId: 'gamba_osaka',
        homeName: '鹿島アントラーズ',
        awayName: 'ガンバ大阪',
      ),
    ];

    await tester.binding.setSurfaceSize(const Size(390, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userProfileProvider.overrideWith(
            (ref) => Stream<UserProfile?>.value(
              UserProfile(
                uid: 'user',
                email: 'user@example.com',
                followedTeamIds: const ['kashima_antlers', 'gamba_osaka'],
              ),
            ),
          ),
          followedTeamsProvider.overrideWith((ref) async => teams),
          homeUpcomingGamesProvider.overrideWith(
            (ref) async => HomeUpcomingGames(
              games: games,
              presentation: TeamPresentationLogoResolver(const []),
            ),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('ja', 'JP'),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('ja', 'JP'), Locale('en', 'US')],
          theme: _darkTheme(),
          home: const HomeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byKey(const ValueKey('home-sport-page-favorites')),
        matching: find.text('スタジアム'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('home-sport-page-favorites')),
        matching: find.text('移動'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('サッカー'));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('home-sport-page-football')),
        matching: find.text('スタジアム'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('home-sport-page-football')),
        matching: find.text('移動'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('home-sport-page-football')),
        matching: find.byKey(const Key('followed-fixture-place')),
      ),
      findsNWidgets(2),
    );
    expect(tester.takeException(), isNull);
  });
}

Game _game({
  String id = 'game',
  required String? homeTeamId,
  required String? awayTeamId,
  String competitionKey = 'football_j1',
  String homeName = '鹿島アントラーズ',
  String awayName = '浦和レッズ',
  String? venue = '県立カシマサッカースタジアム',
}) {
  return Game(
    id: id,
    leagueId: 'j1_league',
    competitionKey: competitionKey,
    homeTeamId: homeTeamId,
    homeTeamNameJa: homeName,
    homeTeamNameEn: homeName,
    awayTeamId: awayTeamId,
    awayTeamNameJa: awayName,
    awayTeamNameEn: awayName,
    startTimeUtc: Timestamp.fromDate(DateTime.utc(2026, 10, 17, 10)),
    startTimeJst: '2026-10-17 19:00',
    timezone: 'UTC',
    status: GameStatus.scheduled,
    venue: venue,
  );
}

Team _team(String id, String name, String competitionKey) {
  return Team(
    id: id,
    nameEn: name,
    nameJa: name,
    leagueId: 'league',
    competitionKey: competitionKey,
  );
}

ThemeData _darkTheme() {
  return ThemeData(
    useMaterial3: true,
    fontFamily: _fontFamily,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF1565C0),
      brightness: Brightness.dark,
    ),
  );
}

Future<void> _pumpCard(
  WidgetTester tester, {
  required Game game,
  required List<String> perspectiveTeamIds,
}) async {
  await tester.binding.setSurfaceSize(const Size(390, 520));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final theme = _darkTheme();
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('ja', 'JP'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ja', 'JP'), Locale('en', 'US')],
      theme: theme,
      home: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: ListView(
          children: [
            RepaintBoundary(
              key: const Key('place-cue-shot'),
              child: GameCard(
                game: game,
                perspectiveTeamIds: perspectiveTeamIds,
              ),
            ),
          ],
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void _expectCueOnHomeSide(WidgetTester tester) {
  final cue = tester.getCenter(find.byKey(const Key('followed-fixture-place')));
  final card = tester.getCenter(find.byType(Card));
  expect(cue.dx, lessThan(card.dx));
}

void _expectCueOnAwaySide(WidgetTester tester) {
  final cue = tester.getCenter(find.byKey(const Key('followed-fixture-place')));
  final card = tester.getCenter(find.byType(Card));
  expect(cue.dx, greaterThan(card.dx));
}

Future<void> _capture(WidgetTester tester, String name) async {
  if (_captureDir.isEmpty) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const Key('place-cue-shot')),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('$_captureDir/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
  });
}
