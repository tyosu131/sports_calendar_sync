import 'package:cloud_firestore/cloud_firestore.dart';

/// Broadcast platform info for a game
class BroadcastInfo {
  const BroadcastInfo({
    required this.platform,
    this.url,
    this.note,
  });

  /// e.g. "DAZN", "U-NEXT", "ABEMA", "NHK", "フジテレビ"
  final String platform;
  final String? url;
  final String? note;

  factory BroadcastInfo.fromMap(Map<String, dynamic> data) {
    return BroadcastInfo(
      platform: data['platform'] as String,
      url: data['url'] as String?,
      note: data['note'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'platform': platform,
      if (url != null) 'url': url,
      if (note != null) 'note': note,
    };
  }
}

/// Game status
enum GameStatus {
  scheduled,
  live,
  finished,
  postponed,
  cancelled,
}

/// A single game/match
class Game {
  const Game({
    required this.id,
    required this.leagueId,
    required this.homeTeamId,
    required this.homeTeamNameJa,
    required this.awayTeamId,
    required this.awayTeamNameJa,
    required this.startTimeUtc,
    required this.startTimeJst,
    required this.timezone,
    required this.status,
    this.venue,
    this.homeScore,
    this.awayScore,
    this.broadcastPlatforms = const [],
    this.rapidApiFixtureId,
  });

  final String id;
  final String leagueId;
  final String homeTeamId;
  final String homeTeamNameJa;
  final String awayTeamId;
  final String awayTeamNameJa;

  /// UTC timestamp — used for calendar sync
  final Timestamp startTimeUtc;

  /// JST string — used for display in Japan (e.g. "2025-07-15 19:00")
  final String startTimeJst;

  /// Venue timezone (e.g. "America/New_York", "Asia/Tokyo")
  final String timezone;

  final GameStatus status;
  final String? venue;
  final int? homeScore;
  final int? awayScore;

  /// Streaming/broadcast platforms (DAZN, ABEMA, etc.)
  final List<BroadcastInfo> broadcastPlatforms;

  final int? rapidApiFixtureId;

  factory Game.fromFirestore(Map<String, dynamic> data, String docId) {
    final broadcastList = (data['broadcastPlatforms'] as List<dynamic>? ?? [])
        .map((e) => BroadcastInfo.fromMap(e as Map<String, dynamic>))
        .toList();

    return Game(
      id: docId,
      leagueId: data['leagueId'] as String,
      homeTeamId: data['homeTeamId'] as String,
      homeTeamNameJa: data['homeTeamNameJa'] as String,
      awayTeamId: data['awayTeamId'] as String,
      awayTeamNameJa: data['awayTeamNameJa'] as String,
      startTimeUtc: data['startTimeUTC'] as Timestamp,
      startTimeJst: data['startTimeJST'] as String,
      timezone: data['timezone'] as String,
      status: GameStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => GameStatus.scheduled,
      ),
      venue: data['venue'] as String?,
      homeScore: data['homeScore'] as int?,
      awayScore: data['awayScore'] as int?,
      broadcastPlatforms: broadcastList,
      rapidApiFixtureId: data['rapidApiFixtureId'] as int?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'leagueId': leagueId,
      'homeTeamId': homeTeamId,
      'homeTeamNameJa': homeTeamNameJa,
      'awayTeamId': awayTeamId,
      'awayTeamNameJa': awayTeamNameJa,
      'startTimeUTC': startTimeUtc,
      'startTimeJST': startTimeJst,
      'timezone': timezone,
      'status': status.name,
      if (venue != null) 'venue': venue,
      if (homeScore != null) 'homeScore': homeScore,
      if (awayScore != null) 'awayScore': awayScore,
      'broadcastPlatforms': broadcastPlatforms.map((b) => b.toMap()).toList(),
      if (rapidApiFixtureId != null) 'rapidApiFixtureId': rapidApiFixtureId,
    };
  }

  DateTime get startTimeUtcDateTime => startTimeUtc.toDate();
}
