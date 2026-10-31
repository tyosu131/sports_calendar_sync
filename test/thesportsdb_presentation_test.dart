import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sports_calendar_sync/domain/models/game.dart';
import 'package:sports_calendar_sync/domain/policies/kickoff_clock.dart';
import 'package:sports_calendar_sync/presentation/widgets/game_card.dart';

Game _ufcCard() => Game(
  id: 'tsdb_1',
  leagueId: 'ufc',
  competitionKey: 'mma_ufc',
  homeTeamId: 'tsdb_league_4443',
  homeTeamNameJa: 'UFC 324 Gaethje vs Pimblett',
  homeTeamNameEn: 'UFC 324 Gaethje vs Pimblett',
  awayTeamNameJa: '',
  startTimeUtc: Timestamp.fromDate(DateTime.utc(2026, 11, 7, 22)),
  startTimeJst: '2026-11-08 07:00',
  timezone: 'UTC',
  status: GameStatus.scheduled,
  venue: 'T-Mobile Arena',
  venueUtcOffsetMinutes: -8 * 60,
);

void main() {
  setUpAll(() async => initializeDateFormatting('ja'));

  test(
    'venue offset gives the venue local time, preferred over a reference clock',
    () {
      // Sydney card: 22:00 UTC is 09:00 next day at the venue (+11).
      final sydney = displayedKickoff(
        startTimeUtc: DateTime.utc(2026, 1, 31, 22),
        providerTimezone: 'UTC',
        competitionKey: 'mma_ufc',
        venueUtcOffsetMinutes: 11 * 60,
      );
      expect(sydney.reference!.label, '現地時間');
      expect(sydney.reference!.time, '09:00');
      expect(sydney.reference!.date, isNull); // Same calendar day as JST (2/1).
      expect(sydney.reference!.zone, 'UTC+11:00');

      final vegas = displayedKickoff(
        startTimeUtc: DateTime.utc(2026, 11, 7, 22),
        providerTimezone: 'UTC',
        competitionKey: 'mma_ufc',
        venueUtcOffsetMinutes: -8 * 60,
      );
      expect(vegas.reference!.text, '現地時間 11/7 14:00');
    },
  );

  test(
    'no offset falls back to the competition clock; JST venues add nothing',
    () {
      final nfl = displayedKickoff(
        startTimeUtc: DateTime.utc(2026, 11, 9, 1, 20),
        providerTimezone: 'UTC',
        competitionKey: 'americanfootball_nfl',
      );
      expect(nfl.reference!.label, '米東部時間');
      final tokyo = venueLocalKickoff(
        startTimeUtc: DateTime.utc(2026, 11, 9, 1),
        competitionKey: 'mma_ufc',
        venueUtcOffsetMinutes: 9 * 60,
      );
      expect(tokyo, isNull);
    },
  );

  testWidgets('UFC card shows one title and no vs', (tester) async {
    final game = _ufcCard();
    expect(game.isSingleTitleEvent, isTrue);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: GameCard(game: game)),
        ),
      ),
    );
    expect(find.byKey(const Key('game-card-event-title')), findsOneWidget);
    expect(find.text('UFC 324 Gaethje vs Pimblett'), findsOneWidget);
    expect(find.text('vs'), findsNothing);
    expect(find.text('現地時間 11/7 14:00'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
