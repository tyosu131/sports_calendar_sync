import 'dart:io';
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sports_calendar_sync/core/config/sports_registry.dart';
import 'package:sports_calendar_sync/core/utils/date_time_utils.dart';
import 'package:sports_calendar_sync/domain/models/game.dart';
import 'package:sports_calendar_sync/presentation/theme/competition_vs_frame.dart';
import 'package:sports_calendar_sync/presentation/theme/presentation_decoration.dart';
import 'package:sports_calendar_sync/presentation/widgets/competition_vs_frame.dart';
import 'package:sports_calendar_sync/presentation/widgets/game_card.dart';

const _captureDir = String.fromEnvironment('CAPTURE_VS_FRAME');

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

  test('home and away frame colors differ and ignore team names', () {
    const keys = [
      'football_j1',
      'football_premier',
      'baseball_npb',
      'unknown',
      null,
    ];
    for (final key in keys) {
      final first = competitionVsFrameColors(key);
      final again = competitionVsFrameColors(key);
      expect(first.home, again.home);
      expect(first.away, again.away);
      expect(first.home, isNot(first.away));
      expect(decorativeCardPalette, contains(first.home));
      expect(decorativeCardPalette, contains(first.away));
      expect(_channelSpread(first.home), greaterThan(40));
      expect(_channelSpread(first.away), greaterThan(40));
    }
    expect(
      competitionVsFrameColors('football_j1').home,
      isNot(competitionVsFrameColors('football_premier').home),
    );
  });

  test('contrast ratio matches WCAG reference pairs', () {
    expect(contrastRatio(Colors.white, Colors.black), closeTo(21, 0.05));
    expect(contrastRatio(Colors.black, Colors.white), closeTo(21, 0.05));
    expect(contrastRatio(Colors.white, Colors.white), closeTo(1, 0.01));
    expect(
      contrastRatio(Colors.white, const Color(0xFF767676)),
      closeTo(4.54, 0.06),
    );
  });

  testWidgets(
    'match card frames differ by color and shape without going gray',
    (tester) async {
      final theme = _darkTheme();
      final game = _game(timezone: 'America/New_York');
      await _pumpCard(
        tester,
        theme: theme,
        game: game,
        perspectiveTeamIds: const ['kashima_antlers'],
        boundaryKey: 'vs-frame-shot',
      );

      final home = _painter(tester, 'vs-frame-home-paint');
      final away = _painter(tester, 'vs-frame-away-paint');
      final frames = competitionVsFrameColors('football_j1');
      expect(home.side, CompetitionVsSideKind.home);
      expect(away.side, CompetitionVsSideKind.away);
      expect(home.color, frames.home);
      expect(away.color, frames.away);
      expect(home.color, isNot(away.color));
      expect(
        competitionVsFrameFill(home.color),
        isNot(competitionVsFrameFill(away.color)),
      );

      final homeBox = tester.getRect(find.byKey(const Key('vs-frame-home')));
      final awayBox = tester.getRect(find.byKey(const Key('vs-frame-away')));
      expect(homeBox.right, lessThan(awayBox.left));

      final card = tester.widget<Card>(find.byType(Card));
      expect(card.color, theme.colorScheme.surface);
      expect(card.color, isNot(home.color));
      expect(card.color, isNot(away.color));
      expect(card.color, isNot(Colors.grey));
      expect(card.color, isNot(const Color(0xFF9E9E9E)));

      final homeLabel = tester
          .getSemantics(find.byKey(const Key('vs-frame-home')))
          .label;
      final awayLabel = tester
          .getSemantics(find.byKey(const Key('vs-frame-away')))
          .label;
      expect(homeLabel, startsWith('ホーム側'));
      expect(homeLabel, contains('鹿島アントラーズ'));
      expect(awayLabel, startsWith('アウェイ側'));
      expect(awayLabel, contains('浦和レッズ'));
      expect(
        find.byKey(const Key('followed-fixture-place-stadium')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('followed-fixture-place-travel')),
        findsNothing,
      );
      expect(find.byKey(const Key('neutral-team-mark')), findsNothing);
      expect(find.text('鹿'), findsOneWidget);
      expect(find.text('浦'), findsOneWidget);
      expect(find.byType(Image), findsNothing);

      final badge = tester.widget<CircleAvatar>(
        find.byType(CircleAvatar).first,
      );
      expect(badge.backgroundColor, isNot(frames.home));
      expect(badge.backgroundColor, isNot(frames.away));

      final kickoff = DateTimeUtils.formatTimeOnly(game.startTimeUtcDateTime);
      expect(find.text(kickoff), findsOneWidget);
      expect(find.text('06:00'), findsNothing);
      expect(find.text('10:00'), findsNothing);
      expect(find.textContaining('America/New_York'), findsNothing);
      expect(find.textContaining('現地'), findsNothing);

      final resolved = Theme.of(tester.element(find.byType(GameCard)));
      final time = tester.widget<Text>(find.text(kickoff));
      expect(time.style?.fontWeight, FontWeight.w800);
      expect(time.style?.fontSize, resolved.textTheme.headlineMedium?.fontSize);
      final date = tester.widget<Text>(
        find.text(DateTimeUtils.formatJstDate(game.startTimeUtcDateTime)),
      );
      expect(date.style?.fontSize, resolved.textTheme.bodyLarge?.fontSize);
      expect(date.style!.fontSize!, lessThan(time.style!.fontSize!));
      _expectTeamNameContrast(
        tester,
        homeName: '鹿島アントラーズ',
        awayName: '浦和レッズ',
        frames: frames,
        bodyLarge: resolved.textTheme.bodyLarge?.fontSize,
      );

      await _capture(tester, 'home-vs-frame', 'vs-frame-shot');
    },
  );

  testWidgets('away card keeps the transit cue and the away frame', (
    tester,
  ) async {
    final theme = _darkTheme();
    await _pumpCard(
      tester,
      theme: theme,
      game: _game(timezone: 'UTC'),
      perspectiveTeamIds: const ['urawa_reds'],
      boundaryKey: 'vs-frame-away-shot',
    );

    expect(
      _painter(tester, 'vs-frame-away-paint').side,
      CompetitionVsSideKind.away,
    );
    expect(
      find.byKey(const Key('followed-fixture-place-travel')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('followed-fixture-place-stadium')),
      findsNothing,
    );
    expect(find.text('19:00'), findsOneWidget);
    expect(find.text('10:00'), findsNothing);
    expect(find.text('鹿'), findsOneWidget);
    await _capture(tester, 'away-vs-frame', 'vs-frame-away-shot');
  });

  testWidgets('same competition uses the same frame colors for other clubs', (
    tester,
  ) async {
    final theme = _darkTheme();
    await _pumpCard(
      tester,
      theme: theme,
      game: _game(
        homeTeamId: 'kawasaki_frontale',
        homeName: '川崎フロンターレ',
        awayTeamId: 'yokohama_f_marinos',
        awayName: '横浜Ｆ・マリノス',
      ),
      perspectiveTeamIds: const [],
    );
    final frames = competitionVsFrameColors('football_j1');
    expect(_painter(tester, 'vs-frame-home-paint').color, frames.home);
    expect(_painter(tester, 'vs-frame-away-paint').color, frames.away);
    expect(find.text('川'), findsOneWidget);
    expect(find.text('横'), findsOneWidget);
    expect(find.byKey(const Key('neutral-team-mark')), findsNothing);
    final resolved = Theme.of(tester.element(find.byType(GameCard)));
    _expectTeamNameContrast(
      tester,
      homeName: '川崎フロンターレ',
      awayName: '横浜Ｆ・マリノス',
      frames: frames,
      bodyLarge: resolved.textTheme.bodyLarge?.fontSize,
    );
  });

  testWidgets(
    'every enabled competition keeps team-name contrast on the painted fill',
    (tester) async {
      final theme = _darkTheme();
      final enabled = SportsRegistry.enabled;
      expect(enabled, isNotEmpty);

      var lightestKey = enabled.first.competitionKey;
      var darkestKey = enabled.first.competitionKey;
      var lightest = -1.0;
      var darkest = 2.0;
      for (final competition in enabled) {
        final frames = competitionVsFrameColors(competition.competitionKey);
        for (final base in [frames.home, frames.away]) {
          final luminance = relativeLuminance(competitionVsFrameFill(base));
          if (luminance > lightest) {
            lightest = luminance;
            lightestKey = competition.competitionKey;
          }
          if (luminance < darkest) {
            darkest = luminance;
            darkestKey = competition.competitionKey;
          }
        }
      }

      for (final competition in enabled) {
        final key = competition.competitionKey;
        final homeName = 'Home $key';
        final awayName = 'Away $key';
        await _pumpCard(
          tester,
          theme: theme,
          game: _game(
            competitionKey: key,
            homeTeamId: 'home-side',
            homeName: homeName,
            awayName: awayName,
          ),
          perspectiveTeamIds: const ['home-side'],
          boundaryKey: 'vs-frame-contrast',
        );
        final frames = competitionVsFrameColors(key);
        expect(frames.home, isNot(frames.away));
        expect(
          _painter(tester, 'vs-frame-home-paint').side,
          CompetitionVsSideKind.home,
        );
        expect(
          _painter(tester, 'vs-frame-away-paint').side,
          CompetitionVsSideKind.away,
        );
        final resolved = Theme.of(tester.element(find.byType(GameCard)));
        _expectTeamNameContrast(
          tester,
          homeName: homeName,
          awayName: awayName,
          frames: frames,
          bodyLarge: resolved.textTheme.bodyLarge?.fontSize,
        );
        if (key == lightestKey) {
          await _capture(tester, 'light-frame', 'vs-frame-contrast');
        }
        if (key == darkestKey) {
          await _capture(tester, 'dark-frame', 'vs-frame-contrast');
        }
      }
    },
  );
}

