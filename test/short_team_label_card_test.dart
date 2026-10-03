import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sports_calendar_sync/data/providers/auth_providers.dart';
import 'package:sports_calendar_sync/data/providers/game_providers.dart';
import 'package:sports_calendar_sync/data/providers/repository_providers.dart';
import 'package:sports_calendar_sync/data/providers/team_providers.dart';
import 'package:sports_calendar_sync/data/repositories/user_repository.dart';
import 'package:sports_calendar_sync/domain/models/game.dart';
import 'package:sports_calendar_sync/domain/models/team.dart';
import 'package:sports_calendar_sync/presentation/screens/league_teams_screen.dart';

const _screenshotDir = String.fromEnvironment(
  'CAPTURE_SHORT_LABEL_SCREENSHOTS',
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

Team _team({
  required String id,
  required String nameJa,
  required String nameEn,
}) {
  return Team(
    id: id,
    nameEn: nameEn,
    nameJa: nameJa,
    leagueId: 'sample_j1_league',
    competitionKey: 'football_j1',
  );
}

void main() {
  setUpAll(_loadCjkFont);

  testWidgets('league cards use a place alias or the full name', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final kawasaki = _team(
      id: 'kawasaki_frontale',
      nameJa: '川崎フロンターレ',
      nameEn: 'Kawasaki Frontale',
    );
    final marinos = _team(
      id: 'yokohama_f_marinos',
      nameJa: '横浜Ｆ・マリノス',
      nameEn: 'Yokohama F. Marinos',
    );
    final users = SampleUserRepository();
    await users.followTeam(SampleUserRepository.sampleUid, kawasaki.id);
    await users.followTeam(SampleUserRepository.sampleUid, marinos.id);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userRepositoryProvider.overrideWith((ref) => users),
          userProfileProvider.overrideWith(
            (ref) => users.watchProfile(SampleUserRepository.sampleUid),
          ),
          teamsByCompetitionProvider.overrideWith(
            (ref, key) async => [kawasaki, marinos],
          ),
          upcomingGamesForTeamIdsProvider.overrideWith(
            (ref, key) async => const <Game>[],
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
            home: const LeagueTeamsScreen(competitionKey: 'football_j1'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final kawasakiCard = find.byKey(
      const ValueKey('league-team-card-kawasaki_frontale'),
    );
    final marinosCard = find.byKey(
      const ValueKey('league-team-card-yokohama_f_marinos'),
    );
    expect(
      find.descendant(of: kawasakiCard, matching: find.text('川崎')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: kawasakiCard, matching: find.text('川')),
      findsOneWidget,
    );
    expect(find.text('川崎F'), findsNothing);
    final fullName = tester.widget<Text>(
      find.descendant(of: marinosCard, matching: find.text('横浜Ｆ・マリノス')),
    );
    expect(fullName.maxLines, 2);
    expect(fullName.overflow, TextOverflow.ellipsis);
    expect(find.text('マリノス'), findsNothing);
    expect(find.text('フォロー中'), findsNWidgets(2));
    expect(find.text('次の試合は未定'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
    await _capture(tester, 'short-label-kawasaki');

    await tester.tap(
      find.descendant(of: marinosCard, matching: find.byTooltip('フォロー解除')),
    );
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: marinosCard, matching: find.text('フォロー')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: kawasakiCard, matching: find.text('フォロー中')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
