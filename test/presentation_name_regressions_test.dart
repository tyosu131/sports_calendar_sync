import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sports_calendar_sync/core/utils/local_ics_builder.dart';
import 'package:sports_calendar_sync/domain/models/game.dart';
import 'package:sports_calendar_sync/domain/policies/team_display_name_policy.dart';

void main() {
  final cases =
      jsonDecode(
            File(
              'test/fixtures/presentation_name_regressions.json',
            ).readAsStringSync(),
          )
          as List;

  for (final row in cases) {
    test('final name policy shared oracle: ${row['id']}', () {
      final game = regressionGame(row);
      final before = game.toFirestore();
      expect(teamDisplayNames.awayName(game), row['expected']);
      expect(game.toFirestore(), before);
      expect(game.awayTeamId, isNull);
    });
  }

  test('local ICS preserves rejected raw labels using the shared oracle', () {
    for (final row in cases.where((row) => row['expected'] != '')) {
      final game = regressionGame(row);
      final ics = LocalIcsBuilder.buildForTeam(
        teamId: 'kawasaki_frontale',
        games: [game],
        generatedAtUtc: DateTime.utc(2026, 9, 21),
      );
      final summary = ics
          .split('\r\n')
          .singleWhere((line) => line.startsWith('SUMMARY:'));
      expect(
        summary.endsWith(' vs ${row['expected']}'),
        isTrue,
        reason: row['id'],
      );
      expect(ics, contains('UID:${row['id']}@sports-calendar-sync.local'));
      expect(game.homeTeamId, 'kawasaki_frontale');
      expect(game.awayTeamId, isNull);
    }
  });
}

Game regressionGame(Map<String, dynamic> row) {
  final names = row['names'] as Map<String, dynamic>;
  return Game(
    id: row['id'],
    leagueId: 'test',
    competitionKey: row['competition'],
    homeTeamId: 'kawasaki_frontale',
    homeTeamNameJa: '川崎フロンターレ',
    awayTeamNameJa: names['japanese'] ?? '',
    awayTeamNameEn: names['english'],
    awayTeamProviderName: names['provider'],
    startTimeUtc: Timestamp.fromDate(DateTime.utc(2026, 9, 21, 9)),
    startTimeJst: '',
    timezone: 'UTC',
    status: GameStatus.scheduled,
  );
}
