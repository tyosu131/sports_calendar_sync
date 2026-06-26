import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sports_calendar_sync/core/utils/local_ics_builder.dart';
import 'package:sports_calendar_sync/domain/models/game.dart';

void main() {
  group('LocalIcsBuilder', () {
    test('generates VCALENDAR and VEVENT content', () {
      final ics = LocalIcsBuilder.buildForTeam(
        teamId: 'kashima_antlers',
        games: [_sampleGame()],
        generatedAtUtc: DateTime.utc(2026, 6, 26, 1, 2, 3),
      );

      expect(ics, contains('BEGIN:VCALENDAR'));
      expect(ics, contains('VERSION:2.0'));
      expect(ics, contains('PRODID:'));
      expect(ics, contains('CALSCALE:GREGORIAN'));
      expect(ics, contains('BEGIN:VEVENT'));
      expect(ics, contains('END:VEVENT'));
      expect(ics, contains('END:VCALENDAR'));
    });

    test('formats DTSTART as UTC Z time', () {
      final ics = LocalIcsBuilder.buildForTeam(
        teamId: 'kashima_antlers',
        games: [
          _sampleGame(startTimeUtc: DateTime.utc(2026, 7, 1, 10, 30, 45)),
        ],
        generatedAtUtc: DateTime.utc(2026),
      );

      expect(ics, contains('DTSTART:20260701T103045Z'));
    });

    test('uses a deterministic UID and Japanese team names in SUMMARY', () {
      final ics = LocalIcsBuilder.buildForTeam(
        teamId: 'kashima_antlers',
        games: [_sampleGame(id: 'sample_game_001')],
        generatedAtUtc: DateTime.utc(2026),
      );

      expect(ics, contains('UID:sample_game_001@sports-calendar-sync.local'));
      expect(ics, contains('SUMMARY:鹿島アントラーズ vs 浦和レッズ'));
    });

    test('escapes description and location text', () {
      final ics = LocalIcsBuilder.buildForTeam(
        teamId: 'kashima_antlers',
        games: [
          _sampleGame(
            competitionKey: r'football,j1;sample\key',
            venue:
                r'国立,競技場;Main\Gate'
                '\n'
                'Line2',
          ),
        ],
        generatedAtUtc: DateTime.utc(2026),
      );

      expect(ics, contains(r'Competition: football\,j1\;sample\\key'));
      expect(ics, contains(r'LOCATION:国立\,競技場\;Main\\Gate\nLine2'));
    });

    test('generates one VEVENT for each game', () {
      final ics = LocalIcsBuilder.buildForTeam(
        teamId: 'kashima_antlers',
        games: [
          _sampleGame(id: 'game_1'),
          _sampleGame(id: 'game_2', startTimeUtc: DateTime.utc(2026, 7, 2)),
        ],
        generatedAtUtc: DateTime.utc(2026),
      );

      expect(RegExp('BEGIN:VEVENT').allMatches(ics), hasLength(2));
      expect(ics, contains('UID:game_1@sports-calendar-sync.local'));
      expect(ics, contains('UID:game_2@sports-calendar-sync.local'));
    });

    test('handles null venue without writing null text', () {
      final ics = LocalIcsBuilder.buildForTeam(
        teamId: 'kashima_antlers',
        games: [_sampleGame(venue: null)],
        generatedAtUtc: DateTime.utc(2026),
      );

      expect(ics, contains('LOCATION:'));
      expect(ics, isNot(contains('LOCATION:null')));
    });
  });
}

Game _sampleGame({
  String id = 'game_1',
  DateTime? startTimeUtc,
  String? competitionKey = 'football_j1',
  String? venue = 'カシマサッカースタジアム',
}) {
  return Game(
    id: id,
    competitionKey: competitionKey,
    leagueId: 'j1_league',
    homeTeamId: 'kashima_antlers',
    homeTeamNameJa: '鹿島アントラーズ',
    awayTeamId: 'urawa_reds',
    awayTeamNameJa: '浦和レッズ',
    startTimeUtc: Timestamp.fromDate(
      startTimeUtc ?? DateTime.utc(2026, 7, 1, 10),
    ),
    startTimeJst: '2026-07-01 19:00',
    timezone: 'Asia/Tokyo',
    status: GameStatus.scheduled,
    venue: venue,
  );
}
