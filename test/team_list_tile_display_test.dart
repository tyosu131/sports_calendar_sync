import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sports_calendar_sync/domain/models/team.dart';
import 'package:sports_calendar_sync/presentation/widgets/team_list_tile.dart';

void main() {
  testWidgets('team list shows only competition-default primary name', (
    tester,
  ) async {
    const arsenal = Team(
      id: 'arsenal',
      nameEn: 'Arsenal',
      nameJa: 'アーセナル',
      leagueId: 'premier',
      competitionKey: 'football_premier',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TeamListTile(
            team: arsenal,
            isFollowing: true,
            onFollowToggle: () {},
          ),
        ),
      ),
    );
    expect(find.text('Arsenal'), findsOneWidget);
    expect(find.text('アーセナル'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
