/// A sports team stored in Firestore under /teams/{id}.
///
/// ## competitionKey
/// Identifies which competition (league) this team belongs to.
/// Must match a [SportDefinition.competitionKey] in [SportsRegistry].
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
  final String leagueId;

  /// Competition key matching [SportDefinition.competitionKey].
  /// null when the Firestore document predates Phase 0.
  final String? competitionKey;

  final String? logoUrl;
  final String? country;

  /// External API team ID (API-SPORTS or other source).
  final int? externalTeamId;

  /// @deprecated Use [externalTeamId].
  // ignore: deprecated_member_use_from_same_package
  final int? rapidApiId;

  factory Team.fromFirestore(Map<String, dynamic> data, String docId) {
    // Prefer the new `competitionKey` field; fall back to legacy `sportKey`.
    // Do NOT infer from `sportType` — ambiguous inference is worse than null.
    final competitionKey =
        data['competitionKey'] as String? ?? data['sportKey'] as String?;

    return Team(
      id: docId,
      nameEn: data['nameEn'] as String,
      nameJa: data['nameJa'] as String,
      leagueId: data['leagueId'] as String,
      competitionKey: competitionKey,
      logoUrl: data['logoUrl'] as String?,
      country: data['country'] as String?,
      externalTeamId: data['externalTeamId'] as int? ??
          data['rapidApiId'] as int?,
      // ignore: deprecated_member_use_from_same_package
      rapidApiId: data['rapidApiId'] as int?,
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