void _expectTeamNameContrast(
  WidgetTester tester, {
  required String homeName,
  required String awayName,
  required CompetitionVsFrameColors frames,
  required double? bodyLarge,
}) {
  final homeText = tester.widget<Text>(find.text(homeName));
  final awayText = tester.widget<Text>(find.text(awayName));
  final homeFill = competitionVsFrameFill(frames.home);
  final awayFill = competitionVsFrameFill(frames.away);
  expect(homeText.style?.color, competitionVsFrameTextColor(frames.home));
  expect(awayText.style?.color, competitionVsFrameTextColor(frames.away));
  expect(homeText.style?.color, anyOf(Colors.white, Colors.black));
  expect(awayText.style?.color, anyOf(Colors.white, Colors.black));
  expect(
    contrastRatio(homeText.style!.color!, homeFill),
    greaterThanOrEqualTo(4.5),
  );
  expect(
    contrastRatio(awayText.style!.color!, awayFill),
    greaterThanOrEqualTo(4.5),
  );
  expect(homeText.style?.fontSize, bodyLarge);
  expect(awayText.style?.fontSize, bodyLarge);
  expect(homeText.style?.fontWeight, FontWeight.bold);
}

CompetitionVsFramePainter _painter(WidgetTester tester, String key) {
  return tester.widget<CustomPaint>(find.byKey(Key(key))).painter!
      as CompetitionVsFramePainter;
}

