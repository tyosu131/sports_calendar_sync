import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:intl/date_symbol_data_local.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sports_calendar_sync/core/utils/app_router.dart';
import 'package:sports_calendar_sync/data/providers/auth_providers.dart';
import 'package:sports_calendar_sync/data/providers/game_providers.dart';
import 'package:sports_calendar_sync/data/providers/repository_providers.dart';
import 'package:sports_calendar_sync/data/providers/team_providers.dart';
import 'package:sports_calendar_sync/data/repositories/game_repository.dart';
import 'package:sports_calendar_sync/data/repositories/team_repository.dart';
import 'package:sports_calendar_sync/data/repositories/user_repository.dart';
import 'package:sports_calendar_sync/domain/models/game.dart';
import 'package:sports_calendar_sync/domain/models/team.dart';
import 'package:sports_calendar_sync/domain/models/user_profile.dart';
import 'package:sports_calendar_sync/domain/policies/home_sport_navigation.dart';
import 'package:sports_calendar_sync/domain/policies/team_presentation_policy.dart';
import 'package:sports_calendar_sync/presentation/screens/league_teams_screen.dart';

const _screenshotDir = String.fromEnvironment(
  'CAPTURE_SPORT_SUBNAV_SCREENSHOTS',
);

String? _fontFamily;

Future<void> _loadCjkFont() async {
  const path = '/usr/share/fonts/truetype/droid/DroidSansFallbackFull.ttf';
  if (!File(path).existsSync()) return;
  final bytes = await File(path).readAsBytes();
  await ui.loadFontFromList(bytes, fontFamily: 'DroidSansFallback');
  _fontFamily = 'DroidSansFallback';
  await initializeDateFormatting('ja');
}

Game _kashimaGame() {
  return Game(
    id: 'football-game',
    leagueId: 'sample_j1_league',
    competitionKey: 'football_j1',
    homeTeamId: 'kashima_antlers',
    homeTeamNameJa: '鹿島アントラーズ',
    homeTeamNameEn: 'Kashima Antlers',
    awayTeamId: 'urawa_reds',
    awayTeamNameJa: '浦和レッズ',
    awayTeamNameEn: 'Urawa Reds',
    startTimeUtc: Timestamp.fromDate(DateTime.utc(2026, 10, 10, 10)),
    startTimeJst: '2026-10-10 19:00',
    timezone: 'Asia/Tokyo',
    status: GameStatus.scheduled,
  );
}

Finder _inPage(String id, Finder matching) {
  return find.descendant(
    of: find.byKey(ValueKey('home-sport-page-$id')),
    matching: matching,
  );
}

void _expectTwoDestinations(WidgetTester tester) {
  final bar = tester.widget<NavigationBar>(
    find.byKey(const ValueKey('sport-sub-nav')),
  );
  expect(bar.destinations, hasLength(2));
  expect(
    bar.destinations.map(
      (destination) => (destination as NavigationDestination).label,
    ),
    ['ホーム', 'リーグ'],
  );
  const leagueLabels = {
    'Jリーグ',
    'プレミアリーグ',
    'NPB',
    'MLB',
    'NBA',
    'NFL',
    'NHL',
    'Bリーグ',
  };
  expect(
    bar.destinations
        .map((destination) => (destination as NavigationDestination).label)
        .toSet()
        .intersection(leagueLabels),
    isEmpty,
  );
}

void _expectSelectedIcons(WidgetTester tester, {required bool leagues}) {
  expect(
    find.descendant(
      of: find.byKey(const ValueKey('sport-sub-nav')),
      matching: find.byIcon(leagues ? Icons.home_outlined : Icons.home),
    ),
    findsOneWidget,
  );
  expect(
    find.descendant(
      of: find.byKey(const ValueKey('sport-sub-nav')),
      matching: find.byIcon(
        leagues ? Icons.emoji_events : Icons.emoji_events_outlined,
      ),
    ),
    findsOneWidget,
  );
  final selectedLabel = leagues ? 'リーグ' : 'ホーム';
  final unselectedLabel = leagues ? 'ホーム' : 'リーグ';
  expect(
    tester
        .widget<Text>(
          find.descendant(
            of: find.byKey(const ValueKey('sport-sub-nav')),
            matching: find.text(selectedLabel),
          ),
        )
        .style
        ?.fontWeight,
    FontWeight.w800,
  );
  expect(
    tester
        .widget<Text>(
          find.descendant(
            of: find.byKey(const ValueKey('sport-sub-nav')),
            matching: find.text(unselectedLabel),
          ),
        )
        .style
        ?.fontWeight,
    FontWeight.w500,
  );
}

