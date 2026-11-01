import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sports_calendar_sync/core/config/display_language_setting.dart';
import 'package:sports_calendar_sync/core/config/sports_registry.dart';
import 'package:sports_calendar_sync/domain/models/game.dart';
import 'package:sports_calendar_sync/domain/models/team.dart';
import 'package:sports_calendar_sync/domain/policies/competition_display_policy.dart';
import 'package:sports_calendar_sync/domain/policies/followed_fixture_place.dart';
import 'package:sports_calendar_sync/domain/policies/home_sport_navigation.dart';
import 'package:sports_calendar_sync/domain/policies/kickoff_clock.dart';
import 'package:sports_calendar_sync/domain/policies/team_display_name_policy.dart';
import 'package:sports_calendar_sync/domain/policies/team_presentation_policy.dart';

Game _bout({
  required String competition,
  required String homeId,
  required String homeJa,
  required String homeEn,
  required String awayId,
  required String awayJa,
  required String awayEn,
  String? homeCountry,
  String? awayCountry,
  String? venue,
  String? venueJa,
  String? venueEn,
  DateTime? start,
}) => Game(
  id: 'g',
  leagueId: 'l',
  competitionKey: competition,
  homeTeamId: homeId,
  homeTeamNameJa: homeJa,
  homeTeamNameEn: homeEn,
  awayTeamId: awayId,
  awayTeamNameJa: awayJa,
  awayTeamNameEn: awayEn,
  homeTeamCountry: homeCountry,
  awayTeamCountry: awayCountry,
  venue: venue,
  venueJa: venueJa,
  venueEn: venueEn,
  startTimeUtc: Timestamp.fromDate(start ?? DateTime.utc(2026, 11, 15, 4)),
  startTimeJst: '',
  timezone: 'UTC',
  status: GameStatus.scheduled,
);

