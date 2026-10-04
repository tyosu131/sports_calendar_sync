import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sports_calendar_sync/core/config/sports_registry.dart';
import 'package:sports_calendar_sync/domain/models/user_profile.dart';
import 'package:sports_calendar_sync/domain/policies/home_sport_navigation.dart';

/// Static contract between Flutter query shape and repo Firebase config.
///
/// This does not know which revision is deployed. Deploy confirmation stays
/// in docs/production-config-handoff.md.
void main() {
  late String rules;
  late Map<String, dynamic> indexesFile;
  late String teamRepository;
  late String gameRepository;
  late String membershipRepository;
  late String listingService;
  late String userRepository;
  late String userProfile;
  late String searchScreen;
  late String leagueScreen;
  late String functionsIndex;
  late String handoff;

  setUpAll(() {
    rules = File('firestore.rules').readAsStringSync();
    indexesFile =
        jsonDecode(File('firestore.indexes.json').readAsStringSync())
            as Map<String, dynamic>;
    teamRepository = File(
      'lib/data/repositories/team_repository.dart',
    ).readAsStringSync();
    gameRepository = File(
      'lib/data/repositories/game_repository.dart',
    ).readAsStringSync();
    membershipRepository = File(
      'lib/data/repositories/competition_membership_repository.dart',
    ).readAsStringSync();
    listingService = File(
      'lib/data/services/competition_team_listing.dart',
    ).readAsStringSync();
    userRepository = File(
      'lib/data/repositories/user_repository.dart',
    ).readAsStringSync();
    userProfile = File(
      'lib/domain/models/user_profile.dart',
    ).readAsStringSync();
    searchScreen = File(
      'lib/presentation/screens/team_search_screen.dart',
    ).readAsStringSync();
    leagueScreen = File(
      'lib/presentation/screens/league_teams_screen.dart',
    ).readAsStringSync();
    functionsIndex = File('functions/src/index.ts').readAsStringSync();
    handoff = File('docs/production-config-handoff.md').readAsStringSync();
  });

  test('handoff ledger does not claim to know production', () {
    expect(handoff, contains('リポジトリは本番のデプロイ済みリビジョンを知らない'));
    expect(handoff, contains('firestore.rules'));
    expect(handoff, contains('firestore.indexes.json'));
    expect(handoff, contains('asia-northeast1'));
    expect(handoff, contains('competitionSeasonMemberships'));
    expect(handoff, contains('permission-denied'));
    expect(handoff, contains('PR #53'));
    expect(handoff, contains('1fe5ecc'));
    expect(handoff, contains('football_j2_j3_special'));
    expect(handoff, contains('football_emperor_cup'));
    expect(handoff, contains('functions-deploy-required'));
    expect(
      handoff,
      contains('rules のデプロイ、indexes のデプロイ、Firestore への書き込み、API sync は不要'),
    );
    expect(handoff, isNot(contains('別 PR')));
  });

  test('client Firebase config names one project', () {
    const projectId = 'sports-calendar-sync-a4564';
    for (final path in [
      'firebase.json',
      'lib/firebase_options.dart',
      'lib/core/utils/ics_url_builder.dart',
      'android/app/google-services.json',
      'ios/Runner/GoogleService-Info.plist',
      'macos/Runner/GoogleService-Info.plist',
    ]) {
      expect(File(path).readAsStringSync(), contains(projectId), reason: path);
    }
  });

  test(
    'rules publish every client collection and keep membership readable',
    () {
      const collections = [
        'users',
        'teams',
        'leagues',
        'games',
        'competitionSeasonMemberships',
        'subscriptions',
        'translationMaps',
      ];
      for (final name in collections) {
        expect(rules, contains('match /$name/'), reason: name);
      }
      expect(
        rules,
        contains(
          'match /competitionSeasonMemberships/{membershipId} {\n'
          '      allow read: if true;\n'
          '      allow write: if false; // admin SDK only',
        ),
      );
      expect(rules, isNot(contains('match /{document=**}')));
      expect(
        rules,
        contains(
          "keys().hasAll(['email', 'followedTeamIds', 'preferredLanguage'])",
        ),
      );
    },
  );

  test('profile create writes the keys an update must still contain', () {
    final data = const UserProfile(
      uid: 'uid',
      email: 'a@example.com',
      followedTeamIds: ['jubilo_iwata'],
      preferredLanguage: 'ja',
    ).toFirestore();
    expect(
      data.keys,
      containsAll(['email', 'followedTeamIds', 'preferredLanguage']),
    );
    expect(data['preferredLanguage'], 'ja');

    final follow = _between(
      _firestoreRepository(userRepository),
      'Future<void> followTeam',
      'Future<void> unfollowTeam',
    );
    expect(follow, contains("'followedTeamIds': FieldValue.arrayUnion"));
    expect(follow, isNot(contains('preferredLanguage')));
    expect(userProfile, contains("'preferredLanguage': preferredLanguage"));
  });

  test('membership read errors stay distinct from an empty league', () {
    expect(membershipRepository, contains('permission-denied, must propagate'));
    expect(
      membershipRepository,
      contains(".where('competitionKey', isEqualTo: key)"),
    );
    expect(
      _firestoreRepository(membershipRepository),
      isNot(contains('catch')),
    );
    expect(listingService, isNot(contains('catch')));
    expect(listingService, contains('findReadableMembershipForCompetition'));
    expect(searchScreen, contains("Text('エラー: \$e')"));
    expect(leagueScreen, contains("'エラー: \$error'"));
  });

  test(
    'football home search is equality-only until the query is non-empty',
    () {
      final football = followDiscoverySportTabs().singleWhere(
        (tab) => tab.label == 'サッカー',
      );
      expect(
        competitionsForHomeSportTab(
          football,
        ).map((item) => item.competitionKey),
        ['football_j1', 'football_premier'],
      );
      expect(
        SportsRegistry.enabled.map((item) => item.competitionKey),
        isNot(contains('football_j2_j3_special')),
      );
      expect(
        teamRepository,
        contains(
          'if (trimmedQuery.isEmpty) {\n'
          '      return fetchTeams(competitionKey: competitionKey);\n'
          '    }',
        ),
      );
      expect(
        File('lib/data/services/sport_team_search.dart').readAsStringSync(),
        contains(
          'searchTeams(query, competitionKey: competition.competitionKey)',
        ),
      );
    },
  );

  test('required queries stay covered when extra indexes exist', () {
    expect(indexesFile['fieldOverrides'], isEmpty);

    final flat = _squash(teamRepository);
    for (final snippet in _singleFieldTeamSnippets) {
      expect(flat, contains(_squash(snippet)), reason: snippet);
    }
    final games = _squash(gameRepository);
    for (final snippet in _compositeGameSnippets) {
      expect(games, contains(_squash(snippet)), reason: snippet);
    }

    final indexes = (indexesFile['indexes'] as List).cast<Map>();
    for (final required in _requiredComposites) {
      expect(
        indexes.any((index) => _covers(index, required)),
        isTrue,
        reason:
            '${required.collection} ${required.fields.map((field) => field.path).join(",")}',
      );
    }
  });

  test('client callables exist in the Functions entry', () {
    const names = [
      'getCalendar',
      'ensureCalendarFeed',
      'rotateCalendarFeed',
      'beginGoogleCalendarConnection',
      'getGoogleCalendarConnectionStatus',
      'disconnectGoogleCalendar',
      'googleCalendarOAuthCallback',
      'syncGoogleCalendarNow',
      'syncGoogleCalendarOnFollowChange',
    ];
    for (final name in names) {
      expect(functionsIndex, contains(name), reason: name);
    }
    expect(
      File(
        'lib/data/repositories/google_calendar_connection_repository.dart',
      ).readAsStringSync(),
      contains("instanceFor(region: 'asia-northeast1')"),
    );
    expect(
      File(
        'lib/data/repositories/calendar_feed_repository.dart',
      ).readAsStringSync(),
      contains('ensureCalendarFeed'),
    );
  });
}

