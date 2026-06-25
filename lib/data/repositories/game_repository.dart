import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/utils/app_constants.dart';
import '../../domain/models/game.dart';

/// Read API for game schedules.
abstract class GameRepository {
  Future<List<Game>> fetchUpcomingGamesForTeam(
    String teamId, {
    int limit = AppConstants.defaultPageSize,
  });

  Future<List<Game>> fetchUpcomingGamesForTeams(
    List<String> teamIds, {
    int limit = 50,
    DateTime? from,
  });

  Future<List<Game>> fetchScheduleGamesForTeams(
    List<String> teamIds, {
    int limit = 120,
  });

  Stream<List<Game>> watchUpcomingGamesForTeam(String teamId);

  Future<Game?> fetchGame(String gameId);
}

/// Handles Firestore read operations for game schedules.
class FirestoreGameRepository implements GameRepository {
  FirestoreGameRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _games =>
      _firestore.collection(AppConstants.gamesCollection);

  /// Fetch upcoming games for a specific team.
  @override
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
  @override
  Future<List<Game>> fetchUpcomingGamesForTeams(
    List<String> teamIds, {
    int limit = 50,
    DateTime? from,
  }) async {
    if (teamIds.isEmpty) return [];

    final fromTimestamp = from != null
        ? Timestamp.fromDate(from)
        : Timestamp.now();

    // Firestore doesn't support OR queries across different fields natively.
    // We query home and away separately, then merge.
    final chunks = <List<String>>[];
    for (var i = 0; i < teamIds.length; i += 10) {
      chunks.add(
        teamIds.sublist(i, i + 10 > teamIds.length ? teamIds.length : i + 10),
      );
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

      allGames.addAll(
        homeSnap.docs.map((d) => Game.fromFirestore(d.data(), d.id)),
      );
      allGames.addAll(
        awaySnap.docs.map((d) => Game.fromFirestore(d.data(), d.id)),
      );
    }

    // Sort, deduplicate, limit
    allGames.sort((a, b) => a.startTimeUtc.compareTo(b.startTimeUtc));
    final seen = <String>{};
    return allGames.where((g) => seen.add(g.id)).take(limit).toList();
  }

  /// Fetch schedule games for multiple teams without filtering to future only.
  @override
  Future<List<Game>> fetchScheduleGamesForTeams(
    List<String> teamIds, {
    int limit = 120,
  }) async {
    if (teamIds.isEmpty) return [];

    // Read-only schedule query. Unlike the home feed, this intentionally does
    // not filter to future/scheduled games so a schedule view can show past
    // results and scores as well.
    final chunks = <List<String>>[];
    for (var i = 0; i < teamIds.length; i += 10) {
      chunks.add(
        teamIds.sublist(i, i + 10 > teamIds.length ? teamIds.length : i + 10),
      );
    }

    final allGames = <Game>[];
    for (final chunk in chunks) {
      final homeSnap = await _games
          .where('homeTeamId', whereIn: chunk)
          .orderBy('startTimeUTC')
          .limit(limit)
          .get();

      final awaySnap = await _games
          .where('awayTeamId', whereIn: chunk)
          .orderBy('startTimeUTC')
          .limit(limit)
          .get();

      allGames.addAll(
        homeSnap.docs.map((d) => Game.fromFirestore(d.data(), d.id)),
      );
      allGames.addAll(
        awaySnap.docs.map((d) => Game.fromFirestore(d.data(), d.id)),
      );
    }

    allGames.sort((a, b) => a.startTimeUtc.compareTo(b.startTimeUtc));
    final seen = <String>{};
    return allGames.where((g) => seen.add(g.id)).take(limit).toList();
  }