int _channelSpread(Color color) {
  final channels = [
    (color.r * 255).round(),
    (color.g * 255).round(),
    (color.b * 255).round(),
  ];
  channels.sort();
  return channels.last - channels.first;
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
  required ThemeData theme,
  required Game game,
  required List<String> perspectiveTeamIds,
  String? boundaryKey,
}) async {
  await tester.binding.setSurfaceSize(const Size(390, 640));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final card = GameCard(game: game, perspectiveTeamIds: perspectiveTeamIds);
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
            if (boundaryKey == null)
              card
            else
              RepaintBoundary(key: Key(boundaryKey), child: card),
          ],
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _capture(
  WidgetTester tester,
  String name,
  String boundaryKey,
) async {
  if (_captureDir.isEmpty) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(Key(boundaryKey)),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('$_captureDir/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
  });
}

Game _game({
  String timezone = 'UTC',
  String competitionKey = 'football_j1',
  String homeTeamId = 'kashima_antlers',
  String homeName = '鹿島アントラーズ',
  String awayTeamId = 'urawa_reds',
  String awayName = '浦和レッズ',
}) {
  return Game(
    id: 'vs-frame',
    leagueId: 'j1',
    competitionKey: competitionKey,
    homeTeamId: homeTeamId,
    homeTeamNameJa: homeName,
    homeTeamNameEn: homeName,
    awayTeamId: awayTeamId,
    awayTeamNameJa: awayName,
    awayTeamNameEn: awayName,
    startTimeUtc: Timestamp.fromDate(DateTime.utc(2026, 10, 17, 10)),
    startTimeJst: '2026-10-17 19:00',
    timezone: timezone,
    status: GameStatus.scheduled,
    venue: '国立競技場',
  );
}