String _squash(String value) => value.replaceAll(RegExp(r'\s+'), ' ');

String _between(String source, String start, String end) {
  final from = source.indexOf(start);
  final to = source.indexOf(end, from + start.length);
  return source.substring(from, to);
}

String _firestoreRepository(String source) {
  final start = source.indexOf('class Firestore');
  final end = source.indexOf('class Sample');
  return source.substring(start, end < 0 ? source.length : end);
}

bool _covers(Map index, _Composite required) {
  if (index['collectionGroup'] != required.collection) return false;
  if (index['queryScope'] != 'COLLECTION') return false;
  final fields = (index['fields'] as List).cast<Map>();
  if (fields.length < required.fields.length) return false;
  for (var i = 0; i < required.fields.length; i++) {
    final actual = fields[i];
    final expected = required.fields[i];
    if (actual['fieldPath'] != expected.path) return false;
    if (expected.arrayConfig != null) {
      if (actual['arrayConfig'] != expected.arrayConfig) return false;
    } else if (actual['order'] != 'ASCENDING') {
      return false;
    }
  }
  if (fields.length == required.fields.length) return true;
  return fields.length == required.fields.length + 1 &&
      fields.last['fieldPath'] == '__name__';
}

class _Field {
  const _Field(this.path, {this.arrayConfig});

