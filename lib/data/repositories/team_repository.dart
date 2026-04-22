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

  /// Fetch all leagues, optionally filtered by sport type.
  Future<List<League>> fetchLeagues({SportType? sportType}) async {
    Query<Map<String, dynamic>> query = _leagues;
    if (sportType != null) {
      query = query.where('sportType', isEqualTo: sportType.name);
    }
    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => League.fromFirestore(doc.data(), doc.id))
        .toList();
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
      chunks.add(teamIds.sublist(i, i + 30 > teamIds.length ? teamIds.length : i + 30));
    }

    final results = <Team>[];
    for (final chunk in chunks) {
      final snapshot = await _teams.where(FieldPath.documentId, whereIn: chunk).get();
      results.addAll(
        snapshot.docs.map((doc) => Team.fromFirestore(doc.data(), doc.id)),
      );
    }
    return results;
  }

  /// Search teams by name (Japanese or English).
  /// Note: Firestore doesn't support full-text search natively.
  /// This uses prefix matching on nameJa. For production, consider Algolia.
  Future<List<Team>> searchTeams(String query) async {
    if (query.isEmpty) return [];

    final snapshot = await _teams
        .where('nameJa', isGreaterThanOrEqualTo: query)
        .where('nameJa', isLessThan: '${query}z')
        .limit(AppConstants.defaultPageSize)
        .get();

    return snapshot.docs
        .map((doc) => Team.fromFirestore(doc.data(), doc.id))
        .toList();
  }
}
