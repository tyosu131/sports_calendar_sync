import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/utils/app_constants.dart';
import '../../domain/models/competition_season_membership.dart';
import '../../domain/policies/competition_season_membership_policy.dart';

/// Read-only access to competition-season membership documents.
abstract class CompetitionMembershipRepository {
  /// Returns the best readable membership for [competitionKey], if any.
  Future<CompetitionSeasonMembership?> findReadableMembershipForCompetition(
    String competitionKey,
  );
}

class FirestoreCompetitionMembershipRepository
    implements CompetitionMembershipRepository {
  FirestoreCompetitionMembershipRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _memberships => _firestore
      .collection(AppConstants.competitionSeasonMembershipsCollection);

  @override
  Future<CompetitionSeasonMembership?> findReadableMembershipForCompetition(
    String competitionKey,
  ) async {
    final key = competitionKey.trim();
    if (key.isEmpty) return null;

    final snapshot = await _memberships
        .where('competitionKey', isEqualTo: key)
        .get();

    CompetitionSeasonMembership? best;
    for (final doc in snapshot.docs) {
      final parsed = _fromFirestore(doc.data(), doc.id);
      if (parsed == null || !membershipIsReadable(parsed)) continue;
      if (best == null || parsed.seasonYear > best.seasonYear) {
        best = parsed;
      } else if (parsed.seasonYear == best.seasonYear &&
          parsed.competitionSeasonKey.compareTo(best.competitionSeasonKey) >
              0) {
        best = parsed;
      }
    }
    return best;
  }

  CompetitionSeasonMembership? _fromFirestore(
    Map<String, dynamic> data,
    String docId,
  ) {
    final competitionKey = data['competitionKey'] as String?;
    final seasonYear = data['seasonYear'];
    final displayNameJa = data['displayNameJa'] as String?;
    final membershipType = data['membershipType'] as String?;
    final status = data['status'] as String?;
    final seedable = data['seedable'];
    if (competitionKey == null ||
        seasonYear is! num ||
        displayNameJa == null ||
        membershipType == null ||
        status == null ||
        seedable is! bool) {
      return null;
    }

    List<String>? memberTeamIds;
    final rawIds = data['memberTeamIds'];
    if (rawIds is List) {
      memberTeamIds = rawIds.whereType<String>().toList(growable: false);
    }

    List<CompetitionSeasonMembershipGroup>? groups;
    final rawGroups = data['groups'];
    if (rawGroups is List) {
      final parsed = <CompetitionSeasonMembershipGroup>[];
      for (final entry in rawGroups) {
        if (entry is! Map) continue;
        final groupKey = entry['groupKey'];
        final nameJa = entry['displayNameJa'];
        final teamIds = entry['teamIds'];
        if (groupKey is! String || nameJa is! String || teamIds is! List) {
          continue;
        }
        parsed.add(
          CompetitionSeasonMembershipGroup(
            groupKey: groupKey,
            displayNameJa: nameJa,
            teamIds: teamIds.whereType<String>().toList(growable: false),
          ),
        );
      }
      if (parsed.isNotEmpty) groups = parsed;
    }

    return CompetitionSeasonMembership(
      competitionSeasonKey: data['competitionSeasonKey'] as String? ?? docId,
      competitionKey: competitionKey,
      seasonYear: seasonYear.toInt(),
      displayNameJa: displayNameJa,
      membershipType: membershipType,
      status: status,
      seedable: seedable,
      memberTeamIds: memberTeamIds,
      groups: groups,
    );
  }
}

/// Sample memberships mirror reviewed local data only. No invented rosters.
class SampleCompetitionMembershipRepository
    implements CompetitionMembershipRepository {
  static const _memberships = <CompetitionSeasonMembership>[
    CompetitionSeasonMembership(
      competitionSeasonKey: 'football_j2_j3_2026_hyakunen',
      competitionKey: 'football_j2_j3_special',
      seasonYear: 2026,
      displayNameJa: '明治安田Ｊ２・Ｊ３百年構想リーグ',
      membershipType: 'special_tournament',
      status: 'seedable',
      seedable: true,
      groups: [
        CompetitionSeasonMembershipGroup(
          groupKey: 'east_a',
          displayNameJa: 'EAST-A',
          teamIds: ['vegalta_sendai', 'jubilo_iwata'],
        ),
      ],
    ),
  ];

  @override
  Future<CompetitionSeasonMembership?> findReadableMembershipForCompetition(
    String competitionKey,
  ) async {
    CompetitionSeasonMembership? best;
    for (final membership in _memberships) {
      if (membership.competitionKey != competitionKey) continue;
      if (!membershipIsReadable(membership)) continue;
      if (best == null || membership.seasonYear > best.seasonYear) {
        best = membership;
      }
    }
    return best;
  }
}
