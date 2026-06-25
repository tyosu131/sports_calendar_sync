import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/utils/app_constants.dart';
import '../../domain/models/sport.dart';
import '../../domain/models/team.dart';

/// Read API for teams and leagues.
abstract class TeamRepository {
  Future<List<League>> fetchLeagues({String? competitionKey});

  Future<List<Team>> fetchTeamsByLeague(String leagueId);

  Future<List<Team>> fetchTeams({String? competitionKey});

  Future<Team?> fetchTeam(String teamId);

  Future<List<Team>> fetchTeamsByIds(List<String> teamIds);

  Future<List<Team>> searchTeams(String query, {String? competitionKey});
}

/// Handles Firestore read operations for teams and leagues.
class FirestoreTeamRepository implements TeamRepository {
  FirestoreTeamRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _teams =>
      _firestore.collection(AppConstants.teamsCollection);

  CollectionReference<Map<String, dynamic>> get _leagues =>
      _firestore.collection(AppConstants.leaguesCollection);

  /// Fetch all leagues, optionally filtered by [competitionKey].
  ///
  /// When [competitionKey] is null, all leagues are returned.
  /// Queries the `competitionKey` field first; also accepts legacy `sportKey`
  /// documents via a separate fallback query so old data remains visible.
  @override
  Future<List<League>> fetchLeagues({String? competitionKey}) async {
    if (competitionKey == null) {
      final snapshot = await _leagues.get();
      return snapshot.docs
          .map((doc) => League.fromFirestore(doc.data(), doc.id))
          .toList();
    }

    // Primary query: new documents with `competitionKey` field.
    final primarySnap = await _leagues
        .where('competitionKey', isEqualTo: competitionKey)
        .get();

    // Fallback query: legacy documents that only have `sportKey`.
    final legacySnap = await _leagues
        .where('sportKey', isEqualTo: competitionKey)
        .get();

    // Merge, deduplicate by document ID.
    final seen = <String>{};
    final results = <League>[];
    for (final doc in [...primarySnap.docs, ...legacySnap.docs]) {
      if (seen.add(doc.id)) {
        results.add(League.fromFirestore(doc.data(), doc.id));
      }
    }
    return results;
  }