Future<void> _capture(WidgetTester tester, String name) async {
  if (_screenshotDir.isEmpty) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byType(RepaintBoundary).first,
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('$_screenshotDir/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
  });
}

Future<ProviderContainer> _pumpRoutedHome(
  WidgetTester tester, {
  required SampleUserRepository users,
}) async {
  await tester.binding.setSurfaceSize(const Size(390, 844));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  final container = ProviderContainer(
    overrides: [
      userRepositoryProvider.overrideWith((ref) => users),
      teamRepositoryProvider.overrideWith((ref) => SampleTeamRepository()),
      gameRepositoryProvider.overrideWith((ref) => SampleGameRepository()),
      userProfileProvider.overrideWith(
        (ref) => users.watchProfile(SampleUserRepository.sampleUid),
      ),
      homeUpcomingGamesProvider.overrideWith(
        (ref) async => HomeUpcomingGames(
          games: [_kashimaGame()],
          presentation: TeamPresentationLogoResolver(const []),
        ),
      ),
    ],
  );
  addTearDown(container.dispose);
  final router = container.read(routerProvider);
  addTearDown(router.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        routerConfig: router,
        locale: const Locale('ja', 'JP'),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('ja', 'JP'), Locale('en', 'US')],
        theme: ThemeData(
          useMaterial3: true,
          fontFamily: _fontFamily,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1565C0),
            brightness: Brightness.dark,
          ),
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          fontFamily: _fontFamily,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1565C0),
            brightness: Brightness.dark,
          ),
        ),
        themeMode: ThemeMode.dark,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  setUpAll(_loadCjkFont);

  testWidgets(
    'sport tabs drill from leagues to teams and favorites stay plain',
    (tester) async {
      final users = SampleUserRepository();
      await _pumpRoutedHome(tester, users: users);

      expect(find.byType(NavigationBar), findsNothing);
      expect(find.byKey(const ValueKey('sport-sub-nav')), findsNothing);
      expect(
        _inPage(HomeSportTabIds.favorites, find.text('鹿島アントラーズ')),
        findsWidgets,
      );
      expect(find.byType(Image), findsNothing);
      await _capture(tester, 'favorites-no-subnav');

      await tester.tap(find.text('サッカー'));
      await tester.pumpAndSettle();
      _expectTwoDestinations(tester);
      _expectSelectedIcons(tester, leagues: false);
      expect(
        _inPage(HomeSportTabIds.football, find.text('鹿島アントラーズ')),
        findsWidgets,
      );
      expect(
        _inPage(HomeSportTabIds.football, find.text('読売ジャイアンツ')),
        findsNothing,
      );
      expect(
        _inPage(HomeSportTabIds.football, find.text('Jリーグ')),
        findsNothing,
      );
      expect(tester.getSize(find.byType(TabBar)).width, 390);
      await _capture(tester, 'football-home-subnav');

      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey('sport-sub-nav')),
          matching: find.text('リーグ'),
        ),
      );
      await tester.pumpAndSettle();
      _expectTwoDestinations(tester);
      _expectSelectedIcons(tester, leagues: true);
      expect(
        _inPage(HomeSportTabIds.football, find.text('Jリーグ')),
        findsOneWidget,
      );
      expect(
        _inPage(HomeSportTabIds.football, find.text('プレミアリーグ')),
        findsOneWidget,
      );
      expect(_inPage(HomeSportTabIds.football, find.text('NPB')), findsNothing);
      expect(
        _inPage(HomeSportTabIds.football, find.text('J2リーグ')),
        findsNothing,
      );
      expect(
        _inPage(HomeSportTabIds.football, find.text('サッカーでフォローしているチームがありません')),
        findsNothing,
      );
      expect(find.byType(Image), findsNothing);

      await tester.enterText(
        _inPage(
          HomeSportTabIds.football,
          find.byKey(const ValueKey('sport-league-search-football')),
        ),
        'プレミア',
      );
      await tester.pump();
      expect(
        _inPage(HomeSportTabIds.football, find.text('Jリーグ')),
        findsNothing,
      );
      expect(
        _inPage(HomeSportTabIds.football, find.text('プレミアリーグ')),
        findsOneWidget,
      );
      await tester.tap(find.byTooltip('検索をクリア'));
      await tester.pump();

      await _capture(tester, 'football-leagues');

      await tester.tap(_inPage(HomeSportTabIds.football, find.text('Jリーグ')));
      await tester.pumpAndSettle();
      final kashima = find.byKey(
        const ValueKey('league-team-card-kashima_antlers'),
      );
      final urawa = find.byKey(const ValueKey('league-team-card-urawa_reds'));
      expect(
        find.descendant(of: kashima, matching: find.text('鹿島')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: kashima, matching: find.text('vs 浦和')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: urawa, matching: find.text('浦和')),
        findsOneWidget,
      );
      expect(find.byType(NavigationBar), findsNothing);
      expect(find.byType(Image), findsNothing);
      await _capture(tester, 'football-jleague-teams');
      expect(
        find.descendant(
          of: urawa,
          matching: find.byIcon(Icons.favorite_border),
        ),
        findsOneWidget,
      );
      await tester.tap(
        find.descendant(of: urawa, matching: find.byTooltip('フォローする')),
      );
      await tester.pumpAndSettle();
      expect(
        find.descendant(of: urawa, matching: find.byIcon(Icons.favorite)),
        findsOneWidget,
      );
      final followed = await users.fetchProfile(SampleUserRepository.sampleUid);
      expect(followed!.followedTeamIds, contains('urawa_reds'));

      await tester.tap(
        find.descendant(of: urawa, matching: find.byTooltip('フォロー解除')),
      );
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: urawa,
          matching: find.byIcon(Icons.favorite_border),
        ),
        findsOneWidget,
      );

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(
        _inPage(HomeSportTabIds.football, find.text('Jリーグ')),
        findsOneWidget,
      );
      _expectSelectedIcons(tester, leagues: true);

      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey('sport-sub-nav')),
          matching: find.text('ホーム'),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        _inPage(HomeSportTabIds.football, find.text('Jリーグ')),
        findsNothing,
      );
      expect(
        _inPage(HomeSportTabIds.football, find.text('鹿島アントラーズ')),
        findsWidgets,
      );
      _expectSelectedIcons(tester, leagues: false);

      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey('sport-sub-nav')),
          matching: find.text('リーグ'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('野球'));
      await tester.pumpAndSettle();
      expect(
        _inPage(
          HomeSportTabIds.baseball,
          find.byKey(const ValueKey('sport-league-baseball_npb')),
        ),
        findsOneWidget,
      );
      expect(
        _inPage(
          HomeSportTabIds.baseball,
          find.byKey(const ValueKey('sport-league-baseball_mlb')),
        ),
        findsOneWidget,
      );
      expect(
        _inPage(HomeSportTabIds.baseball, find.text('Jリーグ')),
        findsNothing,
      );
      _expectTwoDestinations(tester);

      await tester.tap(find.text('その他スポーツ'));
      await tester.pumpAndSettle();
      expect(
        _inPage(
          HomeSportTabIds.other,
          find.byKey(const ValueKey('sport-league-basketball_nba')),
        ),
        findsOneWidget,
      );
      expect(
        _inPage(
          HomeSportTabIds.other,
          find.byKey(const ValueKey('sport-league-basketball_b_league')),
        ),
        findsOneWidget,
      );
      expect(_inPage(HomeSportTabIds.other, find.text('NPB')), findsNothing);
      _expectTwoDestinations(tester);

      await tester.tap(find.text('お気に入り'));
      await tester.pumpAndSettle();
      expect(find.byType(NavigationBar), findsNothing);
      expect(
        _inPage(HomeSportTabIds.favorites, find.text('鹿島アントラーズ')),
        findsWidgets,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'signed-out users can browse leagues and follow asks to sign in',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final container = ProviderContainer(
        overrides: [
          userProfileProvider.overrideWith(
            (ref) => Stream<UserProfile?>.value(null),
          ),
          teamRepositoryProvider.overrideWith((ref) => SampleTeamRepository()),
          gameRepositoryProvider.overrideWith((ref) => SampleGameRepository()),
          followedTeamsProvider.overrideWith((ref) async => const <Team>[]),
          homeUpcomingGamesProvider.overrideWith(
            (ref) async => HomeUpcomingGames(
              games: const [],
              presentation: TeamPresentationLogoResolver(const []),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      final router = container.read(routerProvider);
      addTearDown(router.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
            locale: const Locale('ja', 'JP'),
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('ja', 'JP'), Locale('en', 'US')],
            theme: ThemeData(
              useMaterial3: true,
              fontFamily: _fontFamily,
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF1565C0),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('サインインが必要です'), findsWidgets);
      expect(find.byType(NavigationBar), findsNothing);

      await tester.tap(find.text('野球'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey('sport-sub-nav')),
          matching: find.text('リーグ'),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        _inPage(
          HomeSportTabIds.baseball,
          find.byKey(const ValueKey('sport-league-baseball_npb')),
        ),
        findsOneWidget,
      );
      expect(find.text('サインインが必要です'), findsNothing);

      final npbRow = _inPage(
        HomeSportTabIds.baseball,
        find.byKey(const ValueKey('sport-league-baseball_npb')),
      );
      await tester.ensureVisible(npbRow);
      await tester.tap(npbRow);
      await tester.pumpAndSettle();
      // NPB is outside the Japanese domestic-football catalog, so the card
      // keeps the trailing English token instead of an invented short label.
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('league-team-card-yomiuri_giants')),
          matching: find.text('Giants'),
        ),
        findsOneWidget,
      );
      await tester.tap(find.byTooltip('フォローする').first);
      await tester.pumpAndSettle();
      expect(find.text('Googleでサインイン'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('league team screen keeps loading, error, empty, and unknown', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    Future<void> pumpScreen({
      required String competitionKey,
      List<Override> overrides = const [],
      bool settle = true,
    }) async {
      await tester.pumpWidget(
        ProviderScope(
          key: UniqueKey(),
          overrides: overrides,
          child: MaterialApp(
            locale: const Locale('ja', 'JP'),
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('ja', 'JP'), Locale('en', 'US')],
            theme: ThemeData(
              useMaterial3: true,
              fontFamily: _fontFamily,
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF1565C0),
              ),
            ),
            home: LeagueTeamsScreen(competitionKey: competitionKey),
          ),
        ),
      );
      if (settle) {
        await tester.pumpAndSettle();
      } else {
        await tester.pump();
      }
    }

    final pending = Completer<List<Team>>();
    await pumpScreen(
      competitionKey: 'baseball_npb',
      settle: false,
      overrides: [
        teamsByCompetitionProvider.overrideWith((ref, key) => pending.future),
      ],
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('NPB'), findsOneWidget);

    await pumpScreen(
      competitionKey: 'baseball_npb',
      overrides: [
        teamsByCompetitionProvider.overrideWith(
          (ref, key) => Future<List<Team>>.error(Exception('teams failed')),
        ),
      ],
    );
    expect(find.textContaining('エラー'), findsOneWidget);
    expect(find.text('再試行'), findsOneWidget);

    await pumpScreen(
      competitionKey: 'football_premier',
      overrides: [
        teamRepositoryProvider.overrideWith((ref) => SampleTeamRepository()),
      ],
    );
    expect(find.text('このリーグのチームはまだありません'), findsOneWidget);
    expect(find.text('プレミアリーグ'), findsOneWidget);

    await pumpScreen(competitionKey: 'not_a_league');
    expect(find.text('このリーグは見つかりません'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
