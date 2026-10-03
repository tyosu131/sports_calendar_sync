import 'package:flutter_test/flutter_test.dart';
import 'package:sports_calendar_sync/data/repositories/team_repository.dart';
import 'package:sports_calendar_sync/data/services/sport_team_search.dart';
import 'package:sports_calendar_sync/domain/models/sport.dart';
import 'package:sports_calendar_sync/domain/models/team.dart';
import 'package:sports_calendar_sync/domain/policies/home_sport_navigation.dart';

class _RecordingTeamRepository implements TeamRepository {
  _RecordingTeamRepository(this._byCompetition);

  final Map<String, List<Team>> _byCompetition;
  final queriedCompetitionKeys = <String?>[];

  @override
  Future<List<Team>> searchTeams(String query, {String? competitionKey}) async {
    queriedCompetitionKeys.add(competitionKey);
    if (competitionKey == null) {
      return _byCompetition.values.expand((teams) => teams).take(20).toList();
    }
    return List<Team>.from(_byCompetition[competitionKey] ?? const []);
  }

  @override
  Future<List<Team>> fetchTeams({String? competitionKey}) async => [];

  @override
  Future<Team?> fetchTeam(String teamId) async => null;

  @override
  Future<List<Team>> fetchTeamsByIds(List<String> teamIds) async => [];

  @override
  Future<List<Team>> fetchTeamsByLeague(String leagueId) async => [];

  @override
  Future<List<League>> fetchLeagues({String? competitionKey}) async => [];
}

Team _team(String id, String competitionKey, {required String nameJa}) {
  return Team(
    id: id,
    nameEn: id,
    nameJa: nameJa,
    leagueId: 'league',
    competitionKey: competitionKey,
  );
}

void main() {
  test(
    'sport-home search queries each registry competition, not first 20',
    () async {
      final repository = _RecordingTeamRepository({
        'football_j1': [
          for (var i = 0; i < 25; i++)
            _team('football_$i', 'football_j1', nameJa: 'soccer$i'),
        ],
        'baseball_npb': [
          _team('yomiuri_giants', 'baseball_npb', nameJa: '読売ジャイアンツ'),
        ],
      });
      final baseball = followDiscoverySportTabs().firstWhere(
        (tab) => tab.id == HomeSportTabIds.baseball,
      );

      final result = await searchTeamsForSportTab(
        repository: repository,
        tab: baseball,
        query: '',
      );

      expect(repository.queriedCompetitionKeys, isNot(contains(null)));
      expect(repository.queriedCompetitionKeys, [
        'baseball_npb',
        'baseball_mlb',
      ]);
      expect(result.map((team) => team.id), ['yomiuri_giants']);
    },
  );

  test(
    'sport-home search dedupes the same team id across competitions',
    () async {
      const shared = Team(
        id: 'arsenal',
        nameEn: 'Arsenal',
        nameJa: 'アーセナル',
        leagueId: 'league',
        competitionKey: 'football_premier',
      );
      final repository = _RecordingTeamRepository({
        'football_j1': [shared],
        'football_premier': [shared],
      });
      final football = followDiscoverySportTabs().firstWhere(
        (tab) => tab.id == HomeSportTabIds.football,
      );

      final result = await searchTeamsForSportTab(
        repository: repository,
        tab: football,
        query: '',
      );

      expect(result, hasLength(1));
      expect(result.single.id, 'arsenal');
      expect(repository.queriedCompetitionKeys, [
        'football_j1',
        'football_premier',
      ]);
    },
  );
}