  /// Fetch all teams for a given league.
  @override
  Future<List<Team>> fetchTeamsByLeague(String leagueId) async {
    final snapshot = await _teams
        .where('leagueId', isEqualTo: leagueId)
        .orderBy('nameJa')
        .get();
    return snapshot.docs
        .map((doc) => Team.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  /// Fetch teams, optionally filtered by competition.
  ///
  /// null = all known teams.
  @override
  Future<List<Team>> fetchTeams({String? competitionKey}) async {
    if (competitionKey == null) {
      final snapshot = await _teams
          .orderBy('nameJa')
          .limit(AppConstants.defaultPageSize)
          .get();
      return snapshot.docs
          .map((doc) => Team.fromFirestore(doc.data(), doc.id))
          .toList();
    }

    final primarySnap = await _teams
        .where('competitionKey', isEqualTo: competitionKey)
        .limit(AppConstants.defaultPageSize)
        .get();
    final legacySnap = await _teams
        .where('sportKey', isEqualTo: competitionKey)
        .limit(AppConstants.defaultPageSize)
        .get();

    final seen = <String>{};
    final results = <Team>[];
    for (final doc in [...primarySnap.docs, ...legacySnap.docs]) {
      if (seen.add(doc.id)) {
        results.add(Team.fromFirestore(doc.data(), doc.id));
      }
    }
    results.sort((a, b) => a.nameJa.compareTo(b.nameJa));
    return results;
  }

  /// Fetch a single team by ID.
  @override
  Future<Team?> fetchTeam(String teamId) async {
    final doc = await _teams.doc(teamId).get();
    if (!doc.exists || doc.data() == null) return null;
    return Team.fromFirestore(doc.data()!, doc.id);
  }

  /// Fetch multiple teams by their IDs (for followed teams list).
  @override
  Future<List<Team>> fetchTeamsByIds(List<String> teamIds) async {
    if (teamIds.isEmpty) return [];

    // Firestore 'whereIn' supports up to 30 items per query
    final chunks = <List<String>>[];
    for (var i = 0; i < teamIds.length; i += 30) {
      chunks.add(
        teamIds.sublist(i, i + 30 > teamIds.length ? teamIds.length : i + 30),
      );
    }

    final results = <Team>[];
    for (final chunk in chunks) {
      final snapshot = await _teams
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      results.addAll(
        snapshot.docs.map((doc) => Team.fromFirestore(doc.data(), doc.id)),
      );
    }
    return results;
  }

  /// Search teams by name (Japanese or English).
  ///
  /// Two complementary strategies are combined and deduplicated by document ID:
  ///
  /// 1. `nameJa` prefix search — fast for Japanese prefix input (e.g. "鹿島").
  ///    Upper bound uses the maximum Unicode scalar suffix so CJK and
  ///    full-width Latin characters are included in the range.
  ///
  /// 2. `searchKeywords` array-contains search — covers mid-string Japanese
  ///    matches (via aliases stored at seed/sync time) and English input.
  ///    The query value is lowercased to match the stored lowercase keywords.
  ///
  /// When [competitionKey] is provided, both strategies issue a primary query
  /// (new `competitionKey` field) and a legacy fallback (`sportKey` field).
  @override
  Future<List<Team>> searchTeams(String query, {String? competitionKey}) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) {
      return fetchTeams(competitionKey: competitionKey);
    }

    const maxUnicodeSuffix = '\uDBFF\uDFFF';
    final endQuery = '$trimmedQuery$maxUnicodeSuffix';

    final keywordQueries = _searchKeywordQueries(trimmedQuery);

    Query<Map<String, dynamic>> nameFilter(Query<Map<String, dynamic>> base) =>
        base
            .where('nameJa', isGreaterThanOrEqualTo: trimmedQuery)
            .where('nameJa', isLessThan: endQuery);

    // Helper: merge docs from multiple snapshots, deduplicate by doc ID,
    // and honour the overall page size limit.
    List<Team> mergeSnapshots(
      List<List<QueryDocumentSnapshot<Map<String, dynamic>>>> snapshots,
    ) {
      final seen = <String>{};
      final results = <Team>[];
      for (final docs in snapshots) {
        for (final doc in docs) {
          if (seen.add(doc.id)) {
            results.add(Team.fromFirestore(doc.data(), doc.id));
            if (results.length >= AppConstants.defaultPageSize) return results;
          }
        }
      }
      return results;
    }

    if (competitionKey == null) {
      // No competition filter — search across all teams ("すべて" tab).

      // 1. nameJa prefix search.
      final prefixSnap = await nameFilter(
        _teams,
      ).limit(AppConstants.defaultPageSize).get();

      // 2. searchKeywords array-contains search (no composite index needed).
      final kwSnaps = await Future.wait(
        keywordQueries.map(
          (keyword) => _teams
              .where('searchKeywords', arrayContains: keyword)
              .limit(AppConstants.defaultPageSize)
              .get(),
        ),
      );

      return mergeSnapshots([
        prefixSnap.docs,
        ...kwSnaps.map((snap) => snap.docs),
      ]);
    }

    // Competition-filtered search.

    // 1a. nameJa prefix — primary (competitionKey field).
    final prefixPrimarySnap = await nameFilter(_teams)
        .where('competitionKey', isEqualTo: competitionKey)
        .limit(AppConstants.defaultPageSize)
        .get();

    // 1b. nameJa prefix — legacy fallback (sportKey field).
    final prefixLegacySnap = await nameFilter(_teams)
        .where('sportKey', isEqualTo: competitionKey)
        .limit(AppConstants.defaultPageSize)
        .get();

    // 2. searchKeywords — primary and legacy fallback.
    final kwPrimarySnaps = await Future.wait(
      keywordQueries.map(
        (keyword) => _teams
            .where('competitionKey', isEqualTo: competitionKey)
            .where('searchKeywords', arrayContains: keyword)
            .limit(AppConstants.defaultPageSize)
            .get(),
      ),
    );
    final kwLegacySnaps = await Future.wait(
      keywordQueries.map(
        (keyword) => _teams
            .where('sportKey', isEqualTo: competitionKey)
            .where('searchKeywords', arrayContains: keyword)
            .limit(AppConstants.defaultPageSize)
            .get(),
      ),
    );

    return mergeSnapshots([
      prefixPrimarySnap.docs,
      prefixLegacySnap.docs,
      ...kwPrimarySnaps.map((snap) => snap.docs),
      ...kwLegacySnaps.map((snap) => snap.docs),
    ]);
  }

  List<String> _searchKeywordQueries(String query) {
    final asciiNormalized = _normalizeAsciiWidth(query);
    return {
      query,
      query.toLowerCase(),
      query.toUpperCase(),
      asciiNormalized,
      asciiNormalized.toLowerCase(),
      asciiNormalized.toUpperCase(),
    }.where((value) => value.isNotEmpty).toList();
  }

