import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sports_calendar_sync/core/config/sports_registry.dart';
import 'package:sports_calendar_sync/domain/models/game.dart';
import 'package:sports_calendar_sync/domain/models/team.dart';
import 'package:sports_calendar_sync/domain/policies/home_sport_navigation.dart';

Team _team(String id, String? competitionKey) {
  return Team(
    id: id,
    nameEn: id,
    nameJa: id,
    leagueId: 'league',
    competitionKey: competitionKey,
  );
}

Game _game(String id, String? competitionKey) {
  return Game(
    id: id,
    leagueId: 'league',
    competitionKey: competitionKey,
    homeTeamNameJa: id,
    awayTeamNameJa: id,
    startTimeUtc: Timestamp.fromDate(DateTime.utc(2026, 12, 1, 10)),
    startTimeJst: '2026-12-01 19:00',
    timezone: 'Asia/Tokyo',
    status: GameStatus.scheduled,
  );
}

void main() {
  test('home tabs are favorites, baseball, football, then other sports', () {
    final tabs = homeSportTabs();

    expect(defaultHomeSportTabIndex(tabs), 0);
    expect(tabs.map((tab) => tab.id), [
      HomeSportTabIds.favorites,
      HomeSportTabIds.baseball,
      HomeSportTabIds.football,
      HomeSportTabIds.other,
    ]);
    expect(tabs.map((tab) => tab.label), ['お気に入り', '野球', 'サッカー', 'その他スポーツ']);
    expect(tabs.first.showsAllSports, isTrue);
    expect(tabs[1].sportCategories, {'baseball'});
    expect(tabs[2].sportCategories, {'football'});
    expect(tabs[3].sportCategories, {
      'basketball',
      'americanFootball',
      'hockey',
    });
    const leagueLabels = {
      'Jリーグ',
      'プレミアリーグ',
      'NPB',
      'MLB',
      'NBA',
      'NFL',
      'NHL',
      'Bリーグ',
    };
    expect(
      tabs.map((tab) => tab.label).toSet().intersection(leagueLabels),
      isEmpty,
    );
  });

  test('tabs follow enabled categories and do not invent a missing sport', () {
    final footballFirst = homeSportTabs(
      enabledCategories: ['football', 'hockey', 'baseball'],
    );
    expect(footballFirst.map((tab) => tab.label), [
      'お気に入り',
      '野球',
      'サッカー',
      'その他スポーツ',
    ]);
    expect(footballFirst.last.sportCategories, {'hockey'});

    final basketballOnly = homeSportTabs(enabledCategories: ['basketball']);
    expect(basketballOnly.map((tab) => tab.id), [
      HomeSportTabIds.favorites,
      HomeSportTabIds.other,
    ]);
    expect(basketballOnly.last.sportCategories, {'basketball'});
    expect(SportsRegistry.enabledCategories, isNot(contains('rugby')));
  });

  test(
    'sport tabs keep known competitions and leave unknown keys on favorites',
    () {
      final tabs = homeSportTabs();
      final baseball = tabs[1];
      final football = tabs[2];
      final other = tabs[3];
      final teams = [
        _team('giants', 'baseball_npb'),
        _team('mlb', 'baseball_mlb'),
        _team('antlers', 'football_j1'),
        _team('j2', 'football_j2'),
        _team('arsenal', 'football_premier'),
        _team('cup', 'football_emperor_cup'),
        _team('lakers', 'basketball_nba'),
        _team('bleague', 'basketball_b_league'),
        _team('nfl', 'americanfootball_nfl'),
        _team('nhl', 'hockey_nhl'),
        _team('legacy', null),
        _team('unknown', 'unrelated_competition'),
      ];
      final games = [
        for (final team in teams) _game(team.id, team.competitionKey),
      ];

      expect(teamsForHomeSportTab(teams, tabs.first), teams);
      expect(gamesForHomeSportTab(games, tabs.first), games);

      expect(teamsForHomeSportTab(teams, baseball).map((team) => team.id), [
        'giants',
        'mlb',
      ]);
      expect(gamesForHomeSportTab(games, football).map((game) => game.id), [
        'antlers',
        'j2',
        'arsenal',
        'cup',
      ]);
      expect(teamsForHomeSportTab(teams, other).map((team) => team.id), [
        'lakers',
        'bleague',
        'nfl',
        'nhl',
      ]);
      expect(
        gamesForHomeSportTab(games, baseball).map((game) => game.id),
        isNot(contains('legacy')),
      );
      expect(
        gamesForHomeSportTab(games, football).map((game) => game.id),
        isNot(contains('unknown')),
      );
      expect(
        sportCategoryForCompetitionKey('football_j_league_cup'),
        'football',
      );
      expect(
        sportCategoryForCompetitionKey('americanfootball_nfl'),
        'americanFootball',
      );
      expect(sportCategoryForCompetitionKey(null), isNull);
      expect(sportCategoryForCompetitionKey('   '), isNull);
    },
  );
}
