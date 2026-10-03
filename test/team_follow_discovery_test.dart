import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sports_calendar_sync/data/providers/auth_providers.dart';
import 'package:sports_calendar_sync/data/providers/repository_providers.dart';
import 'package:sports_calendar_sync/data/repositories/competition_membership_repository.dart';
import 'package:sports_calendar_sync/data/repositories/team_repository.dart';
import 'package:sports_calendar_sync/data/repositories/user_repository.dart';
import 'package:sports_calendar_sync/presentation/screens/team_search_screen.dart';
import 'package:sports_calendar_sync/presentation/widgets/team_presentation_badge.dart';

const _screenshotDir = String.fromEnvironment(
  'CAPTURE_TEAM_SEARCH_SCREENSHOTS',
);

String? _fontFamily;

Future<void> _loadCjkFont() async {
  const path = '/usr/share/fonts/truetype/droid/DroidSansFallbackFull.ttf';
  if (!File(path).existsSync()) return;
  final bytes = await File(path).readAsBytes();
  await ui.loadFontFromList(bytes, fontFamily: 'DroidSansFallback');
  _fontFamily = 'DroidSansFallback';
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

  testWidgets('team search uses sport tabs and sub-nav, not flat leagues', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final users = SampleUserRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userRepositoryProvider.overrideWith((ref) => users),
          teamRepositoryProvider.overrideWith((ref) => SampleTeamRepository()),
          competitionMembershipRepositoryProvider.overrideWith(
            (ref) => SampleCompetitionMembershipRepository(),
          ),
          userProfileProvider.overrideWith(
            (ref) => users.watchProfile(SampleUserRepository.sampleUid),
          ),
        ],
        child: RepaintBoundary(
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
                brightness: Brightness.dark,
              ),
            ),
            home: const TeamSearchScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('team-search-sport-tabs')),
      findsOneWidget,
    );
    expect(find.text('フォロー中'), findsOneWidget);
    expect(find.text('お気に入り'), findsNothing);
    expect(find.text('Jリーグ'), findsNothing);
    expect(find.text('プレミアリーグ'), findsNothing);
    expect(find.byType(NavigationBar), findsNothing);
    expect(
      find.byKey(const ValueKey('team-search-query-following')),
      findsOneWidget,
    );
    expect(find.text('チーム名で検索...'), findsOneWidget);
    expect(find.text('リーグを検索'), findsNothing);
    expect(find.text('鹿島アントラーズ'), findsOneWidget);
    expect(find.text('ガンバ大阪'), findsOneWidget);
    expect(find.text('Yomiuri Giants'), findsNothing);
    expect(find.text('鹿'), findsNothing);
    expect(find.text('ガ'), findsNothing);
    expect(find.byKey(const Key('neutral-team-mark')), findsWidgets);
    expect(
      tester
          .getSemantics(
            find.descendant(
              of: find.widgetWithText(ListTile, '鹿島アントラーズ'),
              matching: find.byType(TeamPresentationBadge),
            ),
          )
          .label,
      '鹿島アントラーズ',
    );
    expect(tester.takeException(), isNull);
    await _capture(tester, 'search-following');

    await tester.enterText(
      find.byKey(const ValueKey('team-search-query-following')),
      '存在しないチーム',
    );
    await tester.pumpAndSettle();
    expect(find.text('条件に合うフォロー中のチームはありません'), findsOneWidget);
    expect(find.byTooltip('検索をクリア'), findsOneWidget);
    await tester.tap(find.byTooltip('検索をクリア'));
    await tester.pumpAndSettle();
    expect(find.text('鹿島アントラーズ'), findsOneWidget);
    expect(find.byTooltip('検索をクリア'), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('サッカー'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('sport-sub-nav')), findsOneWidget);
    _expectTwoDestinations(tester);
    expect(
      find.byKey(const ValueKey('team-search-query-football')),
      findsOneWidget,
    );
    expect(find.text('チーム名で検索...'), findsOneWidget);
    expect(find.text('リーグを検索'), findsNothing);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('team-search-page-football')),
        matching: find.text('鹿島アントラーズ'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('team-search-page-football')),
        matching: find.text('Yomiuri Giants'),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('team-search-page-football')),
        matching: find.text('ベガルタ仙台'),
      ),
      findsNothing,
    );
    final kashimaTile = find.widgetWithText(ListTile, '鹿島アントラーズ');
    expect(
      find.descendant(of: kashimaTile, matching: find.byIcon(Icons.favorite)),
      findsOneWidget,
    );
    final urawaTile = find.widgetWithText(ListTile, '浦和レッズ');
    expect(
      find.descendant(
        of: urawaTile,
        matching: find.byIcon(Icons.favorite_border),
      ),
      findsOneWidget,
    );
    expect(find.text('鹿'), findsNothing);
    expect(find.text('浦'), findsNothing);
    expect(find.text('川'), findsNothing);
    expect(
      tester
          .getSemantics(
            find.descendant(
              of: urawaTile,
              matching: find.byType(TeamPresentationBadge),
            ),
          )
          .label,
      '浦和レッズ',
    );
    expect(tester.takeException(), isNull);
    await _capture(tester, 'search-football-home');

    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('sport-sub-nav')),
        matching: find.text('リーグ'),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('team-search-page-football')),
        matching: find.text('Jリーグ'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('team-search-query-football')),
      findsNothing,
    );
    expect(find.text('チーム名で検索...'), findsNothing);
    expect(find.text('リーグを検索'), findsOneWidget);
    await _capture(tester, 'search-football-leagues');

    await tester.tap(find.text('野球'));
    await tester.pumpAndSettle();
    _expectSelectedHome(tester);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('team-search-page-baseball')),
        matching: find.text('Jリーグ'),
      ),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('team-search-query-baseball')),
      findsOneWidget,
    );
    expect(find.text('チーム名で検索...'), findsOneWidget);
    expect(find.text('リーグを検索'), findsNothing);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('team-search-page-baseball')),
        matching: find.text('Yomiuri Giants'),
      ),
      findsOneWidget,
    );
    expect(find.text('Giants'), findsNothing);
    expect(find.text('Y'), findsNothing);
    expect(
      tester
          .getSemantics(
            find.descendant(
              of: find.widgetWithText(ListTile, 'Yomiuri Giants'),
              matching: find.byType(TeamPresentationBadge),
            ),
          )
          .label,
      'Yomiuri Giants',
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('team-search-page-baseball')),
        matching: find.text('鹿島アントラーズ'),
      ),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('following tab stays empty without follows and does not throw', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final users = SampleUserRepository();
    await users.unfollowTeam(SampleUserRepository.sampleUid, 'kashima_antlers');
    await users.unfollowTeam(SampleUserRepository.sampleUid, 'gamba_osaka');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userRepositoryProvider.overrideWith((ref) => users),
          teamRepositoryProvider.overrideWith((ref) => SampleTeamRepository()),
          competitionMembershipRepositoryProvider.overrideWith(
            (ref) => SampleCompetitionMembershipRepository(),
          ),
          userProfileProvider.overrideWith(
            (ref) => users.watchProfile(SampleUserRepository.sampleUid),
          ),
        ],
        child: RepaintBoundary(
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
                brightness: Brightness.dark,
              ),
            ),
            home: const TeamSearchScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('フォロー中のチームはありません'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(tester.takeException(), isNull);
    await _capture(tester, 'search-following-empty');

    await tester.tap(find.text('サッカー'));
    await tester.pumpAndSettle();
    expect(find.text('鹿島アントラーズ'), findsOneWidget);
    expect(find.text('フォロー中のチームはありません'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

void _expectTwoDestinations(WidgetTester tester) {
  final bar = tester.widget<NavigationBar>(
    find.byKey(const ValueKey('sport-sub-nav')),
  );
  expect(bar.destinations, hasLength(2));
}

void _expectSelectedHome(WidgetTester tester) {
  expect(
    find.descendant(
      of: find.byKey(const ValueKey('sport-sub-nav')),
      matching: find.byIcon(Icons.home),
    ),
    findsOneWidget,
  );
}
