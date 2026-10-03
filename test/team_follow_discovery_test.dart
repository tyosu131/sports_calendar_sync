import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sports_calendar_sync/data/providers/auth_providers.dart';
import 'package:sports_calendar_sync/data/providers/repository_providers.dart';
import 'package:sports_calendar_sync/data/repositories/competition_membership_repository.dart';
import 'package:sports_calendar_sync/data/repositories/team_repository.dart';
import 'package:sports_calendar_sync/data/repositories/user_repository.dart';
import 'package:sports_calendar_sync/presentation/screens/team_search_screen.dart';

void main() {
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
        child: const MaterialApp(
          locale: Locale('ja', 'JP'),
          localizationsDelegates: [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [Locale('ja', 'JP'), Locale('en', 'US')],
          home: TeamSearchScreen(),
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

    await tester.tap(find.text('サッカー'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('sport-sub-nav')), findsOneWidget);
    _expectTwoDestinations(tester);

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
