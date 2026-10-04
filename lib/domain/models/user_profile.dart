import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/utils/app_constants.dart';
import 'firestore_decode.dart';

/// User profile stored in Firestore under /users/{uid}.
///
/// ## Canonical follow state
/// [followedTeamIds] is the authoritative list of stable team IDs followed by
/// the user. Following a team is independent of the competition in which the
/// team was discovered.
///
/// ## Compatibility fields
/// - [selectedCompetitions]: competition keys the user has opted into.
///   Each value must match a [SportDefinition.competitionKey] in [SportsRegistry].
/// - [favoriteTeamIdsByCompetition]: map from competitionKey to list of team IDs.
/// These fields remain readable and writable for existing documents, but they
/// are not canonical follow state.
///
/// ## Backward compatibility
/// - Legacy Firestore documents that only have `followedTeamIds` are read
///   correctly; [selectedCompetitions] and [favoriteTeamIdsByCompetition]
///   will be empty.
class UserProfile {
  const UserProfile({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.selectedCompetitions = const [],
    this.favoriteTeamIdsByCompetition = const {},
    this.followedTeamIds = const [],
    this.preferredLanguage = 'ja',
    this.createdAt,
  });

  final String uid;
  final String email;
  final String? displayName;
  final String? photoUrl;

  /// Compatibility field: competition keys the user has opted into.
  /// This is not canonical follow state.
  /// Each value matches [SportDefinition.competitionKey] in [SportsRegistry].
  /// Examples: ["football_j1", "baseball_npb"]
  final List<String> selectedCompetitions;

  /// Compatibility field mapping competitionKey to team IDs.
  /// This is not canonical follow state.
  /// Example: {"football_j1": ["kashima_antlers"], "baseball_npb": ["yomiuri_giants"]}
  final Map<String, List<String>> favoriteTeamIdsByCompetition;

  /// Stable team IDs currently followed by the user.
  /// This flat list is the authoritative, competition-independent follow state.
  final List<String> followedTeamIds;

  /// 'ja' or 'en'.
  final String preferredLanguage;

  final Timestamp? createdAt;

  /// Compatibility alias for the canonical [followedTeamIds] list.
  List<String> get allFavoriteTeamIds => followedTeamIds;

  factory UserProfile.fromFirestore(Map<String, dynamic> data, String uid) {
    final decoder = FirestoreDecoder(
      collection: AppConstants.usersCollection,
      documentId: uid,
    );
    final favoriteTeamIdsByCompetition = _favoriteMap(decoder, data);

    // A missing preferredLanguage stays `ja` so an old document can still be
    // shown. The follow write repairs that key. A present non-string fails.
    final preferredLanguage =
        decoder.optional<String>(
          data,
          'preferredLanguage',
          expected: 'String',
        ) ??
        'ja';

    return UserProfile(
      uid: uid,
      email: decoder.optional<String>(data, 'email', expected: 'String') ?? '',
      displayName: decoder.optional<String>(
        data,
        'displayName',
        expected: 'String',
      ),
      photoUrl: decoder.optional<String>(data, 'photoUrl', expected: 'String'),
      selectedCompetitions: decoder.stringList(data, 'selectedCompetitions'),
      favoriteTeamIdsByCompetition: favoriteTeamIdsByCompetition,
      followedTeamIds: decoder.stringList(data, 'followedTeamIds'),
      preferredLanguage: preferredLanguage,
      createdAt: decoder.optional<Timestamp>(
        data,
        'createdAt',
        expected: 'Timestamp',
      ),
    );
  }

  static Map<String, List<String>> _favoriteMap(
    FirestoreDecoder decoder,
    Map<String, dynamic> data,
  ) {
    if (!data.containsKey('favoriteTeamIdsByCompetition') ||
        data['favoriteTeamIdsByCompetition'] == null) {
      return const {};
    }
    final rawMap = data['favoriteTeamIdsByCompetition'];
    if (rawMap is! Map) {
      decoder.fail('favoriteTeamIdsByCompetition', 'Map<String, List>', rawMap);
    }
    final favoriteTeamIdsByCompetition = <String, List<String>>{};
    for (final entry in rawMap.entries) {
      final key = entry.key;
      if (key is! String) {
        decoder.fail('favoriteTeamIdsByCompetition', 'String key', key);
      }
      final value = entry.value;
      if (value is! List) {
        decoder.fail(
          'favoriteTeamIdsByCompetition.$key',
          'List<String>',
          value,
        );
      }
      final ids = <String>[];
      for (var index = 0; index < value.length; index++) {
        final item = value[index];
        if (item is! String) {
          decoder.fail(
            'favoriteTeamIdsByCompetition.$key[$index]',
            'String',
            item,
          );
        }
        ids.add(item);
      }
      favoriteTeamIdsByCompetition[key] = List<String>.unmodifiable(ids);
    }
    return favoriteTeamIdsByCompetition;
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      if (displayName != null) 'displayName': displayName,
      if (photoUrl != null) 'photoUrl': photoUrl,
      'selectedCompetitions': selectedCompetitions,
      'favoriteTeamIdsByCompetition': favoriteTeamIdsByCompetition,
      // Canonical follow state; also consumed by getCalendar.
      'followedTeamIds': followedTeamIds,
      'preferredLanguage': preferredLanguage,
      if (createdAt != null) 'createdAt': createdAt,
    };
  }

  UserProfile copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    List<String>? selectedCompetitions,
    Map<String, List<String>>? favoriteTeamIdsByCompetition,
    List<String>? followedTeamIds,
    String? preferredLanguage,
    Timestamp? createdAt,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      selectedCompetitions: selectedCompetitions ?? this.selectedCompetitions,
      favoriteTeamIdsByCompetition:
          favoriteTeamIdsByCompetition ?? this.favoriteTeamIdsByCompetition,
      followedTeamIds: followedTeamIds ?? this.followedTeamIds,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Returns compatibility team IDs recorded for a specific competition.
  /// This does not determine whether a team is globally followed.
  List<String> favoriteTeamIdsForCompetition(String competitionKey) =>
      favoriteTeamIdsByCompetition[competitionKey] ?? [];

  /// Returns true if the compatibility competition preference is selected.
  /// This does not determine whether a team is globally followed.
  bool hasCompetitionSelected(String competitionKey) =>
      selectedCompetitions.contains(competitionKey);
}
