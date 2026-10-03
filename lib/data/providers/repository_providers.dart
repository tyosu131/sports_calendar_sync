import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/calendar_feed_repository.dart';
import '../repositories/competition_membership_repository.dart';
import '../repositories/game_repository.dart';
import '../repositories/team_repository.dart';
import '../repositories/user_repository.dart';
import '../services/competition_team_listing.dart';

// ── Repository providers ──────────────────────────────────────────────────────

const useSampleData = bool.fromEnvironment('USE_SAMPLE_DATA');

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return useSampleData ? SampleUserRepository() : FirestoreUserRepository();
});

final teamRepositoryProvider = Provider<TeamRepository>((ref) {
  return useSampleData ? SampleTeamRepository() : FirestoreTeamRepository();
});

final competitionMembershipRepositoryProvider =
    Provider<CompetitionMembershipRepository>((ref) {
      return useSampleData
          ? SampleCompetitionMembershipRepository()
          : FirestoreCompetitionMembershipRepository();
    });

final competitionTeamListingServiceProvider =
    Provider<CompetitionTeamListingService>((ref) {
      return CompetitionTeamListingService(
        teamRepository: ref.watch(teamRepositoryProvider),
        membershipRepository: ref.watch(
          competitionMembershipRepositoryProvider,
        ),
      );
    });

final gameRepositoryProvider = Provider<GameRepository>((ref) {
  return useSampleData ? SampleGameRepository() : FirestoreGameRepository();
});

final calendarFeedRepositoryProvider = Provider<CalendarFeedRepository>((ref) {
  return CalendarFeedRepository.firebase();
});
