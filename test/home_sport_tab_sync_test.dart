import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sports_calendar_sync/data/providers/auth_providers.dart';
import 'package:sports_calendar_sync/data/providers/game_providers.dart';
import 'package:sports_calendar_sync/data/providers/team_providers.dart';
import 'package:sports_calendar_sync/domain/models/game.dart';
import 'package:sports_calendar_sync/domain/models/team.dart';
import 'package:sports_calendar_sync/domain/models/user_profile.dart';
import 'package:sports_calendar_sync/domain/policies/home_sport_navigation.dart';
import 'package:sports_calendar_sync/domain/policies/team_presentation_policy.dart';
import 'package:sports_calendar_sync/presentation/screens/home_screen.dart';

const _screenshotDir = String.fromEnvironment('CAPTURE_HOME_SCREENSHOTS');

String? _fontFamily;

Future<void> _loadCjkFont() async {
  const path = '/usr/share/fonts/truetype/droid/DroidSansFallbackFull.ttf';
  if (!File(path).existsSync()) return;
  final bytes = await File(path).readAsBytes();
  await ui.loadFontFromList(bytes, fontFamily: 'DroidSansFallback');
  _fontFamily = 'DroidSansFallback';
}

Team _team({
  required String id,
  required String name,
  required String competitionKey,
}) {
  return Team(
    id: id,
    nameEn: name,
    nameJa: name,
    leagueId: 'league',
    competitionKey: competitionKey,
  );
}

Game _game({
  required String id,
  required String name,
  required String competitionKey,
  required String teamId,
}) {
  return Game(
    id: id,
    leagueId: 'league',
    competitionKey: competitionKey,
    homeTeamId: teamId,
    homeTeamNameJa: name,
    homeTeamNameEn: name,
    awayTeamId: 'opponent',
    awayTeamNameJa: '対戦相手',
    awayTeamNameEn: 'Opponent',
    startTimeUtc: Timestamp.fromDate(DateTime.utc(2026, 12, 1, 10)),
    startTimeJst: '2026-12-01 19:00',
    timezone: 'Asia/Tokyo',
    status: GameStatus.scheduled,
  );
}

UserProfile _profile(List<String> teamIds) {
  return UserProfile(
    uid: 'user',
    email: 'user@example.com',
    followedTeamIds: teamIds,
  );
}

TabController _tabs(WidgetTester tester) {
  final tabContext = tester.element(find.byType(TabBar));
  final viewContext = tester.element(find.byType(TabBarView));
  final tabController = DefaultTabController.of(tabContext);
  final viewController = DefaultTabController.of(viewContext);
  expect(tabController, same(viewController));
  return tabController;
}

double _pageLeft(WidgetTester tester, String id) {
  return tester.getTopLeft(find.byKey(ValueKey('home-sport-page-$id'))).dx;
}

const _sportTabLabels = ['お気に入り', '野球', 'サッカー', 'その他スポーツ'];

void _expectSportTabLabelsFit(WidgetTester tester) {
  final bar = find.byType(TabBar);
  final barRect = tester.getRect(bar);
  final tabBar = tester.widget<TabBar>(bar);
  expect(tabBar.isScrollable, isFalse);
  expect(tester.getSize(bar).width, 390);

  for (final label in _sportTabLabels) {
    final finder = find.descendant(of: bar, matching: find.text(label));
    expect(finder, findsOneWidget);
    final text = tester.widget<Text>(finder);
    expect(text.data, label);
    expect(text.overflow, isNot(TextOverflow.ellipsis));

    final rect = tester.getRect(finder);
    expect(rect.left, greaterThanOrEqualTo(barRect.left - 0.5));
    expect(rect.right, lessThanOrEqualTo(barRect.right + 0.5));

    final paragraph = tester.renderObject<RenderParagraph>(finder);
    final painter = TextPainter(
      text: paragraph.text,
      textDirection: TextDirection.ltr,
      textScaler: paragraph.textScaler,
    )..layout();
    expect(
      paragraph.size.width,
      greaterThanOrEqualTo(painter.width - 0.5),
      reason: '$label is clipped inside the tab',
    );
  }
}