  /// Stream of upcoming games for a team (real-time updates).
  @override
  Stream<List<Game>> watchUpcomingGamesForTeam(String teamId) {
    final now = Timestamp.now();
    return _games
        .where('homeTeamId', isEqualTo: teamId)
        .where('startTimeUTC', isGreaterThanOrEqualTo: now)
        .orderBy('startTimeUTC')
        .limit(AppConstants.defaultPageSize)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => Game.fromFirestore(d.data(), d.id)).toList(),
        );
  }

  /// Fetch a single game by ID.
  @override
  Future<Game?> fetchGame(String gameId) async {
    final doc = await _games.doc(gameId).get();
    if (!doc.exists || doc.data() == null) return null;
    return Game.fromFirestore(doc.data()!, doc.id);
  }
}

/// In-memory sample implementation for the free MVP mode.
///
/// This repository never reads Firestore. It is selected with:
///
/// ```shell
/// flutter run --dart-define=USE_SAMPLE_DATA=true
/// ```
class SampleGameRepository implements GameRepository {
  @override
  Future<List<Game>> fetchUpcomingGamesForTeam(
    String teamId, {
    int limit = AppConstants.defaultPageSize,
  }) async {
    return _upcomingGames(limit: limit)
        .where((game) => game.homeTeamId == teamId || game.awayTeamId == teamId)
        .take(limit)
        .toList();
  }

  @override
  Future<List<Game>> fetchUpcomingGamesForTeams(
    List<String> teamIds, {
    int limit = 50,
    DateTime? from,
  }) async {
    if (teamIds.isEmpty) return [];
    final ids = teamIds.toSet();
    final fromDate = from ?? DateTime.now();
    final games =
        _sampleGames()
            .where(
              (game) =>
                  game.startTimeUtc.toDate().isAfter(fromDate) ||
                  game.startTimeUtc.toDate().isAtSameMomentAs(fromDate),
            )
            .where(
              (game) =>
                  ids.contains(game.homeTeamId) ||
                  ids.contains(game.awayTeamId),
            )
            .toList()
          ..sort((a, b) => a.startTimeUtc.compareTo(b.startTimeUtc));
    return games.take(limit).toList();
  }

  @override
  Stream<List<Game>> watchUpcomingGamesForTeam(String teamId) {
    return Stream.fromFuture(fetchUpcomingGamesForTeam(teamId));
  }

  @override
  Future<List<Game>> fetchScheduleGamesForTeams(
    List<String> teamIds, {
    int limit = 120,
  }) async {
    if (teamIds.isEmpty) return [];
    final ids = teamIds.toSet();
    final games =
        _sampleGames()
            .where(
              (game) =>
                  ids.contains(game.homeTeamId) ||
                  ids.contains(game.awayTeamId),
            )
            .toList()
          ..sort((a, b) => a.startTimeUtc.compareTo(b.startTimeUtc));
    return games.take(limit).toList();
  }

  @override
  Future<Game?> fetchGame(String gameId) async {
    for (final game in _sampleGames()) {
      if (game.id == gameId) return game;
    }
    return null;
  }

  List<Game> _upcomingGames({required int limit}) {
    final now = DateTime.now();
    final games =
        _sampleGames()
            .where(
              (game) =>
                  game.startTimeUtc.toDate().isAfter(now) ||
                  game.startTimeUtc.toDate().isAtSameMomentAs(now),
            )
            .toList()
          ..sort((a, b) => a.startTimeUtc.compareTo(b.startTimeUtc));
    return games.take(limit).toList();
  }

