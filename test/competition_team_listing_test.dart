import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sports_calendar_sync/data/repositories/competition_membership_repository.dart';
import 'package:sports_calendar_sync/data/repositories/team_repository.dart';
import 'package:sports_calendar_sync/data/services/competition_team_listing.dart';
import 'package:sports_calendar_sync/domain/models/competition_season_membership.dart';
import 'package:sports_calendar_sync/domain/models/sport.dart';
import 'package:sports_calendar_sync/domain/models/team.dart';

class _FakeMembershipRepository implements CompetitionMembershipRepository {
  _FakeMembershipRepository(this._byKey);

  final Map<String, CompetitionSeasonMembership> _byKey;

  @override
  Future<CompetitionSeasonMembership?> findReadableMembershipForCompetition(
    String competitionKey,
  ) async {
    return _byKey[competitionKey];
  }
}

class _FakeTeamRepository implements TeamRepository {
  _FakeTeamRepository(this._teams);

  final List<Team> _teams;

  @override
  Future<List<Team>> fetchTeams({String? competitionKey}) async {
    if (competitionKey == null) return _teams;
    return _teams
        .where(
          (team) =>
              team.competitionKey == competitionKey ||
              team.competitionKey == competitionKey,
        )
        .toList();
  }

  @override
  Future<List<Team>> fetchTeamsByIds(List<String> teamIds) async {
    final ids = teamIds.toSet();
    return _teams.where((team) => ids.contains(team.id)).toList();
  }

  @override
  Future<Team?> fetchTeam(String teamId) async =>
      _teams.where((team) => team.id == teamId).firstOrNull;

  @override
  Future<List<Team>> fetchTeamsByLeague(String leagueId) async => [];

  @override
  Future<List<League>> fetchLeagues({String? competitionKey}) async => [];

  @override
  Future<List<Team>> searchTeams(
    String query, {
    String? competitionKey,
  }) async => [];
}

class _DeniedMembershipRepository implements CompetitionMembershipRepository {
  @override
  Future<CompetitionSeasonMembership?> findReadableMembershipForCompetition(
    String competitionKey,
  ) {
    throw FirebaseException(
      plugin: 'cloud_firestore',
      code: 'permission-denied',
      message: 'Missing or insufficient permissions.',
    );
  }
}

class _MismatchedLegacyRepository implements TeamRepository {
  @override
  Future<List<Team>> fetchTeams({String? competitionKey}) async {
    return [
      _team('kashima_antlers', 'football_j1'),
      _team('vegalta_sendai', 'football_j2'),
    ];
  }

  @override
  Future<List<Team>> fetchTeamsByIds(List<String> teamIds) async => [];

  @override
  Future<Team?> fetchTeam(String teamId) async => null;

  @override
  Future<List<Team>> fetchTeamsByLeague(String leagueId) async => [];

  @override
  Future<List<League>> fetchLeagues({String? competitionKey}) async => [];

  @override
  Future<List<Team>> searchTeams(
    String query, {
    String? competitionKey,
  }) async => [];
}

Team _team(String id, String competitionKey) {
  return Team(
    id: id,
    nameEn: id,
    nameJa: id,
    leagueId: 'league',
    competitionKey: competitionKey,
  );
}

void main() {
  test('canonical membership wins over legacy team.competitionKey', () async {
    const membership = CompetitionSeasonMembership(
      competitionSeasonKey: 'football_j1_2026',
      competitionKey: 'football_j1',
      seasonYear: 2026,
      displayNameJa: 'J1',
      membershipType: 'league',
      status: 'approved',
      seedable: true,
      memberTeamIds: ['kashima_antlers'],
    );
    final service = CompetitionTeamListingService(
      teamRepository: _FakeTeamRepository([
        _team('kashima_antlers', 'football_j1'),
        _team('urawa_reds', 'football_j1'),
      ]),
      membershipRepository: _FakeMembershipRepository({
        'football_j1': membership,
      }),
    );

    final result = await service.listTeams('football_j1');
    expect(
      result.source,
      CompetitionTeamListingSource.canonicalSeasonMembership,
    );
    expect(result.teams.map((team) => team.id), ['kashima_antlers']);
  });

  test('same team id may appear in multiple competition memberships', () async {
    const shared = 'arsenal';
    final repo = _FakeMembershipRepository({
      'football_premier': const CompetitionSeasonMembership(
        competitionSeasonKey: 'football_premier_2026',
        competitionKey: 'football_premier',
        seasonYear: 2026,
        displayNameJa: 'PL',
        membershipType: 'league',
        status: 'approved',
        seedable: true,
        memberTeamIds: [shared],
      ),
      'football_champions_league': const CompetitionSeasonMembership(
        competitionSeasonKey: 'football_ucl_2026',
        competitionKey: 'football_champions_league',
        seasonYear: 2026,
        displayNameJa: 'UCL',
        membershipType: 'league',
        status: 'approved',
        seedable: true,
        memberTeamIds: [shared],
      ),
    });
    final teams = _FakeTeamRepository([_team(shared, 'football_premier')]);
    final service = CompetitionTeamListingService(
      teamRepository: teams,
      membershipRepository: repo,
    );

    final premier = await service.listTeams('football_premier');
    final ucl = await service.listTeams('football_champions_league');
    expect(premier.teams.single.id, shared);
    expect(ucl.teams.single.id, shared);
  });

  test('membership permission-denied stays an error', () {
    final service = CompetitionTeamListingService(
      teamRepository: _FakeTeamRepository([
        _team('kashima_antlers', 'football_j1'),
      ]),
      membershipRepository: _DeniedMembershipRepository(),
    );

    expect(
      service.listTeams('football_j1'),
      throwsA(
        isA<FirebaseException>().having(
          (error) => error.code,
          'code',
          'permission-denied',
        ),
      ),
    );
  });

  test('legacy fallback when no readable membership exists', () async {
    final service = CompetitionTeamListingService(
      teamRepository: _FakeTeamRepository([_team('giants', 'baseball_npb')]),
      membershipRepository: SampleCompetitionMembershipRepository(),
    );

    final result = await service.listTeams('baseball_npb');
    expect(
      result.source,
      CompetitionTeamListingSource.legacyTeamDocumentCompatibility,
    );
    expect(result.teams.single.id, 'giants');
  });

  test(
    'legacy fallback hides a team whose resolved competition is another league',
    () async {
      final service = CompetitionTeamListingService(
        teamRepository: _MismatchedLegacyRepository(),
        membershipRepository: SampleCompetitionMembershipRepository(),
      );

      final result = await service.listTeams('football_j1');
      expect(
        result.source,
        CompetitionTeamListingSource.legacyTeamDocumentCompatibility,
      );
      expect(result.teams.map((team) => team.id), ['kashima_antlers']);
      expect(
        teamMatchesCompetitionScope(result.teams.single, 'football_j1'),
        isTrue,
      );
      expect(
        teamMatchesCompetitionScope(
          _team('vegalta_sendai', 'football_j2'),
          'football_j1',
        ),
        isFalse,
      );
    },
  );

  test('sample repository exposes J2/J3 special membership only', () async {
    final repo = SampleCompetitionMembershipRepository();
    final special = await repo.findReadableMembershipForCompetition(
      'football_j2_j3_special',
    );
    expect(special, isNotNull);
    expect(
      await repo.findReadableMembershipForCompetition('football_j1'),
      isNull,
    );
  });
}