void main() {
  setUpAll(() async => initializeDateFormatting('ja'));
  tearDown(() => displayLanguageMode.value = DisplayLanguageMode.auto);

  group('name language', () {
    test('Japanese fighter is Japanese, foreign fighter English, in UFC', () {
      final bout = _bout(
        competition: 'mma_ufc',
        homeId: 'ufc_alexandre_pantoja',
        homeJa: 'アレシャンドレ・パントージャ',
        homeEn: 'Alexandre Pantoja',
        awayId: 'ufc_tatsuro_taira',
        awayJa: '平良達郎',
        awayEn: 'Tatsuro Taira',
        homeCountry: 'Brazil',
        awayCountry: 'Japan',
      );
      expect(teamDisplayNames.homeName(bout), 'Alexandre Pantoja');
      expect(teamDisplayNames.awayName(bout), '平良達郎');
    });

    test('team with country Japan stays Japanese anywhere', () {
      const fighter = Team(
        id: 'some_new_fighter',
        nameEn: 'Rinya Nakamura',
        nameJa: '中村倫也',
        leagueId: 'ufc',
        competitionKey: 'mma_ufc',
        country: 'Japan',
      );
      expect(teamDisplayNames.teamName(fighter), '中村倫也');
    });

    test('NPB is Japanese; NFL and MLB are English', () {
      const giants = Team(
        id: 'yomiuri_giants',
        nameEn: 'Yomiuri Giants',
        nameJa: '読売ジャイアンツ',
        leagueId: 'npb',
        competitionKey: 'baseball_npb',
      );
      const chiefs = Team(
        id: 'kansas_city_chiefs',
        nameEn: 'Kansas City Chiefs',
        nameJa: 'カンザスシティ・チーフス',
        leagueId: 'nfl',
        competitionKey: 'americanfootball_nfl',
        country: 'USA',
      );
      expect(teamDisplayNames.teamName(giants), '読売ジャイアンツ');
      expect(teamDisplayNames.teamName(chiefs), 'Kansas City Chiefs');
    });

    test('Japan national team is Japanese via provider country', () {
      final match = _bout(
        competition: 'football_international_friendly',
        homeId: 'japan',
        homeJa: '日本',
        homeEn: 'Japan',
        awayId: 'venezuela',
        awayJa: 'Venezuela',
        awayEn: 'Venezuela',
        homeCountry: 'Japan',
        awayCountry: 'Venezuela',
      );
      expect(
        teamDisplayNames.languageForSide(
          competitionKey: match.competitionKey,
          country: match.homeTeamCountry,
        ),
        DisplayLanguage.japanese,
      );
      expect(teamDisplayNames.awayName(match), 'Venezuela');
    });

    test('English setting makes every name and label English', () {
      displayLanguageMode.value = DisplayLanguageMode.english;
      final bout = _bout(
        competition: 'mma_ufc',
        homeId: 'ufc_kai_asakura',
        homeJa: '朝倉海',
        homeEn: 'Kai Asakura',
        awayId: 'ufc_brandon_royval',
        awayJa: 'ブランドン・ロイバル',
        awayEn: 'Brandon Royval',
        homeCountry: 'Japan',
        awayCountry: 'USA',
        venue: 'Saitama Super Arena',
        venueJa: 'さいたまスーパーアリーナ',
        venueEn: 'Saitama Super Arena',
      );
      expect(teamDisplayNames.homeName(bout), 'Kai Asakura');
      expect(teamDisplayNames.venueName(bout), 'Saitama Super Arena');
      expect(
        CompetitionDisplayPolicy.forKey('football_j1')!.label,
        'J1 League',
      );
      const giants = Team(
        id: 'yomiuri_giants',
        nameEn: 'Yomiuri Giants',
        nameJa: '読売ジャイアンツ',
        leagueId: 'npb',
        competitionKey: 'baseball_npb',
      );
      expect(teamDisplayNames.teamName(giants), 'Yomiuri Giants');
    });

    test('no country means the competition rule applies', () {
      final bout = _bout(
        competition: 'mma_ufc',
        homeId: 'x',
        homeJa: '平良達郎',
        homeEn: 'Tatsuro Taira',
        awayId: 'y',
        awayJa: 'ブランドン・ロイバル',
        awayEn: 'Brandon Royval',
      );
      expect(teamDisplayNames.homeName(bout), 'Tatsuro Taira');
    });

    test('venue follows the home side and falls back to the stored value', () {
      final japanEvent = _bout(
        competition: 'mma_ufc',
        homeId: 'ufc_kai_asakura',
        homeJa: '朝倉海',
        homeEn: 'Kai Asakura',
        awayId: 'ufc_brandon_royval',
        awayJa: 'ブランドン・ロイバル',
        awayEn: 'Brandon Royval',
        homeCountry: 'Japan',
        awayCountry: 'USA',
        venue: 'Saitama Super Arena',
        venueJa: 'さいたまスーパーアリーナ',
        venueEn: 'Saitama Super Arena',
      );
      expect(teamDisplayNames.venueName(japanEvent), 'さいたまスーパーアリーナ');

      final vegas = _bout(
        competition: 'mma_ufc',
        homeId: 'ufc_alexandre_pantoja',
        homeJa: 'アレシャンドレ・パントージャ',
        homeEn: 'Alexandre Pantoja',
        awayId: 'ufc_tatsuro_taira',
        awayJa: '平良達郎',
        awayEn: 'Tatsuro Taira',
        homeCountry: 'Brazil',
        awayCountry: 'Japan',
        venue: 'T-Mobile Arena',
        venueJa: 'T-モバイル・アリーナ',
        venueEn: 'T-Mobile Arena',
      );
      expect(teamDisplayNames.venueName(vegas), 'T-Mobile Arena');

      final legacy = _bout(
        competition: 'football_j1',
        homeId: 'kashima_antlers',
        homeJa: '鹿島アントラーズ',
        homeEn: 'Kashima Antlers',
        awayId: 'urawa_reds',
        awayJa: '浦和レッズ',
        awayEn: 'Urawa Reds',
        venue: 'Kashima Soccer Stadium',
      );
      expect(teamDisplayNames.venueName(legacy), 'Kashima Soccer Stadium');
    });

    test('profile value maps to the mode', () {
      expect(displayLanguageModeFor('en'), DisplayLanguageMode.english);
      expect(displayLanguageModeFor('ja'), DisplayLanguageMode.auto);
      expect(displayLanguageModeFor(null), DisplayLanguageMode.auto);
    });
  });

  group('NFL and UFC', () {
    test('NFL and UFC each get their own sport tab', () {
      final ufc = SportsRegistry.findByKey('mma_ufc');
      expect(ufc, isNotNull);
      expect(ufc!.sportCategory, 'mma');
      expect(SportsRegistry.findByKey('americanfootball_nfl'), isNotNull);
      final ids = homeSportTabs().map((tab) => tab.id);
      expect(ids, containsAll([HomeSportTabIds.americanFootball, HomeSportTabIds.mma]));
      expect(ids, isNot(contains(HomeSportTabIds.other)));
      expect(CompetitionDisplayPolicy.forKey('mma_ufc')!.label, 'UFC');
      expect(
        CompetitionDisplayPolicy.forKey('americanfootball_nfl')!.label,
        'NFL',
      );
    });

    test('UFC bouts have no home stadium or away travel cue', () {
      expect(
        fixturePlaceForPerspective(
          homeTeamId: 'a',
          awayTeamId: 'b',
          perspectiveTeamIds: const ['a', 'b'],
          competitionKey: 'mma_ufc',
        ),
        isEmpty,
      );
      expect(
        fixturePlaceForPerspective(
          homeTeamId: 'a',
          awayTeamId: 'b',
          perspectiveTeamIds: const ['b'],
          competitionKey: 'americanfootball_nfl',
        ),
        {FollowedFixturePlace.travel},
      );
    });
  });

  group('reference clock', () {
    test('Japanese competitions show JST only', () {
      final kickoff = displayedKickoff(
        startTimeUtc: DateTime.utc(2026, 11, 15, 10),
        providerTimezone: 'UTC',
        competitionKey: 'football_j1',
      );
      expect(kickoff.reference, isNull);
      expect(kickoff.time, '19:00');
    });

    test('Premier League adds UK time on the same day', () {
      // 15:00 GMT on 15 Nov = 00:00 JST on 16 Nov.
      final reference = referenceKickoff(
        startTimeUtc: DateTime.utc(2026, 11, 15, 15),
        competitionKey: 'football_premier',
      )!;
      expect(reference.label, '英国時間');
      expect(reference.time, '15:00');
      expect(reference.date, '11/15');
      expect(reference.text, '英国時間 11/15 15:00');
    });

    test('NFL uses US Eastern with daylight saving', () {
      // 1 Nov 2026 is after the US DST end (EST, UTC-5).
      final reference = referenceKickoff(
        startTimeUtc: DateTime.utc(2026, 11, 9, 1, 20),
        competitionKey: 'americanfootball_nfl',
      )!;
      expect(reference.label, '米東部時間');
      expect(reference.time, '20:20');
      expect(reference.date, '11/8');

      final september = referenceKickoff(
        startTimeUtc: DateTime.utc(2026, 9, 14, 0, 20),
        competitionKey: 'americanfootball_nfl',
      )!;
      expect(september.time, '20:20'); // EDT, UTC-4.
    });

    test('English setting shortens the clock label', () {
      displayLanguageMode.value = DisplayLanguageMode.english;
      final reference = referenceKickoff(
        startTimeUtc: DateTime.utc(2026, 11, 9, 1, 20),
        competitionKey: 'mma_ufc',
      )!;
      expect(reference.label, 'ET');
    });
  });

  test('team color parses only #RRGGBB', () {
    expect(parseTeamPresentationColor('#E31837'), const Color(0xFFE31837));
    expect(parseTeamPresentationColor('E31837'), isNull);
    expect(parseTeamPresentationColor('#E3183'), isNull);
    expect(parseTeamPresentationColor(null), isNull);
  });
}
