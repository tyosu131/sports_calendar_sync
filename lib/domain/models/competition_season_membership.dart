import '../../core/utils/app_constants.dart';
import 'firestore_decode.dart';

/// Season-scoped competition membership. Canonical team participation lives
/// here, not on [Team.competitionKey].
class CompetitionSeasonMembership {
  const CompetitionSeasonMembership({
    required this.competitionSeasonKey,
    required this.competitionKey,
    required this.seasonYear,
    required this.displayNameJa,
    required this.membershipType,
    required this.status,
    required this.seedable,
    this.memberTeamIds,
    this.groups,
  });

  final String competitionSeasonKey;
  final String competitionKey;
  final int seasonYear;
  final String displayNameJa;
  final String membershipType;
  final String status;
  final bool seedable;
  final List<String>? memberTeamIds;
  final List<CompetitionSeasonMembershipGroup>? groups;

  /// Throws [FirestoreDecodeException] when a present field has the wrong type
  /// or a required field is missing. An unreadable status is still returned;
  /// callers decide whether that document may be listed.
  factory CompetitionSeasonMembership.fromFirestore(
    Map<String, dynamic> data,
    String docId,
  ) {
    final decoder = FirestoreDecoder(
      collection: AppConstants.competitionSeasonMembershipsCollection,
      documentId: docId,
    );
    final seasonYear = decoder.require<int>(
      data,
      'seasonYear',
      expected: 'int',
    );
    return CompetitionSeasonMembership(
      competitionSeasonKey:
          decoder.optional<String>(
            data,
            'competitionSeasonKey',
            expected: 'String',
          ) ??
          docId,
      competitionKey: decoder.require<String>(
        data,
        'competitionKey',
        expected: 'String',
      ),
      seasonYear: seasonYear,
      displayNameJa: decoder.require<String>(
        data,
        'displayNameJa',
        expected: 'String',
      ),
      membershipType: decoder.require<String>(
        data,
        'membershipType',
        expected: 'String',
      ),
      status: decoder.require<String>(data, 'status', expected: 'String'),
      seedable: decoder.require<bool>(data, 'seedable', expected: 'bool'),
      memberTeamIds: _memberTeamIds(decoder, data),
      groups: _groups(decoder, data),
    );
  }

  static List<String>? _memberTeamIds(
    FirestoreDecoder decoder,
    Map<String, dynamic> data,
  ) {
    if (!data.containsKey('memberTeamIds') || data['memberTeamIds'] == null) {
      return null;
    }
    final rawIds = data['memberTeamIds'];
    if (rawIds is! List) {
      decoder.fail('memberTeamIds', 'List<String>', rawIds);
    }
    final ids = <String>[];
    for (var index = 0; index < rawIds.length; index++) {
      final id = rawIds[index];
      if (id is! String) decoder.fail('memberTeamIds[$index]', 'String', id);
      ids.add(id);
    }
    return List<String>.unmodifiable(ids);
  }

  static List<CompetitionSeasonMembershipGroup>? _groups(
    FirestoreDecoder decoder,
    Map<String, dynamic> data,
  ) {
    if (!data.containsKey('groups') || data['groups'] == null) return null;
    final rawGroups = data['groups'];
    if (rawGroups is! List) decoder.fail('groups', 'List<Map>', rawGroups);
    final parsed = <CompetitionSeasonMembershipGroup>[];
    for (var index = 0; index < rawGroups.length; index++) {
      final entry = rawGroups[index];
      if (entry is! Map) decoder.fail('groups[$index]', 'Map', entry);
      final groupKey = entry['groupKey'];
      final nameJa = entry['displayNameJa'];
      final teamIds = entry['teamIds'];
      if (groupKey is! String) {
        decoder.fail('groups[$index].groupKey', 'String', groupKey);
      }
      if (nameJa is! String) {
        decoder.fail('groups[$index].displayNameJa', 'String', nameJa);
      }
      if (teamIds is! List) {
        decoder.fail('groups[$index].teamIds', 'List<String>', teamIds);
      }
      final ids = <String>[];
      for (var teamIndex = 0; teamIndex < teamIds.length; teamIndex++) {
        final id = teamIds[teamIndex];
        if (id is! String) {
          decoder.fail('groups[$index].teamIds[$teamIndex]', 'String', id);
        }
        ids.add(id);
      }
      parsed.add(
        CompetitionSeasonMembershipGroup(
          groupKey: groupKey,
          displayNameJa: nameJa,
          teamIds: List<String>.unmodifiable(ids),
        ),
      );
    }
    return List<CompetitionSeasonMembershipGroup>.unmodifiable(parsed);
  }
}

class CompetitionSeasonMembershipGroup {
  const CompetitionSeasonMembershipGroup({
    required this.groupKey,
    required this.displayNameJa,
    required this.teamIds,
  });

  final String groupKey;
  final String displayNameJa;
  final List<String> teamIds;
}
