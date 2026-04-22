import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/utils/app_constants.dart';
import '../../domain/models/game.dart';

/// Handles Firestore read operations for game schedules.
class GameRepository {
  GameRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _games =>
      _firestore.collection(AppConstants.gamesCollection);

  /// Fetch upcoming games for a specific team.
  Future<List<Game>> fetchUpcomingGamesForTeam(
    String teamId, {
    int limit = AppConstants.defaultPageSize,
  }) async {
    final now = Timestamp.now();
    final snapshot = await _games
        .where('homeTeamId', isEqualTo: teamId)
        .where('startTimeUTC', isGreaterThanOrEqualTo: now)
        .where('status', isEqualTo: GameStatus.scheduled.name)
        .orderBy('startTimeUTC')
        .limit(limit)
        .get();

    // Also fetch away games
    final awaySnapshot = await _games
        .where('awayTeamId', isEqualTo: teamId)
        .where('startTimeUTC', isGreaterThanOrEqualTo: now)
        .where('status', isEqualTo: GameStatus.scheduled.name)
        .orderBy('startTimeUTC')
        .limit(limit)
        .get();

    final allGames = [
      ...snapshot.docs.map((doc) => Game.fromFirestore(doc.data(), doc.id)),
      ...awaySnapshot.docs.map((doc) => Game.fromFirestore(doc.data(), doc.id)),
    ];

    // Sort by startTimeUTC and deduplicate
    allGames.sort((a, b) => a.startTimeUtc.compareTo(b.startTimeUtc));
    final seen = <String>{};
    return allGames.where((g) => seen.add(g.id)).take(limit).toList();
  }

  /// Fetch upcoming games for multiple teams (user's followed teams).
  Future<List<Game>> fetchUpcomingGamesForTeams(
    List<String> teamIds, {
    int limit = 50,
    DateTime? from,
  }) async {
    if (teamIds.isEmpty) return [];

    final fromTimestamp = from != null ? Timestamp.fromDate(from) : Timestamp.now();

    // Firestore doesn't support OR queries across different fields natively.
    // We query home and away separately, then merge.
    final chunks = <List<String>>[];
    for (var i = 0; i < teamIds.length; i += 10) {
      chunks.add(teamIds.sublist(i, i + 10 > teamIds.length ? teamIds.length : i + 10));
    }

    final allGames = <Game>[];
    for (final chunk in chunks) {
      final homeSnap = await _games
          .where('homeTeamId', whereIn: chunk)
          .where('startTimeUTC', isGreaterThanOrEqualTo: fromTimestamp)
          .orderBy('startTimeUTC')
          .limit(limit)
          .get();

      final awaySnap = await _games
          .where('awayTeamId', whereIn: chunk)
          .where('startTimeUTC', isGreaterThanOrEqualTo: fromTimestamp)
          .orderBy('startTimeUTC')
          .limit(limit)
          .get();

      allGames.addAll(homeSnap.docs.map((d) => Game.fromFirestore(d.data(), d.id)));
      allGames.addAll(awaySnap.docs.map((d) => Game.fromFirestore(d.data(), d.id)));
    }

    // Sort, deduplicate, limit
    allGames.sort((a, b) => a.startTimeUtc.compareTo(b.startTimeUtc));
    final seen = <String>{};
    return allGames.where((g) => seen.add(g.id)).take(limit).toList();
  }

  /// Stream of upcoming games for a team (real-time updates).
  Stream<List<Game>> watchUpcomingGamesForTeam(String teamId) {
    final now = Timestamp.now();
    return _games
        .where('homeTeamId', isEqualTo: teamId)
        .where('startTimeUTC', isGreaterThanOrEqualTo: now)
        .orderBy('startTimeUTC')
        .limit(AppConstants.defaultPageSize)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Game.fromFirestore(d.data(), d.id)).toList());
  }

  /// Fetch a single game by ID.
  Future<Game?> fetchGame(String gameId) async {
    final doc = await _games.doc(gameId).get();
    if (!doc.exists || doc.data() == null) return null;
    return Game.fromFirestore(doc.data()!, doc.id);
  }
}