  String _normalizeAsciiWidth(String value) {
    final buffer = StringBuffer();
    for (final codePoint in value.runes) {
      if (codePoint == 0x3000) {
        buffer.writeCharCode(0x20);
      } else if (codePoint >= 0xFF01 && codePoint <= 0xFF5E) {
        buffer.writeCharCode(codePoint - 0xFEE0);
      } else {
        buffer.writeCharCode(codePoint);
      }
    }
    return buffer.toString();
  }
}

/// In-memory sample implementation for the free MVP mode.
///
/// This repository never reads Firestore. It is selected with:
///
/// ```shell
/// flutter run --dart-define=USE_SAMPLE_DATA=true
/// ```
class SampleTeamRepository implements TeamRepository {
  static const _leagues = [
    League(
      id: 'sample_j1_league',
      nameEn: 'J.League',
      nameJa: 'Jリーグ',
      competitionKey: 'football_j1',
      country: 'Japan',
      externalLeagueId: 98,
    ),
    League(
      id: 'sample_j2_league',
      nameEn: 'J2 League',
      nameJa: 'J2リーグ',
      competitionKey: 'football_j2',
      country: 'Japan',
      externalLeagueId: 99,
    ),
    League(
      id: 'sample_j3_league',
      nameEn: 'J3 League',
      nameJa: 'J3リーグ',
      competitionKey: 'football_j3',
      country: 'Japan',
      externalLeagueId: 100,
    ),
    League(
      id: 'sample_npb_league',
      nameEn: 'NPB',
      nameJa: 'NPB',
      competitionKey: 'baseball_npb',
      country: 'Japan',
    ),
    League(
      id: 'sample_nba_league',
      nameEn: 'NBA',
      nameJa: 'NBA',
      competitionKey: 'basketball_nba',
      country: 'USA',
    ),
  ];

  static const _teams = [
    Team(
      id: 'kashima_antlers',
      nameEn: 'Kashima Antlers',
      nameJa: '鹿島アントラーズ',
      leagueId: 'sample_j1_league',
      competitionKey: 'football_j1',
      country: 'Japan',
      externalTeamId: 290,
    ),
    Team(
      id: 'urawa_reds',
      nameEn: 'Urawa Reds',
      nameJa: '浦和レッズ',
      leagueId: 'sample_j1_league',
      competitionKey: 'football_j1',
      country: 'Japan',
      externalTeamId: 296,
    ),
    Team(
      id: 'gamba_osaka',
      nameEn: 'Gamba Osaka',
      nameJa: 'ガンバ大阪',
      leagueId: 'sample_j1_league',
      competitionKey: 'football_j1',
      country: 'Japan',
      externalTeamId: 288,
    ),
    Team(
      id: 'cerezo_osaka',
      nameEn: 'Cerezo Osaka',
      nameJa: 'セレッソ大阪',
      leagueId: 'sample_j1_league',
      competitionKey: 'football_j1',
      country: 'Japan',
      externalTeamId: 294,
    ),
    Team(
      id: 'vegalta_sendai',
      nameEn: 'Vegalta Sendai',
      nameJa: 'ベガルタ仙台',
      leagueId: 'sample_j2_league',
      competitionKey: 'football_j2',
      country: 'Japan',
      externalTeamId: 282,
    ),
    Team(
      id: 'jubilo_iwata',
      nameEn: 'Jubilo Iwata',
      nameJa: 'ジュビロ磐田',
      leagueId: 'sample_j2_league',
      competitionKey: 'football_j2',
      country: 'Japan',
      externalTeamId: 281,
    ),
    Team(
      id: 'fc_gifu',
      nameEn: 'FC Gifu',
      nameJa: 'FC岐阜',
      leagueId: 'sample_j3_league',
      competitionKey: 'football_j3',
      country: 'Japan',
      externalTeamId: 310,
    ),
    Team(
      id: 'reilac_shiga',
      nameEn: 'Reilac Shiga FC',
      nameJa: 'レイラック滋賀FC',
      leagueId: 'sample_j3_league',
      competitionKey: 'football_j3',
      country: 'Japan',
      externalTeamId: 7117,
    ),
    Team(
      id: 'yomiuri_giants',
      nameEn: 'Yomiuri Giants',
      nameJa: '読売ジャイアンツ',
      leagueId: 'sample_npb_league',
      competitionKey: 'baseball_npb',
      country: 'Japan',
    ),
    Team(
      id: 'hanshin_tigers',
      nameEn: 'Hanshin Tigers',
      nameJa: '阪神タイガース',
      leagueId: 'sample_npb_league',
      competitionKey: 'baseball_npb',
      country: 'Japan',
    ),
    Team(
      id: 'los_angeles_lakers',
      nameEn: 'Los Angeles Lakers',
      nameJa: 'ロサンゼルス・レイカーズ',
      leagueId: 'sample_nba_league',
      competitionKey: 'basketball_nba',
      country: 'USA',
    ),
    Team(
      id: 'golden_state_warriors',
      nameEn: 'Golden State Warriors',
      nameJa: 'ゴールデンステイト・ウォリアーズ',
      leagueId: 'sample_nba_league',
      competitionKey: 'basketball_nba',
      country: 'USA',
    ),
  ];

