import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sports_calendar_sync/domain/models/game.dart';

void main() {
  test('GOAL game accepts an unmapped opponent and preserves source IDs', () {
    final game = Game.fromFirestore({
      'competitionKey': 'football_premier',
      'competitionSeasonKey': 'football_premier_2026_2027',
      'leagueId': 'premier_league',
      'homeTeamId': 'arsenal',
      'homeSourceTeamId': 'goal-arsenal',
      'homeTeamNameJa': 'アーセナル',
      'awaySourceTeamId': 'goal-opponent',
      'awayTeamNameJa': 'Opponent FC',
      'startTimeUTC': Timestamp.fromDate(DateTime.utc(2026, 9, 20)),
      'startTimeJST': '2026-09-20 09:00',
      'timezone': 'UTC',
      'status': 'scheduled',
      'broadcastPlatforms': <dynamic>[],
      'sourceProvider': 'goal',
      'sourceFixtureId': 'goal-fixture-1',
    }, 'game-1');

    expect(game.homeTeamId, 'arsenal');
    expect(game.awayTeamId, isNull);
    expect(game.homeSourceTeamId, 'goal-arsenal');
    expect(game.awaySourceTeamId, 'goal-opponent');
    expect(game.awayTeamNameJa, 'Opponent FC');
    expect(game.toFirestore(), isNot(contains('awayTeamId')));
    expect(game.toFirestore()['sourceFixtureId'], 'goal-fixture-1');
  });
}
