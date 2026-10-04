import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sports_calendar_sync/domain/models/competition_season_membership.dart';
import 'package:sports_calendar_sync/domain/models/firestore_decode.dart';
import 'package:sports_calendar_sync/domain/models/game.dart';
import 'package:sports_calendar_sync/domain/models/sport.dart';
import 'package:sports_calendar_sync/domain/models/team.dart';

void main() {
  test('decodes a valid team', () {
    final team = Team.fromFirestore({
      'nameEn': 'Kashima Antlers',
      'nameJa': '鹿島アントラーズ',
      'leagueId': 'j1_league',
      'competitionKey': 'football_j1',
      'externalTeamId': 1,
    }, 'kashima_antlers');

    expect(team.id, 'kashima_antlers');
    expect(team.nameJa, '鹿島アントラーズ');
    expect(team.leagueId, 'j1_league');
    expect(team.competitionKey, 'football_j1');
    expect(team.externalTeamId, 1);
  });

  test('an invalid required team field names the document and field', () {
    expect(
      () => Team.fromFirestore({
        'nameEn': 12,
        'nameJa': '鹿島アントラーズ',
        'leagueId': 'j1_league',
      }, 'kashima_antlers'),
      throwsA(_decode('teams', 'kashima_antlers', 'nameEn', 'int')),
    );
  });

  test('decodes a valid game', () {
    final game = Game.fromFirestore({
      'leagueId': 'j1_league',
      'competitionKey': 'football_j1',
      'homeTeamNameJa': '鹿島アントラーズ',
      'awayTeamNameJa': '浦和レッズ',
      'startTimeUTC': Timestamp.fromDate(DateTime.utc(2026, 8, 1)),
      'startTimeJST': '2026-08-01 19:00',
      'timezone': 'UTC',
      'status': 'finished',
      'homeScore': 1,
      'awayScore': 0,
      'broadcastPlatforms': [
        {'platform': 'DAZN', 'url': 'https://example.test/dazn'},
      ],
    }, 'game-1');

    expect(game.status, GameStatus.finished);
    expect(game.homeScore, 1);
    expect(game.broadcastPlatforms.single.platform, 'DAZN');
  });

  test('decode text names the type and not the stored value', () {
    const secret = 'user@example.com';
    const token = 'https://example.test/reset?token=abc123';
    FirestoreDecodeException? error;
    try {
      Game.fromFirestore({
        ..._game(),
        'startTimeUTC': secret,
        'broadcastPlatforms': [
          {'platform': token},
        ],
      }, 'game-1');
    } on FirestoreDecodeException catch (caught) {
      error = caught;
    }

    expect(error, isNotNull);
    expect(error!.field, 'startTimeUTC');
    expect(error.actual, secret);
    expect(error.toString(), contains('games/game-1'));
    expect(error.toString(), contains('expected Timestamp, got String'));
    expect(error.toString(), isNot(contains(secret)));
    expect(error.toString(), isNot(contains(token)));
    expect(error.toString(), isNot(contains('example.test')));

    FirestoreDecodeException? missing;
    FirestoreDecodeException? isNull;
    try {
      Team.fromFirestore({
        'nameJa': '鹿島アントラーズ',
        'leagueId': 'j1_league',
      }, 'kashima_antlers');
    } on FirestoreDecodeException catch (caught) {
      missing = caught;
    }
    try {
      Team.fromFirestore({
        'nameEn': null,
        'nameJa': '鹿島アントラーズ',
        'leagueId': 'j1_league',
      }, 'kashima_antlers');
    } on FirestoreDecodeException catch (caught) {
      isNull = caught;
    }
    expect(missing!.toString(), contains('got missing'));
    expect(isNull!.toString(), contains('got null'));
    expect(missing.toString(), isNot(contains('got null')));
  });

  test('an invalid timestamp names the game document', () {
    expect(
      () => Game.fromFirestore({
        ..._game(),
        'startTimeUTC': '2026-08-01T10:00:00Z',
      }, 'game-1'),
      throwsA(_decode('games', 'game-1', 'startTimeUTC', 'String')),
    );
  });

  test('an invalid required league field names the league document', () {
    expect(
      () => League.fromFirestore({
        'nameEn': 'J1 League',
        'nameJa': 1,
        'country': 'Japan',
      }, 'j1_league'),
      throwsA(_decode('leagues', 'j1_league', 'nameJa', 'int')),
    );
  });

  test('a malformed broadcast entry names the index and field', () {
    expect(
      () => Game.fromFirestore({
        ..._game(),
        'broadcastPlatforms': [
          {'platform': 1},
        ],
      }, 'game-1'),
      throwsA(
        _decode('games', 'game-1', 'broadcastPlatforms[0].platform', 'int'),
      ),
    );
  });

  test('a bad membership field fails instead of being skipped', () {
    expect(
      () => CompetitionSeasonMembership.fromFirestore({
        'competitionKey': 'football_j1',
        'seasonYear': '2026',
        'displayNameJa': 'J1',
        'membershipType': 'league',
        'status': 'seedable',
        'seedable': true,
      }, 'football_j1_2026'),
      throwsA(
        _decode(
          'competitionSeasonMemberships',
          'football_j1_2026',
          'seasonYear',
          'String',
        ),
      ),
    );
  });

  test('an unreadable membership status still decodes', () {
    final membership = CompetitionSeasonMembership.fromFirestore({
      'competitionKey': 'football_j1',
      'seasonYear': 2026,
      'displayNameJa': 'J1',
      'membershipType': 'league',
      'status': 'draft',
      'seedable': false,
      'memberTeamIds': ['kashima_antlers'],
    }, 'football_j1_2026');

    expect(membership.status, 'draft');
    expect(membership.memberTeamIds, ['kashima_antlers']);
  });
}

Map<String, dynamic> _game() => {
  'leagueId': 'j1_league',
  'homeTeamNameJa': '鹿島アントラーズ',
  'awayTeamNameJa': '浦和レッズ',
  'startTimeUTC': Timestamp.fromDate(DateTime.utc(2026, 8, 1)),
  'startTimeJST': '2026-08-01 19:00',
  'timezone': 'UTC',
  'status': 'scheduled',
};

Matcher _decode(
  String collection,
  String documentId,
  String field,
  String actualType,
) {
  return isA<FirestoreDecodeException>()
      .having((error) => error.collection, 'collection', collection)
      .having((error) => error.documentId, 'documentId', documentId)
      .having((error) => error.field, 'field', field)
      .having(
        (error) => error.toString(),
        'toString',
        contains('$collection/$documentId'),
      )
      .having(
        (error) => error.actual.runtimeType.toString(),
        'actual type',
        actualType,
      );
}