Future<void> _pumpHome(
  WidgetTester tester, {
  UserProfile? profile,
  bool loadingProfile = false,
  Object? profileError,
  List<Team> teams = const [],
  List<Game> games = const [],
  Object? teamsError,
  Object? gamesError,
  bool settle = true,
}) async {
  await tester.binding.setSurfaceSize(const Size(390, 844));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  late final Stream<UserProfile?> profileStream;
  if (loadingProfile) {
    final controller = StreamController<UserProfile?>();
    addTearDown(controller.close);
    profileStream = controller.stream;
  } else if (profileError != null) {
    profileStream = Stream<UserProfile?>.error(profileError);
  } else {
    profileStream = Stream<UserProfile?>.value(profile);
  }

  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: [
        userProfileProvider.overrideWith((ref) => profileStream),
        if (teamsError != null)
          followedTeamsProvider.overrideWith((ref) => Future.error(teamsError))
        else
          followedTeamsProvider.overrideWith((ref) async => teams),
        if (gamesError != null)
          homeUpcomingGamesProvider.overrideWith(
            (ref) => Future.error(gamesError),
          )
        else
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
        theme: ThemeData(
          useMaterial3: true,
          fontFamily: _fontFamily,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1565C0)),
        ),
        home: const HomeScreen(),
      ),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
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

