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

    // Query errors, including permission-denied, must propagate. A rules
    // failure is not the same as "no readable membership".
    final snapshot = await _memberships
        .where('competitionKey', isEqualTo: key)
        .get();

    CompetitionSeasonMembership? best;
    for (final doc in snapshot.docs) {
      // A malformed document fails the read. Skipping it would look like
      // "no membership" and fall through to the legacy team query.
      final parsed = CompetitionSeasonMembership.fromFirestore(
        doc.data(),
        doc.id,
      );
      if (!membershipIsReadable(parsed)) continue;
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