  @override
  Future<List<League>> fetchLeagues({String? competitionKey}) async {
    final leagues = competitionKey == null
        ? _leagues
        : _leagues
              .where((league) => league.competitionKey == competitionKey)
              .toList();
    return [...leagues]..sort((a, b) => a.nameJa.compareTo(b.nameJa));
  }

  @override
  Future<List<Team>> fetchTeamsByLeague(String leagueId) async {
    return _sortedTeams(_teams.where((team) => team.leagueId == leagueId));
  }

  @override
  Future<List<Team>> fetchTeams({String? competitionKey}) async {
    return _sortedTeams(
      competitionKey == null
          ? _teams
          : _teams.where((team) => team.competitionKey == competitionKey),
    );
  }

  @override
  Future<Team?> fetchTeam(String teamId) async {
    for (final team in _teams) {
      if (team.id == teamId) return team;
    }
    return null;
  }

  @override
  Future<List<Team>> fetchTeamsByIds(List<String> teamIds) async {
    if (teamIds.isEmpty) return [];
    final byId = {for (final team in _teams) team.id: team};
    final teams = <Team>[];
    for (final id in teamIds) {
      final team = byId[id];
      if (team != null) teams.add(team);
    }
    return teams;
  }

  @override
  Future<List<Team>> searchTeams(String query, {String? competitionKey}) async {
    final normalizedQuery = _normalize(query);
    final scopedTeams = competitionKey == null
        ? _teams
        : _teams.where((team) => team.competitionKey == competitionKey);

    if (normalizedQuery.isEmpty) {
      return _sortedTeams(scopedTeams);
    }

    return _sortedTeams(
      scopedTeams.where(
        (team) => _searchableText(team).contains(normalizedQuery),
      ),
    );
  }

  List<Team> _sortedTeams(Iterable<Team> teams) {
    return teams.toList()..sort((a, b) => a.nameJa.compareTo(b.nameJa));
  }

  String _searchableText(Team team) {
    final aliases = <String>[
      team.id,
      team.nameEn,
      team.nameJa,
      if (team.id == 'gamba_osaka') ...['G大阪', 'ガンバ'],
      if (team.id == 'cerezo_osaka') ...['C大阪', 'セレッソ'],
      if (team.id == 'kashima_antlers') '鹿島',
      if (team.id == 'urawa_reds') '浦和',
      if (team.id == 'vegalta_sendai') '仙台',
      if (team.id == 'jubilo_iwata') '磐田',
      if (team.id == 'fc_gifu') '岐阜',
      if (team.id == 'reilac_shiga') ...['滋賀', 'Biwako Shiga'],
      if (team.id == 'yomiuri_giants') ...['巨人', 'ジャイアンツ'],
      if (team.id == 'hanshin_tigers') ...['阪神', 'タイガース'],
      if (team.id == 'los_angeles_lakers') ...['レイカーズ', 'Lakers'],
      if (team.id == 'golden_state_warriors') ...['ウォリアーズ', 'Warriors', 'GSW'],
    ];
    return aliases.map(_normalize).join(' ');
  }

  String _normalize(String value) {
    final buffer = StringBuffer();
    for (final codePoint in value.runes) {
      if (codePoint == 0x3000) {
        buffer.writeCharCode(0x20);
      } else if (codePoint >= 0xFF01 && codePoint <= 0xFF5E) {
        buffer.writeCharCode(codePoint - 0xFEE0);
      } else {
        buffer.writeCharCode(codePoint);
      }
    }
    return buffer.toString().toLowerCase().trim();
  }
}
