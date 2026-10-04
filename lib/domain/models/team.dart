import '../../core/utils/app_constants.dart';
import 'firestore_decode.dart';

/// A sports team stored in Firestore under /teams/{id}.
///
/// [id] is the stable team identity across competitions and seasons. Canonical
/// participation belongs to a CompetitionSeasonMembership, not this document.
///
/// ## competitionKey and leagueId
/// These are compatibility fields used by current Firestore queries and UI.
/// They describe the legacy/default competition view only and must not be used
/// as the canonical source of a team's competition-season memberships.
///
/// When reading legacy Firestore documents that lack `competitionKey`, the
/// field is left as null rather than guessed from `sportType`.
/// Callers that need a non-null value should handle null explicitly.
///
/// ## Backward compatibility
/// - Firestore field `sportKey` is a legacy alias for `competitionKey`.
///   Both are written on save; `competitionKey` takes precedence on read.
/// - [rapidApiId] is a legacy alias for [externalTeamId].
class Team {
  const Team({
    required this.id,
    required this.nameEn,
    required this.nameJa,
    required this.leagueId,
    this.competitionKey,
    this.logoUrl,
    this.country,
    this.externalTeamId,
    @Deprecated('Use externalTeamId') this.rapidApiId,
  });

  final String id;
  final String nameEn;
  final String nameJa;

  /// Legacy/default league used by existing queries; not canonical membership.
  final String leagueId;

  /// Legacy/default competition key matching [SportDefinition.competitionKey].
  /// Null when the Firestore document predates Phase 0; not canonical
  /// competition-season membership.
  final String? competitionKey;

  final String? logoUrl;
  final String? country;

  /// External API team ID (API-SPORTS or other source).
  final int? externalTeamId;

  /// @deprecated Use [externalTeamId].
  // ignore: deprecated_member_use_from_same_package
  final int? rapidApiId;

  factory Team.fromFirestore(Map<String, dynamic> data, String docId) {
    final decoder = FirestoreDecoder(
      collection: AppConstants.teamsCollection,
      documentId: docId,
    );
    // Prefer the new `competitionKey` field; fall back to legacy `sportKey`.
    // Do NOT infer from `sportType` — ambiguous inference is worse than null.
    final competitionKey = readLegacyCompetitionKey(decoder, data);
    final externalTeamId = decoder.optional<int>(
      data,
      'externalTeamId',
      expected: 'int',
    );
    final rapidApiId = decoder.optional<int>(
      data,
      'rapidApiId',
      expected: 'int',
    );

    return Team(
      id: docId,
      nameEn: decoder.require<String>(data, 'nameEn', expected: 'String'),
      nameJa: decoder.require<String>(data, 'nameJa', expected: 'String'),
      leagueId: decoder.require<String>(data, 'leagueId', expected: 'String'),
      competitionKey: competitionKey,
      logoUrl: decoder.optional<String>(data, 'logoUrl', expected: 'String'),
      country: decoder.optional<String>(data, 'country', expected: 'String'),
      externalTeamId: externalTeamId ?? rapidApiId,
      // ignore: deprecated_member_use_from_same_package
      rapidApiId: rapidApiId,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'nameEn': nameEn,
      'nameJa': nameJa,
      'leagueId': leagueId,
      if (competitionKey != null) 'competitionKey': competitionKey,
      // Legacy alias — kept so existing queries on `sportKey` still work.
      if (competitionKey != null) 'sportKey': competitionKey,
      if (logoUrl != null) 'logoUrl': logoUrl,
      if (country != null) 'country': country,
      if (externalTeamId != null) 'externalTeamId': externalTeamId,
      // Legacy alias.
      if (externalTeamId != null) 'rapidApiId': externalTeamId,
    };
  }

  Team copyWith({
    String? id,
    String? nameEn,
    String? nameJa,
    String? leagueId,
    String? competitionKey,
    String? logoUrl,
    String? country,
    int? externalTeamId,
  }) {
    return Team(
      id: id ?? this.id,
      nameEn: nameEn ?? this.nameEn,
      nameJa: nameJa ?? this.nameJa,
      leagueId: leagueId ?? this.leagueId,
      competitionKey: competitionKey ?? this.competitionKey,
      logoUrl: logoUrl ?? this.logoUrl,
      country: country ?? this.country,
      externalTeamId: externalTeamId ?? this.externalTeamId,
    );
  }
}
