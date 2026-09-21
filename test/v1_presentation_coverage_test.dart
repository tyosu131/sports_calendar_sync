import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sports_calendar_sync/core/utils/local_ics_builder.dart';
import 'package:sports_calendar_sync/domain/models/game.dart';
import 'package:sports_calendar_sync/domain/models/team.dart';
import 'package:sports_calendar_sync/domain/policies/team_display_name_policy.dart';
import 'package:sports_calendar_sync/domain/policies/team_presentation_policy.dart';

void main() {
  test(
    'all 178 V1 slots match the same oracle used by actual ICS/Google tests',
    () {
      final snapshot =
          jsonDecode(
                File(
                  'test/fixtures/v1_presentation_snapshot.json',
                ).readAsStringSync(),
              )
              as Map<String, dynamic>;
      final teams = (snapshot['teams'] as List)
          .map(
            (row) =>
                Team.fromFirestore(Map<String, dynamic>.from(row), row['id']),
          )
          .toList();
      final resolver = TeamPresentationLogoResolver(teams);
      final rows = snapshot['games'] as List;
      expect(rows, hasLength(89));
      var nameCount = 0;
      var logoCount = 0;
      var neutralCount = 0;
      for (final row in rows) {
        final raw = Map<String, dynamic>.from(row);
        final game = Game.fromFirestore({
          ...raw,
          'startTimeUTC': Timestamp.fromDate(DateTime.utc(2026, 9, 21, 9)),
          'startTimeJST': '',
          'timezone': 'UTC',
          'status': 'scheduled',
        }, raw['id']);
        final before = game.toFirestore();
        final localIcs = LocalIcsBuilder.buildForTeam(
          teamId: game.homeTeamId ?? game.awayTeamId!,
          games: [game],
          generatedAtUtc: DateTime.utc(2026, 9, 21),
        );
        expect(
          localIcs,
          contains('${raw['homeExpectedName']} vs ${raw['awayExpectedName']}'),
        );
        for (final home in [true, false]) {
          final side = home ? 'home' : 'away';
          final name = home
              ? teamDisplayNames.homeName(game)
              : teamDisplayNames.awayName(game);
          expect(
            name,
            raw['${side}ExpectedName'],
            reason: '${raw['id']} $side',
          );
          nameCount++;
          expect(
            resolver.side(game, home),
            raw['${side}ExpectedLogo'],
            reason: name,
          );
          if (resolver.side(game, home) != null) logoCount++;
          expect(publicTeamLogoUrl(resolver.side(game, home)), isNull);
          neutralCount++;
          // Master-backed Search/Followed/Detail presentation must agree too.
          final entry = clubPresentation([
            raw['${side}TeamProviderName'],
            raw['${side}TeamNameEn'],
            raw['${side}TeamNameJa'],
          ], competitionKey: game.competitionKey);
          expect(entry, isNotNull);
          final master = Team(
            id: 'presentation-test-only',
            nameEn: entry!.nameEn,
            nameJa: entry.nameJa,
            leagueId: 'test',
            competitionKey: game.competitionKey,
          );
          expect(teamDisplayNames.teamName(master), name);
          expect(
            teamPresentationLogoCandidate(master),
            raw['${side}ExpectedLogo'],
          );
          expect(teamPresentationLogo(master), isNull);
          expect(
            home ? game.homeTeamId : game.awayTeamId,
            raw['${side}TeamId'],
          );
        }
        expect(game.toFirestore(), before);
      }
      expect(nameCount, 178);
      expect(logoCount, 178);
      expect(neutralCount, 178);
    },
  );

  test(
    'domestic competition changes retain participant name/logo without canonical promotion',
    () {
      for (final name in [
        'JEF United',
        'Tokyo',
        'Roasso Kumamoto',
        'Tegevajaro Miyazaki',
        'Vissel Kobe',
        'Kawasaki Frontale',
      ]) {
        final logos = <String?>{};
        final names = <String>{};
        for (final competition in [
          'football_j1',
          'football_j_league_cup',
          'football_emperor_cup',
        ]) {
          final game = Game.fromFirestore({
            'leagueId': 'test',
            'competitionKey': competition,
            'homeTeamNameJa': name,
            'homeTeamProviderName': name,
            'awayTeamNameJa': 'Unknown FC',
            'startTimeUTC': Timestamp.fromMillisecondsSinceEpoch(0),
            'startTimeJST': '',
            'timezone': 'UTC',
            'status': 'scheduled',
          }, 'same-fixture');
          logos.add(TeamPresentationLogoResolver(const []).side(game, true));
          names.add(teamDisplayNames.homeName(game));
          expect(game.homeTeamId, isNull);
          expect(game.awayTeamId, isNull);
        }
        expect(logos, hasLength(1));
        expect(logos.single, isNotNull);
        expect(names, hasLength(1));
      }
    },
  );
}