void main() {
  setUpAll(_loadCjkFont);

  testWidgets('tap and horizontal swipe share one home sport index', (
    tester,
  ) async {
    await _pumpHome(tester, profile: _profile(const []));

    final controller = _tabs(tester);
    expect(controller.index, defaultHomeSportTabIndex(homeSportTabs()));
    expect(controller.index, 0);
    expect(_pageLeft(tester, HomeSportTabIds.favorites), closeTo(0, 1));
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byType(BottomNavigationBar), findsNothing);
    _expectSportTabLabelsFit(tester);

    await tester.tap(find.text('サッカー'));
    await tester.pumpAndSettle();
    expect(controller.index, 2);
    expect(_pageLeft(tester, HomeSportTabIds.football), closeTo(0, 1));
    expect(find.byKey(const ValueKey('sport-sub-nav')), findsOneWidget);
    expect(
      tester
          .widget<NavigationBar>(find.byKey(const ValueKey('sport-sub-nav')))
          .destinations,
      hasLength(2),
    );

    await tester.timedDrag(
      find.byType(TabBarView),
      const Offset(280, 0),
      const Duration(milliseconds: 400),
    );
    await tester.pumpAndSettle();
    expect(controller.index, 1);
    expect(_pageLeft(tester, HomeSportTabIds.baseball), closeTo(0, 1));

    await tester.timedDrag(
      find.byType(TabBarView),
      const Offset(-280, 0),
      const Duration(milliseconds: 400),
    );
    await tester.pumpAndSettle();
    expect(controller.index, 2);
    expect(_pageLeft(tester, HomeSportTabIds.football), closeTo(0, 1));

    await tester.tap(find.text('お気に入り'));
    await tester.pumpAndSettle();
    expect(controller.index, 0);
    expect(_pageLeft(tester, HomeSportTabIds.favorites), closeTo(0, 1));
    expect(find.byKey(const ValueKey('sport-sub-nav')), findsNothing);
    expect(find.byType(NavigationBar), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sport tab labels stay fully visible at phone width 390', (
    tester,
  ) async {
    await _pumpHome(tester, profile: _profile(const []));
    _expectSportTabLabelsFit(tester);

    await tester.tap(find.text('その他スポーツ'));
    await tester.pumpAndSettle();
    _expectSportTabLabelsFit(tester);
    expect(find.byKey(const ValueKey('sport-sub-nav')), findsOneWidget);
    expect(
      tester
          .widget<NavigationBar>(find.byKey(const ValueKey('sport-sub-nav')))
          .destinations,
      hasLength(2),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('sport tabs show only that sport and keep full labels', (
    tester,
  ) async {
    final teams = [
      _team(
        id: 'kashima_antlers',
        name: '鹿島アントラーズ',
        competitionKey: 'football_j1',
      ),
      _team(
        id: 'yomiuri_giants',
        name: '読売ジャイアンツ',
        competitionKey: 'baseball_npb',
      ),
      _team(
        id: 'los_angeles_lakers',
        name: 'ロサンゼルス・レイカーズ',
        competitionKey: 'basketball_nba',
      ),
    ];
    final games = [
      _game(
        id: 'football-game',
        name: '鹿島アントラーズ',
        competitionKey: 'football_j1',
        teamId: 'kashima_antlers',
      ),
      _game(
        id: 'baseball-game',
        name: '読売ジャイアンツ',
        competitionKey: 'baseball_npb',
        teamId: 'yomiuri_giants',
      ),
      _game(
        id: 'other-game',
        name: 'ロサンゼルス・レイカーズ',
        competitionKey: 'basketball_nba',
        teamId: 'los_angeles_lakers',
      ),
    ];

    await _pumpHome(
      tester,
      profile: _profile(teams.map((team) => team.id).toList()),
      teams: teams,
      games: games,
    );

    expect(find.text('Jリーグ'), findsNothing);
    expect(find.text('NPB'), findsNothing);
    expect(find.text('NBA'), findsNothing);
    expect(find.byType(Image), findsNothing);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('home-sport-page-favorites')),
        matching: find.text('鹿島アントラーズ'),
      ),
      findsWidgets,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('home-sport-page-favorites')),
        matching: find.text('読売ジャイアンツ'),
      ),
      findsWidgets,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('home-sport-page-favorites')),
        matching: find.text('ロサンゼルス・レイカーズ'),
      ),
      findsWidgets,
    );
    _expectSportTabLabelsFit(tester);
    await _capture(tester, 'home-favorites');

    await tester.tap(find.text('サッカー'));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('home-sport-page-football')),
        matching: find.text('鹿島アントラーズ'),
      ),
      findsWidgets,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('home-sport-page-football')),
        matching: find.text('読売ジャイアンツ'),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('home-sport-page-football')),
        matching: find.text('ロサンゼルス・レイカーズ'),
      ),
      findsNothing,
    );
    await _capture(tester, 'home-football');
    expect(tester.takeException(), isNull);
  });

  testWidgets('no-follow, loading, and error stay on the sport navigation', (
    tester,
  ) async {
    await _pumpHome(tester, profile: _profile(const []));
    expect(find.text('フォローしているチームがありません'), findsWidgets);
    expect(find.text('お気に入り'), findsOneWidget);
    expect(_tabs(tester).index, 0);
    await _capture(tester, 'home-no-follow');
    expect(tester.takeException(), isNull);

    await _pumpHome(
      tester,
      profile: _profile(const ['kashima_antlers']),
      teams: [
        _team(
          id: 'kashima_antlers',
          name: '鹿島アントラーズ',
          competitionKey: 'football_j1',
        ),
      ],
      games: [
        _game(
          id: 'football-game',
          name: '鹿島アントラーズ',
          competitionKey: 'football_j1',
          teamId: 'kashima_antlers',
        ),
      ],
    );
    await tester.tap(find.text('野球'));
    await tester.pumpAndSettle();
    expect(_tabs(tester).index, 1);
    expect(find.text('野球でフォローしているチームがありません'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('home-sport-page-baseball')),
        matching: find.text('鹿島アントラーズ'),
      ),
      findsNothing,
    );
    await _capture(tester, 'home-baseball-no-follow');

    await _pumpHome(
      tester,
      profile: _profile(const ['kashima_antlers']),
      teamsError: Exception('teams failed'),
    );
    expect(find.textContaining('エラー'), findsWidgets);
    expect(find.byType(TabBar), findsOneWidget);
    expect(_tabs(tester).index, 0);

    await _pumpHome(
      tester,
      profile: _profile(const ['kashima_antlers']),
      teams: [
        _team(
          id: 'kashima_antlers',
          name: '鹿島アントラーズ',
          competitionKey: 'football_j1',
        ),
      ],
      gamesError: Exception('games failed'),
    );
    expect(find.textContaining('エラー'), findsWidgets);
    expect(find.byType(TabBar), findsOneWidget);

    await _pumpHome(tester, profile: null);
    expect(find.text('サインインが必要です'), findsWidgets);
    expect(find.text('お気に入り'), findsOneWidget);
    expect(_tabs(tester).index, 0);

    await _pumpHome(tester, loadingProfile: true, settle: false);
    expect(find.byType(CircularProgressIndicator), findsWidgets);
    expect(find.byType(TabBar), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
