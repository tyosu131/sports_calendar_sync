import 'package:cloud_firestore/cloud_firestore.dart';

/// Broadcast platform info attached to a game.
class BroadcastInfo {
  const BroadcastInfo({
    required this.platform,
    this.url,
    this.note,
  });

  /// Platform name, e.g. "DAZN", "U-NEXT", "ABEMA", "NHK".
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

/// Game / match status.
enum GameStatus {
  scheduled,
  live,
  finished,
  postponed,
  cancelled,
}

/// A single game / match stored in Firestore under /games/{id}.
///
/// ## competitionKey
/// Identifies which competition (league) this game belongs to.
/// Must match a [SportDefinition.competitionKey] in [SportsRegistry].
/// Examples: "football_j1", "baseball_npb", "basketball_nba".
///
/// When reading legacy Firestore documents that lack `competitionKey`, the
/// field is left as null rather than guessed.  Callers that need a non-null
/// value should handle null explicitly.
///
/// ## Backward compatibility
/// - Firestore field `sportKey` is a legacy alias for `competitionKey`.
///   Both are written on save; `competitionKey` takes precedence on read.
/// - [rapidApiFixtureId] is a legacy alias for [externalFixtureId].
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
    this.competitionKey,
    this.competitionSeasonKey,
    this.homeTeamNameEn,
    this.awayTeamNameEn,
    this.homeTeamLogoUrl,
    this.awayTeamLogoUrl,
    this.venue,
    this.homeScore,
    this.awayScore,
    this.broadcastPlatforms = const [],
    this.externalFixtureId,
    @Deprecated('Use externalFixtureId') this.rapidApiFixtureId,
  });

  final String id;

  /// Competition key matching [SportDefinition.competitionKey].
  /// null when the Firestore document predates Phase 0 and the competition
  /// cannot be determined without ambiguity.
  final String? competitionKey;

  /// Concrete competition season / tournament profile key.
  ///
  /// Example: "football_j1_2026_hyakunen". null for legacy documents that do
  /// not yet carry season/tournament metadata.
  final String? competitionSeasonKey;

  final String leagueId;
  final String homeTeamId;
  final String homeTeamNameJa;
  final String awayTeamId;
  final String awayTeamNameJa;

  /// English team name — used as translation fallback and in English UI.
  final String? homeTeamNameEn;
  final String? awayTeamNameEn;

  /// Team logo URL.  null when not available.
  final String? homeTeamLogoUrl;
  final String? awayTeamLogoUrl;

  /// UTC timestamp used for calendar sync.
  final Timestamp startTimeUtc;

  /// JST display string, e.g. "2025-07-15 19:00".
  final String startTimeJst;

  /// Venue timezone, e.g. "Asia/Tokyo", "America/New_York".
  final String timezone;

  final GameStatus status;
  final String? venue;
  final int? homeScore;
  final int? awayScore;

  /// Streaming / broadcast platforms (DAZN, ABEMA, etc.).
  final List<BroadcastInfo> broadcastPlatforms;

  /// External API fixture ID (API-SPORTS or other source).
  final int? externalFixtureId;

  /// @deprecated Use [externalFixtureId].
  // ignore: deprecated_member_use_from_same_package
  final int? rapidApiFixtureId;

  factory Game.fromFirestore(Map<String, dynamic> data, String docId) {
    final broadcastList = (data['broadcastPlatforms'] as List<dynamic>? ?? [])
        .map((e) => BroadcastInfo.fromMap(e as Map<String, dynamic>))
        .toList();

    // Prefer the new `competitionKey` field; fall back to legacy `sportKey`.
    // Do NOT infer from leagueId — ambiguous inference is worse than null.
    final competitionKey =
        data['competitionKey'] as String? ?? data['sportKey'] as String?;

    return Game(
      id: docId,
      competitionKey: competitionKey,
      competitionSeasonKey: data['competitionSeasonKey'] as String?,
      leagueId: data['leagueId'] as String,
      homeTeamId: data['homeTeamId'] as String,
      homeTeamNameJa: data['homeTeamNameJa'] as String,
      awayTeamId: data['awayTeamId'] as String,
      awayTeamNameJa: data['awayTeamNameJa'] as String,
      homeTeamNameEn: data['homeTeamNameEn'] as String?,
      awayTeamNameEn: data['awayTeamNameEn'] as String?,
      homeTeamLogoUrl: data['homeTeamLogoUrl'] as String?,
      awayTeamLogoUrl: data['awayTeamLogoUrl'] as String?,
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
      externalFixtureId: data['externalFixtureId'] as int? ??
          data['rapidApiFixtureId'] as int?,
      // ignore: deprecated_member_use_from_same_package
      rapidApiFixtureId: data['rapidApiFixtureId'] as int?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      if (competitionKey != null) 'competitionKey': competitionKey,
      if (competitionSeasonKey != null)
        'competitionSeasonKey': competitionSeasonKey,
      // Legacy alias — kept so existing queries on `sportKey` still work.
      if (competitionKey != null) 'sportKey': competitionKey,
      'leagueId': leagueId,
      'homeTeamId': homeTeamId,
      'homeTeamNameJa': homeTeamNameJa,
      'awayTeamId': awayTeamId,
      'awayTeamNameJa': awayTeamNameJa,
      if (homeTeamNameEn != null) 'homeTeamNameEn': homeTeamNameEn,
      if (awayTeamNameEn != null) 'awayTeamNameEn': awayTeamNameEn,
      if (homeTeamLogoUrl != null) 'homeTeamLogoUrl': homeTeamLogoUrl,
      if (awayTeamLogoUrl != null) 'awayTeamLogoUrl': awayTeamLogoUrl,
      'startTimeUTC': startTimeUtc,
      'startTimeJST': startTimeJst,
      'timezone': timezone,
      'status': status.name,
      if (venue != null) 'venue': venue,
      if (homeScore != null) 'homeScore': homeScore,
      if (awayScore != null) 'awayScore': awayScore,
      'broadcastPlatforms': broadcastPlatforms.map((b) => b.toMap()).toList(),
      if (externalFixtureId != null) 'externalFixtureId': externalFixtureId,
      // Legacy alias.
      if (externalFixtureId != null) 'rapidApiFixtureId': externalFixtureId,
    };
  }

  DateTime get startTimeUtcDateTime => startTimeUtc.toDate();
}