  List<Game> _sampleGames() {
    return [
      _game(
        id: 'sample_finished_kashima_gamba_001',
        daysFromNow: -7,
        utcHour: 10,
        leagueId: 'sample_j1_league',
        competitionKey: 'football_j1',
        homeTeamId: 'kashima_antlers',
        homeTeamNameJa: '鹿島アントラーズ',
        homeTeamNameEn: 'Kashima Antlers',
        awayTeamId: 'gamba_osaka',
        awayTeamNameJa: 'ガンバ大阪',
        awayTeamNameEn: 'Gamba Osaka',
        venue: '県立カシマサッカースタジアム',
        status: GameStatus.finished,
        homeScore: 2,
        awayScore: 1,
      ),
      _game(
        id: 'sample_kashima_urawa_001',
        daysFromNow: 7,
        utcHour: 10,
        leagueId: 'sample_j1_league',
        competitionKey: 'football_j1',
        homeTeamId: 'kashima_antlers',
        homeTeamNameJa: '鹿島アントラーズ',
        homeTeamNameEn: 'Kashima Antlers',
        awayTeamId: 'urawa_reds',
        awayTeamNameJa: '浦和レッズ',
        awayTeamNameEn: 'Urawa Reds',
        venue: '県立カシマサッカースタジアム',
        broadcastPlatforms: const [
          BroadcastInfo(platform: 'DAZN', note: 'サンプル放送情報'),
        ],
      ),
      _game(
        id: 'sample_osaka_derby_001',
        daysFromNow: 10,
        utcHour: 9,
        leagueId: 'sample_j1_league',
        competitionKey: 'football_j1',
        homeTeamId: 'gamba_osaka',
        homeTeamNameJa: 'ガンバ大阪',
        homeTeamNameEn: 'Gamba Osaka',
        awayTeamId: 'cerezo_osaka',
        awayTeamNameJa: 'セレッソ大阪',
        awayTeamNameEn: 'Cerezo Osaka',
        venue: 'パナソニック スタジアム 吹田',
        broadcastPlatforms: const [
          BroadcastInfo(platform: 'DAZN', note: 'サンプル放送情報'),
        ],
      ),
      _game(
        id: 'sample_sendai_iwata_001',
        daysFromNow: 14,
        utcHour: 10,
        leagueId: 'sample_j2_league',
        competitionKey: 'football_j2',
        homeTeamId: 'vegalta_sendai',
        homeTeamNameJa: 'ベガルタ仙台',
        homeTeamNameEn: 'Vegalta Sendai',
        awayTeamId: 'jubilo_iwata',
        awayTeamNameJa: 'ジュビロ磐田',
        awayTeamNameEn: 'Jubilo Iwata',
        venue: 'ユアテックスタジアム仙台',
      ),
      _game(
        id: 'sample_gifu_shiga_001',
        daysFromNow: 21,
        utcHour: 5,
        leagueId: 'sample_j3_league',
        competitionKey: 'football_j3',
        homeTeamId: 'fc_gifu',
        homeTeamNameJa: 'FC岐阜',
        homeTeamNameEn: 'FC Gifu',
        awayTeamId: 'reilac_shiga',
        awayTeamNameJa: 'レイラック滋賀FC',
        awayTeamNameEn: 'Reilac Shiga FC',
        venue: '岐阜メモリアルセンター長良川競技場',
      ),
      _game(
        id: 'sample_kashima_gamba_001',
        daysFromNow: 28,
        utcHour: 10,
        leagueId: 'sample_j1_league',
        competitionKey: 'football_j1',
        homeTeamId: 'kashima_antlers',
        homeTeamNameJa: '鹿島アントラーズ',
        homeTeamNameEn: 'Kashima Antlers',
        awayTeamId: 'gamba_osaka',
        awayTeamNameJa: 'ガンバ大阪',
        awayTeamNameEn: 'Gamba Osaka',
        venue: '国立競技場',
      ),
      _game(
        id: 'sample_finished_giants_tigers_001',
        daysFromNow: -4,
        utcHour: 9,
        leagueId: 'sample_npb_league',
        competitionKey: 'baseball_npb',
        homeTeamId: 'yomiuri_giants',
        homeTeamNameJa: '読売ジャイアンツ',
        homeTeamNameEn: 'Yomiuri Giants',
        awayTeamId: 'hanshin_tigers',
        awayTeamNameJa: '阪神タイガース',
        awayTeamNameEn: 'Hanshin Tigers',
        venue: '東京ドーム',
        status: GameStatus.finished,
        homeScore: 4,
        awayScore: 3,
      ),
      _game(
        id: 'sample_giants_tigers_001',
        daysFromNow: 5,
        utcHour: 9,
        leagueId: 'sample_npb_league',
        competitionKey: 'baseball_npb',
        homeTeamId: 'yomiuri_giants',
        homeTeamNameJa: '読売ジャイアンツ',
        homeTeamNameEn: 'Yomiuri Giants',
        awayTeamId: 'hanshin_tigers',
        awayTeamNameJa: '阪神タイガース',
        awayTeamNameEn: 'Hanshin Tigers',
        venue: '東京ドーム',
        broadcastPlatforms: const [
          BroadcastInfo(platform: '地上波', note: 'サンプル放送情報'),
        ],
      ),
      _game(
        id: 'sample_finished_lakers_warriors_001',
        daysFromNow: -2,
        utcHour: 11,
        leagueId: 'sample_nba_league',
        competitionKey: 'basketball_nba',
        homeTeamId: 'los_angeles_lakers',
        homeTeamNameJa: 'ロサンゼルス・レイカーズ',
        homeTeamNameEn: 'Los Angeles Lakers',
        awayTeamId: 'golden_state_warriors',
        awayTeamNameJa: 'ゴールデンステイト・ウォリアーズ',
        awayTeamNameEn: 'Golden State Warriors',
        venue: 'Crypto.com Arena',
        status: GameStatus.finished,
        homeScore: 112,
        awayScore: 108,
      ),
      _game(
        id: 'sample_lakers_warriors_001',
        daysFromNow: 12,
        utcHour: 11,
        leagueId: 'sample_nba_league',
        competitionKey: 'basketball_nba',
        homeTeamId: 'los_angeles_lakers',
        homeTeamNameJa: 'ロサンゼルス・レイカーズ',
        homeTeamNameEn: 'Los Angeles Lakers',
        awayTeamId: 'golden_state_warriors',
        awayTeamNameJa: 'ゴールデンステイト・ウォリアーズ',
        awayTeamNameEn: 'Golden State Warriors',
        venue: 'Crypto.com Arena',
        broadcastPlatforms: const [
          BroadcastInfo(platform: 'NBA League Pass', note: 'サンプル配信情報'),
        ],
      ),
    ]..sort((a, b) => a.startTimeUtc.compareTo(b.startTimeUtc));
  }

