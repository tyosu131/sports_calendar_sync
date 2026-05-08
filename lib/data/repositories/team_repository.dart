import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/utils/app_constants.dart';
import '../../domain/models/sport.dart';
import '../../domain/models/team.dart';

/// Handles Firestore read operations for teams and leagues.
class TeamRepository {
  TeamRepository({FirebaseFirestore? firestore})
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
  Future<Team?> fetchTeam(String teamId) async {
    final doc = await _teams.doc(teamId).get();
    if (!doc.exists || doc.data() == null) return null;
    return Team.fromFirestore(doc.data()!, doc.id);
  }

  /// Fetch multiple teams by their IDs (for followed teams list).
  Future<List<Team>> fetchTeamsByIds(List<String> teamIds) async {
    if (teamIds.isEmpty) return [];

    // Firestore 'whereIn' supports up to 30 items per query
    final chunks = <List<String>>[];
    for (var i = 0; i < teamIds.length; i += 30) {
      chunks.add(teamIds.sublist(
          i, i + 30 > teamIds.length ? teamIds.length : i + 30));
    }

    final results = <Team>[];
    for (final chunk in chunks) {
      final snapshot =
          await _teams.where(FieldPath.documentId, whereIn: chunk).get();
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
  Future<List<Team>> searchTeams(
    String query, {
    String? competitionKey,
  }) async {
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
        List<List<QueryDocumentSnapshot<Map<String, dynamic>>>> snapshots) {
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
      final prefixSnap = await nameFilter(_teams)
          .limit(AppConstants.defaultPageSize)
          .get();

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
