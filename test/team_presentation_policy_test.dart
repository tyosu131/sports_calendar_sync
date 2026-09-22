import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sports_calendar_sync/data/providers/game_providers.dart';
import 'package:sports_calendar_sync/data/providers/repository_providers.dart';
import 'package:sports_calendar_sync/data/repositories/team_repository.dart';
import 'package:sports_calendar_sync/domain/models/game.dart';
import 'package:sports_calendar_sync/domain/models/team.dart';
import 'package:sports_calendar_sync/domain/policies/club_presentation_data.dart';
import 'package:sports_calendar_sync/domain/policies/team_display_name_policy.dart';
import 'package:sports_calendar_sync/domain/policies/team_presentation_policy.dart';

Game fixture(String name, String competition, {String? id, String? logo}) =>
    Game(
      id: '$competition-$name',
      leagueId: 'league',
      competitionKey: competition,
      homeTeamNameJa: name,
      homeTeamProviderName: name,
      homeTeamId: id,
      homeTeamLogoUrl: logo,
      awayTeamNameJa: 'Unknown FC',
      homeSourceTeamId: 'provider-home',
      awaySourceTeamId: 'provider-away',
      startTimeUtc: Timestamp.fromMillisecondsSinceEpoch(0),
      startTimeJst: '',
      timezone: 'UTC',
      status: GameStatus.scheduled,
    );