  Game _game({
    required String id,
    required int daysFromNow,
    required int utcHour,
    required String leagueId,
    required String competitionKey,
    required String homeTeamId,
    required String homeTeamNameJa,
    required String homeTeamNameEn,
    required String awayTeamId,
    required String awayTeamNameJa,
    required String awayTeamNameEn,
    required String venue,
    List<BroadcastInfo> broadcastPlatforms = const [],
    GameStatus status = GameStatus.scheduled,
    int? homeScore,
    int? awayScore,
  }) {
    final startUtc = _futureUtc(daysFromNow, utcHour);
    return Game(
      id: id,
      leagueId: leagueId,
      competitionKey: competitionKey,
      competitionSeasonKey: '${competitionKey}_sample_2026',
      homeTeamId: homeTeamId,
      homeTeamNameJa: homeTeamNameJa,
      homeTeamNameEn: homeTeamNameEn,
      awayTeamId: awayTeamId,
      awayTeamNameJa: awayTeamNameJa,
      awayTeamNameEn: awayTeamNameEn,
      startTimeUtc: Timestamp.fromDate(startUtc),
      startTimeJst: _formatJst(startUtc),
      timezone: 'Asia/Tokyo',
      status: status,
      venue: venue,
      homeScore: homeScore,
      awayScore: awayScore,
      broadcastPlatforms: broadcastPlatforms,
    );
  }

  DateTime _futureUtc(int daysFromNow, int utcHour) {
    final now = DateTime.now().toUtc();
    return DateTime.utc(now.year, now.month, now.day + daysFromNow, utcHour);
  }

  String _formatJst(DateTime utc) {
    final jst = utc.add(const Duration(hours: 9));
    String twoDigits(int value) => value.toString().padLeft(2, '0');
    return '${jst.year}-${twoDigits(jst.month)}-${twoDigits(jst.day)} '
        '${twoDigits(jst.hour)}:${twoDigits(jst.minute)}';
  }
}