  final String path;
  final String? arrayConfig;
}

class _Composite {
  const _Composite(this.collection, this.fields);

  final String collection;
  final List<_Field> fields;
}

const _requiredComposites = <_Composite>[
  _Composite('games', [
    _Field('homeTeamId'),
    _Field('status'),
    _Field('startTimeUTC'),
  ]),
  _Composite('games', [
    _Field('awayTeamId'),
    _Field('status'),
    _Field('startTimeUTC'),
  ]),
  _Composite('games', [_Field('homeTeamId'), _Field('startTimeUTC')]),
  _Composite('games', [_Field('awayTeamId'), _Field('startTimeUTC')]),
  _Composite('teams', [_Field('leagueId'), _Field('nameJa')]),
  _Composite('teams', [_Field('competitionKey'), _Field('nameJa')]),
  _Composite('teams', [_Field('sportKey'), _Field('nameJa')]),
  _Composite('teams', [
    _Field('competitionKey'),
    _Field('searchKeywords', arrayConfig: 'CONTAINS'),
  ]),
  _Composite('teams', [
    _Field('sportKey'),
    _Field('searchKeywords', arrayConfig: 'CONTAINS'),
  ]),
];

const _singleFieldTeamSnippets = <String>[
  ".where('competitionKey', isEqualTo: competitionKey)\n        .get()",
  ".where('sportKey', isEqualTo: competitionKey)\n        .get()",
  ".orderBy('nameJa')\n          .limit(AppConstants.defaultPageSize)",
  '.where(FieldPath.documentId, whereIn: chunk)',
  ".where('nameJa', isGreaterThanOrEqualTo: candidate)\n"
      ".where('nameJa', isLessThan:",
  ".where('searchKeywords', arrayContains: keyword)\n"
      '              .limit(AppConstants.defaultPageSize)',
  ".where('leagueId', isEqualTo: leagueId)\n        .orderBy('nameJa')",
  "nameFilter(_teams, candidate)\n"
      "            .where('competitionKey', isEqualTo: competitionKey)",
  "nameFilter(_teams, candidate)\n"
      "            .where('sportKey', isEqualTo: competitionKey)",
  ".where('competitionKey', isEqualTo: competitionKey)\n"
      "            .where('searchKeywords', arrayContains: keyword)",
  ".where('sportKey', isEqualTo: competitionKey)\n"
      "            .where('searchKeywords', arrayContains: keyword)",
];

const _compositeGameSnippets = <String>[
  ".where('homeTeamId', isEqualTo: teamId)\n"
      "        .where('startTimeUTC', isGreaterThanOrEqualTo: now)\n"
      "        .where('status', isEqualTo: GameStatus.scheduled.name)\n"
      "        .orderBy('startTimeUTC')",
  ".where('awayTeamId', isEqualTo: teamId)\n"
      "        .where('startTimeUTC', isGreaterThanOrEqualTo: now)\n"
      "        .where('status', isEqualTo: GameStatus.scheduled.name)\n"
      "        .orderBy('startTimeUTC')",
  ".where('homeTeamId', whereIn: chunk)\n"
      "          .where('startTimeUTC', isGreaterThanOrEqualTo: fromTimestamp)\n"
      "          .orderBy('startTimeUTC')",
  ".where('awayTeamId', whereIn: chunk)\n"
      "          .where('startTimeUTC', isGreaterThanOrEqualTo: fromTimestamp)\n"
      "          .orderBy('startTimeUTC')",
  ".where('homeTeamId', whereIn: chunk)\n          .orderBy('startTimeUTC')",
  ".where('awayTeamId', whereIn: chunk)\n          .orderBy('startTimeUTC')",
  ".where('homeTeamId', isEqualTo: teamId)\n"
      "        .where('startTimeUTC', isGreaterThanOrEqualTo: now)\n"
      "        .orderBy('startTimeUTC')",
];