void main() {
  test(
    'public logos require exact documented rights, not provider availability',
    () {
      const url = 'https://assets.example.test/approved.png';
      const evidence = {
        url: 'Test-only permission record; no production grant',
      };
      expect(publicTeamLogoUrl(url), isNull);
      expect(publicTeamLogoUrl(url, rightsEvidence: evidence), url);
      expect(
        publicTeamLogoUrl('$url?other=1', rightsEvidence: evidence),
        isNull,
      );
      expect(publicTeamLogoUrl(url, rightsEvidence: const {url: ''}), isNull);
      expect(
        publicTeamLogoUrl(
          'http://assets.example.test/logo',
          rightsEvidence: const {'http://assets.example.test/logo': 'record'},
        ),
        isNull,
      );
      expect(confirmedPublicLogoRights, isEmpty);
      for (final entry in clubPresentationEntries) {
        expect(publicTeamLogoUrl(entry.logoUrl), isNull, reason: entry.nameEn);
      }
    },
  );
  test(
    'V1 examples resolve names and logos identically for Games and Teams',
    () {
      final cases = [
        ('Tokyo', 'FC Tokyo', 'FC東京', 'football_j1'),
        ('Tochigi', 'Tochigi SC', '栃木ＳＣ', 'football_emperor_cup'),
        ('Sabah', 'Sabah', 'Sabah', 'football_champions_league'),
        ('JEF United', 'JEF United Chiba', 'ジェフユナイテッド千葉', 'football_j1'),
        ('Kawasaki Frontale', 'Kawasaki Frontale', '川崎フロンターレ', 'football_j1'),
        ('Vissel Kobe', 'Vissel Kobe', 'ヴィッセル神戸', 'football_j1'),
        ('Arsenal FC', 'Arsenal', 'Arsenal', 'football_premier'),
        ('Fulham', 'Fulham', 'Fulham', 'football_premier'),
        (
          'Tottenham Hotspur',
          'Tottenham Hotspur',
          'Tottenham Hotspur',
          'football_premier',
        ),
        (
          'Real Madrid',
          'Real Madrid',
          'Real Madrid',
          'football_champions_league',
        ),
        (
          'Roasso Kumamoto',
          'Roasso Kumamoto',
          'ロアッソ熊本',
          'football_j_league_cup',
        ),
        (
          'Tegevajaro Miyazaki',
          'Tegevajaro Miyazaki',
          'テゲバジャーロ宮崎',
          'football_emperor_cup',
        ),
        (
          'Bayern München',
          'Bayern Munich',
          'Bayern Munich',
          'football_champions_league',
        ),
        (
          'Slavia Praha',
          'Slavia Prague',
          'Slavia Prague',
          'football_champions_league',
        ),
        (
          'Fleetwood Town',
          'Fleetwood Town',
          'Fleetwood Town',
          'football_league_cup',
        ),
      ];
      for (final (provider, english, display, competition) in cases) {
        final game = fixture(provider, competition);
        final team = Team(
          id: 'master',
          nameEn: english,
          nameJa: display,
          leagueId: 'discovery',
          competitionKey: competition,
        );
        final before = game.toFirestore();
        expect(teamDisplayNames.homeName(game), display);
        expect(teamDisplayNames.teamName(team), display);
        final logo = TeamPresentationLogoResolver(const []).side(game, true);
        expect(logo, isNotNull, reason: provider);
        expect(logo, teamPresentationLogoCandidate(team), reason: provider);
        expect(game.toFirestore(), before);
        expect(game.homeTeamId, isNull);
      }
      expect(
        clubPresentation(['ＦＣ東京'], competitionKey: 'football_j1')?.nameJa,
        'FC東京',
      );
    },
  );

  test('Japanese discovery, domestic cup and V1 calendar labels agree', () {
    for (final competition in [
      'football_j1',
      'football_j2',
      'football_j3',
      'football_j_league_cup',
      'football_emperor_cup',
    ]) {
      expect(
        teamDisplayNames.homeName(fixture('JEF United', competition)),
        'ジェフユナイテッド千葉',
      );
    }
  });

  test('all reviewed masters have unique self-resolution and HTTPS logos', () {
    for (final entry in clubPresentationEntries) {
      expect(
        clubPresentation([
          entry.nameEn,
        ], competitionKey: entry.competitionKeys.firstOrNull),
        same(entry),
      );
      expect(Uri.parse(entry.logoUrl).scheme, 'https');
    }
  });

  test(
    'game logo wins, then canonical master, then unique presentation master',
    () {
      const team = Team(
        id: 'kawasaki_frontale',
        nameEn: 'Kawasaki Frontale',
        nameJa: '川崎フロンターレ',
        leagueId: 'discovery',
        competitionKey: 'football_j1',
        logoUrl: 'https://master/logo.png',
      );
      final resolver = TeamPresentationLogoResolver([team]);
      expect(
        resolver.side(
          fixture(
            'Kawasaki Frontale',
            'football_j1',
            id: team.id,
            logo: 'https://game/logo.png',
          ),
          true,
        ),
        'https://game/logo.png',
      );
      expect(
        resolver.side(
          fixture('provider text', 'football_j1', id: team.id),
          true,
        ),
        team.logoUrl,
      );
      expect(
        resolver.side(fixture('Kawasaki Frontale', 'football_j1'), true),
        teamPresentationLogoCandidate(team),
      );
      expect(
        resolver.side(
          fixture('Kawasaki Frontale', 'football_emperor_cup'),
          true,
        ),
        teamPresentationLogoCandidate(team),
      );
    },
  );

  test(
    'unknown, partial, ambiguous and conflicting names never guess a logo',
    () {
      for (final name in [
        'Unknown FC',
        'Fulh',
        'United',
        'Tochigi unknown',
        'Sabah',
        'Tokyo unknown',
      ]) {
        expect(
          TeamPresentationLogoResolver(
            const [],
          ).side(fixture(name, 'football_j1'), true),
          isNull,
        );
      }
      const first = Team(
        id: 'one',
        nameEn: 'Fulham',
        nameJa: 'フラム',
        leagueId: 'premier',
        competitionKey: 'football_premier',
        logoUrl: 'https://one/logo',
      );
      final ambiguous = TeamPresentationLogoResolver([
        first,
        first.copyWith(id: 'two'),
      ]);
      expect(
        ambiguous.side(fixture('Fulham', 'football_premier'), true),
        isNull,
      );
      final conflict = Game.fromFirestore({
        ...fixture('Fulham', 'football_premier').toFirestore(),
        'homeTeamNameEn': 'Arsenal',
      }, 'conflict');
      expect(
        TeamPresentationLogoResolver([first]).side(conflict, true),
        isNull,
      );
      expect(
        TeamPresentationLogoResolver(
          const [],
        ).side(fixture('Fulham', 'baseball_npb'), true),
        isNull,
      );
    },
  );

  test(
    'multiple screens batch identities and share four bounded master lookups',
    () async {
      final repository = RecordingTeams();
      final container = ProviderContainer(
        overrides: [teamRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      final games = List.generate(
        12,
        (index) => fixture(
          index.isEven ? 'Kawasaki Frontale' : 'Arsenal FC',
          index.isEven ? 'football_j1' : 'football_premier',
          id: index.isEven ? 'kawasaki_frontale' : 'arsenal',
        ),
      );
      final resolver = await container.read(
        gamePresentationProvider(games).future,
      );
      for (final game in games) {
        expect(resolver.side(game, true), isNotNull);
      }
      await container.read(gamePresentationProvider([...games]).future);
      expect(repository.masterReads, {
        'football_j1': 1,
        'football_j2': 1,
        'football_j3': 1,
        'football_premier': 1,
      });
      expect(repository.canonicalReads, hasLength(2));
      for (final ids in repository.canonicalReads) {
        expect(ids.toSet(), {'kawasaki_frontale', 'arsenal'});
      }
    },
  );

  test(
    'empty schedule performs no reads; failed metadata does not lose games',
    () async {
      final repository = RecordingTeams()..fail = true;
      final container = ProviderContainer(
        overrides: [teamRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      await container.read(gamePresentationProvider(const []).future);
      expect(repository.masterReads, isEmpty);
      expect(repository.canonicalReads, isEmpty);
      final games = [fixture('Arsenal FC', 'football_premier', id: 'arsenal')];
      final resolver = await container.read(
        gamePresentationProvider(games).future,
      );
      expect(resolver.side(games.single, true), isNotNull);
      expect(games.single.homeTeamId, 'arsenal');
    },
  );
}

class RecordingTeams implements TeamRepository {
  final masterReads = <String, int>{};
  final canonicalReads = <List<String>>[];
  bool fail = false;
  @override
  Future<List<Team>> fetchTeams({String? competitionKey}) async {
    masterReads.update(
      competitionKey!,
      (reads) => reads + 1,
      ifAbsent: () => 1,
    );
    if (fail) throw StateError('unavailable');
    return const [];
  }

  @override
  Future<List<Team>> fetchTeamsByIds(List<String> ids) async {
    canonicalReads.add(ids);
    if (fail) throw StateError('unavailable');
    return const [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
