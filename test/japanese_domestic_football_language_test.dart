import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sports_calendar_sync/domain/models/game.dart';
import 'package:sports_calendar_sync/domain/models/team.dart';
import 'package:sports_calendar_sync/domain/policies/japanese_domestic_football.dart';
import 'package:sports_calendar_sync/domain/policies/league_browse_presentation.dart';
import 'package:sports_calendar_sync/domain/policies/team_display_name_policy.dart';
import 'package:sports_calendar_sync/domain/policies/team_presentation_policy.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ja');
  });

  final oracle =
      jsonDecode(
            File(
              'test/fixtures/japanese_domestic_football_language.json',
            ).readAsStringSync(),
          )
          as Map<String, dynamic>;

  test(
    'Japanese domestic football classification matches the shared oracle',
    () {
      for (final key in oracle['japanese'] as List) {
        expect(isJapaneseDomesticFootballCompetition(key as String), isTrue);
        expect(teamDisplayNames.languageFor(key), DisplayLanguage.japanese);
      }
      for (final key in oracle['english'] as List) {
        final value = key == '' ? null : key as String;
        expect(
          isJapaneseDomesticFootballCompetition(value),
          isFalse,
          reason: '$key',
        );
        expect(teamDisplayNames.languageFor(value), DisplayLanguage.english);
      }
    },
  );

  test('shared name inputs choose the same canonical language', () {
    for (final row in oracle['names'] as List) {
      final data = Map<String, dynamic>.from(row as Map);
      final competition = data['competition'] as String?;
      final team = Team(
        id: data['teamId'] as String,
        nameEn: data['english'] as String,
        nameJa: data['japanese'] as String,
        leagueId: 'test',
        competitionKey: competition,
      );
      final game = _game(
        competition: competition,
        homeJa: data['japanese'] as String,
        homeEn: data['english'] as String,
        homeProvider: data['provider'] as String,
        homeTeamId: data['teamId'] as String,
      );
      expect(
        teamDisplayNames.teamName(team),
        data['expected'],
        reason: data['id'],
      );
      expect(
        teamDisplayNames.homeName(game),
        data['expected'],
        reason: data['id'],
      );
    }
  });

  test(
    'confirmed J1 J2 and J3 clubs stay Japanese in every domestic context',
    () {
      const domestic = [
        'football_j1',
        'football_j2',
        'football_j3',
        'football_j_league_cup',
        'football_emperor_cup',
        'football_j2_j3_special',
      ];
      final catalog =
          jsonDecode(
                File(
                  'functions/src/domain/teamPresentationCatalog.json',
                ).readAsStringSync(),
              )
              as List;
      final clubs = catalog.where((row) {
        final source = (row as Map)['source'] as String;
        return source.endsWith('j1Teams.js') ||
            source.endsWith('j2Teams.js') ||
            source.endsWith('j3Teams.js');
      }).toList();
      expect(clubs, isNotEmpty);
      for (final row in clubs) {
        final entry = Map<String, dynamic>.from(row as Map);
        final nameJa = entry['nameJa'] as String;
        final nameEn = entry['nameEn'] as String;
        final source = entry['source'] as String;
        expect(nameJa, isNotEmpty, reason: nameEn);
        final division = source.endsWith('j1Teams.js')
            ? 'football_j1'
            : source.endsWith('j2Teams.js')
            ? 'football_j2'
            : 'football_j3';
        final team = Team(
          id: 'catalog-$nameEn',
          nameEn: nameEn,
          nameJa: nameJa,
          leagueId: 'test',
          competitionKey: division,
        );
        expect(teamDisplayNames.teamName(team), nameJa, reason: nameEn);
        for (final competition in domestic) {
          expect(
            teamDisplayNames.homeName(
              _game(
                competition: competition,
                homeJa: nameJa,
                homeEn: nameEn,
                homeProvider: nameEn,
              ),
            ),
            nameJa,
            reason: '$nameEn $competition',
          );
        }
      }
    },
  );

  test('legacy sportKey is classified before a name is chosen', () {
    final team = Team.fromFirestore({
      'nameEn': 'Jubilo Iwata',
      'nameJa': 'ジュビロ磐田',
      'leagueId': 'j2_league',
      'sportKey': 'football_j2',
    }, 'jubilo_iwata');
    expect(team.competitionKey, 'football_j2');
    expect(teamDisplayNames.teamName(team), 'ジュビロ磐田');

    final game = Game.fromFirestore({
      'leagueId': 'j2_j3',
      'sportKey': 'football_j2_j3_special',
      'competitionSeasonKey': 'football_j2_j3_2026_hyakunen',
      'homeTeamId': 'jubilo_iwata',
      'homeTeamNameJa': 'ジュビロ磐田',
      'homeTeamNameEn': 'Jubilo Iwata',
      'homeTeamProviderName': 'Jubilo Iwata',
      'awayTeamNameJa': 'ベガルタ仙台',
      'awayTeamNameEn': 'Vegalta Sendai',
      'awayTeamProviderName': 'Vegalta Sendai',
      'startTimeUTC': Timestamp.fromDate(DateTime.utc(2026, 9, 19, 9)),
      'startTimeJST': '2026-09-19 18:00',
      'timezone': 'UTC',
      'status': 'scheduled',
    }, 'legacy-special');
    expect(game.competitionKey, 'football_j2_j3_special');
    expect(teamDisplayNames.homeName(game), 'ジュビロ磐田');
    expect(teamDisplayNames.awayName(game), 'ベガルタ仙台');
  });

  test('a season key alone does not create a domestic competition context', () {
    final game = _game(
      competition: null,
      seasonKey: 'football_j2_j3_2026_hyakunen',
      homeJa: 'ジュビロ磐田',
      homeEn: 'Jubilo Iwata',
      homeProvider: 'Jubilo Iwata',
    );
    expect(game.competitionKey, isNull);
    expect(teamDisplayNames.homeName(game), 'Jubilo Iwata');
  });

  test(
    'next opponent uses the game competition language, not a short label',
    () {
      const jubilo = Team(
        id: 'jubilo_iwata',
        nameEn: 'Jubilo Iwata',
        nameJa: 'ジュビロ磐田',
        leagueId: 'j2_league',
        competitionKey: 'football_j2',
      );
      final game = _game(
        competition: 'football_j2_j3_special',
        seasonKey: 'football_j2_j3_2026_hyakunen',
        homeJa: 'ジュビロ磐田',
        homeEn: 'Jubilo Iwata',
        homeProvider: 'Jubilo Iwata',
        homeTeamId: 'jubilo_iwata',
        awayJa: 'ベガルタ仙台',
        awayEn: 'Vegalta Sendai',
        awayProvider: 'Vegalta Sendai',
        awayTeamId: 'vegalta_sendai',
      );
      final next = nextMatchForTeam(jubilo, [
        game,
      ], competitionContextKey: 'football_j2_j3_special');
      expect(next?.opponent, 'vs ベガルタ仙台');
    },
  );

  test('short domestic aliases follow the same competition classification', () {
    expect(
      clubPresentation([
        'Tokyo',
      ], competitionKey: 'football_j2_j3_special')?.nameJa,
      'ＦＣ東京',
    );
    expect(
      clubPresentation([
        'Tochigi',
      ], competitionKey: 'football_j_future_domestic')?.nameJa,
      '栃木ＳＣ',
    );
    expect(
      clubPresentation(['Tokyo'], competitionKey: 'football_premier'),
      isNull,
    );
    expect(
      clubPresentation(['Sabah'], competitionKey: 'football_j2_j3_special'),
      isNull,
    );
  });
}

Game _game({
  required String? competition,
  required String homeJa,
  required String homeEn,
  required String homeProvider,
  String? seasonKey,
  String? homeTeamId,
  String awayJa = '対戦相手',
  String awayEn = 'Opponent',
  String awayProvider = 'Opponent',
  String? awayTeamId,
}) {
  return Game(
    id: 'language-game',
    leagueId: 'test',
    competitionKey: competition,
    competitionSeasonKey: seasonKey,
    homeTeamId: homeTeamId,
    awayTeamId: awayTeamId,
    homeTeamNameJa: homeJa,
    awayTeamNameJa: awayJa,
    homeTeamNameEn: homeEn,
    awayTeamNameEn: awayEn,
    homeTeamProviderName: homeProvider,
    awayTeamProviderName: awayProvider,
    startTimeUtc: Timestamp.fromDate(DateTime.utc(2026, 9, 19, 9)),
    startTimeJst: '2026-09-19 18:00',
    timezone: 'UTC',
    status: GameStatus.scheduled,
  );
}
